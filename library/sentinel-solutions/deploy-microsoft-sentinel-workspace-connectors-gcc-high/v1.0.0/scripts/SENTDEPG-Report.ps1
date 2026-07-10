<#
.SYNOPSIS
    SENTDEPG-Report.ps1 — report ingestion volume, projected cost, connector health and ingestion drift via KQL (read-only).
.DESCRIPTION
    PURPOSE
        Runs KQL against the workspace to produce the cost/health rollup used at Gate 6 and Gate 8:
        GB/day per table (from the Usage table), a projected monthly cost, Sentinel connector health
        (from SentinelHealth), and an INGESTION-DRIFT flag for any expected source table that has had
        zero rows in the last N hours. Exports the per-table volume to CSV. Read-only — it changes
        nothing.
    HOW TO RUN
        pwsh -File .\SENTDEPG-Report.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -PricePerGB 2.76 -DriftHours 24
        (PricePerGB is a placeholder for YOUR negotiated per-GB analytics rate — verify current Sentinel
         pricing for your region/cloud; the projection is indicative only.)

        Prereqs: Az modules (incl. Az.OperationalInsights) and Microsoft Sentinel Reader on the
        workspace. Sign in with an MFA-capable admin.
    EXPECTED RESULTS
        Tables of GB/day per DataType, a projected monthly cost line, a SentinelHealth status summary,
        and a drift list. A ingestion-volume CSV is written next to the script. PASS = no expected
        source is silently at zero and projected cost is within the G5 budget.
.NOTES
    White-label. Read-only. Az / KQL (Invoke-AzOperationalInsightsQuery). No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [double] $PricePerGB = 2.76,
    [int] $DriftHours = 24,
    [string[]] $ExpectedTables = @('AzureActivity','SigninLogs','AuditLogs','OfficeActivity','CommonSecurityLog','Syslog','SecurityIncident'),
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $wsId = $ws.CustomerId
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

function Invoke-Kql([string]$Query){
    (Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $Query -ErrorAction Stop).Results
}

# --- Volume per table -------------------------------------------------------------------------------
Write-Section 'Ingestion volume — GB/day per table (last 24h)'
$volume = @()
try {
    $q = @'
Usage
| where TimeGenerated > ago(24h)
| where IsBillable == true
| summarize GB = round(sum(Quantity) / 1024.0, 3) by DataType
| sort by GB desc
'@
    $volume = @(Invoke-Kql $q)
    if ($volume.Count -eq 0) { Write-Host 'No billable usage in the last 24h.' -ForegroundColor Yellow }
    else { $volume | Format-Table DataType, GB -AutoSize }
}
catch { Write-Warning ("Usage query failed: {0}" -f $_.Exception.Message) }

# --- Projected monthly cost -------------------------------------------------------------------------
Write-Section 'Projected monthly cost (indicative)'
try {
    $dayGB = ($volume | Measure-Object -Property GB -Sum).Sum
    if (-not $dayGB) { $dayGB = 0 }
    $monthly = [math]::Round($dayGB * 30 * $PricePerGB, 2)
    Write-Host ("Total billable: {0} GB/day  x 30  x `${1}/GB  =  ~`${2}/month (indicative)" -f $dayGB, $PricePerGB, $monthly)
    Write-Host 'Compare to the G5 budget. Verify current Sentinel/Log Analytics pricing for your region/cloud.'
}
catch { Write-Warning ("Cost projection failed: {0}" -f $_.Exception.Message) }

# --- Connector health -------------------------------------------------------------------------------
Write-Section 'Connector / ingestion health (SentinelHealth, last 24h)'
try {
    $q = @'
SentinelHealth
| where TimeGenerated > ago(24h)
| summarize Latest = arg_max(TimeGenerated, Status) by SentinelResourceName, SentinelResourceType
| project SentinelResourceName, SentinelResourceType, Status
'@
    $health = @(Invoke-Kql $q)
    if ($health.Count -eq 0) { Write-Host 'SentinelHealth returned nothing — enable Health monitoring (Gate 8).' -ForegroundColor Yellow }
    else { $health | Format-Table -AutoSize }
}
catch { Write-Warning ("SentinelHealth query failed (is Health monitoring enabled?): {0}" -f $_.Exception.Message) }

# --- Ingestion drift --------------------------------------------------------------------------------
Write-Section ("Ingestion drift — expected sources with zero rows in the last {0}h" -f $DriftHours)
foreach ($t in $ExpectedTables) {
    try {
        $q = "$t | where TimeGenerated > ago(${DriftHours}h) | count"
        $c = @(Invoke-Kql $q)
        $n = if ($c.Count -gt 0) { [int]$c[0].Count } else { 0 }
        if ($n -eq 0) { Write-Host ("  DRIFT: {0} has 0 rows in {1}h (or table absent) — investigate." -f $t, $DriftHours) -ForegroundColor Red }
        else { Write-Host ("  OK: {0} = {1} rows." -f $t, $n) -ForegroundColor Green }
    }
    catch { Write-Host ("  {0}: table not present / query failed (expected if not yet connected)." -f $t) -ForegroundColor Yellow }
}

# --- Export ----------------------------------------------------------------------------------------
if ($volume.Count -gt 0) {
    $out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ("SENTDEPG-ingestion-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
    $volume | Select-Object DataType, GB | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
    Write-Host ''
    Write-Host ("Volume exported to: {0}" -f $out) -ForegroundColor Green
}
