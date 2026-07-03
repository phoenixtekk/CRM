<#
.SYNOPSIS
    MDEG-Remediation.ps1 — safely fix common MDE integration gaps on a GCC High tenant (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Change script that closes common gaps found by validation: ensures the pilot/prod group
        is assigned to the EDR onboarding policy and to the risk-based compliance policy. Runs
        in preview (-WhatIf) by default and only changes assignments — it never onboards or
        offboards a device. Replace values like your-group-name only if you override the
        defaults. Connects to US Government Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEG-Remediation.ps1              # preview (WhatIf)
        powershell -ExecutionPolicy Bypass -File .\MDEG-Remediation.ps1 -WhatIf:$false -Confirm:$false   # apply
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All,
         Group.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        A list of planned assignment changes. In preview nothing is written. When applied, the
        named group is added to the onboarding and compliance policy assignments. PASS = the
        planned/applied changes match what MDEG-Validation.ps1 reported missing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless you explicitly apply changes.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string] $TenantId,
    [string] $GroupName            = 'SG-MDE-Pilot',
    [string] $EdrPolicyName        = 'MDE - EDR Onboarding - Pilot',
    [string] $CompliancePolicyName = 'CP-Windows-MDE-Risk'
)

$ErrorActionPreference = 'Stop'
# Default to preview unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $p = @{ Environment = 'USGov'; Scopes = @('DeviceManagementConfiguration.ReadWrite.All','Group.Read.All') }
    if ($TenantId) { $p.TenantId = $TenantId }
    Connect-MgGraph @p | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { throw "Connected to '$($ctx.Environment)', not USGov. Aborting on GCC High to avoid changing the wrong tenant." }
}

function Get-GovGroupId {
    param([string] $Name)
    $r = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.us/beta/groups?`$filter=displayName eq '{0}'" -f $Name) -ErrorAction Stop
    (@($r.value) | Select-Object -First 1).id
}

function Get-GovConfigPolicy {
    param([string] $Name)
    $r = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.us/beta/deviceManagement/deviceConfigurations" -ErrorAction Stop
    @($r.value) | Where-Object { $_.displayName -eq $Name } | Select-Object -First 1
}

function Get-GovCompliancePolicy {
    param([string] $Name)
    $r = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.us/beta/deviceManagement/deviceCompliancePolicies" -ErrorAction Stop
    @($r.value) | Where-Object { $_.displayName -eq $Name } | Select-Object -First 1
}

function Add-GroupAssignment {
    param([string] $PolicyKind, [string] $PolicyId, [string] $GroupId, [string] $PolicyName, [string] $GroupName)
    # /assign replaces the assignment set; read current, append the group, write back.
    $base   = "https://graph.microsoft.us/beta/deviceManagement/$PolicyKind/$PolicyId"
    $cur    = Invoke-MgGraphRequest -Method GET -Uri "$base/assignments" -ErrorAction Stop
    $existing = @($cur.value)
    if ($existing | Where-Object { $_.target.groupId -eq $GroupId }) {
        Write-Host ("  Already assigned: '{0}' -> '{1}'. No change." -f $PolicyName, $GroupName) -ForegroundColor DarkGray
        return
    }
    $targets = @()
    foreach ($a in $existing) { $targets += @{ target = $a.target } }
    $targets += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId } }
    $body = @{ assignments = $targets } | ConvertTo-Json -Depth 8

    if ($PSCmdlet.ShouldProcess(("{0} '{1}'" -f $PolicyKind, $PolicyName), ("Assign group '{0}'" -f $GroupName))) {
        Invoke-MgGraphRequest -Method POST -Uri "$base/assign" -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
        Write-Host ("  APPLIED: assigned '{0}' -> '{1}'." -f $PolicyName, $GroupName) -ForegroundColor Green
    } else {
        Write-Host ("  WHATIF: would assign '{0}' -> '{1}'." -f $PolicyName, $GroupName) -ForegroundColor Yellow
    }
}

try {
    Connect-UsGovGraph -TenantId $TenantId
    if ($WhatIfPreference) { Write-Host "Running in PREVIEW (-WhatIf). No changes will be written. Re-run with -WhatIf:`$false -Confirm:`$false to apply." -ForegroundColor Cyan }

    $groupId = Get-GovGroupId -Name $GroupName
    if (-not $groupId) { throw "Group '$GroupName' not found. Create it first (03-implementation.md Step 3)." }

    Write-Host "`nChecking EDR onboarding policy assignment..." -ForegroundColor Cyan
    $edr = Get-GovConfigPolicy -Name $EdrPolicyName
    if ($edr) { Add-GroupAssignment 'deviceConfigurations' $edr.id $groupId $EdrPolicyName $GroupName }
    else { Write-Warning "EDR onboarding policy '$EdrPolicyName' not found — create it (03-implementation.md Step 4)." }

    Write-Host "`nChecking risk-based compliance policy assignment..." -ForegroundColor Cyan
    $cp = Get-GovCompliancePolicy -Name $CompliancePolicyName
    if ($cp) { Add-GroupAssignment 'deviceCompliancePolicies' $cp.id $groupId $CompliancePolicyName $GroupName }
    else { Write-Warning "Compliance policy '$CompliancePolicyName' not found — create it (03-implementation.md Step 6)." }

    Write-Host "`nDone. Re-run MDEG-Validation.ps1 to confirm the gate is green." -ForegroundColor Green
}
catch {
    Write-Error ("Remediation failed: {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
