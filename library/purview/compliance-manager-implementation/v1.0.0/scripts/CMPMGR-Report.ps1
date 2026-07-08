<#
.SYNOPSIS
    CMPMGR-Report.ps1 — read-only Compliance Manager score-posture rollup (CM Score Posture - Report).
.DESCRIPTION
    PURPOSE
        Produces the "CM Score Posture - Report": rolls up the local action plan / evidence register
        (from CMPMGR-Configuration.ps1), the role-separation snapshot (Compliance Manager role groups),
        and the licensing SKUs, into a single posture summary. It does NOT read the Compliance Manager
        score itself — that is portal-managed with no broad public API; the authoritative score and
        export are the Purview portal's Compliance Manager export. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Report.ps1 -PlanCsv .\out\CM-Action-Plan-Pilot.csv
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Report.ps1 -PlanCsv .\out\CM-Action-Plan-Pilot.csv -HtmlPath .\CM-Posture.html
        PlanCsv is optional; without it, the report covers roles + licensing only. Requires
        ExchangeOnlineManagement (Connect-IPPSSession) for role membership and, optionally,
        Microsoft.Graph for licensing.
    EXPECTED RESULTS
        A console posture summary: action-status breakdown, actions missing owner/evidence, the
        role-separation snapshot, and the licensing SKUs — plus an optional standalone HTML report.
.NOTES
    Purview — Microsoft Purview Compliance Manager Implementation. Read-only. No credentials are stored.
    Authoritative score/export = Purview portal (Compliance Manager). Verify against your tenant.
#>
[CmdletBinding()]
param(
    [string]$PlanCsv,
    [string]$HtmlPath
)

$sections = [ordered]@{}

# --- Action plan rollup (local) ---
Write-Host '=== CM Score Posture - Report ===' -ForegroundColor Cyan
if ($PlanCsv -and (Test-Path -LiteralPath $PlanCsv)) {
    $plan = @(Import-Csv -LiteralPath $PlanCsv)
    Write-Host ("Action plan: {0} action(s) from {1}" -f $plan.Count, $PlanCsv) -ForegroundColor Cyan
    $byImpl = $plan | Group-Object ImplementationStatus | Sort-Object Name
    $byTest = $plan | Group-Object TestStatus | Sort-Object Name
    $byImpl | ForEach-Object { Write-Host ("  Implementation - {0}: {1}" -f $_.Name, $_.Count) }
    $byTest | ForEach-Object { Write-Host ("  Test - {0}: {1}" -f $_.Name, $_.Count) }
    $noOwner    = @($plan | Where-Object { [string]::IsNullOrWhiteSpace($_.Owner) })
    $noEvidence = @($plan | Where-Object { [string]::IsNullOrWhiteSpace($_.EvidenceSource) })
    if ($noOwner.Count)    { Write-Host ("  [GAP] {0} action(s) missing an owner" -f $noOwner.Count) -ForegroundColor Yellow }
    if ($noEvidence.Count) { Write-Host ("  [GAP] {0} action(s) missing an evidence source" -f $noEvidence.Count) -ForegroundColor Yellow }
    $sections['Action plan'] = ($byImpl + $byTest | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Count }) -join '<br>'
} else {
    Write-Host 'No PlanCsv supplied (or not found) — reporting roles + licensing only. Build the plan with CMPMGR-Configuration.ps1 -Commit.' -ForegroundColor DarkYellow
}

# --- Role separation snapshot ---
Write-Host ''
Write-Host '=== CM Roles - Separation Evidence ===' -ForegroundColor Cyan
$roleLines = @()
if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
    try {
        Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        foreach ($g in 'Compliance Manager Administrators','Compliance Manager Assessors','Compliance Manager Contributors','Compliance Manager Readers') {
            if (-not (Get-RoleGroup -Identity $g -ErrorAction SilentlyContinue)) { Write-Host ("  [missing] {0}" -f $g) -ForegroundColor DarkYellow; continue }
            $m = @(Get-RoleGroupMember -Identity $g -ErrorAction SilentlyContinue)
            Write-Host ("  {0}: {1} member(s)" -f $g, $m.Count)
            $roleLines += ("{0}: {1} member(s)" -f $g, $m.Count)
        }
    } catch {
        Write-Host ("  Could not read role groups: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    }
} else {
    Write-Host '  ExchangeOnlineManagement not installed — skipping role snapshot.' -ForegroundColor DarkYellow
}
$sections['Role separation'] = ($roleLines -join '<br>')

# --- Licensing ---
Write-Host ''
Write-Host '=== Licensing ===' -ForegroundColor Cyan
$licLines = @()
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome -ErrorAction Stop
        foreach ($s in (Get-MgSubscribedSku -All -ErrorAction Stop)) {
            Write-Host ("  {0} (enabled: {1})" -f $s.SkuPartNumber, $s.PrepaidUnits.Enabled)
            $licLines += ("{0} (enabled: {1})" -f $s.SkuPartNumber, $s.PrepaidUnits.Enabled)
        }
    } catch { Write-Host ("  Could not read licensing: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow }
} else {
    Write-Host '  Microsoft.Graph not installed — skipping licensing.' -ForegroundColor DarkYellow
}
$sections['Licensing'] = ($licLines -join '<br>')

# --- Optional HTML ---
if ($HtmlPath) {
    $body = "<h1>CM Score Posture - Report</h1><p>Generated $(Get-Date -Format u). Authoritative score/export: Purview portal (Compliance Manager).</p>"
    foreach ($k in $sections.Keys) { $body += "<h2>$k</h2><p>$($sections[$k])</p>" }
    try {
        $body | Out-File -LiteralPath $HtmlPath -Encoding UTF8
        Write-Host ("`nHTML report written to {0}" -f $HtmlPath) -ForegroundColor Green
    } catch { Write-Warning "Could not write HTML: $($_.Exception.Message)" }
}

Write-Host ''
Write-Host 'Report complete (read-only). The authoritative Compliance Score and its export are in the Purview portal (Compliance Manager); this rollup is supplementary evidence.' -ForegroundColor Cyan
