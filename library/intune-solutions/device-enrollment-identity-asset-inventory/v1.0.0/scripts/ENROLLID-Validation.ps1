<#
.SYNOPSIS
    ENROLLID-Validation.ps1 — confirm a device is enrolled and check its primary-user association (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        For one device (by name), verifies it exists as an Intune managed device and reports its
        primary user. Optionally checks the primary user matches an expected user, so you can confirm
        the identity association is correct before relying on service-desk lookup.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENROLLID-Validation.ps1 -DeviceName PC-001 [-ExpectedUser user@contoso.com] [-ExpectShared]
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        "ENROLLED + PRIMARY USER OK" when the device is enrolled and the primary user matches the
        expectation (a set user, or None when -ExpectShared).
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)] [string]$DeviceName,
    [string]$ExpectedUser,
    [switch]$ExpectShared
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
Write-Host "=== ENROLLID Validation — $DeviceName ===" -ForegroundColor Cyan
$enc = [uri]::EscapeDataString($DeviceName)
$res = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$enc'").value
if (-not $res) { Write-Host "Result: NOT ENROLLED — no managed device named '$DeviceName'." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
$d = $res | Select-Object -First 1
Write-Host ("Enrolled       : YES ({0}, {1})" -f $d.operatingSystem, $d.osVersion) -ForegroundColor Green
Write-Host ("Ownership      : {0}" -f $d.managedDeviceOwnerType)
# primary user via the managedDevice -> users relationship
$pu = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices/$($d.id)/users").value
$puUpn = if ($pu) { ($pu | Select-Object -First 1).userPrincipalName } else { $null }
Write-Host ("Primary user   : {0}" -f ($(if($puUpn){$puUpn}else{'None'})))
$ok = $true
if ($ExpectShared) { if ($puUpn) { $ok = $false; Write-Host "  Expected None (shared) but a primary user is set." -ForegroundColor Yellow } }
elseif ($ExpectedUser) { if ($puUpn -ne $ExpectedUser) { $ok = $false; Write-Host ("  Expected primary user {0}." -f $ExpectedUser) -ForegroundColor Yellow } }
elseif (-not $puUpn) { $ok = $false; Write-Host "  No primary user set (expected one for an assigned device)." -ForegroundColor Yellow }
if ($ok) { Write-Host "`nResult: ENROLLED + PRIMARY USER OK" -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }
else { Write-Host "`nResult: PRIMARY USER MISMATCH — fix with ENROLLID-Remediation.ps1" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
