<#
.SYNOPSIS
    POCMDE-TestSignal.ps1 — generate BENIGN, simulated test signal to trigger MDE detections. Safe only.
.DESCRIPTION
    PURPOSE
        Produces harmless, industry-standard test signal on an ONBOARDED PILOT DEVICE so the
        MDE detection pipeline has something to catch. It does two safe things:
          1. Writes the EICAR anti-malware test file (a documented 68-byte harmless string that
             every AV recognises — it is NOT malware) to trigger Microsoft Defender Antivirus.
          2. Prints the exact portal steps to launch a Microsoft BUILT-IN evaluation simulation
             (security.microsoft.com -> Endpoints -> Evaluation & tutorials).
        NO real malware, exploit, or attack tooling is downloaded or executed. -WhatIf shows
        what it would do without writing anything.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDE-TestSignal.ps1 -WhatIf
        # Generate benign signal (run ON a pilot device):
        powershell -ExecutionPolicy Bypass -File .\POCMDE-TestSignal.ps1
    EXPECTED RESULTS
        Microsoft Defender Antivirus detects/quarantines the EICAR file; you then run a built-in
        simulation from the portal. Both surface as detections for the PoC to validate.
.NOTES
    White-label. BENIGN test signal only (EICAR + Microsoft built-in simulations). Never uses real threats.
    Verify the current built-in simulation catalogue in your tenant.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Tag = 'MDE-PoC-TESTSIGNAL',
    [string]$WorkDir = "$env:TEMP\MDE-PoC"
)

Write-Host "`n=== POCMDE — benign test signal ($Tag) ===" -ForegroundColor Cyan
Write-Host "SAFE ONLY: EICAR test file + Microsoft built-in simulation. No real malware is used." -ForegroundColor Yellow

# EICAR standard test string, assembled at runtime so this script file itself is not flagged.
$eicar = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$' + 'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
$eicarPath = Join-Path $WorkDir 'eicar-poc.com'

if ($PSCmdlet.ShouldProcess($eicarPath, "Write benign EICAR test file (tagged $Tag)")) {
    if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null }
    try {
        Set-Content -Path $eicarPath -Value $eicar -Encoding ascii -NoNewline
        Write-Host "  Wrote EICAR test file: $eicarPath" -ForegroundColor Green
        Write-Host "  Microsoft Defender Antivirus should detect/quarantine it within moments." -ForegroundColor Gray
        Write-Host "  (If it persists, real-time protection may be off — see Troubleshooting 'EICAR not detected'.)" -ForegroundColor Gray
    } catch {
        Write-Host ("  Could not write file (AV may have blocked the path already): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WhatIf] Would write benign EICAR test file to $eicarPath. No file written." -ForegroundColor Yellow
}

Write-Host "`n[Built-in EDR simulation — run from the portal]" -ForegroundColor Cyan
Write-Host "  1. security.microsoft.com -> Endpoints -> Evaluation & tutorials -> Tutorials & simulations." -ForegroundColor Gray
Write-Host "  2. Pick a 'Do-it-yourself' / tutorial scenario and target a device in 'MDE PoC - Pilot Ring - Pilot'." -ForegroundColor Gray
Write-Host "  3. These simulations are provided by Microsoft for SAFE evaluation. Verify the current catalogue." -ForegroundColor Gray

$stamp = (Get-Date).ToString('u')
Write-Host "`nSignal generated at: $stamp  (record this — compare to detection time in the scorecard)." -ForegroundColor Cyan
Write-Host "Next: POCMDE-Validate.ps1" -ForegroundColor Cyan
