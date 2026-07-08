<#
.SYNOPSIS
    OPSHEALTH-Remediate.ps1 — print the prioritized remediation plan; commit ONLY the audit-log re-enable (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Generates the remediation plan for the health check and changes NOTHING by default. It prints the
        prioritized plan (finding -> severity -> owning capability -> recommended action) from a
        Remediation-Register CSV (or a live re-scan), and routes DLP / label / retention / insider-risk
        fixes to their OWNING capability solution (piloted in simulation/test there). Its ONLY commit path,
        -EnableUnifiedAuditLog -Commit, performs the single safe, reversible direct fix — re-enabling the
        unified audit log via Exchange Online. It never enables/enforces DLP, labels, retention, or IRM.
    HOW TO RUN
        Plan only (default):     powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-Remediate.ps1 -WhatIf
        From a register CSV:     .\OPSHEALTH-Remediate.ps1 -RegisterCsv .\opshealth-register.csv -WhatIf
        Commit the one safe fix: .\OPSHEALTH-Remediate.ps1 -EnableUnifiedAuditLog -Commit
        Prereqs: ExchangeOnlineManagement; MFA-capable admin. -Commit needs R7 change-control sign-off.
    EXAMPLE
        .\OPSHEALTH-Remediate.ps1 -WhatIf
    EXPECTED RESULTS
        The prioritized plan (WhatIf) with changes = none; with -EnableUnifiedAuditLog -Commit the unified
        audit log reads enabled after propagation (the only direct write). All other items are routed to
        their owning capability solution — never flipped on here.
.NOTES
    White-label. -WhatIf by default; only -Commit writes, and only the audit-log re-enable. No credentials in code.
#>
[CmdletBinding()]
param(
    [string] $RegisterCsv,
    [switch] $EnableUnifiedAuditLog,
    [switch] $Commit,
    [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
$doCommit = $Commit -and -not $WhatIf
$mode = $(if($doCommit){'COMMIT (audit-log re-enable only)'}else{'WHATIF (plan only — no changes)'})
Write-Host ("`n=== Microsoft Purview Health Check — remediation [{0}] ===" -f $mode) -ForegroundColor Cyan

# --- Print the prioritized plan --------------------------------------------------------------------
Write-Section 'Prioritized remediation plan'
if ($RegisterCsv -and (Test-Path $RegisterCsv)) {
    $rows = Import-Csv -Path $RegisterCsv
    if ($rows) {
        $rows | Sort-Object @{e={ switch ($_.Severity) { 'High'{0} 'Medium'{1} default{2} } }} |
            Select-Object Finding, Domain, Rating, Severity, Owner, 'Owning capability', 'Recommended action' | Format-Table -AutoSize
    } else { Write-Host '  Register CSV is empty.' -ForegroundColor Yellow }
} else {
    Write-Host '  No -RegisterCsv supplied. Build the Remediation Register from OPSHEALTH-Discovery.ps1 /' -ForegroundColor Yellow
    Write-Host '  OPSHEALTH-ScopeCheck.ps1 findings (fields: Finding, Domain, Rating, Severity, Owner,' -ForegroundColor Yellow
    Write-Host '  Owning capability, Recommended action), then re-run with -RegisterCsv to prioritize it.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '  ROUTING RULE — this solution does NOT flip high-impact capabilities:' -ForegroundColor Cyan
Write-Host '   - DLP / labels / retention / insider-risk gaps  -> owning capability solution (pilot in simulation/test there)'
Write-Host '   - Records / retention-schedule / legal-hold / regulatory items -> compliance/records/privacy/legal (determination required)'
Write-Host '   - Unified audit log OFF -> the ONE safe fix below (-EnableUnifiedAuditLog -Commit)'

# --- The one safe, reversible direct fix: re-enable the unified audit log ---------------------------
Write-Section 'The one safe direct fix — unified audit log'
if ($EnableUnifiedAuditLog) {
    try {
        if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
        $ual = (Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
        if ($ual) { Write-Host '  Unified audit log is already ON — no action.' -ForegroundColor Green }
        else {
            Write-Host '  Unified audit log is OFF.' -ForegroundColor Yellow
            if ($doCommit) {
                Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
                Write-Host '    COMMITTED: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true.' -ForegroundColor Green
                Write-Host '    Ingestion can take time to reflect — verify in tenant. Rollback: set it back to $false.' -ForegroundColor DarkYellow
            } else {
                Write-Host '    WHATIF: would run Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true. Re-run with -Commit.' -ForegroundColor Yellow
            }
        }
    }
    catch { Write-Warning ("Could not read/set the unified audit log: {0}" -f $_.Exception.Message); Write-Host '  Confirm Exchange Online access. Verify in tenant.' }
} else {
    Write-Host '  (-EnableUnifiedAuditLog not passed — skipping. This is the only direct write this solution performs.)' -ForegroundColor DarkGray
}

Write-Section 'Done'
if ($doCommit) { Write-Host 'Committed the audit-log re-enable only. Re-run OPSHEALTH-Validate.ps1 to re-score.' -ForegroundColor Green }
else           { Write-Host 'Plan only — nothing changed. Route each item to its owning capability; commit the audit-log fix with -EnableUnifiedAuditLog -Commit.' -ForegroundColor Cyan }
Write-Host 'HARD RULE: never enable/enforce DLP, labels, retention, or insider risk from this solution — pilot them in their owning solution.' -ForegroundColor Yellow
