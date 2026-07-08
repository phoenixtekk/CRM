<#
.SYNOPSIS
    RETAIL-Configuration.ps1 — safely fix common retail Purview gaps (default -WhatIf; never auto-blocks DLP).
.DESCRIPTION
    PURPOSE
        Remediates the low-risk gaps RETAIL-Validation.ps1 finds — enabling a published-but-off label
        policy and enabling a disabled retention policy — WITHOUT ever switching a DLP policy to
        enforce/block (that is the audit gate, a human decision, and blocking PAN/PII is high-impact).
        Runs in -WhatIf (preview) by default; pass -Apply to make changes. It never deletes anything
        and never enables Enforce/Block mode on DLP; it only reports DLP policies still in test/audit.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\RETAIL-Configuration.ps1
        Apply changes:          powershell -ExecutionPolicy Bypass -File .\RETAIL-Configuration.ps1 -Apply
        Sign in as a Compliance Administrator when prompted.
    EXPECTED RESULTS
        A list of proposed actions (WhatIf) or the applied changes (-Apply). DLP enforce/block is never
        automated — the script only lists PCI/PII DLP policies still in test/audit for the operator to
        promote via the Implementation Guide (Step 8) after the audit gate.
.NOTES
    White-label — Purview / Retail. Default is a dry run.
    PowerShell 5.1+/7+. Uses Get-/Set-LabelPolicy and Get-/Set-RetentionCompliancePolicy; reads
    Get-DlpCompliancePolicy. Does not create/delete objects.
#>
[CmdletBinding()] param(
    [switch]$Apply,
    [string]$LabelPolicyName     = 'Label Policy - Retail Data Classification - Pilot',
    [string]$RetentionPolicyName = 'Retention Policy - Retail Baseline - 5 Year'
)
$WhatIf = -not $Apply
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'APPLY'})

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== Microsoft Purview for Retail — configuration/remediation [{0}] ===" -f $mode) -ForegroundColor Cyan

# 1. Enable the label policy if it exists but is disabled
$lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
if ($lp) {
    if (-not $lp.Enabled) {
        Write-Host ("  Label policy '{0}' is disabled -> enable it." -f $LabelPolicyName) -ForegroundColor Yellow
        if (-not $WhatIf) { Set-LabelPolicy -Identity $LabelPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  Label policy '{0}' already enabled - no action." -f $LabelPolicyName) -ForegroundColor Green }
} else { Write-Host ("  Label policy '{0}' not found - create it (Implementation Step 3)." -f $LabelPolicyName) -ForegroundColor Yellow }

# 2. Enable the retention policy if it exists but is disabled
$rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
if ($rp) {
    if (-not $rp.Enabled) {
        Write-Host ("  Retention policy '{0}' is disabled -> enable it." -f $RetentionPolicyName) -ForegroundColor Yellow
        if (-not $WhatIf) { Set-RetentionCompliancePolicy -Identity $RetentionPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
    } else { Write-Host ("  Retention policy '{0}' already enabled - no action." -f $RetentionPolicyName) -ForegroundColor Green }
} else { Write-Host ("  Retention policy '{0}' not found - create it (Implementation Step 10)." -f $RetentionPolicyName) -ForegroundColor Yellow }

# 3. DLP: report only - NEVER auto-enforce/block (the audit gate is a human decision)
Write-Host "`n  Retail DLP policies still in test/audit (promote to Block manually after the audit gate):" -ForegroundColor Cyan
$auditDlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue |
            Where-Object { $_.Mode -notmatch 'Enable' -and $_.Name -match 'PCI|Cardholder|PII|Customer|Retail' }
if ($auditDlp) { $auditDlp | Select-Object Name, Mode | Format-Table -AutoSize }
else { Write-Host "    none (no retail/PCI test-audit DLP policies found)." -ForegroundColor Green }
Write-Host "  NOTE: this script never switches DLP to Block - see Implementation Guide Step 8." -ForegroundColor Yellow

if ($WhatIf) { Write-Host "`nPreview only. Re-run with -Apply to make the changes above." -ForegroundColor Cyan }
else         { Write-Host "`nConfiguration applied. Re-run RETAIL-Validation.ps1 to confirm." -ForegroundColor Green }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
