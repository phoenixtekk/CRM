<#
.SYNOPSIS
    PURVIEW-MFG-Remediation.ps1 — safely fix common Purview gaps (default -WhatIf, never auto-enforce).
.DESCRIPTION
    PURPOSE
        Remediates the low-risk gaps that PURVIEW-MFG-Validation.ps1 finds — enabling a published-but-
        off Manufacturing label policy and enabling a disabled retention policy — WITHOUT ever
        silently switching a DLP policy to enforce (that is the audit gate, a human decision) and
        without touching label encryption or the export-control rule. Runs in -WhatIf by default;
        pass -Apply to make changes. It never deletes anything.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\PURVIEW-MFG-Remediation.ps1
        Apply changes:           powershell -ExecutionPolicy Bypass -File .\PURVIEW-MFG-Remediation.ps1 -Apply
        Sign in as a Compliance Administrator when prompted.
    EXAMPLE
        .\PURVIEW-MFG-Remediation.ps1 -WhatIf
    EXPECTED RESULTS
        A list of proposed actions (WhatIf) or the applied changes (-Apply). DLP enforce is never
        automated — the script only reports DLP policies still in test/audit for the operator to
        promote via the Implementation Guide (Step 8).
.NOTES
    White-label — Purview Solutions. Default is a dry run. PowerShell 5.1+/7+.
    Uses Get-/Set-LabelPolicy and Get-/Set-RetentionCompliancePolicy; reads Get-DlpCompliancePolicy.
#>
[CmdletBinding()] param(
    [switch]$Apply,
    [switch]$WhatIf,
    [string]$LabelPolicyName     = 'Label Policy - Manufacturing Taxonomy - All Users',
    [string]$RetentionPolicyName = 'Retention Policy - Manufacturing Baseline - 5 Year'
)
$doApply = $Apply -and -not $WhatIf
$mode = $(if($doApply){'APPLY'}else{'WHATIF (preview only)'})

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== Microsoft Purview for Manufacturing — remediation [{0}] ===" -f $mode) -ForegroundColor Cyan

# 1. Enable the label policy if it exists but is disabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
if ($lp) {
    if (-not $lp.Enabled) {
        Write-Host ("  Label policy '{0}' is disabled -> enable it." -f $LabelPolicyName) -ForegroundColor Yellow
        if ($doApply) { Set-LabelPolicy -Identity $LabelPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  Label policy '{0}' already enabled — no action." -f $LabelPolicyName) -ForegroundColor Green }
} else { Write-Host ("  Label policy '{0}' not found — create it (Implementation Step 3)." -f $LabelPolicyName) -ForegroundColor Yellow }

# 2. Enable the retention policy if it exists but is disabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
if ($rp) {
    if (-not $rp.Enabled) {
        Write-Host ("  Retention policy '{0}' is disabled -> enable it." -f $RetentionPolicyName) -ForegroundColor Yellow
        if ($doApply) { Set-RetentionCompliancePolicy -Identity $RetentionPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  Retention policy '{0}' already enabled — no action." -f $RetentionPolicyName) -ForegroundColor Green }
} else { Write-Host ("  Retention policy '{0}' not found — create it (Implementation Step 10)." -f $RetentionPolicyName) -ForegroundColor Yellow }

# 3. DLP: report only — NEVER auto-enforce (the audit gate is a human decision)
Write-Host "`n  DLP policies still in test/audit (promote to Enforce manually after the audit gate):" -ForegroundColor Cyan
$auditDlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Mode -notmatch 'Enable' }
if ($auditDlp) { $auditDlp | Select-Object Name, Mode | Format-Table -AutoSize }
else { Write-Host "    none (no test/audit DLP policies found)." -ForegroundColor Green }
Write-Host "  NOTE: this script never switches DLP to Enforce — see Implementation Guide Step 8." -ForegroundColor Yellow

if ($doApply) { Write-Host "`nRemediation applied. Re-run PURVIEW-MFG-Validation.ps1 to confirm." -ForegroundColor Green }
else          { Write-Host "`nPreview only. Re-run with -Apply to make the changes above." -ForegroundColor Cyan }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
