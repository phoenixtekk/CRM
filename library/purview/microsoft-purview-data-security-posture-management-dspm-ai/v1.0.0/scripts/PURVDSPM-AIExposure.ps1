<#
.SYNOPSIS
    PURVDSPM-AIExposure.ps1 — report AI/Copilot interaction activity and SharePoint/OneDrive oversharing (read-only).
.DESCRIPTION
    PURPOSE
        The DSPM-for-AI exposure report. Pulls AI/Copilot interaction records from Purview auditing
        (the same signal that feeds DSPM for AI) and the SharePoint/OneDrive sharing signal that
        indicates oversharing — content broadly reachable, and therefore reachable by AI. Read-only.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Exchange Online / Security & Compliance PowerShell (for
        Search-UnifiedAuditLog):
          Connect-ExchangeOnline        # (or Connect-IPPSSession where Search-UnifiedAuditLog is available)
          .\PURVDSPM-AIExposure.ps1 -Days 30
    EXPECTED RESULTS
        AI-Exposure-Copilot-Assess.csv (AI interaction activity) and Oversharing-Report-Sites-Assess.csv
        (sharing-link / broad-access events). Empty AI results usually mean auditing is off (Req 2.3) or
        Copilot/AI has not been used yet — confirm both.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    VERIFY IN YOUR TENANT: the audit RecordType/Operations used to surface AI interactions and sharing
    evolve. This script parameterizes them (-AiRecordTypes / -SharingOperations) with current-documented
    defaults; confirm the exact values in Purview → Audit for your tenant rather than assuming. For the
    richest AI data-access / oversharing view, use the DSPM for AI reports and (where licensed)
    SharePoint Advanced Management's data-access governance report in the portal — this script provides
    the portable, scriptable signal, not a replacement for those blades.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string[]]$AiRecordTypes = @("CopilotInteraction"),
    [string[]]$SharingOperations = @("SharingSet","SharingInvitationCreated","AnonymousLinkCreated","AddedToSecureLink","CompanyLinkCreated"),
    [int]$ResultSize = 5000,
    [string]$AiOutPath = ".\AI-Exposure-Copilot-Assess.csv",
    [string]$SharingOutPath = ".\Oversharing-Report-Sites-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== PURVDSPM AI Exposure — DSPM for AI signal (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    Write-Host "Search-UnifiedAuditLog not available. Connect Exchange Online / Security & Compliance PowerShell first (Connect-ExchangeOnline)." -ForegroundColor Red
    return
}

$start = (Get-Date).AddDays(-1 * [math]::Abs($Days))
$end   = Get-Date
Write-Host ("Window: {0:yyyy-MM-dd} .. {1:yyyy-MM-dd}" -f $start, $end) -ForegroundColor Cyan

function Invoke-AuditSearch {
    param([string[]]$RecordTypes, [string[]]$Operations)
    $params = @{ StartDate = $start; EndDate = $end; ResultSize = $ResultSize; Formatted = $true }
    if ($RecordTypes) { $params.RecordType = $RecordTypes }
    if ($Operations)  { $params.Operations = $Operations }
    try { return @(Search-UnifiedAuditLog @params) }
    catch { Write-Host "  Audit search failed: $($_.Exception.Message)" -ForegroundColor Yellow; return @() }
}

# --- AI / Copilot interactions ---
Write-Host "`n[1/2] AI / Copilot interactions..." -ForegroundColor Cyan
$aiRaw = Invoke-AuditSearch -RecordTypes $AiRecordTypes -Operations @()
$aiRows = foreach ($e in $aiRaw) {
    $d = $null; try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    [pscustomobject]@{
        CreationDate = $e.CreationDate
        User         = $e.UserIds
        Operation    = $e.Operations
        RecordType   = $e.RecordType
        AppHost      = $d.CopilotEventData.AppHost
        Accessed     = ($d.CopilotEventData.AccessedResources | ForEach-Object { $_.Name }) -join "; "
        SensitivityLabels = ($d.CopilotEventData.AccessedResources | ForEach-Object { $_.SensitivityLabelId }) -join "; "
    }
}
$aiRows | Export-Csv -Path $AiOutPath -NoTypeInformation -Encoding UTF8
Write-Host ("  {0} AI-interaction record(s) → {1}  (AI Exposure - Copilot - Assess)" -f @($aiRows).Count, $AiOutPath) -ForegroundColor Green
if (@($aiRows).Count -eq 0) {
    Write-Host "  No AI interactions found — confirm auditing is ON (Req 2.3), that Copilot/AI has been used, and the -AiRecordTypes value for your tenant." -ForegroundColor Yellow
}

# --- Oversharing signal (broad/anonymous sharing events) ---
Write-Host "`n[2/2] SharePoint/OneDrive sharing (oversharing signal)..." -ForegroundColor Cyan
$shRaw = Invoke-AuditSearch -RecordTypes @() -Operations $SharingOperations
$shRows = foreach ($e in $shRaw) {
    $d = $null; try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    [pscustomobject]@{
        CreationDate = $e.CreationDate
        User         = $e.UserIds
        Operation    = $e.Operations
        Site         = $d.SiteUrl
        Object       = $d.ObjectId
        TargetUser   = $d.TargetUserOrGroupName
        LinkType     = $d.EventData
    }
}
$shRows | Export-Csv -Path $SharingOutPath -NoTypeInformation -Encoding UTF8
Write-Host ("  {0} sharing event(s) → {1}  (Oversharing Report - Sites - Assess)" -f @($shRows).Count, $SharingOutPath) -ForegroundColor Green

# Top oversharing sites (priority reduction targets)
if (@($shRows).Count -gt 0) {
    Write-Host "`n=== Top sites by broad-sharing events (priority oversharing targets) ===" -ForegroundColor Cyan
    $shRows | Where-Object Site | Group-Object Site | Sort-Object Count -Descending | Select-Object -First 15 |
        ForEach-Object { Write-Host ("  {0,-6} {1}" -f $_.Count, $_.Name) }
}

Write-Host "`nNext: cross-read these with DSPM for AI → Reports, then baseline recommendations with PURVDSPM-Tracker.ps1." -ForegroundColor Cyan
