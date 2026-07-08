<#
.SYNOPSIS
    OPSMANAGED-Remediation.ps1 — safely fix low-risk drift; route high-impact changes to the owning capability (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates only the low-risk drift the service is allowed to fix directly — enabling a published-
        but-off label policy and enabling a disabled retention policy — WITHOUT ever switching a DLP policy
        to enforce or making any other high-impact change (those are routed to the owning capability and
        piloted in simulation/test there). Runs in -WhatIf by default; pass -Apply to make the two safe
        changes. It only REPORTS DLP policies still in test/audit for the owner to promote via the owning
        solution. It never deletes anything.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Remediation.ps1
        Apply changes:          powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Remediation.ps1 -Apply
        Sign in as a Compliance Administrator when prompted; make changes under change control (Req 2.6).
    EXAMPLE
        .\OPSMANAGED-Remediation.ps1 -WhatIf
    EXPECTED RESULTS
        A list of proposed actions (WhatIf) or the applied changes (-Apply). DLP enforce and all other
        high-impact changes are never automated — they are routed to the owning capability, piloted first.
.NOTES
    White-label — Purview Solutions. Default is a dry run.
    Uses Get-/Set-LabelPolicy and Get-/Set-RetentionCompliancePolicy; reads Get-DlpCompliancePolicy.
#>
[CmdletBinding()] param(
    [switch]$Apply,
    [string]$LabelPolicyName,
    [string]$RetentionPolicyName
)
$WhatIf = -not $Apply
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'APPLY'})

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== Microsoft Purview Managed Service — remediation [{0}] ===" -f $mode) -ForegroundColor Cyan
Write-Host "  ROUTING RULE: this service directly fixes only low-risk drift (enable a disabled label/retention policy)." -ForegroundColor Cyan
Write-Host "  All high-impact changes (DLP enforce, label/retention/insider-risk changes) are routed to the OWNING capability and piloted there." -ForegroundColor Cyan

# 1. Enable a disabled label policy (only if a name is supplied)
if ($LabelPolicyName) {
    $lp = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabelPolicyName }
    if ($lp) {
        if (-not $lp.Enabled) {
            Write-Host ("`n  Label policy '{0}' is disabled -> enable it." -f $LabelPolicyName) -ForegroundColor Yellow
            if (-not $WhatIf) { Set-LabelPolicy -Identity $LabelPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
        } else { Write-Host ("`n  Label policy '{0}' already enabled — no action." -f $LabelPolicyName) -ForegroundColor Green }
    } else { Write-Host ("`n  Label policy '{0}' not found — create it in the owning Labels solution." -f $LabelPolicyName) -ForegroundColor Yellow }
} else { Write-Host "`n  (No -LabelPolicyName supplied — pass one to enable a specific disabled label policy.)" -ForegroundColor DarkGray }

# 2. Enable a disabled retention policy (only if a name is supplied)
if ($RetentionPolicyName) {
    $rp = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RetentionPolicyName }
    if ($rp) {
        if (-not $rp.Enabled) {
            Write-Host ("  Retention policy '{0}' is disabled -> enable it." -f $RetentionPolicyName) -ForegroundColor Yellow
            if (-not $WhatIf) { Set-RetentionCompliancePolicy -Identity $RetentionPolicyName -Enabled $true; Write-Host "    enabled." -ForegroundColor Green }
        } else { Write-Host ("  Retention policy '{0}' already enabled — no action." -f $RetentionPolicyName) -ForegroundColor Green }
    } else { Write-Host ("  Retention policy '{0}' not found — create it in the owning Lifecycle solution." -f $RetentionPolicyName) -ForegroundColor Yellow }
} else { Write-Host "  (No -RetentionPolicyName supplied — pass one to enable a specific disabled retention policy.)" -ForegroundColor DarkGray }

# 3. DLP: report only — NEVER auto-enforce (route to the owning DLP solution, piloted)
Write-Host "`n  DLP policies still in test/audit (promote to Enforce in the OWNING DLP solution, piloted first):" -ForegroundColor Cyan
$auditDlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Mode -notmatch 'Enable' }
if ($auditDlp) { $auditDlp | Select-Object Name, Mode | Format-Table -AutoSize }
else { Write-Host "    none (no test/audit DLP policies found)." -ForegroundColor Green }
Write-Host "  NOTE: this service never switches DLP to Enforce — record the change in `Managed Service – Tuning Log`." -ForegroundColor Yellow

if ($WhatIf) { Write-Host "`nPreview only. Re-run with -Apply (under change control) to make the low-risk changes above." -ForegroundColor Cyan }
else         { Write-Host "`nRemediation applied. Re-run OPSMANAGED-Validation.ps1 to confirm." -ForegroundColor Green }

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
