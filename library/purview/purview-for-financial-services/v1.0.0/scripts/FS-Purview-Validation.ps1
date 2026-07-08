<#
.SYNOPSIS
    FS-Purview-Validation.ps1 — confirm the expected FS labels, DLP, retention, and comms objects exist. Read-only.
.DESCRIPTION
    PURPOSE
        Verifies that the named objects this Financial Services solution deploys are present and in the
        expected state: the FS sensitivity-label taxonomy is published, the DLP policy exists (and its
        mode is reported so you can see whether it has passed the audit gate into enforce), the
        retention policy exists and is enabled (and whether it is locked), and the communication-
        compliance policy exists. Pass/fail per the Testing Guide.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FS-Purview-Validation.ps1
        Sign in as a Compliance Administrator when prompted. Optionally pass -LabelPolicyName /
        -DlpPolicyName / -RetentionPolicyName / -CommPolicyName to match your renamed objects.
    EXPECTED RESULTS
        "VALIDATION PASSED" when the label policy is enabled, the DLP policy is present, and the
        retention policy is enabled. The communication-compliance check is reported (informational —
        it may be role-gated). Exit code 0 on pass, 1 on any gap.
.NOTES
    White-label — Purview / Financial Services. Read-only.
    Uses Get-Label / Get-LabelPolicy / Get-DlpCompliancePolicy / Get-RetentionCompliancePolicy /
    Get-SupervisoryReviewPolicyV2.
#>
[CmdletBinding()] param(
    [string]$LabelPolicyName     = 'Label Policy - FS Taxonomy - Pilot',
    [string]$DlpPolicyName       = 'DLP Policy - FS NPI and Financial',
    [string]$RetentionPolicyName = 'Retention Policy - FS Communications Supervision - 6 Year',
    [string]$CommPolicyName      = 'Comm Compliance - FS Supervision (FINRA 3110) - Pilot'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview (Financial Services) — validation ===" -ForegroundColor Cyan
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
Write-Host ("FS label policy published    : {0}" -f ($(if($lpOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($lpOk){'Green'}else{'Yellow'}))
if (-not $lpOk) { $pass = $false }

# 3. DLP policy present (report its mode — audit vs enforce)
$dlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$DlpPolicyName*" }
$dlpOk = [bool]$dlp
$dlpMode = ($(if($dlp){ ($dlp | Select-Object -First 1).Mode }else{'-'}))
Write-Host ("FS DLP policy present        : {0}  (mode: {1})" -f ($(if($dlpOk){'YES'}else{'NO'}), $dlpMode)) -ForegroundColor ($(if($dlpOk){'Green'}else{'Yellow'}))
if (-not $dlpOk) { $pass = $false }

# 4. Retention policy enabled (report lock state)
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
$rpOk = $rp -and $rp.Enabled
$locked = ($(if($rp){[bool]$rp.RestrictiveRetention}else{$false}))
Write-Host ("FS retention policy enabled  : {0}  (Preservation Lock: {1})" -f ($(if($rpOk){'YES'}else{'NO'}), $(if($locked){'LOCKED'}else{'unlocked'}))) -ForegroundColor ($(if($rpOk){'Green'}else{'Yellow'}))
if (-not $rpOk) { $pass = $false }

# 5. Communication-compliance policy present (informational — may be role-gated)
try {
    $cc = Get-SupervisoryReviewPolicyV2 -ErrorAction Stop | Where-Object { $_.Name -eq $CommPolicyName }
    $ccOk = [bool]$cc
    Write-Host ("FS supervision policy present: {0}" -f ($(if($ccOk){'YES'}else{'NO (create per Implementation Step 10)'}))) -ForegroundColor ($(if($ccOk){'Green'}else{'Yellow'}))
} catch {
    Write-Host "FS supervision policy present: UNKNOWN (cmdlet role-gated / licensing — verify Communication Compliance role)" -ForegroundColor Yellow
}

if ($pass) { Write-Host "`nResult: VALIDATION PASSED" -ForegroundColor Green }
else       { Write-Host "`nResult: GAPS FOUND — see FS-Purview-Remediation.ps1 (-WhatIf) and the Implementation Guide" -ForegroundColor Yellow }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
if ($pass) { exit 0 } else { exit 1 }
