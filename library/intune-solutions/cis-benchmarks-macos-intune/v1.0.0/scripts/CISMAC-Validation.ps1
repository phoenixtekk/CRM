<#
.SYNOPSIS
    CISMAC-Validation.ps1 — per-device CIS-compliance check for a Mac (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Checks one Mac's effective Intune configuration state against the CIS macOS baseline policies
        it should have, and reports per-policy PASS/DRIFT. It reads, for the named device, the Intune
        deviceConfigurationStates / per-policy status for the CIS macOS objects (settings catalog,
        custom profiles, shell scripts) and flags any that are not 'compliant'/'succeeded'.
        Read-only — it does not change settings. (On-device CIS enforcement is delivered by Apple
        .mobileconfig payloads and shell scripts; this script reports the Intune view of them.)
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISMAC-Validation.ps1 -DeviceName "MAC-001" -PolicyNameLike "CIS macOS"
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All +
        DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A per-policy PASS/DRIFT table for that Mac and "DEVICE COMPLIANT" when no drift is found.
.NOTES
    Intune Solutions — CIS macOS. Read-only. Control values are deferred to the CIS Benchmark.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$DeviceName,
    [string]$PolicyNameLike = 'CIS macOS'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host ("=== CIS macOS Validation — {0} ===" -f $DeviceName) -ForegroundColor Cyan

$dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $DeviceName)).value | Select-Object -First 1
if (-not $dev) { Write-Host "Mac not found in Intune (check -DeviceName)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 2 }

# Per-policy configuration states for this device, filtered to the CIS macOS objects
$states = (Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/managedDevices/{0}/deviceConfigurationStates" -f $dev.id)).value
$cis = $states | Where-Object { $_.displayName -like ("*{0}*" -f $PolicyNameLike) }

if (-not $cis) { Write-Host "  No CIS macOS policy states found for this device (is it in the assigned group and synced?)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 2 }

$drift = 0
foreach ($s in $cis) {
    $ok = $s.state -in @('compliant','succeeded')
    if (-not $ok) { $drift++ }
    $status = if ($ok) { 'PASS' } else { 'DRIFT' }
    $color  = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1}  (state={2})" -f $status, $s.displayName, $s.state) -ForegroundColor $color
}

if ($drift -eq 0) { Write-Host "`nResult: DEVICE COMPLIANT" -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }
else { Write-Host ("`nResult: {0} CIS macOS object(s) DRIFTED — run CISMAC-Remediation.ps1 to reapply." -f $drift) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
