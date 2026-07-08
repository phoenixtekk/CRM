<#
.SYNOPSIS
    RETAIL-Validation.ps1 — confirm the expected retail labels, PCI + PII DLP, and retention objects exist.
.DESCRIPTION
    PURPOSE
        Verifies the named objects this solution deploys are present and in the expected state: the
        retail sensitivity-label taxonomy is published, BOTH the PCI cardholder-data and customer-PII
        DLP policies exist (and reports each mode so you can see whether it has passed the audit gate
        into enforce/block), and the retention policy exists and is enabled. Pass/fail per the Testing
        Guide. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RETAIL-Validation.ps1
        Sign in as a Compliance Administrator when prompted. Optionally pass -PciDlpName / -PiiDlpName /
        -RetentionPolicyName / -LabelPolicyName to match your renamed objects.
    EXPECTED RESULTS
        "VALIDATION PASSED" when the label policy is enabled, both DLP policies are present, and the
        retention policy is enabled. Exit code 0 on pass, 1 on any gap.
.NOTES
    White-label — Purview / Retail. Read-only.
    PowerShell 5.1+/7+. Uses Get-Label / Get-LabelPolicy / Get-DlpCompliancePolicy /
    Get-RetentionCompliancePolicy.
#>
[CmdletBinding()] param(
    [string]$LabelPolicyName     = 'Label Policy - Retail Data Classification - Pilot',
    [string]$PciDlpName          = 'DLP Policy - Retail PCI Cardholder Data',
    [string]$PiiDlpName          = 'DLP Policy - Retail Customer PII',
    [string]$RetentionPolicyName = 'Retention Policy - Retail Baseline - 5 Year'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview for Retail — validation ===" -ForegroundColor Cyan
$pass = $true

# 1. Sensitivity labels present
$labels = Get-Label -ErrorAction SilentlyContinue
$labelCount = @($labels).Count
$hasLabels = $labelCount -ge 1
Write-Host ("Sensitivity labels present   : {0} ({1} found)" -f ($(if($hasLabels){'YES'}else{'NO'}), $labelCount)) -ForegroundColor ($(if($hasLabels){'Green'}else{'Yellow'}))
if (-not $hasLabels) { $pass = $false }

# 2. Label policy enabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
$lpOk = $lp -and $lp.Enabled
Write-Host ("Label policy published       : {0}" -f ($(if($lpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($lpOk){'Green'}else{'Yellow'}))
if (-not $lpOk) { $pass = $false }

# 3. PCI DLP policy present (report mode - audit vs enforce)
$pci = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$PciDlpName*" }
$pciOk = [bool]$pci
$pciMode = ($(if($pci){ ($pci | Select-Object -First 1).Mode }else{'-'}))
Write-Host ("PCI cardholder DLP present   : {0}  (mode: {1})" -f ($(if($pciOk){'YES'}else{'NO'}), $pciMode)) -ForegroundColor ($(if($pciOk){'Green'}else{'Yellow'}))
if (-not $pciOk) { $pass = $false }

# 4. Customer-PII DLP policy present (report mode)
$pii = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$PiiDlpName*" }
$piiOk = [bool]$pii
$piiMode = ($(if($pii){ ($pii | Select-Object -First 1).Mode }else{'-'}))
Write-Host ("Customer-PII DLP present     : {0}  (mode: {1})" -f ($(if($piiOk){'YES'}else{'NO'}), $piiMode)) -ForegroundColor ($(if($piiOk){'Green'}else{'Yellow'}))
if (-not $piiOk) { $pass = $false }

# 5. Retention policy enabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
$rpOk = $rp -and $rp.Enabled
Write-Host ("Retention policy enabled     : {0}" -f ($(if($rpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($rpOk){'Green'}else{'Yellow'}))
if (-not $rpOk) { $pass = $false }

if ($pass) { Write-Host "`nResult: VALIDATION PASSED" -ForegroundColor Green }
else       { Write-Host "`nResult: GAPS FOUND — see RETAIL-Configuration.ps1 (-WhatIf) and the Implementation Guide" -ForegroundColor Yellow }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
if ($pass) { exit 0 } else { exit 1 }
