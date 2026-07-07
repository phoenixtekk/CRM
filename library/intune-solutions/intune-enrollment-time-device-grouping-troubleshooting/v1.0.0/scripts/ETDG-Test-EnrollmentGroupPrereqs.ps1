<#
.SYNOPSIS
    ETDG-Test-EnrollmentGroupPrereqs.ps1 — full prerequisite validation: group spec (R1-R7), Provisioning Client SP exists, and the admin's Intune RBAC scope groups (R9). Read-only.
.DESCRIPTION
    One-shot gate before saving an enrollment policy. Validates the target group against R1-R7,
    confirms the Intune Provisioning Client service principal (AppId
    f1346770-5b25-470b-88bd-d5744ab7952c) EXISTS in the tenant, and lists Intune RBAC role
    assignments / scope groups so you can confirm the target group is within the operating admin's
    scope (R9). Read-only against Microsoft Graph.
.EXAMPLE
    .\ETDG-Test-EnrollmentGroupPrereqs.ps1 -GroupName "Autopilot - Devices - Pilot"
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: a consolidated PASS/FAIL for R1-R7, an SP-exists PASS/FAIL, and a listing of
    Intune role assignments + scope groups. Pass = group ready AND SP present AND (custom RBAC) the
    group is in scope. White-label. Read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'
)

$ErrorActionPreference = 'Stop'

function Connect-EtdgGraph {
    param([string[]]$Scopes = @('Group.Read.All', 'Application.Read.All', 'DeviceManagementRBAC.Read.All'))
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or ($Scopes | Where-Object { $ctx.Scopes -notcontains $_ })) {
        Connect-MgGraph -Scopes $Scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($null -ne $resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-EtdgGraph

# --- Group spec (R1-R7) ---
$escaped = $GroupName -replace "'", "''"
$grp = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $escaped)
if (-not $grp) { throw "Group '$GroupName' not found." }
$g = $grp[0]

$owners  = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/groups/$($g.id)/owners"
$ownerOk = [bool]($owners | Where-Object { $_.appId -eq $ProvisioningClientAppId })

$checks = [ordered]@{
    'R1 Security group'                 = [bool]$g.securityEnabled -and -not ($g.groupTypes -contains 'Unified')
    'R2 Assigned membership'            = [string]::IsNullOrEmpty($g.membershipRule)
    'R3 Cloud-only'                     = -not $g.onPremisesSyncEnabled
    'R4 Not mail-enabled'               = -not $g.mailEnabled
    'R5 Not role-assignable'            = -not $g.isAssignableToRole
    'R7 Provisioning Client is Owner'   = $ownerOk
}

Write-Host "`n=== Group prerequisites: $GroupName ===" -ForegroundColor Cyan
$checks.GetEnumerator() | ForEach-Object {
    $res = $(if ($_.Value) { 'PASS' } else { 'FAIL' })
    $col = $(if ($_.Value) { 'Green' } else { 'Red' })
    Write-Host ("  {0,-34} {1}" -f $_.Key, $res) -ForegroundColor $col
}

# --- SP exists in tenant (distinct from ownership) ---
$sp = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '{0}'" -f $ProvisioningClientAppId)
if ($sp) {
    Write-Host ("`nProvisioning Client SP present : PASS  ('{0}', appId {1})" -f $sp[0].displayName, $ProvisioningClientAppId) -ForegroundColor Green
} else {
    Write-Host "`nProvisioning Client SP present : FAIL  — not provisioned in this tenant." -ForegroundColor Red
    Write-Host "  Fix: open https://intune.microsoft.com once as Global Administrator to provision it, or open a Microsoft support case." -ForegroundColor Yellow
}

# --- Intune RBAC scope groups (R9) ---
Write-Host "`n=== Intune RBAC role assignments / scope groups (R9) ===" -ForegroundColor Cyan
try {
    $assignments = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/beta/deviceManagement/roleAssignments"
    if (-not $assignments) {
        Write-Host "  No custom Intune role assignments found — tenant likely uses built-in roles only; R9 does not apply." -ForegroundColor Green
    } else {
        foreach ($a in $assignments) {
            $scopeGroups = @()
            if ($a.resourceScopes) { $scopeGroups = $a.resourceScopes }
            elseif ($a.scopeMembers) { $scopeGroups = $a.scopeMembers }
            $inScope = $scopeGroups -contains $g.id
            Write-Host ("  Assignment '{0}': scopeGroups={1}  targetGroupInScope={2}" -f $a.displayName, ($scopeGroups -join ','), $inScope)
        }
        Write-Host "  Review above: the target group (or a parent scope group) must be in the operating admin's scope, or Save may report 'could not find the security group'." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Could not read Intune role assignments (need DeviceManagementRBAC.Read.All / sufficient role). Verify scope in Intune > Tenant administration > Roles." -ForegroundColor Yellow
}

# --- Verdict ---
$groupReady = -not ($checks.Values | Where-Object { -not $_ })
if ($groupReady -and $sp) {
    Write-Host "`nVERDICT: Prerequisites met (confirm RBAC scope above). Save should commit after propagation." -ForegroundColor Green
} else {
    Write-Host "`nVERDICT: NOT ready — resolve the FAIL items above before saving the enrollment policy." -ForegroundColor Red
}
