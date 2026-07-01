<#
.SYNOPSIS
    WSUSM-Remediation.ps1 — clear residual WSUS pointers / conflicting update policy (safe by default).
.DESCRIPTION
    PURPOSE
        Removes the WSUS-era registry values that keep a device pointed at WSUS after the controlling
        GPO has been unlinked or set to Not Configured: WUServer, WUStatusServer (under
        ...\WindowsUpdate), UseWUServer (under ...\WindowsUpdate\AU), and the
        DoNotConnectToWindowsUpdateInternetLocations online-scan block. Then it requests an MDM sync
        and a Windows Update scan so the Intune ring applies and the device scans Microsoft.
    HOW TO RUN
        Preview (default, changes nothing): powershell -ExecutionPolicy Bypass -File .\WSUSM-Remediation.ps1
        Apply changes:                       powershell -ExecutionPolicy Bypass -File .\WSUSM-Remediation.ps1 -Confirm
        (Run elevated. -WhatIf is the default; pass -Confirm to actually remove the values.)
    EXPECTED RESULTS
        In preview: each value that WOULD be removed is listed, nothing changes. With -Confirm: the
        values are removed, an MDM sync + USO scan are requested. Re-run WSUSM-Validation.ps1 after a
        policy cycle.
.NOTES
    Workplace Marketplace — Intune Solutions. Removing the GPO that re-writes these values is still
    required so they do not return on the next Group Policy refresh.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $Confirm
)

# Default to -WhatIf unless the operator explicitly passes -Confirm.
if (-not $Confirm -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$au = "$wu\AU"

Write-Host "`n=== WSUS-to-WUfB Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "MODE: PREVIEW (-WhatIf) — no changes will be made. Pass -Confirm to apply.`n" -ForegroundColor Yellow }

$targets = @(
    @{ Path = $wu; Name = 'WUServer' },
    @{ Path = $wu; Name = 'WUStatusServer' },
    @{ Path = $wu; Name = 'DoNotConnectToWindowsUpdateInternetLocations' },
    @{ Path = $au; Name = 'UseWUServer' }
)

$removed = 0
foreach ($t in $targets) {
    $existing = Get-ItemProperty -Path $t.Path -Name $t.Name -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        if ($PSCmdlet.ShouldProcess("$($t.Path)\$($t.Name)", "Remove value")) {
            Remove-ItemProperty -Path $t.Path -Name $t.Name -ErrorAction SilentlyContinue
            Write-Host ("  Removed {0}\{1}" -f $t.Path, $t.Name) -ForegroundColor Green
            $removed++
        } else {
            Write-Host ("  WOULD remove {0}\{1}  (current: {2})" -f $t.Path, $t.Name, $existing.$($t.Name)) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  Not present: {0}\{1}" -f $t.Path, $t.Name) -ForegroundColor DarkGray
    }
}

if (-not $WhatIfPreference) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden -ErrorAction SilentlyContinue
    Write-Host "  MDM sync requested." -ForegroundColor Green
    try {
        if (Test-Path "$env:WINDIR\System32\UsoClient.exe") { & "$env:WINDIR\System32\UsoClient.exe" StartScan; Write-Host "  Windows Update scan (USO) started." -ForegroundColor Green }
        else { (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow(); Write-Host "  Update detection triggered." -ForegroundColor Green }
    } catch { Write-Host "  Scan trigger skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
    Write-Host ("`nDone — removed {0} value(s). Re-run WSUSM-Validation.ps1 after a policy cycle." -f $removed) -ForegroundColor Green
} else {
    Write-Host "`nPreview complete. Re-run with -Confirm to apply." -ForegroundColor Yellow
}
Write-Host "Reminder: unlink/disable the WSUS GPO too, or these values return on the next gpupdate." -ForegroundColor Cyan
