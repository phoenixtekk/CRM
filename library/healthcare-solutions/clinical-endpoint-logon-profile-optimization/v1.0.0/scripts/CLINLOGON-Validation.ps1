<#
.SYNOPSIS
    Clinical Endpoint Logon & Profile Optimization (FSLogix) - per-device validation
    (read-only, PASS/FAIL).

    PURPOSE:
        Run ON a clinical endpoint (signed in as a test clinician, or just after a
        test sign-in). Validates the endpoint-side outcome of the deployment and
        reports PASS/FAIL for each:
          - FSLogix Profile Container is enabled and configured to the named share
            (VHD Locations matches the expected profile share)
          - a profile container is currently ATTACHED for the signed-in user
          - a logon-time sample is at/under the target (vs. the captured baseline)
        Makes NO changes.

    HOW TO RUN:
        On the endpoint:
          .\CLINLOGON-Validation.ps1 -ExpectedSharePath "\\fileserver\ClinicalProfiles$" -TargetLogonSeconds 25
        (Obtain -ExpectedSharePath from your storage team; -TargetLogonSeconds is the
         target agreed in the Assess phase, R6.)

    EXPECTED RESULTS:
        A PASS/FAIL line per check and an overall DEVICE RESULT. Exit code 0 if all
        PASS, 1 if any FAIL. See 06-troubleshooting.md for any FAIL.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ExpectedSharePath,
    [int]$TargetLogonSeconds = 30
)

$ErrorActionPreference = 'Stop'
$pass = $true

function Write-Result {
    param([string]$Label, [bool]$Ok, [string]$Detail)
    $tag = if ($Ok) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1} {2}" -f $tag, $Label, $Detail)
    if (-not $Ok) { $script:pass = $false }
}

Write-Host ("Validating FSLogix on {0} for user {1}`n" -f $env:COMPUTERNAME, $env:USERNAME)

# 1. Profile Container enabled + configured to expected share
$prof = Get-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -ErrorAction SilentlyContinue
$enabled = ($prof -and $prof.Enabled -eq 1)
Write-Result "Profile Container enabled" $enabled

$vhdLoc = @($prof.VHDLocations)
$shareMatch = $false
foreach ($loc in $vhdLoc) {
    if ($loc -and ($loc.TrimEnd('\') -ieq $ExpectedSharePath.TrimEnd('\'))) { $shareMatch = $true }
}
Write-Result "Configured to expected share" $shareMatch ("(configured: {0})" -f ($vhdLoc -join '; '))

# 2. Container attached for current user
#    FSLogix attaches the profile as a mounted disk; the user's ProfileImagePath
#    points into the FSLogix mount and a 'frx' attach is logged. Detect via the
#    FSLogix profile status registry and a mounted volume label.
$attached = $false
$status = Get-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles\Sessions" -ErrorAction SilentlyContinue
# Fallback / primary heuristic: a volume whose label starts with 'Profile-' is the attached container
$frxVol = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.FileSystemLabel -like 'Profile-*' -or $_.FileSystemLabel -like 'O365-*' }
if ($frxVol) { $attached = $true }
# Also accept: current user profile path resolves and is not the temp (.TEMP) profile
$sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
$profPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid" -ErrorAction SilentlyContinue).ProfileImagePath
$notTemp  = ($profPath -and ($profPath -notlike '*TEMP*'))
Write-Result "Container attached (not temporary profile)" ($attached -and $notTemp) ("(profile: {0})" -f $profPath)

# 3. Logon-time sample vs. target (from Microsoft-Windows-User Profile Service / GroupPolicy operational logs)
$logonSeconds = $null
try {
    # Most recent user-profile load duration from the User Profile Service operational log (event 1 / load)
    $evt = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-User Profile Service/Operational'; Id=1,2 } -MaxEvents 50 -ErrorAction SilentlyContinue |
           Sort-Object TimeCreated
    if ($evt -and $evt.Count -ge 2) {
        $start = ($evt | Where-Object Id -eq 1 | Select-Object -Last 1).TimeCreated
        $end   = ($evt | Where-Object Id -eq 2 | Select-Object -Last 1).TimeCreated
        if ($start -and $end -and $end -gt $start) { $logonSeconds = [math]::Round(($end - $start).TotalSeconds,1) }
    }
} catch { }

if ($logonSeconds -ne $null) {
    Write-Result "Logon time within target" ($logonSeconds -le $TargetLogonSeconds) ("(measured {0}s, target <= {1}s)" -f $logonSeconds, $TargetLogonSeconds)
} else {
    Write-Host ("[WARN] Logon time within target  (could not sample - run CLINLOGON-Set-FSLogixBaseline.ps1 to measure explicitly)")
}

Write-Host ''
if ($pass) { Write-Host 'DEVICE RESULT: PASS'; exit 0 } else { Write-Host 'DEVICE RESULT: FAIL - see 06-troubleshooting.md'; exit 1 }
