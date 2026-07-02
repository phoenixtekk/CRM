<#
.SYNOPSIS
    ODFB-Validation.ps1 — confirm OneDrive for Business is configured for the signed-in user.

.DESCRIPTION
    PURPOSE
        Verifies the three core capabilities are applied on this device: Silent Account
        Configuration, Known Folder Move (Desktop/Documents/Pictures redirected to OneDrive),
        and Files On-Demand.

    HOW TO RUN
        Run as the signed-in pilot user:
            powershell -ExecutionPolicy Bypass -File .\ODFB-Validation.ps1

    EXPECTED RESULTS
        "OneDrive CONFIGURED" with SilentAccountConfig=1, the three known folders pointing into
        OneDrive, and FilesOnDemandEnabled=1.

.NOTES
    White-label — Intune Solutions. Read-only; makes no changes.
#>
[CmdletBinding()]
param()

Write-Host "=== OneDrive Validation — user $($env:USERNAME) on $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

$pol = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
$silent = (Get-ItemProperty $pol -Name SilentAccountConfig -ErrorAction SilentlyContinue).SilentAccountConfig
$fod    = (Get-ItemProperty $pol -Name FilesOnDemandEnabled -ErrorAction SilentlyContinue).FilesOnDemandEnabled
$kfm    = (Get-ItemProperty $pol -Name KFMSilentOptIn -ErrorAction SilentlyContinue).KFMSilentOptIn

Write-Host ("Silent account config : {0}" -f ($(if ($silent -eq 1) { 'Enabled (1)' } else { 'NOT set' })))
Write-Host ("Files On-Demand       : {0}" -f ($(if ($fod -eq 1)    { 'Enabled (1)' } else { 'NOT set' })))
Write-Host ("KFM policy (Tenant ID): {0}" -f ($(if ($kfm)          { $kfm } else { 'NOT set' })))

# Known folder locations (HKCU User Shell Folders)
$usf = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$shell = Get-ItemProperty $usf -ErrorAction SilentlyContinue
$folders = @{ Desktop = 'Desktop'; Documents = 'Personal'; Pictures = 'My Pictures' }
$redirected = 0
foreach ($k in $folders.Keys) {
    $val = $shell.($folders[$k])
    $isOd = $val -match 'OneDrive'
    if ($isOd) { $redirected++ }
    Write-Host ("Known folder {0,-9}: {1}" -f $k, ($(if ($isOd) { "OneDrive  ($val)" } else { "LOCAL  ($val)" })))
}

$ok = ($silent -eq 1) -and ($fod -eq 1) -and ($redirected -eq 3)
if ($ok) {
    Write-Host "`nResult: OneDrive CONFIGURED" -ForegroundColor Green; exit 0
} else {
    Write-Host "`nResult: OneDrive NOT FULLY CONFIGURED — sync policy, sign out/in, or run ODFB-Remediation.ps1" -ForegroundColor Yellow; exit 1
}
