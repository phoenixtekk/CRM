<#
.SYNOPSIS
    ENTPAW-Discovery.ps1 — inventory privileged roles/holders, device compliance, CA device-filter policies, and the PAW marker.
.DESCRIPTION
    PURPOSE
        Records the before-state for a PAW rollout: who holds privileged directory roles, existing
        Intune device compliance policies, any Conditional Access policies that already use a device
        condition/filter, and whether the chosen device-marker attribute (extensionAttribute1) is
        already in use. This is the baseline you keep for rollback.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTPAW-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. Read-only scopes:
        RoleManagement.Read.Directory, Policy.Read.All, Device.Read.All,
        DeviceManagementConfiguration.Read.All, User.Read.All.
    EXPECTED RESULTS
        A printed inventory: privileged role holders, compliance policies, CA device-filter policies,
        and current devices already tagged with the PAW marker.
.NOTES
    White-label — Entra ID Solutions. Read-only against Graph. Verify Intune + Entra ID P2 availability.
#>
[CmdletBinding()]
param([string]$MarkerAttribute = 'extensionAttribute1', [string]$MarkerValue = 'PAW')
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','Policy.Read.All','Device.Read.All','DeviceManagementConfiguration.Read.All','User.Read.All' -NoWelcome

Write-Host "`n=== ENTPAW — PAW rollout before-state ===" -ForegroundColor Cyan

# Privileged directory role holders (sample of high-value roles)
$roleDefs = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleDefinitions').value)
$targets  = @('Global Administrator','Privileged Role Administrator','Security Administrator','Application Administrator','User Administrator','Exchange Administrator')
Write-Host "Privileged role assignments (active):"
foreach ($rn in $targets) {
    $rd = $roleDefs | Where-Object { $_.displayName -eq $rn } | Select-Object -First 1
    if (-not $rd) { continue }
    $assign = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/roleManagement/directory/roleAssignments?`$filter=roleDefinitionId eq '$($rd.id)'").value)
    Write-Host ("  {0,-32}: {1}" -f $rn, $assign.Count)
}

# Intune compliance policies
try {
    $cp = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceCompliancePolicies').value)
    Write-Host ("`nIntune compliance policies     : {0}" -f $cp.Count)
    $cp | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }
} catch { Write-Host "`nCompliance query failed — verify Intune licensing/permissions." -ForegroundColor Yellow }

# CA policies that use a device condition/filter
$cap = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)
$devPols = @($cap | Where-Object { $_.conditions.devices -or $_.grantControls.builtInControls -contains 'compliantDevice' })
Write-Host ("`nCA policies using a device condition/filter: {0}" -f $devPols.Count)
$devPols | ForEach-Object { Write-Host ("  [{0}] {1}" -f $_.state, $_.displayName) }

# Devices already carrying the PAW marker
try {
    $marked = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=extensionAttributes/$MarkerAttribute eq '$MarkerValue'&`$select=displayName,deviceId").value)
    Write-Host ("`nDevices already marked '$MarkerAttribute=$MarkerValue': {0}" -f $marked.Count) -ForegroundColor ($(if($marked.Count -gt 0){'Yellow'}else{'Green'}))
    $marked | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }
    if ($marked.Count -gt 0) { Write-Host "  (Confirm every marked device is genuinely a PAW; the marker must be reserved for PAWs.)" -ForegroundColor Yellow }
} catch { Write-Host "`nDevice-marker query failed — check Device.Read.All." -ForegroundColor Yellow }

Write-Host "`nKeep this output as your before-state for rollback." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
