<#
.SYNOPSIS
    OPSREPORT-Set-ScopeHealth.ps1 — record the reporting scope and run the pipeline health check (read-only).
.DESCRIPTION
    PURPOSE
        Two read-only helpers for the Purview reporting framework: (1) -ShowScope records/reads the
        reporting scope 'Reporting Scope - Purview - Config' (in-scope capabilities, workloads, date
        window) to a JSON file; (2) -HealthCheck inspects the export set and confirms it is fresh (within
        MaxAgeHours), populated (row counts sane), and that expected source tables are present — logging
        'Purview Pipeline Health - Report'. Never changes Purview or Graph.
    HOW TO RUN
        .\OPSREPORT-Set-ScopeHealth.ps1 -ShowScope -ScopeFile C:\PurviewExports\scope.json
        .\OPSREPORT-Set-ScopeHealth.ps1 -HealthCheck -StoragePath C:\PurviewExports -MaxAgeHours 26
        PowerShell 5.1+/7+. Read-only; safe to run any time.
    EXPECTED RESULTS
        -ShowScope: the recorded scope printed. -HealthCheck: a per-table freshness/row-count table and a
        green/red health verdict. PASS = fresh, populated, all expected tables present.
.NOTES
    Purview — Reporting & Power BI Framework. Read-only. No secrets in code.
#>
[CmdletBinding(DefaultParameterSetName='Health')]
param(
    [Parameter(ParameterSetName='Scope')][switch]$ShowScope,
    [Parameter(ParameterSetName='Scope')][string]$ScopeFile = './scope.json',
    [Parameter(ParameterSetName='Scope')][string[]]$Capabilities = @('DLP','SensitivityLabels','Retention','Audit','Posture','RiskAggregate'),
    [Parameter(ParameterSetName='Scope')][string[]]$Workloads = @('Exchange','SharePoint','OneDrive','Teams','Endpoint'),
    [Parameter(ParameterSetName='Scope')][int]$WindowDays = 30,

    [Parameter(ParameterSetName='Health')][switch]$HealthCheck,
    [Parameter(ParameterSetName='Health')][string]$StoragePath,
    [Parameter(ParameterSetName='Health')][int]$MaxAgeHours = 26
)

if ($ShowScope -or $PSCmdlet.ParameterSetName -eq 'Scope') {
    $scope = [pscustomobject]@{
        Name         = 'Reporting Scope - Purview - Config'
        Capabilities = $Capabilities
        Workloads    = $Workloads
        WindowDays   = $WindowDays
        RecordedUtc  = (Get-Date).ToUniversalTime().ToString('o')
    }
    $scope | ConvertTo-Json -Depth 5 | Out-File -FilePath $ScopeFile -Encoding UTF8
    Write-Host '=== Reporting Scope - Purview - Config ===' -ForegroundColor Cyan
    $scope | Format-List
    Write-Host ("Recorded to {0}" -f $ScopeFile) -ForegroundColor Green
    return
}

# --- Health check ---
if (-not $StoragePath) { throw 'HealthCheck requires -StoragePath.' }
$stamp = (Get-Date).ToString('yyyyMM')
$outDir = Join-Path $StoragePath ("Purview Exports - {0} - Report" -f $stamp)
if (-not (Test-Path $outDir)) { throw "Export set not found: $outDir — run OPSREPORT-Report.ps1 first." }
Write-Host '=== Purview Pipeline Health - Report ===' -ForegroundColor Cyan

$expected = @('DLP_LabelActivity','Alerts','AuditActivity','Posture')
$now = Get-Date
$rowsOut = foreach ($t in $expected) {
    $p = Join-Path $outDir ("{0}.csv" -f $t)
    if (-not (Test-Path $p)) {
        [pscustomobject]@{ Table=$t; Present=$false; AgeHours=$null; Rows=$null; Health='MISSING' }
        continue
    }
    $age = [math]::Round(($now - (Get-Item $p).LastWriteTime).TotalHours,1)
    $data = Import-Csv $p -ErrorAction SilentlyContinue
    $n = @($data).Count
    $health = if ($age -gt $MaxAgeHours) { 'STALE' } elseif ($n -eq 0) { 'EMPTY - verify source/licensing' } else { 'OK' }
    [pscustomobject]@{ Table=$t; Present=$true; AgeHours=$age; Rows=$n; Health=$health }
}
$rowsOut | Format-Table -AutoSize

$green = -not ($rowsOut | Where-Object { $_.Health -notin @('OK') })
Write-Host ("Pipeline health: {0}" -f $(if ($green) { 'GREEN (fresh, populated, complete)' } else { 'ATTENTION - see non-OK rows' })) -ForegroundColor $(if ($green) { 'Green' } else { 'Yellow' })
Write-Host 'Note: EMPTY may indicate a lapsed E5/E5-Compliance license for that source — verify tenant.' -ForegroundColor Yellow
