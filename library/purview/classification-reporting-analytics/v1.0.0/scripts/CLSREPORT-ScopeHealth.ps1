<#
.SYNOPSIS
    CLSREPORT-ScopeHealth.ps1 — read-only reporting data-source health: audit ingestion + retention, workloads reporting in, and licensing-readiness flags for the explorers.
.DESCRIPTION
    PURPOSE
        Ongoing health of what the reporting depends on, so a dashboard's numbers stay trustworthy: whether
        unified audit log ingestion is on and the audit retention window; which workloads are actually
        producing classification/DLP activity (so an empty view is explained by "no signal" vs "not
        reporting in"); the published tag inventory the explorers break down by; and licensing-readiness
        flags for the licensing-gated surfaces (Content Viewer, Activity Explorer export). Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSREPORT-ScopeHealth.ps1 -Days 30 -CsvPath .\CLSREPORT-out\scope-health.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and Exchange Online PowerShell
        (Connect-ExchangeOnline). PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        A health table: audit ingestion state, audit retention (where readable), per-workload activity
        presence, tag-inventory counts, and licensing-readiness flags. PASS signal: ingestion True, a
        non-empty tag inventory, and at least one workload reporting activity in the window. Empty inventory
        (baseline estate) and unavailable licensing-gated surfaces are VERIFY/BASELINE notes, not failures.
.NOTES
    Purview — Classification Reporting & Analytics. Read-only against S&C PowerShell / Exchange Online. No changes, no credentials in code.
    Expected results: audit True + tag inventory present + a workload reporting in; licensing gates and baseline estate flagged VERIFY/BASELINE, not FAIL.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string]$CsvPath,
    [string[]]$RecordTypes = @('SensitivityLabelAction','SensitivityLabeledFileAction','ComplianceDLPSharePoint','ComplianceDLPExchange','DLPEndpoint'),
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-ExchangeOnline -ShowBanner:$false }
}

$rows = New-Object System.Collections.Generic.List[object]
function Add-Health { param($Area, $Signal, $Value, $Note)
    $rows.Add([pscustomobject]@{ Area = $Area; Signal = $Signal; Value = $Value; Note = $Note })
}

Write-Host '=== Classification Reporting — Data-Source Health (read-only) ===' -ForegroundColor Cyan

# --- 1. Audit ingestion + retention ---
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $auditOn = [bool]$cfg.UnifiedAuditLogIngestionEnabled
    Add-Health 'Audit' 'UnifiedAuditLogIngestionEnabled' $auditOn ($(if ($auditOn) {'OK — Activity Explorer / activity exports can populate'} else {'ENABLE via CLSREPORT-Configure.ps1 -EnableAudit -Commit (Req 2.4)'}))
    Write-Host ("Audit ingestion: {0}" -f $auditOn) -ForegroundColor $(if ($auditOn) {'Green'} else {'Yellow'})
} catch {
    Add-Health 'Audit' 'UnifiedAuditLogIngestionEnabled' 'VERIFY' ("Could not read: {0}" -f $_.Exception.Message)
}
# Audit retention (mailbox/tenant retention drives how far back Activity Explorer/queries reach — plan-dependent; VERIFY).
Add-Health 'Audit' 'RetentionWindow' 'VERIFY' 'Audit retention is plan-dependent (Standard vs Premium/extended). Confirm your retention in Purview -> Audit; it bounds how far back activity reporting reaches.'

# --- 2. Per-workload activity presence (is each workload reporting in?) ---
Write-Host '--- Per-workload activity presence ---' -ForegroundColor Cyan
$start = (Get-Date).AddDays(-1 * [math]::Abs($Days)); $end = Get-Date
$anyWorkload = $false
foreach ($rt in $RecordTypes) {
    $count = $null
    try {
        $count = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt -ResultSize 1 -ErrorAction Stop).Count
        # ResultSize 1 only tells us presence cheaply; re-query small for a truthy presence flag.
        $present = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt -ResultSize 10 -ErrorAction Stop).Count -gt 0
        if ($present) { $anyWorkload = $true }
        Add-Health 'Workload' $rt $present ($(if ($present) {'reporting in'} else {'no events in window (no signal or workload not producing this RecordType)'}))
        Write-Host ("  {0}: {1}" -f $rt, $(if ($present) {'reporting in'} else {'no events in window'}))
    } catch {
        Add-Health 'Workload' $rt 'VERIFY' ("RecordType may be invalid in this tenant (values evolve): {0}" -f $_.Exception.Message)
        Write-Host ("  {0}: VERIFY (record type)" -f $rt) -ForegroundColor Yellow
    }
}
if (-not $anyWorkload) {
    Write-Host 'No workload reported classification/DLP activity in the window — ingestion lag, pre-activity estate, or record-type mismatch. Not a failure by itself (see CLSREPORT-Report.ps1 notes).' -ForegroundColor Yellow
}

# --- 3. Tag inventory to report on ---
Write-Host '--- Classification tag inventory ---' -ForegroundColor Cyan
$labelCount = $null; $tagCount = $null; $sitCount = $null
try { $labelCount = @(Get-Label -ErrorAction Stop).Count } catch {}
try { $tagCount   = @(Get-ComplianceTag -ErrorAction Stop).Count } catch {}
try { $sitCount   = @(Get-DlpSensitiveInformationType -ErrorAction Stop).Count } catch {}
Add-Health 'Inventory' 'SensitivityLabels' $labelCount ''
Add-Health 'Inventory' 'RetentionLabels'   $tagCount   ''
Add-Health 'Inventory' 'SensitiveInfoTypes' $sitCount  '(includes built-ins)'
Write-Host ("Sensitivity labels: {0} | Retention labels: {1} | SITs: {2}" -f $labelCount, $tagCount, $sitCount)
if (($labelCount -eq 0) -and ($tagCount -eq 0)) {
    Write-Host 'BASELINE: no published sensitivity/retention labels — reports show a baseline (unclassified) estate. A finding to route to governance, not a failure (Req 2.5).' -ForegroundColor Yellow
    Add-Health 'Inventory' 'Baseline' $true 'No published labels — baseline (unclassified) estate; route to governance (Req 2.5)'
}

# --- 4. Licensing-readiness flags for the gated surfaces (VERIFY — never asserted) ---
Write-Host '--- Licensing-readiness flags (verify your licensing/tenant) ---' -ForegroundColor Cyan
$contentExport = [bool](Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue)
$activityExport = [bool](Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue)
Add-Health 'Licensing' 'Export-ContentExplorerData resolves' $contentExport 'Content coverage export is version-/licensing-dependent — VERIFY; portal is the fallback (Req 2.1)'
Add-Health 'Licensing' 'Export-ActivityExplorerData resolves' $activityExport 'Activity Explorer export needs E5 / E5 Compliance + role — VERIFY your licensing/tenant (Req 2.1)'
Add-Health 'Licensing' 'Content Viewer (item content)' 'VERIFY' 'Viewing item content in Content Explorer generally requires E5 / E5 Compliance — VERIFY (Req 2.1)'
Write-Host ("Export-ContentExplorerData: {0} | Export-ActivityExplorerData: {1} (both licensing-/tenant-dependent — VERIFY)" -f $contentExport, $activityExport) -ForegroundColor Gray

# --- Output ---
$rows | Format-Table -AutoSize
if ($CsvPath) {
    $dir = Split-Path -Parent $CsvPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Health inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}
Write-Host 'Done. Read-only health snapshot captured — schedule this alongside CLSREPORT-Report.ps1 to catch audit lag, workload drop-off, and tag-inventory drift.' -ForegroundColor Cyan
