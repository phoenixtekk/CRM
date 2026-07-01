<#
.SYNOPSIS
    NSSSL-Remediation.ps1 — safely request an MDM sync so the inspection-cert profile re-applies.
.DESCRIPTION
    PURPOSE
        When NSSSL-Validation.ps1 reports the inspection root is missing, this triggers an Intune/MDM
        sync so the assigned Trusted certificate profile re-applies to the device. Read-only by
        default (-WhatIf): it previews the action and changes nothing until -Execute is passed.
        It never installs a certificate directly — trust is governed by the Intune profile.
        Netskope decryption-policy changes are made in the Netskope console (not by this script).
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\NSSSL-Remediation.ps1
        Apply           : powershell -ExecutionPolicy Bypass -File .\NSSSL-Remediation.ps1 -Execute
    EXPECTED RESULTS
        In preview: prints what would run. With -Execute: an MDM sync is requested; re-run
        NSSSL-Validation.ps1 after a policy cycle.
.NOTES
    Workplace Marketplace — Network Solutions. Default -WhatIf (no changes without -Execute).
#>
[CmdletBinding()] param([switch]$Execute)
$WhatIf = -not $Execute
Write-Host "=== SSL Inspection Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if($WhatIf){'WHATIF (preview only — pass -Execute to apply)'}else{'EXECUTE'}))) -ForegroundColor ($(if($WhatIf){'Yellow'}else{'Green'}))

$root = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue | Where-Object { $_.Subject -match 'Netskope' } | Select-Object -First 1
Write-Host ("Inspection root currently present: {0}" -f ($(if($root){'YES'}else{'NO'})))

$enroller = "$env:WINDIR\System32\deviceenroller.exe"
if ($WhatIf) {
    Write-Host "  WOULD RUN: $enroller /c /AutoEnrollMDM   (request MDM sync so the trusted-cert profile re-applies)" -ForegroundColor Yellow
    Write-Host "`nNo changes made. Re-run with -Execute to request the sync." -ForegroundColor Yellow
    return
}
if (Test-Path $enroller) {
    Start-Process -FilePath $enroller -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
} else {
    Write-Host "  deviceenroller.exe not found — trigger a sync from Settings -> Access work or school -> Sync." -ForegroundColor Yellow
}
Write-Host "`nRe-run NSSSL-Validation.ps1 after a policy cycle to confirm the inspection root is trusted." -ForegroundColor Green
