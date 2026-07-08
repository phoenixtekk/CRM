<#
.SYNOPSIS
    CLSREPORT-Discovery.ps1 — read-only classification-reporting readiness: audit ingestion, Content/Activity Explorer role coverage, and label/SIT inventory presence.
.DESCRIPTION
    PURPOSE
        Builds the reporting baseline before you enable anything: whether unified audit log ingestion
        (Activity Explorer's data source) is on; current membership of the two Content Explorer viewer
        role groups; an inventory count of sensitivity labels, retention labels, and sensitive information
        types available to report on; and whether the export cmdlets this solution uses resolve in your
        tenant. Read-only — makes no changes. Run it first (Implementation Phase 1).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSREPORT-Discovery.ps1 -CsvPath .\CLSREPORT-out\readiness.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and Exchange Online PowerShell
        (Connect-ExchangeOnline) via the ExchangeOnlineManagement module. PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        Console tables for audit-ingestion state, the two viewer role groups' members, and the classification
        tag inventory, plus an optional CSV. PASS signal: audit ingestion is True, the role groups exist with
        a known (minimal) membership, and a non-empty tag inventory is available to report on. A zero tag
        inventory is a valid BASELINE finding (largely unclassified estate), not a failure.
.NOTES
    Purview — Classification Reporting & Analytics. Read-only against S&C PowerShell / Exchange Online. No changes, no credentials in code.
    Expected results: PASS = audit True + viewer roles known + tag inventory present (or explicit baseline note).
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ListViewerRoleGroup    = 'Content Explorer List Viewer',
    [string]$ContentViewerRoleGroup = 'Content Explorer Content Viewer',
    [string]$UserPrincipalName
)

# --- Modules / connections (modern auth / MFA). Reuses existing sessions if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

# Security & Compliance PowerShell (labels, SITs, role groups)
if (-not (Get-Command Get-RoleGroupMember -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
# Exchange Online (audit config)
if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-ExchangeOnline -ShowBanner:$false }
}

Write-Host '=== Classification Reporting Readiness (read-only) ===' -ForegroundColor Cyan

# --- 1. Audit ingestion (Activity Explorer data source) ---
Write-Host '--- Unified audit log ingestion ---' -ForegroundColor Cyan
$auditOn = $null
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $auditOn = [bool]$cfg.UnifiedAuditLogIngestionEnabled
    if ($auditOn) {
        Write-Host 'PASS: UnifiedAuditLogIngestionEnabled = True (Activity Explorer / activity exports can populate).' -ForegroundColor Green
    } else {
        Write-Host 'MISSING: UnifiedAuditLogIngestionEnabled = False — enable it (CLSREPORT-Configure.ps1 -EnableAudit -Commit) before expecting activity data (Req 2.4).' -ForegroundColor Yellow
    }
} catch {
    Write-Host ("Could not read audit config ({0}) — verify the Exchange Online connection / role." -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- 2. Content Explorer viewer role coverage ---
Write-Host '--- Content Explorer viewer role groups ---' -ForegroundColor Cyan
$roleRows = foreach ($rg in @($ListViewerRoleGroup, $ContentViewerRoleGroup)) {
    $members = @()
    try { $members = @(Get-RoleGroupMember -Identity $rg -ErrorAction Stop | Select-Object -ExpandProperty Name) } catch {}
    [pscustomobject]@{
        RoleGroup   = $rg
        MemberCount = $members.Count
        Members     = ($members -join '; ')
    }
}
$roleRows | Format-Table -AutoSize
$contentViewer = @($roleRows | Where-Object { $_.RoleGroup -eq $ContentViewerRoleGroup })
if ($contentViewer.MemberCount -gt 0) {
    Write-Host ("REVIEW: '{0}' has {1} member(s) — this role EXPOSES sensitive item content; confirm each is intended and minimal (Req 2.2)." -f $ContentViewerRoleGroup, $contentViewer.MemberCount) -ForegroundColor Yellow
} else {
    Write-Host ("'{0}' has no members yet — grant only the minimal approved set (Implementation Step 6)." -f $ContentViewerRoleGroup) -ForegroundColor Gray
}

# --- 3. Classification tag inventory available to report on ---
Write-Host '--- Classification tag inventory ---' -ForegroundColor Cyan
$labelCount = $null; $tagCount = $null; $sitCount = $null
try { $labelCount = @(Get-Label -ErrorAction Stop).Count } catch { Write-Host 'Get-Label unavailable (check role/connection).' -ForegroundColor Gray }
try { $tagCount   = @(Get-ComplianceTag -ErrorAction Stop).Count } catch { Write-Host 'Get-ComplianceTag unavailable (check role/connection).' -ForegroundColor Gray }
try { $sitCount   = @(Get-DlpSensitiveInformationType -ErrorAction Stop).Count } catch { Write-Host 'Get-DlpSensitiveInformationType unavailable (check role/connection).' -ForegroundColor Gray }
Write-Host ("Sensitivity labels : {0}" -f $labelCount)
Write-Host ("Retention labels   : {0}" -f $tagCount)
Write-Host ("Sensitive info types (incl. built-ins): {0}" -f $sitCount)
if (($labelCount -eq 0) -and ($tagCount -eq 0)) {
    Write-Host 'BASELINE: no published sensitivity/retention labels found — reports will show a baseline (unclassified) estate. This is a finding to route to governance, not a failure (Req 2.5).' -ForegroundColor Yellow
}

# --- 4. Export cmdlet availability (licensing-/tenant-dependent — verify) ---
Write-Host '--- Export surface availability (verify your licensing/tenant) ---' -ForegroundColor Cyan
$activityExport = [bool](Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue)
Write-Host ("Export-ActivityExplorerData resolvable : {0}" -f $activityExport)
if (-not $activityExport) {
    Write-Host 'Export-ActivityExplorerData did not resolve — Activity Explorer export requires the appropriate E5 / E5 Compliance licensing and role; verify in your tenant (Req 2.1).' -ForegroundColor Gray
}
# Content Explorer has no supported item-export cmdlet in most tenants — it is a PORTAL (and, where available, Graph) surface.
$contentExportCmd = Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue
if ($contentExportCmd) {
    Write-Host 'Export-ContentExplorerData resolved in this tenant (version-dependent) — coverage export may be scriptable; VERIFY before relying on it.' -ForegroundColor Gray
} else {
    Write-Host 'Content Explorer export: no export cmdlet in this tenant — treat coverage export as a PORTAL/manual (or Graph, where available) action. Flag "verify your licensing/tenant" in reports.' -ForegroundColor Gray
}

# --- Summary / optional CSV ---
Write-Host '--- Baseline summary ---' -ForegroundColor Cyan
$summary = [pscustomobject]@{
    AuditIngestionEnabled = $auditOn
    ListViewerMembers     = ($roleRows | Where-Object { $_.RoleGroup -eq $ListViewerRoleGroup }).MemberCount
    ContentViewerMembers  = $contentViewer.MemberCount
    SensitivityLabels     = $labelCount
    RetentionLabels       = $tagCount
    SensitiveInfoTypes    = $sitCount
    ActivityExportOk      = $activityExport
    ContentExportCmd      = [bool]$contentExportCmd
}
$summary | Format-List

if ($CsvPath) {
    $dir = Split-Path -Parent $CsvPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $roleRows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Role-coverage inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Read-only baseline captured — enable audit + scoped viewer roles next (CLSREPORT-Configure.ps1, -WhatIf first).' -ForegroundColor Cyan
