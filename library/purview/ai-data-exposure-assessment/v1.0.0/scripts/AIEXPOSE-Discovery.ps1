<#
.SYNOPSIS
    AIEXPOSE-Discovery.ps1 — inventory the AI access surface AND measure what AI/Copilot could reach (read-only).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the AI Data-Exposure Assessment. Two halves of the exposure picture:
        (1) the ACCESS SURFACE that bounds what could be exposed — sensitivity labels, the label policies
        that publish them, DLP policies/rules, auto-labeling policies, and (with -IncludeSensitiveTypes)
        the sensitive information types in scope; and (2) REACHABILITY — the SharePoint/OneDrive broad-
        sharing signal (content Copilot can surface to anyone with access) and the AI/Copilot interaction
        activity from the unified audit log (what AI has actually touched, where in use). Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+. Connect Security & Compliance PowerShell (access surface) and, for the
        reachability signal, Exchange Online (unified audit log) and optionally Graph:
          Connect-IPPSSession
          Connect-ExchangeOnline
          .\AIEXPOSE-Discovery.ps1
          .\AIEXPOSE-Discovery.ps1 -IncludeSensitiveTypes -Days 30
        The AI-interaction RecordType and sharing Operations evolve — override with -AiRecordType /
        -SharingOperations if your tenant differs (see .NOTES).
    EXPECTED RESULTS
        Access-surface inventory to .\AIEXPOSE-AccessScope-Estate-Discovery.csv (AI Access Scope - Estate -
        Discovery); with -IncludeSensitiveTypes, the sensitive-info-type list to
        .\AIEXPOSE-SensitiveExposure-Estate-Assess.csv (Sensitive Exposure - Estate - Assess); the AI-
        interaction summary to .\AIEXPOSE-Reachability-Copilot-Assess.csv (AI Reachability - Copilot -
        Assess); and broad-sharing events grouped by site to .\AIEXPOSE-Oversharing-Sites-Assess.csv
        (Oversharing Exposure - Sites - Assess). A thin taxonomy/narrow DLP is itself the first finding;
        pre-adoption, the AI-interaction set may legitimately be empty while oversharing is still present.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets/Graph calls are
    standard Security & Compliance PowerShell / Exchange Online / Graph; none are invented. Feature
    availability (auto-labeling, advanced DLP) is licensing-dependent — the script warns where a feature is
    not readable rather than assuming. VERIFY IN YOUR TENANT: the audit RecordType that surfaces AI/Copilot
    interactions and the sharing Operations both evolve — this script uses common defaults and lets you
    override them, rather than asserting them. Audit data has ingestion latency; very recent activity may
    not appear.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [int]$Days = 30,
    [string]$AiRecordType = "CopilotInteraction",
    [string[]]$SharingOperations = @("SharingSet","AnonymousLinkCreated","AddedToGroup","SharingInvitationCreated"),
    [string]$OutPath          = ".\AIEXPOSE-AccessScope-Estate-Discovery.csv",
    [string]$SensitiveOutPath = ".\AIEXPOSE-SensitiveExposure-Estate-Assess.csv",
    [string]$AiOutPath        = ".\AIEXPOSE-Reachability-Copilot-Assess.csv",
    [string]$SharingOutPath   = ".\AIEXPOSE-Oversharing-Sites-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIEXPOSE Discovery — AI access surface + reachability (read-only) ===" -ForegroundColor Cyan

try { Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

# =========================================================================================
# PART A — Access surface (what protects the estate today; caps how much can be kept from AI)
# =========================================================================================
$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) { $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail }) }

try {
    $labels = Get-Label -ErrorAction Stop
    foreach ($l in $labels) { Add-Row "SensitivityLabel" $l.DisplayName ("Priority={0}; Enabled={1}" -f $l.Priority, $l.Enabled) }
    Write-Host ("  Labels: {0}" -f @($labels).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read labels: $($_.Exception.Message)" -ForegroundColor Yellow }

try {
    $lp = Get-LabelPolicy -ErrorAction Stop
    foreach ($p in $lp) { Add-Row "LabelPolicy" $p.Name ("Labels={0}" -f ($p.Labels -join "; ")) }
    Write-Host ("  Label policies: {0}" -f @($lp).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read label policies: $($_.Exception.Message)" -ForegroundColor Yellow }

try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($d in $dlp) { Add-Row "DlpPolicy" $d.Name ("Mode={0}; Workloads={1}" -f $d.Mode, $d.Workload) }
    Write-Host ("  DLP policies: {0}" -f @($dlp).Count) -ForegroundColor Green
    try {
        $dlpRules = Get-DlpComplianceRule -ErrorAction Stop
        foreach ($r in $dlpRules) { Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled) }
        Write-Host ("  DLP rules: {0}" -f @($dlpRules).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

try {
    $auto = Get-AutoSensitivityLabelPolicy -ErrorAction Stop
    foreach ($a in $auto) { Add-Row "AutoLabelPolicy" $a.Name ("Mode={0}; Label={1}" -f $a.Mode, $a.ApplySensitivityLabel) }
    Write-Host ("  Auto-labeling policies: {0}" -f @($auto).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: auto-labeling not readable (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("  Access-surface inventory written to {0}  (AI Access Scope - Estate - Discovery)" -f $OutPath) -ForegroundColor Green

if ($IncludeSensitiveTypes) {
    try {
        $sits = Get-DlpSensitiveInformationType -ErrorAction Stop
        $sits | Select-Object Name, Publisher, RulePackId | Export-Csv -Path $SensitiveOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  Sensitive information types written to {0}  (Sensitive Exposure - Estate - Assess): {1} type(s)" -f $SensitiveOutPath, @($sits).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read sensitive information types: $($_.Exception.Message)" -ForegroundColor Yellow }
}

# =========================================================================================
# PART B — Reachability (what AI/Copilot could actually reach) — from the unified audit log
# =========================================================================================
$start = (Get-Date).AddDays(-[math]::Abs($Days)); $end = Get-Date
$haveUAL = [bool](Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)
if (-not $haveUAL) {
    Write-Host "  WARN: Search-UnifiedAuditLog not available — connect Exchange Online for the reachability signal. Writing empty reachability exports." -ForegroundColor Yellow
}

# B1. AI/Copilot interaction signal (what AI has actually touched)
$aiRows = [System.Collections.Generic.List[object]]::new()
if ($haveUAL) {
    try {
        Write-Host ("  Searching AI-interaction records (RecordType '{0}', last {1}d)..." -f $AiRecordType, $Days) -ForegroundColor Cyan
        $ai = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $AiRecordType -ResultSize 5000 -ErrorAction Stop
        foreach ($e in $ai) { $aiRows.Add([pscustomobject]@{ CreationDate = $e.CreationDate; UserId = $e.UserIds; Operation = $e.Operations; RecordType = $e.RecordType }) }
        if (@($ai).Count -eq 0) { Write-Host "  No AI-interaction records — pre-adoption, or the RecordType differs (override with -AiRecordType)." -ForegroundColor Yellow }
        else { Write-Host ("  AI-interaction records: {0}" -f @($ai).Count) -ForegroundColor Green }
    } catch { Write-Host "  WARN: AI-interaction search failed (verify RecordType/auditing): $($_.Exception.Message)" -ForegroundColor Yellow }
}
$aiRows | Export-Csv -Path $AiOutPath -NoTypeInformation -Encoding UTF8
Write-Host ("  AI reachability written to {0}  (AI Reachability - Copilot - Assess)" -f $AiOutPath) -ForegroundColor Green

# B2. Broad-sharing / oversharing signal (what AI could surface to anyone with access)
$shareRows = [System.Collections.Generic.List[object]]::new()
if ($haveUAL) {
    try {
        Write-Host ("  Searching broad-sharing events ({0}, last {1}d)..." -f ($SharingOperations -join ","), $Days) -ForegroundColor Cyan
        $share = Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations $SharingOperations -RecordType "SharePointSharingOperation" -ResultSize 5000 -ErrorAction Stop
        foreach ($e in $share) {
            $d = $null; try { $d = $e.AuditData | ConvertFrom-Json } catch {}
            $shareRows.Add([pscustomobject]@{ CreationDate = $e.CreationDate; Operation = $e.Operations; Site = $(if ($d) { $d.SiteUrl } else { $null }); SharedWith = $(if ($d) { $d.TargetUserOrGroupName } else { $null }); SharedBy = $e.UserIds })
        }
        Write-Host ("  Broad-sharing events: {0}" -f @($share).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: sharing-event search failed (verify Operations): $($_.Exception.Message)" -ForegroundColor Yellow }
}
$grouped = $shareRows | Where-Object Site | Group-Object Site | Sort-Object Count -Descending |
    ForEach-Object { [pscustomobject]@{ Site = $_.Name; BroadShareEvents = $_.Count } }
if (@($grouped).Count -gt 0) { $grouped | Export-Csv -Path $SharingOutPath -NoTypeInformation -Encoding UTF8 }
else { $shareRows | Export-Csv -Path $SharingOutPath -NoTypeInformation -Encoding UTF8 }  # emit (possibly empty) so the register step has a file
Write-Host ("  Oversharing exposure written to {0}  (Oversharing Exposure - Sites - Assess)" -f $SharingOutPath) -ForegroundColor Green

Write-Host "`nNext: run AIEXPOSE-RiskRegister.ps1 to score and rank the priority exposure risks." -ForegroundColor Cyan
