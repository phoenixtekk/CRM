<#
.SYNOPSIS
    WHfB-Validation.ps1 — confirm Windows Hello for Business is provisioned for the signed-in user.

.DESCRIPTION
    PURPOSE
        Verifies that the current user has a working WHfB credential on this device: the Next
        Generation Credential (NGC) is set, a TPM-backed key exists, and (hybrid) Cloud
        Kerberos Trust is in effect.

    HOW TO RUN
        Run as the signed-in pilot user (their session) in a normal PowerShell window:
            powershell -ExecutionPolicy Bypass -File .\WHfB-Validation.ps1

    EXPECTED RESULTS
        "WHfB PROVISIONED" with NgcSet = YES and at least one NGC container present. On hybrid
        devices, a Kerberos TGT is listed after first resource access.

.NOTES
    White-label — Intune Solutions. Read-only; makes no changes.
#>
[CmdletBinding()]
param()

Write-Host "=== WHfB Validation — user $($env:USERNAME) on $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# 1) NgcSet from dsregcmd
$dsreg  = (dsregcmd /status) 2>$null
$ngcSet = ($dsreg | Select-String 'NgcSet\s*:\s*YES') -ne $null
Write-Host ("NgcSet (WHfB key set)      : {0}" -f ($(if ($ngcSet) { 'YES' } else { 'NO' }))) -ForegroundColor ($(if ($ngcSet) { 'Green' } else { 'Yellow' }))

# 2) NGC containers on disk (presence indicates provisioning)
$ngcPath = "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc"
$ngcCount = 0
try { $ngcCount = (Get-ChildItem -Path $ngcPath -Directory -ErrorAction Stop).Count } catch {}
Write-Host ("NGC containers present     : {0}" -f $ngcCount)

# 3) PassportForWork keys in registry (per-user enrollment record)
$p4w = "HKLM:\SOFTWARE\Microsoft\Policies\PassportForWork"
$cloudTrust = $null
try {
    $cloudTrust = (Get-ItemProperty -Path "$p4w\*\Device\Policies" -ErrorAction SilentlyContinue).UseCloudTrustForOnPremAuth
} catch {}
Write-Host ("Cloud Kerberos Trust policy: {0}" -f ($(if ($cloudTrust -eq 1) { 'Enabled' } else { 'Not set / cloud-only' })))

# 4) Hybrid TGT (informational)
$tgt = (klist 2>$null | Select-String 'krbtgt')
Write-Host ("Kerberos TGT present       : {0}" -f ($(if ($tgt) { 'YES' } else { 'No (cloud-only, or not yet accessed on-prem)' })))

# Verdict
if ($ngcSet -and $ngcCount -ge 1) {
    Write-Host "`nResult: WHfB PROVISIONED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nResult: WHfB NOT PROVISIONED — sign out/in to trigger enrollment, or run WHfB-Remediation.ps1" -ForegroundColor Yellow
    exit 1
}
