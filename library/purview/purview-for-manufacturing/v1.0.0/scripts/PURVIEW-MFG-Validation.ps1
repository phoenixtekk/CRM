<#
.SYNOPSIS
    PURVIEW-MFG-Validation.ps1 — confirm the Manufacturing labels, SIT, DLP, and retention exist.
.DESCRIPTION
    PURPOSE
        Verifies that the named objects this solution deploys are present and in the expected state:
        the Manufacturing sensitivity labels (MFG-*) and label policy are published, the custom
        part/drawing-number SIT exists, the DLP policy exists (and reports its mode so you can see
        whether it has passed the audit gate into enforce), and the retention policy exists and is
        enabled. Pass/fail per the Testing Guide.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-MFG-Validation.ps1
        Sign in as a Compliance Administrator when prompted. Optionally pass -LabelPolicyName /
        -DlpPolicyName / -RetentionPolicyName / -SitName to match your renamed objects.
    EXAMPLE
        .\PURVIEW-MFG-Validation.ps1
    EXPECTED RESULTS
        "VALIDATION PASSED" when the label policy is enabled, the custom SIT is present, the DLP
        policy is present, and the retention policy is enabled. Exit code 0 on pass, 1 on any gap.
        Read-only; no changes made.
.NOTES
    White-label — Purview Solutions. Read-only. PowerShell 5.1+/7+.
    Uses Get-Label / Get-LabelPolicy / Get-DlpSensitiveInformationType / Get-DlpCompliancePolicy /
    Get-RetentionCompliancePolicy.
#>
[CmdletBinding()] param(
    [string]$LabelPolicyName     = 'Label Policy - Manufacturing Taxonomy - All Users',
    [string]$SitName             = 'SIT - MFG Part/Drawing Number',
    [string]$DlpPolicyName       = 'DLP Policy - Manufacturing IP and CUI',
    [string]$RetentionPolicyName = 'Retention Policy - Manufacturing Baseline - 5 Year'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview for Manufacturing — validation ===" -ForegroundColor Cyan
$pass = $true

# 1. Manufacturing sensitivity labels present
$labels = Get-Label -ErrorAction SilentlyContinue
$mfgLabels = @($labels | Where-Object { $_.DisplayName -like '*MFG-*' })
$hasLabels = $mfgLabels.Count -ge 1
Write-Host ("Manufacturing labels (MFG-*) : {0} ({1} found)" -f ($(if($hasLabels){'YES'}else{'NO'}), $mfgLabels.Count)) -ForegroundColor ($(if($hasLabels){'Green'}else{'Yellow'}))
if (-not $hasLabels) { $pass = $false }

# 2. Label policy enabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
$lpOk = $lp -and $lp.Enabled
Write-Host ("Label policy published       : {0}" -f ($(if($lpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($lpOk){'Green'}else{'Yellow'}))
if (-not $lpOk) { $pass = $false }

# 3. Custom SIT present (IP detection)
$sit = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $SitName }
$sitOk = [bool]$sit
Write-Host ("Custom part/drawing SIT      : {0}" -f ($(if($sitOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($sitOk){'Green'}else{'Yellow'}))
if (-not $sitOk) { $pass = $false }

# 4. DLP policy present (report its mode — audit vs enforce)
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$DlpPolicyName*" }
$dlpOk = [bool]$dlp
$dlpMode = ($(if($dlp){ ($dlp | Select-Object -First 1).Mode }else{'-'}))
Write-Host ("DLP policy present           : {0}  (mode: {1})" -f ($(if($dlpOk){'YES'}else{'NO'}), $dlpMode)) -ForegroundColor ($(if($dlpOk){'Green'}else{'Yellow'}))
if (-not $dlpOk) { $pass = $false }

# 5. Retention policy enabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
$rpOk = $rp -and $rp.Enabled
Write-Host ("Retention policy enabled     : {0}" -f ($(if($rpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($rpOk){'Green'}else{'Yellow'}))
if (-not $rpOk) { $pass = $false }

if ($pass) { Write-Host "`nResult: VALIDATION PASSED" -ForegroundColor Green }
else       { Write-Host "`nResult: GAPS FOUND — see PURVIEW-MFG-Remediation.ps1 (-WhatIf) and the Implementation Guide" -ForegroundColor Yellow }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
if ($pass) { exit 0 } else { exit 1 }
