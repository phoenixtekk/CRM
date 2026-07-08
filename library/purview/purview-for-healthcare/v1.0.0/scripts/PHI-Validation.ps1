<#
.SYNOPSIS
    PHI-Validation.ps1 — confirm the expected PHI labels, HIPAA DLP, and retention objects exist (read-only).
.DESCRIPTION
    PURPOSE
        Verifies that the named objects this Healthcare solution deploys are present and in the
        expected state: the PHI sensitivity-label taxonomy is published, the HIPAA DLP policy exists
        (reporting its mode so you can see whether it has passed the audit gate into enforce), and the
        healthcare retention policy exists and is enabled. Pass/fail per the Testing Guide.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PHI-Validation.ps1
        Sign in as a Compliance Administrator when prompted. Pass -DlpPolicyName /
        -RetentionPolicyName / -LabelPolicyName to match any renamed objects.
.EXAMPLE
    .\PHI-Validation.ps1
    Prints VALIDATION PASSED (exit 0) when the label policy is enabled, the HIPAA DLP policy is
    present, and the retention policy is enabled; GAPS FOUND (exit 1) otherwise. PowerShell 5.1+/7+;
    uses Connect-IPPSSession.
.NOTES
    Expected results: pass/fail per object with exit code 0 (pass) or 1 (gap). Read-only, no changes.
    White-label — no credentials in code.
#>
[CmdletBinding()] param(
    [string]$LabelPolicyName     = 'Label Policy - Healthcare PHI Taxonomy - All Users',
    [string]$DlpPolicyName       = 'DLP Policy - PHI HIPAA',
    [string]$RetentionPolicyName = 'Retention Policy - Healthcare Baseline - Schedule-Defined'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview for Healthcare — validation ===" -ForegroundColor Cyan
$pass = $true

# 1. Sensitivity labels present (PHI-named expected)
$labels = Get-Label -ErrorAction SilentlyContinue
$phiLabels = @($labels | Where-Object { $_.DisplayName -match 'PHI' })
$hasPhi = $phiLabels.Count -ge 1
Write-Host ("PHI sensitivity labels present : {0} ({1} found)" -f ($(if($hasPhi){'YES'}else{'NO'}), $phiLabels.Count)) -ForegroundColor ($(if($hasPhi){'Green'}else{'Yellow'}))
if (-not $hasPhi) { $pass = $false }

# 2. Label policy enabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
$lpOk = $lp -and $lp.Enabled
Write-Host ("PHI label policy published     : {0}" -f ($(if($lpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($lpOk){'Green'}else{'Yellow'}))
if (-not $lpOk) { $pass = $false }

# 3. HIPAA DLP policy present (report its mode — audit vs enforce)
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$DlpPolicyName*" }
$dlpOk = [bool]$dlp
$dlpMode = ($(if($dlp){ ($dlp | Select-Object -First 1).Mode }else{'-'}))
Write-Host ("HIPAA DLP policy present       : {0}  (mode: {1})" -f ($(if($dlpOk){'YES'}else{'NO'}), $dlpMode)) -ForegroundColor ($(if($dlpOk){'Green'}else{'Yellow'}))
if (-not $dlpOk) { $pass = $false }

# 4. Retention policy enabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
$rpOk = $rp -and $rp.Enabled
Write-Host ("Healthcare retention policy on : {0}" -f ($(if($rpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($rpOk){'Green'}else{'Yellow'}))
if (-not $rpOk) { $pass = $false }

if ($pass) { Write-Host "`nResult: VALIDATION PASSED" -ForegroundColor Green }
else       { Write-Host "`nResult: GAPS FOUND — see PHI-Remediation.ps1 (-WhatIf) and the Implementation Guide" -ForegroundColor Yellow }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
if ($pass) { exit 0 } else { exit 1 }
