<#
.SYNOPSIS
    MACMDE-Validation.ps1 — per-device MDE-for-macOS onboarding readiness check (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Checks one Mac's Intune state for the MDE-for-macOS object set and confirms the correct
        ORDER: that the five capability profiles (System Extensions, Full Disk Access, Network Filter,
        Background Services, Notifications) are in a good state, the Microsoft Defender app is
        installed, and the onboarding profile is applied. Flags the dangerous case where onboarding
        is applied while a capability profile is not. Read-only — it does not change anything.
        (The definitive agent health — extensions running, real-time protection on — is read on the
        Mac itself with 'mdatp health'; this script proves the Intune management prerequisites.)
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACMDE-Validation.ps1 -DeviceName MAC-001
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All,
        DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A per-object PASS/DRIFT table for that Mac and 'DEVICE READY' when the five profiles pass,
        the app is installed, and onboarding is applied. Warns if onboarding is applied before the
        capability profiles are healthy.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$DeviceName,
    [string]$NameLike = 'MDE macOS'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

Write-Host ("=== MDE macOS Validation — {0} ===" -f $DeviceName) -ForegroundColor Cyan

$dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $DeviceName)).value | Select-Object -First 1
if (-not $dev) { Write-Host "Mac not found in Intune (check -DeviceName)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 2 }

# The five capability profiles (order matters) + the onboarding profile
$capabilityNames = @(
    'MDE macOS – System Extensions',
    'MDE macOS – Full Disk Access',
    'MDE macOS – Network Filter',
    'MDE macOS – Background Services',
    'MDE macOS – Notifications'
)
$onboardingName = 'MDE macOS – Onboarding'

# Per-profile configuration states for this device, filtered to the MDE macOS objects
$states = (Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/managedDevices/{0}/deviceConfigurationStates" -f $dev.id)).value
$mde = $states | Where-Object { $_.displayName -like ("*{0}*" -f $NameLike) }

if (-not $mde) { Write-Host "  No '$NameLike' profile states found for this device (is it in the assigned group and synced?)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 2 }

function Get-State([string]$wantName) {
    $s = $mde | Where-Object { $_.displayName -like ("*{0}*" -f $wantName) } | Select-Object -First 1
    if ($s) { return $s.state } else { return 'missing' }
}

$capDrift = 0
Write-Host "`nCapability profiles (must be healthy BEFORE onboarding):" -ForegroundColor Cyan
foreach ($n in $capabilityNames) {
    $st = Get-State $n
    $ok = $st -in @('compliant','succeeded')
    if (-not $ok) { $capDrift++ }
    $status = if ($ok) { 'PASS' } else { 'DRIFT' }
    $color  = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1}  (state={2})" -f $status, $n, $st) -ForegroundColor $color
}

# Onboarding profile state
$onboardState = Get-State $onboardingName
$onboardOk = $onboardState -in @('compliant','succeeded')
Write-Host "`nOnboarding profile:" -ForegroundColor Cyan
Write-Host ("  [{0}] {1}  (state={2})" -f ($(if($onboardOk){'PASS'}else{'DRIFT'})), $onboardingName, $onboardState) -ForegroundColor ($(if($onboardOk){'Green'}else{'Yellow'}))

# Microsoft Defender app install state for this device
$appOk = $false
try {
    $appStates = (Invoke-MgGraphRequest -Method GET -Uri ("/beta/users/{0}/mobileAppIntentAndStates/{1}" -f $dev.userId, $dev.id)).mobileAppList 2>$null
} catch { $appStates = $null }
$defApp = $appStates | Where-Object { $_.displayName -match 'Defender' } | Select-Object -First 1
if ($defApp) { $appOk = ($defApp.installState -eq 'installed'); Write-Host ("`nDefender app       : {0} (installState={1})" -f ($(if($appOk){'PASS'}else{'CHECK'})), $defApp.installState) -ForegroundColor ($(if($appOk){'Green'}else{'Yellow'})) }
else { Write-Host "`nDefender app       : state not resolved from Graph — confirm in Intune → Apps → macOS (MDE macOS – Defender App)." -ForegroundColor Yellow }

# Order safety: onboarding applied while a capability profile is not healthy = degraded-agent risk
if ($onboardOk -and $capDrift -gt 0) {
    Write-Host ("`n*** ORDER WARNING: onboarding is applied but {0} capability profile(s) are NOT healthy —" -f $capDrift) -ForegroundColor Red
    Write-Host "    the agent may be SILENTLY DEGRADED. Fix the capability profiles, then re-check 'mdatp health' on the Mac." -ForegroundColor Red
}

Write-Host "`nOn the Mac, confirm the agent is truly healthy:" -ForegroundColor Cyan
Write-Host "  mdatp health   ;   systemextensionsctl list   ;   mdatp connectivity test" -ForegroundColor DarkGray

if ($capDrift -eq 0 -and $onboardOk) { Write-Host "`nResult: DEVICE READY (profiles healthy, onboarding applied). Verify mdatp health on the device." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }
else { Write-Host ("`nResult: NOT READY — {0} capability profile(s) drifted; onboarding {1}. See 03-implementation / 06-troubleshooting." -f $capDrift, ($(if($onboardOk){'applied'}else{'not applied'}))) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
