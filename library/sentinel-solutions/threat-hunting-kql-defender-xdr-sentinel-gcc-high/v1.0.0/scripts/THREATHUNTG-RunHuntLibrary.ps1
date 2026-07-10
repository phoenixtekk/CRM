<#
.SYNOPSIS
    THREATHUNTG-RunHuntLibrary.ps1 — run the whole KQL hunt library across Defender XDR and Sentinel and
    report per-hunt row counts (read-only).
.DESCRIPTION
    PURPOSE
        Executes every hunt in "Hunt Library - Tenant - Main" (THREATHUNTG-HuntLibrary.kql) on its target
        surface — Defender XDR advanced hunting via Microsoft Graph runHuntingQuery, or Microsoft Sentinel
        via the Log Analytics query API — and prints a per-hunt result count. This is the automation that
        runs the library in one pass so the team can triage hits. It RUNS QUERIES ONLY: it reads, counts,
        and reports; it NEVER takes a response action (no isolate/disable/purge). A zero-row hunt is a
        valid "not found this window" result, not a failure.
    HOW TO RUN
        Connect-MgGraph -Environment USGov -Scopes ThreatHunting.Read.All   # Defender XDR (GCC High)
        Connect-AzAccount -Environment AzureUSGovernment                     # Sentinel (Azure Government)

        pwsh -File .\THREATHUNTG-RunHuntLibrary.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" `
             -LibraryPath .\THREATHUNTG-HuntLibrary.kql

        Prereqs: Microsoft.Graph.Security + Az.Accounts/Az.OperationalInsights; Security Reader (Defender)
        and Microsoft Sentinel Reader (workspace). GOVERNMENT (GCC High) is the DEFAULT: Graph
        -Environment USGov (graph.microsoft.us), Az -Environment AzureUSGovernment (portal.azure.us). For
        DoD (IL5) pass -GraphEnvironment USGovDoD (dod-graph.microsoft.us). Verify national-cloud
        endpoints/scopes against current Microsoft Government documentation.
    EXPECTED RESULTS
        A per-hunt line: hunt name, target surface, and row count (or "0 (not found this window)"), plus a
        CSV summary next to the script. Advanced-hunting throttling (HTTP 429) is retried with back-off and
        treated as expected, not an error.
.NOTES
    White-label. Read-only. Microsoft.Graph (runHuntingQuery) + Az / KQL. No credentials in code.
    No response actions. Advanced-hunting schema/retention/limits: verify in your tenant.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string] $LibraryPath = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'THREATHUNTG-HuntLibrary.kql'),
    [int] $MaxRetries = 4,
    # Government (GCC High) is the default for this edition. DoD (IL5): -GraphEnvironment USGovDoD.
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureUSGovernment',
    [ValidateSet('Global','USGov','USGovDoD')] [string] $GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not (Test-Path $LibraryPath)) { Write-Error ("Hunt library not found: {0}" -f $LibraryPath); return }

# --- Parse the .kql library into hunts (name / surface / KQL body) -----------------------------------
# Header lines are comments (start with //); the KQL body is the uncommented lines under each header.
$hunts = New-Object System.Collections.Generic.List[object]
$current = $null
foreach ($raw in (Get-Content -LiteralPath $LibraryPath)) {
    $line = $raw
    if ($line -match '^\s*//\s*HUNT:\s*(\S+)') {
        if ($current -and $current.Kql.Trim()) { $hunts.Add($current) }
        $current = [pscustomobject]@{ Name = $Matches[1]; Surface = 'Sentinel'; Kql = '' }
        continue
    }
    if ($null -eq $current) { continue }
    if ($line -match '^\s*//\s*SURFACE:\s*(.+)$') {
        $current.Surface = if ($Matches[1] -match 'Defender|advanced hunting|XDR') { 'Defender' } else { 'Sentinel' }
        continue
    }
    if ($line -match '^\s*//') { continue }          # skip all comments (headers, Sentinel-variant, template)
    if ($line.Trim().Length -eq 0) { continue }
    $current.Kql += ($line + "`n")
}
if ($current -and $current.Kql.Trim()) { $hunts.Add($current) }
# Drop the template placeholder hunt if present.
$hunts = @($hunts | Where-Object { $_.Name -notmatch '<' -and $_.Kql.Trim() })
if ($hunts.Count -eq 0) { Write-Error 'No runnable hunts parsed from the library.'; return }
Write-Host ("Parsed {0} hunt(s) from {1}." -f $hunts.Count, (Split-Path -Leaf $LibraryPath)) -ForegroundColor Green

# --- Connections -------------------------------------------------------------------------------------
$graphReady = $false; $wsId = $null
try { if (-not (Get-MgContext)) { Connect-MgGraph -Environment $GraphEnvironment -Scopes 'ThreatHunting.Read.All' | Out-Null }; $graphReady = $true }
catch { Write-Warning ("Graph not connected — Defender-side hunts will be skipped: {0}" -f $_.Exception.Message) }
try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $wsId = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop).CustomerId
}
catch { Write-Warning ("Sentinel workspace not resolved — Sentinel-side hunts will be skipped: {0}" -f $_.Exception.Message) }

function Invoke-DefenderHunt([string]$Kql) {
    # Wrap to a count so we return a single number even for large hunts (avoids row-limit truncation).
    $wrapped = "$Kql`n| summarize HuntRows = count()"
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $resp = Invoke-MgSecurityRunHuntingQuery -Query $wrapped -ErrorAction Stop
            return [int]($resp.Results[0].HuntRows)
        }
        catch {
            $msg = $_.Exception.Message
            if ($msg -match '429|throttl|TooManyRequests') {
                $wait = [math]::Pow(2, $attempt)
                Write-Host ("    throttled (429) — backing off {0}s (attempt {1}/{2})." -f $wait, $attempt, $MaxRetries) -ForegroundColor Yellow
                Start-Sleep -Seconds $wait
                continue
            }
            throw
        }
    }
    throw 'Exceeded retry budget (throttling).'
}

function Invoke-SentinelHunt([string]$Kql) {
    $wrapped = "$Kql`n| summarize HuntRows = count()"
    $r = (Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $wrapped -ErrorAction Stop).Results
    $n = if ($r) { [int]$r[0].HuntRows } else { 0 }
    return $n
}

# --- Run each hunt on its surface --------------------------------------------------------------------
Write-Section 'Running the hunt library (read-only)'
$results = New-Object System.Collections.Generic.List[object]
foreach ($h in $hunts) {
    $count = $null; $status = 'OK'
    try {
        if ($h.Surface -eq 'Defender') {
            if (-not $graphReady) { $status = 'SKIPPED (Graph not connected)' }
            else { $count = Invoke-DefenderHunt $h.Kql }
        }
        else {
            if (-not $wsId) { $status = 'SKIPPED (workspace not resolved)' }
            else { $count = Invoke-SentinelHunt $h.Kql }
        }
    }
    catch { $status = ('ERROR: ' + $_.Exception.Message) }

    if ($status -eq 'OK') {
        $label = if ($count -gt 0) { ("{0} row(s)" -f $count) } else { '0 (not found this window)' }
        $color = if ($count -gt 0) { 'Yellow' } else { 'Green' }   # hits warrant triage; zero is clean-for-now
        Write-Host ("  [{0,-9}] {1,-40} {2}" -f $h.Surface, $h.Name, $label) -ForegroundColor $color
    }
    else {
        Write-Host ("  [{0,-9}] {1,-40} {2}" -f $h.Surface, $h.Name, $status) -ForegroundColor Red
    }
    $results.Add([pscustomobject]@{ Hunt = $h.Name; Surface = $h.Surface; Rows = $count; Status = $status })
}

# --- Export ------------------------------------------------------------------------------------------
$out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ("THREATHUNTG-run-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
$results | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Host ''
Write-Host ("Run summary exported to: {0}" -f $out) -ForegroundColor Green
Write-Host 'Triage any hunt with hits, document the outcome in Hunt Register - Tenant - Main, and bookmark findings.'
Write-Host 'Confirmed true positives: hand off to the M365 & Azure Incident Response & Escalation Runbook — do NOT respond from here.'
