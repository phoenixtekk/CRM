<#
.SYNOPSIS
    GEMCONN-Report.ps1 — connector/agent coverage-and-risk report with drift versus a saved baseline.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Gemini Connector Strategy & Agent Development Framework" solution.
        Produces a coverage-and-risk snapshot for a Google Cloud project: how many connectors (data
        stores) exist and their types, how many agents exist, which connectors carry no approval note,
        whether an access boundary is present, and a simple risk tally (unapproved connectors +
        boundary gaps). If -BaselinePath points to a JSON file from a previous run it reports the DRIFT
        (new connectors / new agents / risk-tally change); with -SaveBaseline it writes this run for
        next-cycle comparison. Reads live state via gcloud and the Discovery Engine REST API; makes no
        changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Report.ps1 -ProjectId 'your-project-id'
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Report.ps1 -ProjectId 'your-project-id' -BaselinePath .\gemconn-baseline.json -SaveBaseline
        Requires the Google Cloud SDK (gcloud) authenticated with viewer access to Discovery Engine and
        Access Context Manager. Run 'gcloud auth login' and 'gcloud config set project your-project-id'
        first.
    EXPECTED RESULTS
        A coverage-and-risk report — connector count by type, agent count, connectors lacking an
        approval record, boundary present yes/no, and a risk tally. With -BaselinePath, a drift line
        comparing this run to the saved baseline. Preview surfaces that cannot be read are shown as
        'verify in tenant', not zero.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
    Gemini Enterprise connector/agent surfaces are preview; counts reflect what the API returns in your
    tenant. Boundary read from documented gcloud commands. Never invents connector/agent specifics.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ProjectId,
    [string]$Location = 'global',
    [ValidateSet('v1','v1alpha','v1beta')] [string]$ApiVersion = 'v1',
    [string]$ApprovedConnectorsPath,
    [string]$BaselinePath,
    [switch]$SaveBaseline
)

function Get-GcloudToken {
    try { $t = (& gcloud auth print-access-token 2>$null); if (-not $t) { throw "empty" }; return $t.Trim() }
    catch { Write-Host "Could not obtain a gcloud access token. Run 'gcloud auth login' first." -ForegroundColor Red; throw }
}

$token   = Get-GcloudToken
$headers = @{ Authorization = "Bearer $token"; 'X-Goog-User-Project' = $ProjectId }
$base    = "https://discoveryengine.googleapis.com/$ApiVersion/projects/$ProjectId/locations/$Location/collections/default_collection"

Write-Host "`n=== Gemini Connector Strategy & Agent Development — coverage & risk report ===" -ForegroundColor Cyan
Write-Host ("Project: {0}   Location: {1}" -f $ProjectId, $Location)

# --- Connectors by type ---
$stores = @()
try {
    $resp = Invoke-RestMethod -Method Get -Uri "$base/dataStores" -Headers $headers -ErrorAction Stop
    if ($resp.dataStores) { $stores = $resp.dataStores }
} catch { Write-Host ("   Could not read connectors: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Connectors (data stores) --" -ForegroundColor Cyan
if ($stores.Count -gt 0) {
    $stores | Group-Object { if ($_.industryVertical) { $_.industryVertical } else { '(unspecified)' } } |
        Sort-Object Count -Descending | ForEach-Object { Write-Host ("   {0,-22} count: {1}" -f $_.Name, $_.Count) }
    Write-Host ("   TOTAL connectors: {0}" -f $stores.Count)
} else {
    Write-Host "   No connectors returned — verify in your tenant (preview API surface)." -ForegroundColor Yellow
}

# --- Agents ---
$agentCount = 0
try {
    $resp = Invoke-RestMethod -Method Get -Uri "$base/engines" -Headers $headers -ErrorAction Stop
    if ($resp.engines) { $agentCount = @($resp.engines).Count }
} catch { Write-Host ("   Could not read agents: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
Write-Host "`n-- Agents / assistants --" -ForegroundColor Cyan
Write-Host ("   TOTAL agents/engines: {0}" -f $agentCount)
if ($agentCount -eq 0) { Write-Host "   (Zero may mean 'preview surface' — verify in your tenant.)" -ForegroundColor Yellow }

# --- Unapproved connectors ---
$approved = @()
if ($ApprovedConnectorsPath -and (Test-Path $ApprovedConnectorsPath)) {
    $approved = Get-Content $ApprovedConnectorsPath | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() }
}
$storeIds   = $stores | ForEach-Object { ($_.name -split '/')[-1] }
$unapproved = if ($approved.Count -gt 0) { @($storeIds | Where-Object { $approved -notcontains $_ }) } else { @() }
Write-Host "`n-- Approval coverage --" -ForegroundColor Cyan
if ($approved.Count -eq 0) {
    Write-Host "   No approved allow-list supplied (-ApprovedConnectorsPath) — approval coverage unknown." -ForegroundColor Yellow
} else {
    Write-Host ("   Approved: {0}   Unapproved: {1}" -f ($storeIds.Count - $unapproved.Count), $unapproved.Count)
    $unapproved | ForEach-Object { Write-Host ("     - {0}  <-- no approval record" -f $_) -ForegroundColor Yellow }
}

# --- Access boundary present? ---
$boundary = $false
try {
    $perimeters = & gcloud access-context-manager perimeters list --format=json 2>$null | ConvertFrom-Json
    $boundary = ($perimeters -and $perimeters.Count -gt 0)
} catch { }
Write-Host "`n-- Data-access boundary --" -ForegroundColor Cyan
if ($boundary) { Write-Host "   VPC Service Controls perimeter present: YES" -ForegroundColor Green }
else { Write-Host "   VPC Service Controls perimeter present: NO / not readable — verify in tenant" -ForegroundColor Yellow }

# --- Risk tally ---
$riskTally = ($unapproved.Count) + $(if (-not $boundary) { 1 } else { 0 })
Write-Host "`n-- Risk tally --" -ForegroundColor Cyan
Write-Host ("   Unapproved connectors + boundary gap = {0}" -f $riskTally) -ForegroundColor ($(if ($riskTally -eq 0) { 'Green' } else { 'Yellow' }))

# --- Drift vs baseline ---
if ($BaselinePath -and (Test-Path $BaselinePath)) {
    try {
        $b = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host "`n-- Drift vs baseline --" -ForegroundColor Cyan
        Write-Host ("   Connectors: {0} -> {1}  (delta {2})" -f $b.ConnectorCount, $storeIds.Count, ($storeIds.Count - [int]$b.ConnectorCount))
        Write-Host ("   Agents:     {0} -> {1}  (delta {2})" -f $b.AgentCount, $agentCount, ($agentCount - [int]$b.AgentCount))
        Write-Host ("   Risk tally: {0} -> {1}  (delta {2})" -f $b.RiskTally, $riskTally, ($riskTally - [int]$b.RiskTally))
    } catch { Write-Host ("   Could not read baseline: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

# --- Save baseline ---
if ($BaselinePath -and $SaveBaseline) {
    [pscustomobject]@{
        Timestamp      = (Get-Date).ToString('s')
        ProjectId      = $ProjectId
        ConnectorCount = $storeIds.Count
        AgentCount     = $agentCount
        RiskTally      = $riskTally
    } | ConvertTo-Json | Set-Content -Path $BaselinePath
    Write-Host ("`nBaseline saved to {0}" -f $BaselinePath) -ForegroundColor Green
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
