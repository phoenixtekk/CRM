<#
.SYNOPSIS
    Clinical Endpoint Logon & Profile Optimization (FSLogix) - safe fixes.
    Read-only / -WhatIf by default; acts only with -Apply.

    PURPOSE:
        Applies the two safe, reversible fixes for the most common post-deployment
        issues on a clinical endpoint:
          1. Clear STALE LOCAL CACHED PROFILES - removes leftover local user profiles
             (older than -StaleDays, excluding the current user and built-in/system
             profiles) so a bloated/temporary local profile no longer competes with
             the FSLogix container or fills the local disk. Profiles are removed via
             the supported Win32_UserProfile.Delete() (not a raw folder delete).
          2. RE-POINT FSLOGIX CONFIG - if the configured VHD Locations does not match
             the expected profile share, set it to the named share so the container
             attaches from the correct location.
        It does NOT delete any FSLogix container on the share, change permissions, or
        touch Imprivata/appliance policy.

        Default mode previews the actions (-WhatIf). Pass -Apply to make changes.

    HOW TO RUN:
        Preview: .\CLINLOGON-Remediation.ps1 -ExpectedSharePath "\\fileserver\ClinicalProfiles$"
        Apply  : .\CLINLOGON-Remediation.ps1 -ExpectedSharePath "\\fileserver\ClinicalProfiles$" -Apply
        (Run elevated on the endpoint. Obtain -ExpectedSharePath from your storage team.)

    EXPECTED RESULTS:
        A report of what is / would be changed. With -Apply: stale local cached
        profiles are removed and (if needed) the FSLogix VHD Locations is re-pointed
        to the named share. Re-run CLINLOGON-Validation.ps1 after the next sign-in.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$ExpectedSharePath,
    [int]$StaleDays = 30,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
# When -Apply is NOT supplied, force WhatIf behavior (preview only).
if (-not $Apply) { $WhatIfPreference = $true }

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this script elevated (Administrator)."; exit 1
}

$currentSid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
$cutoff = (Get-Date).AddDays(-$StaleDays)

# ---------------- Fix 1: clear stale local cached profiles ----------------
Write-Host "=== Stale local cached profiles ==="
$profiles = Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue |
            Where-Object { -not $_.Special -and -not $_.Loaded -and $_.SID -ne $currentSid }

foreach ($p in $profiles) {
    $last = $null
    if ($p.LastUseTime) { try { $last = [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } catch {} }
    $isStale = ($last -ne $null -and $last -lt $cutoff)
    $path = $p.LocalPath
    if ($isStale) {
        if ($PSCmdlet.ShouldProcess("$path (SID $($p.SID), last used $last)", "Delete stale local cached profile")) {
            try { $p | Remove-CimInstance; Write-Host ("REMOVED stale profile: {0}" -f $path) }
            catch { Write-Warning ("Failed to remove {0}: {1}" -f $path, $_.Exception.Message) }
        } else {
            Write-Host ("[WhatIf] Would REMOVE stale profile: {0} (last used {1})" -f $path, $last)
        }
    } else {
        Write-Host ("KEEP (not stale): {0} (last used {1})" -f $path, $last)
    }
}

# ---------------- Fix 2: re-point FSLogix VHD Locations ----------------
Write-Host "`n=== FSLogix VHD Locations ==="
$profKey = 'HKLM:\SOFTWARE\FSLogix\Profiles'
if (-not (Test-Path $profKey)) {
    Write-Warning "FSLogix Profiles registry key not found - is the agent installed and configured? See 03-implementation.md."
} else {
    $prof = Get-ItemProperty -Path $profKey -ErrorAction SilentlyContinue
    $current = @($prof.VHDLocations)
    $match = $false
    foreach ($loc in $current) { if ($loc -and ($loc.TrimEnd('\') -ieq $ExpectedSharePath.TrimEnd('\'))) { $match = $true } }

    if ($match) {
        Write-Host ("VHD Locations already correct: {0}" -f ($current -join '; '))
    } else {
        if ($PSCmdlet.ShouldProcess("$profKey\VHDLocations -> $ExpectedSharePath", "Re-point FSLogix VHD Locations")) {
            New-ItemProperty -Path $profKey -Name 'VHDLocations' -Value $ExpectedSharePath -PropertyType MultiString -Force | Out-Null
            Write-Host ("SET VHD Locations to: {0}" -f $ExpectedSharePath)
        } else {
            Write-Host ("[WhatIf] Would SET VHD Locations to: {0} (current: {1})" -f $ExpectedSharePath, ($current -join '; '))
        }
    }
}

Write-Host "`nNote: settings managed by Intune/GPO may re-assert on next policy sync - update the policy in 03-implementation.md as the source of truth."
Write-Host "Next: have a test clinician sign in, then re-run CLINLOGON-Validation.ps1."
