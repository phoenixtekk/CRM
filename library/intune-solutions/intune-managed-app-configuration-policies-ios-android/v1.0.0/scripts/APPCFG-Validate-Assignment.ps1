<#
.SYNOPSIS
    APPCFG-Validate-Assignment.ps1 — confirm a device/user received an App Configuration Policy (read-only, Graph).
.DESCRIPTION
    PURPOSE
        Answers "did this policy reach this device (or user)?" for a named managed-device App
        Configuration Policy. Resolves the policy by name, lists its assigned groups, resolves a
        device (by device name) or user (by UPN) and its group memberships, and reports whether the
        target is covered by the policy's assignments. Read-only; makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Validate-Assignment.ps1 -PolicyName "APPCFG - Ariba - iOS - Pilot" -DeviceName "IPAD-PILOT-01"
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Validate-Assignment.ps1 -PolicyName "APPCFG - Outlook - MAM - Pilot" -Upn user@contoso.com -Environment USGov
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All, Directory.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        The policy's assigned groups and a PASS/FAIL: PASS = the device/user is in an assigned group.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Commercial / USGov). No credentials stored.
.EXAMPLE
    .\APPCFG-Validate-Assignment.ps1 -PolicyName "APPCFG - Ariba - iOS - Pilot" -DeviceName "IPAD-PILOT-01"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$DeviceName,
    [string]$Upn,
    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

if (-not $DeviceName -and -not $Upn) { Write-Host "Provide -DeviceName or -Upn." -ForegroundColor Red; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Directory.Read.All','DeviceManagementManagedDevices.Read.All' -Environment $Environment -NoWelcome

# --- resolve the policy (managed-device first, then managed-app) ---
$enc = [uri]::EscapeDataString($PolicyName)
$pol = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileAppConfigurations?`$filter=displayName eq '$enc'&`$expand=assignments").value | Select-Object -First 1
if (-not $pol) {
    $pol = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/targetedManagedAppConfigurations?`$filter=displayName eq '$enc'&`$expand=assignments").value | Select-Object -First 1
}
if (-not $pol) { Write-Host "FAIL: policy '$PolicyName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$assignedGroups = @($pol.assignments | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
Write-Host ("Policy '{0}' assigned to {1} group(s):" -f $PolicyName, $assignedGroups.Count) -ForegroundColor Cyan
foreach ($g in $assignedGroups) {
    $gn = try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$g").displayName } catch { '(unresolved)' }
    Write-Host ("  - {0}  ({1})" -f $gn, $g)
}

# --- resolve target memberships ---
$targetGroups = @()
if ($DeviceName) {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$([uri]::EscapeDataString($DeviceName))'").value | Select-Object -First 1
    if (-not $dev) { Write-Host "FAIL: device '$DeviceName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
    if ($dev.azureADDeviceId) {
        $aad = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=deviceId eq '$($dev.azureADDeviceId)'").value | Select-Object -First 1
        if ($aad) {
            $mem = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices/$($aad.id)/transitiveMemberOf?`$select=id").value
            $targetGroups = @($mem | ForEach-Object { $_.id })
        }
    }
    $who = "device '$DeviceName'"
} else {
    $usr = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$([uri]::EscapeDataString($Upn))").id
    if (-not $usr) { Write-Host "FAIL: user '$Upn' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
    $mem = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$usr/transitiveMemberOf?`$select=id").value
    $targetGroups = @($mem | ForEach-Object { $_.id })
    $who = "user '$Upn'"
}

$hit = $assignedGroups | Where-Object { $targetGroups -contains $_ }
Write-Host ""
if ($hit) {
    Write-Host ("PASS — {0} is covered by policy '{1}' via group {2}." -f $who, $PolicyName, ($hit -join ', ')) -ForegroundColor Green
} else {
    Write-Host ("FAIL — {0} is NOT in any group assigned to '{1}'. Add it to a targeted group and re-sync." -f $who, $PolicyName) -ForegroundColor Red
}
Disconnect-MgGraph | Out-Null
