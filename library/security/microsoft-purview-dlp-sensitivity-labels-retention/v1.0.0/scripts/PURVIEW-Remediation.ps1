<#
.SYNOPSIS
    PURVIEW-Remediation.ps1 — safely fix common Purview configuration gaps (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates the low-risk gaps that PURVIEW-Validation.ps1 finds — enabling a published-but-off
        label policy and enabling a disabled retention policy — WITHOUT ever silently switching a DLP
        policy to enforce (that is the audit gate, a human decision). Runs in -WhatIf by default;
        pass -Apply to make changes. It never deletes anything and never enables Enforce mode on DLP.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\PURVIEW-Remediation.ps1
        Apply changes:          powershell -ExecutionPolicy Bypass -File .\PURVIEW-Remediation.ps1 -Apply
        Sign in as a Compliance Administrator when prompted.
    EXPECTED RESULTS
        A list of proposed actions (WhatIf) or the applied changes (-Apply). DLP enforce is never
        automated — the script only reports DLP policies still in test/audit for the operator to
        promote via the Implementation Guide (Step 7).
.NOTES
    Phoenixtekk Workplace Marketplace — Security Solutions. Default is a dry run.
    Uses Get-/Set-LabelPolicy and Get-/Set-RetentionCompliancePolicy; reads Get-DlpCompliancePolicy.
#>
[CmdletBinding()] param(
    [switch]$Apply,
    [string]$LabelPolicyName     = 'Label Policy - Sensitivity Taxonomy - All Users',
    [string]$RetentionPolicyName = 'Retention Policy - M365 Baseline - 5 Year'
)
$WhatIf = -not $Apply
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'APPLY'})

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== Microsoft Purview — remediation [{0}] ===" -f $mode) -ForegroundColor Cyan

# 1. Enable the label policy if it exists but is disabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
if ($lp) {
    if (-not $lp.Enabled) {
        Write-Host ("  Label policy '{0}' is disabled -> enable it." -f $LabelPolicyName) -ForegroundColor Yellow
        if (-not $WhatIf) { Set-LabelPolicy -Identity $LabelPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  Label policy '{0}' already enabled — no action." -f $LabelPolicyName) -ForegroundColor Green }
} else { Write-Host ("  Label policy '{0}' not found — create it (Implementation Step 3)." -f $LabelPolicyName) -ForegroundColor Yellow }

# 2. Enable the retention policy if it exists but is disabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
if ($rp) {
    if (-not $rp.Enabled) {
        Write-Host ("  Retention policy '{0}' is disabled -> enable it." -f $RetentionPolicyName) -ForegroundColor Yellow
        if (-not $WhatIf) { Set-RetentionCompliancePolicy -Identity $RetentionPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  Retention policy '{0}' already enabled — no action." -f $RetentionPolicyName) -ForegroundColor Green }
} else { Write-Host ("  Retention policy '{0}' not found — create it (Implementation Step 9)." -f $RetentionPolicyName) -ForegroundColor Yellow }

# 3. DLP: report only — NEVER auto-enforce (the audit gate is a human decision)
Write-Host "`n  DLP policies still in test/audit (promote to Enforce manually after the audit gate):" -ForegroundColor Cyan
$auditDlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Mode -notmatch 'Enable' }
if ($auditDlp) { $auditDlp | Select-Object Name, Mode | Format-Table -AutoSize }
else { Write-Host "    none (no test/audit DLP policies found)." -ForegroundColor Green }
Write-Host "  NOTE: this script never switches DLP to Enforce — see Implementation Guide Step 7." -ForegroundColor Yellow

if ($WhatIf) { Write-Host "`nPreview only. Re-run with -Apply to make the changes above." -ForegroundColor Cyan }
else         { Write-Host "`nRemediation applied. Re-run PURVIEW-Validation.ps1 to confirm." -ForegroundColor Green }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
