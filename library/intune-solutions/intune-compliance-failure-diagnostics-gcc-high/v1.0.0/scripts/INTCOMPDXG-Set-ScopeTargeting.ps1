<#
.SYNOPSIS
    INTCOMPDXG-Set-ScopeTargeting.ps1 — preview/apply a compliance policy's group assignment on GCC High.
.DESCRIPTION
    PURPOSE
        Scopes a fix by adding (or removing) an Entra security group assignment on a device compliance
        policy, so you can pilot the corrected policy on the affected population before expanding.
        Defaults to preview only (-WhatIf); nothing changes until you re-run with -Execute.
        Provide the policy with -PolicyName 'your-policy-name' and the group with
        -GroupName 'your-group-name'; use -Action Add (default) or -Action Remove.
    HOW TO RUN
        Preview (default, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Set-ScopeTargeting.ps1 -PolicyName your-policy-name -GroupName your-group-name
        Apply after review:
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Set-ScopeTargeting.ps1 -PolicyName your-policy-name -GroupName your-group-name -Execute
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.Read.All; connects with
         -Environment USGov. For DoD tenants pass -CloudEnvironment USGovDoD.)
    EXPECTED RESULTS
        In preview: the current assignments and the single add/remove that WOULD be made, with no
        change. With -Execute: the assignment is updated and the new assignment list is printed.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless
    -Execute is supplied; assignment change defaults to -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$PolicyName,
    [Parameter(Mandatory=$true)][string]$GroupName,
    [ValidateSet('Add','Remove')][string]$Action = 'Add',
    [switch]$Execute,
    [ValidateSet('USGov','USGovDoD')][string]$CloudEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$scopes = @('DeviceManagementConfiguration.ReadWrite.All','Group.Read.All')

function Connect-UsGovGraph {
    param([string]$Env,[string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph modules not found. Install: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env) ..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
    }
    $ctx = Get-MgContext
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. On GCC High use -Environment USGov (or USGovDoD)."
    }
    Write-Host ("Connected: tenant={0} environment={1}" -f $ctx.TenantId,$ctx.Environment) -ForegroundColor Green
}
function Invoke-Graph { param([string]$Method,[string]$Uri,$Body)
    if ($Body) { return Invoke-MgGraphRequest -Method $Method -Uri $Uri -Body ($Body | ConvertTo-Json -Depth 10) -OutputType PSObject }
    return Invoke-MgGraphRequest -Method $Method -Uri $Uri -OutputType PSObject
}

Connect-UsGovGraph -Env $CloudEnvironment -Scopes $scopes

# Resolve the compliance policy by display name.
$penc = [uri]::EscapeDataString($PolicyName)
$policy = @((Invoke-Graph GET "/beta/deviceManagement/deviceCompliancePolicies?`$filter=displayName eq '$penc'").value)[0]
if (-not $policy) { throw "Compliance policy '$PolicyName' not found in this tenant." }
$policyId = $policy.id

# Resolve the group by display name.
$genc = [uri]::EscapeDataString($GroupName)
$group = @((Invoke-Graph GET "/v1.0/groups?`$filter=displayName eq '$genc'").value)[0]
if (-not $group) { throw "Group '$GroupName' not found." }
$groupId = $group.id

# Read current assignments.
$current = @((Invoke-Graph GET "/beta/deviceManagement/deviceCompliancePolicies/$policyId/assignments").value)
$currentGroupIds = @($current | ForEach-Object { $_.target.groupId } | Where-Object { $_ })

Write-Host "`n=== Set Scope Targeting ($CloudEnvironment) ===" -ForegroundColor Cyan
Write-Host ("Policy : {0}" -f $PolicyName) -ForegroundColor Cyan
Write-Host ("Group  : {0} ({1})" -f $GroupName,$groupId) -ForegroundColor Cyan
Write-Host ("Action : {0}" -f $Action) -ForegroundColor Cyan
Write-Host ("Current assignment count: {0}" -f $current.Count) -ForegroundColor DarkCyan

# Compute the desired assignment list.
$alreadyAssigned = $currentGroupIds -contains $groupId
$desired = New-Object System.Collections.Generic.List[object]
foreach ($a in $current) { $desired.Add($a) }

$change = $null
if ($Action -eq 'Add') {
    if ($alreadyAssigned) {
        Write-Host "Group is already assigned; nothing to add." -ForegroundColor Yellow
    } else {
        $desired.Add([pscustomobject]@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$groupId } })
        $change = "ADD group '$GroupName' to policy '$PolicyName'"
    }
}
else {
    if (-not $alreadyAssigned) {
        Write-Host "Group is not currently assigned; nothing to remove." -ForegroundColor Yellow
    } else {
        $desired = New-Object System.Collections.Generic.List[object]
        foreach ($a in $current | Where-Object { $_.target.groupId -ne $groupId }) { $desired.Add($a) }
        $change = "REMOVE group '$GroupName' from policy '$PolicyName'"
    }
}

if (-not $change) { Write-Host "`nNo change required." -ForegroundColor Green; return }

$willChange = $Execute.IsPresent
Write-Host ("`nPlanned change: {0}" -f $change) -ForegroundColor Yellow
Write-Host ("Mode: {0}" -f ($(if($willChange){'EXECUTE (change WILL be applied)'}else{'PREVIEW / -WhatIf (no change)'}))) `
    -ForegroundColor ($(if($willChange){'Yellow'}else{'Green'}))

if (-not $willChange) {
    if ($PSCmdlet.ShouldProcess($change, 'ASSIGN (preview)')) { }
    Write-Host "`nPreview only. Re-run with -Execute to apply." -ForegroundColor Yellow
    return
}

if ($PSCmdlet.ShouldProcess($change, 'ASSIGN')) {
    # The assign action replaces the full assignment set with $desired.
    $body = @{ assignments = @($desired | ForEach-Object { @{ target = $_.target } }) }
    Invoke-Graph POST "/beta/deviceManagement/deviceCompliancePolicies/$policyId/assign" $body | Out-Null
    $after = @((Invoke-Graph GET "/beta/deviceManagement/deviceCompliancePolicies/$policyId/assignments").value)
    Write-Host ("Applied. New assignment count: {0}" -f $after.Count) -ForegroundColor Green
    $after | ForEach-Object { Write-Host ("  - groupId {0}" -f $_.target.groupId) -ForegroundColor DarkGray }
    Write-Host "`nPilot on the assigned group, then validate with INTCOMPDXG-Validation.ps1." -ForegroundColor Green
}
