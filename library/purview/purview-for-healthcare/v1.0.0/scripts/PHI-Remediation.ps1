<#
.SYNOPSIS
    PHI-Remediation.ps1 — safely fix common PHI Purview configuration gaps (default -WhatIf; never auto-enforces DLP).
.DESCRIPTION
    PURPOSE
        Remediates the low-risk gaps that PHI-Validation.ps1 finds — enabling a published-but-off PHI
        label policy and enabling a disabled healthcare retention policy — WITHOUT ever silently
        switching a DLP policy to enforce (that is the audit gate, a human decision, and blocking
        clinicians is a patient-care risk). Runs in -WhatIf by default; pass -Apply to make changes.
        It never deletes anything and never enables Enforce mode on DLP.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\PHI-Remediation.ps1
        Apply changes:          powershell -ExecutionPolicy Bypass -File .\PHI-Remediation.ps1 -Apply
        Sign in as a Compliance Administrator when prompted.
.EXAMPLE
    .\PHI-Remediation.ps1 -WhatIf
    Lists the proposed low-risk fixes without changing anything. Re-run with -Apply to make them.
    PowerShell 5.1+/7+; uses Connect-IPPSSession.
.NOTES
    Expected results: a list of proposed actions (default) or applied changes (-Apply). DLP enforce is
    NEVER automated — the script only reports DLP policies still in test/audit for the operator to
    promote via Implementation Step 7. White-label — no credentials in code.
#>
[CmdletBinding()] param(
    [switch]$Apply,
    [string]$LabelPolicyName     = 'Label Policy - Healthcare PHI Taxonomy - All Users',
    [string]$RetentionPolicyName = 'Retention Policy - Healthcare Baseline - Schedule-Defined'
)
$WhatIf = -not $Apply
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'APPLY'})

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== Microsoft Purview for Healthcare — remediation [{0}] ===" -f $mode) -ForegroundColor Cyan

# 1. Enable the PHI label policy if it exists but is disabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
if ($lp) {
    if (-not $lp.Enabled) {
        Write-Host ("  PHI label policy '{0}' is disabled -> enable it." -f $LabelPolicyName) -ForegroundColor Yellow
        if (-not $WhatIf) { Set-LabelPolicy -Identity $LabelPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  PHI label policy '{0}' already enabled — no action." -f $LabelPolicyName) -ForegroundColor Green }
} else { Write-Host ("  PHI label policy '{0}' not found — create it (Implementation Step 3)." -f $LabelPolicyName) -ForegroundColor Yellow }

# 2. Enable the healthcare retention policy if it exists but is disabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
if ($rp) {
    if (-not $rp.Enabled) {
        Write-Host ("  Retention policy '{0}' is disabled -> enable it." -f $RetentionPolicyName) -ForegroundColor Yellow
        if (-not $WhatIf) { Set-RetentionCompliancePolicy -Identity $RetentionPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  Retention policy '{0}' already enabled — no action." -f $RetentionPolicyName) -ForegroundColor Green }
} else { Write-Host ("  Retention policy '{0}' not found — create it (Implementation Step 9)." -f $RetentionPolicyName) -ForegroundColor Yellow }

# 3. DLP: report only — NEVER auto-enforce (the audit gate is a human decision; blocking clinicians is a care risk)
Write-Host "`n  DLP policies still in test/audit (promote to Enforce manually after the audit gate):" -ForegroundColor Cyan
$auditDlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Mode -notmatch 'Enable' }
if ($auditDlp) { $auditDlp | Select-Object Name, Mode | Format-Table -AutoSize }
else { Write-Host "    none (no test/audit DLP policies found)." -ForegroundColor Green }
Write-Host "  NOTE: this script never switches DLP to Enforce — see Implementation Guide Step 7." -ForegroundColor Yellow

if ($WhatIf) { Write-Host "`nPreview only. Re-run with -Apply to make the changes above." -ForegroundColor Cyan }
else         { Write-Host "`nRemediation applied. Re-run PHI-Validation.ps1 to confirm." -ForegroundColor Green }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
