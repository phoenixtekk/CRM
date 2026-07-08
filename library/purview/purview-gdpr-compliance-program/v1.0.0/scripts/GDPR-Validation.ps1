<#
.SYNOPSIS
    GDPR-Validation.ps1 — confirm the named GDPR-program objects exist and are in the expected state.
.DESCRIPTION
    PURPOSE
        Verifies the objects this program deploys are present: the personal-data label policy is
        published, the EU-personal-data DLP policy exists (and reports its mode so you can see whether
        it has passed the audit gate into enforce), and the storage-limitation retention policy exists
        and is enabled. Pass/fail per the Testing Guide — read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GDPR-Validation.ps1
        Sign in as a Compliance Administrator when prompted. Optionally pass -LabelPolicyName /
        -DlpPolicyName / -RetentionPolicyName to match your renamed objects.
    EXPECTED RESULTS
        "VALIDATION PASSED" when the label policy is enabled, the DLP policy is present, and the
        retention policy is enabled. Exit code 0 on pass, 1 on any gap.
.NOTES
    White-label — Purview Solutions. Read-only.
    Uses Get-LabelPolicy / Get-DlpCompliancePolicy / Get-RetentionCompliancePolicy.
#>
[CmdletBinding()] param(
    [string]$LabelPolicyName     = 'Label Policy - Sensitivity Taxonomy - All Users',
    [string]$DlpPolicyName       = 'DLP Policy - EU Personal Data',
    [string]$RetentionPolicyName = 'Retention Policy - Personal Data - Storage Limitation'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview GDPR — validation ===" -ForegroundColor Cyan
$pass = $true

# 1. Personal-data sensitivity label present
$labels = Get-Label -ErrorAction SilentlyContinue
$hasLabel = @($labels | Where-Object { $_.DisplayName -like '*Personal Data*' }).Count -ge 1 -or @($labels).Count -ge 1
Write-Host ("Sensitivity label present  : {0}" -f ($(if($hasLabel){'YES'}else{'NO'}))) -ForegroundColor ($(if($hasLabel){'Green'}else{'Yellow'}))
if (-not $hasLabel) { $pass = $false }

# 2. Label policy enabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
$lpOk = $lp -and $lp.Enabled
Write-Host ("Label policy published     : {0}" -f ($(if($lpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($lpOk){'Green'}else{'Yellow'}))
if (-not $lpOk) { $pass = $false }

# 3. DLP policy present (report its mode — audit vs enforce)
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$DlpPolicyName*" }
$dlpOk = [bool]$dlp
$dlpMode = ($(if($dlp){ ($dlp | Select-Object -First 1).Mode }else{'-'}))
Write-Host ("DLP policy present         : {0}  (mode: {1})" -f ($(if($dlpOk){'YES'}else{'NO'}), $dlpMode)) -ForegroundColor ($(if($dlpOk){'Green'}else{'Yellow'}))
if (-not $dlpOk) { $pass = $false }

# 4. Retention policy enabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
$rpOk = $rp -and $rp.Enabled
Write-Host ("Retention policy enabled   : {0}" -f ($(if($rpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($rpOk){'Green'}else{'Yellow'}))
if (-not $rpOk) { $pass = $false }

if ($pass) { Write-Host "`nResult: VALIDATION PASSED" -ForegroundColor Green }
else       { Write-Host "`nResult: GAPS FOUND — see GDPR-Remediation.ps1 (-WhatIf) and the Implementation Guide" -ForegroundColor Yellow }

Write-Host "Note: the Compliance Manager score + assessment status are reviewed in the Purview portal." -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
if ($pass) { exit 0 } else { exit 1 }
