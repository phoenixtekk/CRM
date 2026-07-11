<#
.SYNOPSIS
    POCMDCA-TestSignal.ps1 — generate BENIGN, simulated cloud-app test signal for the MDCA PoC. Safe only.
.DESCRIPTION
    PURPOSE
        Produces harmless cloud-app signal so the MDCA pipeline has something to surface. It:
          1. Guides upload of Microsoft's SAMPLE Cloud Discovery log to produce a Shadow IT report
             from safe, sample data (Cloud apps -> Cloud discovery -> Create snapshot report).
          2. Guides a BENIGN, policy-matching action performed by the test account (e.g. a small,
             non-sensitive download or a benign administrative activity the audit policy watches for).
        NO real data exfiltration, malicious app connection, or risky OAuth grant is ever performed.
        -WhatIf shows what it would do.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-TestSignal.ps1 -WhatIf
        # Print the benign signal steps:
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-TestSignal.ps1
    EXPECTED RESULTS
        A discovery report populates and the audit policy matches the benign activity, for the PoC to validate.
.NOTES
    White-label. BENIGN signal only (sample discovery log + benign policy-matching activity). Never real exfiltration.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Tag = 'MDCA-PoC-TESTSIGNAL'
)

Write-Host "`n=== POCMDCA — benign test signal ($Tag) ===" -ForegroundColor Cyan
Write-Host "SAFE ONLY: Microsoft sample discovery log + benign policy-matching activity. No real exfiltration." -ForegroundColor Yellow

# 1) Cloud Discovery sample-log upload (portal-driven, safe).
Write-Host "`n[1] Populate Cloud Discovery from Microsoft's SAMPLE log:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess('Cloud Discovery snapshot report', "Guide sample-log upload")) {
    Write-Host "  security.microsoft.com -> Cloud apps -> Cloud discovery -> Actions -> Create Cloud Discovery snapshot report." -ForegroundColor Gray
    Write-Host "  Name it 'MDCA PoC Discovery - Pilot - Report', pick the matching data source, and upload Microsoft's" -ForegroundColor Gray
    Write-Host "  SAMPLE discovery log (documented, benign). This produces a Shadow IT report from safe sample data." -ForegroundColor Green
} else {
    Write-Host "  [WhatIf] Would guide the sample-log upload to create the discovery report." -ForegroundColor Yellow
}

# 2) Benign policy-matching activity.
Write-Host "`n[2] Perform BENIGN policy-matching activity (as the test account):" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess('audit policy trigger', "Guide benign policy-matching activity")) {
    Write-Host "  Sign in as a test account in 'MDCA PoC - Pilot Users - Pilot' and perform the benign action the audit" -ForegroundColor Gray
    Write-Host "  policy watches for — e.g. download a few NON-SENSITIVE files from a monitored app, or perform the benign" -ForegroundColor Gray
    Write-Host "  administrative activity. This is normal activity the audit policy is set to notice. Nothing is exfiltrated." -ForegroundColor Green
} else {
    Write-Host "  [WhatIf] Would guide benign policy-matching activity by the test account." -ForegroundColor Yellow
}

Write-Host ("`nSignal generated at: {0}  (record this for scorecard latency)." -f (Get-Date).ToString('u')) -ForegroundColor Cyan
Write-Host "Next: POCMDCA-Validate.ps1" -ForegroundColor Cyan
