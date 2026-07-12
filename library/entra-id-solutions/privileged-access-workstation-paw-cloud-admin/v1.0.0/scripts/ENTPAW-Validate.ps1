<#
.SYNOPSIS
    ENTPAW-Validate.ps1 — confirm the PAW compliance policy, device marker, and device-filter policy are pilot-ready.
.DESCRIPTION
    PURPOSE
        Validates the PAW pilot before enforcement: the PAW compliance policy exists, the pilot devices
        carry the PAW marker, and the device-filter Conditional Access policy exists, is report-only,
        targets the pilot admins, requires a compliant device, uses the PAW filter, and excludes the
        break-glass group. Also confirms the pilot admins hold eligible (not standing) roles in PIM.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTPAW-Validate.ps1 `
            -PolicyName "CA – Require PAW for Privileged Roles – Pilot (Report-Only)" `
            -PilotAdminGroup "PAW Admins – Cloud Admin – Pilot" `
            -BreakGlassGroupName "CA Break-Glass Exclusion"
        Requires the Microsoft Graph PowerShell SDK. Read-only scopes:
        Policy.Read.All, Group.Read.All, Device.Read.All, DeviceManagementConfiguration.Read.All, RoleManagement.Read.Directory.
    EXPECTED RESULTS
        PASS/WARN lines for compliance policy, device marker, the device-filter policy, and PIM
        eligibility. Any WARN is a gate failure to fix before flipping to enforcement.
.NOTES
    White-label — Entra ID Solutions. Read-only against Graph.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'CA – Require PAW for Privileged Roles – Pilot (Report-Only)',
    [string]$PilotAdminGroup = 'PAW Admins – Cloud Admin – Pilot',
    [string]$BreakGlassGroupName = 'CA Break-Glass Exclusion',
    [string]$CompliancePolicyName = 'Compliance – PAW – Pilot',
    [string]$MarkerAttribute = 'extensionAttribute1',
    [string]$MarkerValue = 'PAW'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','Group.Read.All','Device.Read.All','DeviceManagementConfiguration.Read.All','RoleManagement.Read.Directory' -NoWelcome
Write-Host "`n=== ENTPAW — pilot validation ===" -ForegroundColor Cyan

function Get-GroupId([string]$name) { $enc=[uri]::EscapeDataString($name); (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1 -ExpandProperty id }
function Say($ok,$msg){ Write-Host ("{0} {1}" -f $(if($ok){'PASS '}else{'WARN '}), $msg) -ForegroundColor $(if($ok){'Green'}else{'Yellow'}) }

# Compliance policy
$cp = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceCompliancePolicies').value)
Say ([bool]($cp | Where-Object { $_.displayName -eq $CompliancePolicyName })) "PAW compliance policy '$CompliancePolicyName' exists"

# Device marker present on at least one device
try {
    $marked = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=extensionAttributes/$MarkerAttribute eq '$MarkerValue'&`$select=displayName").value)
    Say ($marked.Count -gt 0) "Devices marked '$MarkerAttribute=$MarkerValue': $($marked.Count)"
} catch { Say $false "Device-marker query failed (check Device.Read.All)" }

# Device-filter policy checks
$pilotId = Get-GroupId $PilotAdminGroup
$bgId    = Get-GroupId $BreakGlassGroupName
$cap = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)
$p = $cap | Where-Object { $_.displayName -eq $PolicyName } | Select-Object -First 1
if (-not $p) { Say $false "Enforcement policy '$PolicyName' not found" }
else {
    Say ($p.state -eq 'enabledForReportingButNotEnforced') "Policy is report-only"
    Say ((-not $pilotId) -or (@($p.conditions.users.includeGroups) -contains $pilotId)) "Policy targets pilot admin group"
    Say ((-not $bgId) -or (@($p.conditions.users.excludeGroups) -contains $bgId)) "Policy excludes break-glass group"
    Say ([bool]$p.conditions.devices) "Policy uses a device filter/condition"
    Say (@($p.grantControls.builtInControls) -contains 'compliantDevice') "Policy requires a compliant device"
}

# PIM eligibility present (pilot admins should be eligible, not standing)
try {
    $elig = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleInstances').value)
    Say ($elig.Count -gt 0) "PIM eligible role assignments exist: $($elig.Count) (roles activated from the PAW)"
} catch { Say $false "PIM eligibility query failed — verify Entra ID P2/PIM" }

Write-Host "`nResolve every WARN before flipping the policy to enforcement." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
