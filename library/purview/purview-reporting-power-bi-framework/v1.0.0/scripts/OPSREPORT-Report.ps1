<#
.SYNOPSIS
    OPSREPORT-Report.ps1 — read-only export of all in-scope Purview reporting sources into the contract-shaped dataset.
.DESCRIPTION
    PURPOSE
        Pulls each licensed Purview reporting source for the requested window and writes one
        contract-conformant table per source into the export set 'Purview Data Export - AllSources -
        Report' (the dataset Power BI binds to). Sources: DLP/label activity (Export-ActivityExplorerData),
        alerts (Get-ProtectionAlert), audit activity (Search-UnifiedAuditLog), and posture (Graph
        security/secureScores). Read-only against Purview/Graph — the only writes are the local export
        files. Aggregate-only for HR-sensitive sources; never exports case content or subjects.
    HOW TO RUN
        Connect-IPPSSession ; Connect-MgGraph -Scopes 'SecurityEvents.Read.All','AuditLog.Read.All'
        .\OPSREPORT-Report.ps1 -StoragePath C:\PurviewExports -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date)
        PowerShell 5.1+/7+. A source that is not licensed is skipped with a note, never fabricated.
    EXPECTED RESULTS
        CSV files under <StoragePath>\Purview Exports - <yyyyMM> - Report: DLP_LabelActivity.csv,
        Alerts.csv, AuditActivity.csv, Posture.csv — columns matching 'Purview Compliance Dataset -
        Report'. A console summary of rows per table.
.NOTES
    Purview — Reporting & Power BI Framework. Read-only source pulls. No secrets in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$StoragePath,
    [datetime]$StartDate = (Get-Date).AddDays(-30),
    [datetime]$EndDate   = (Get-Date)
)

$stamp = (Get-Date).ToString('yyyyMM')
$outDir = Join-Path $StoragePath ("Purview Exports - {0} - Report" -f $stamp)
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
Write-Host ("=== Export set: {0} ===" -f $outDir) -ForegroundColor Cyan
Write-Host ("Window: {0:d} .. {1:d}" -f $StartDate, $EndDate) -ForegroundColor Cyan

$summary = @()
function Save-Table {
    param([string]$Name, [object[]]$Rows)
    $path = Join-Path $outDir ("{0}.csv" -f $Name)
    if ($Rows -and $Rows.Count) { $Rows | Export-Csv -Path $path -NoTypeInformation }
    else { '' | Out-File -FilePath $path } # empty, but present, so a missing source is visible not silent
    $summary += [pscustomobject]@{ Table = $Name; Rows = @($Rows).Count; File = $path }
    $script:summary = $summary
    Write-Host ("  {0,-18} {1,6} rows" -f $Name, @($Rows).Count) -ForegroundColor Green
}

# --- DLP_LabelActivity (Activity Explorer) ---
try {
    $ae = Export-ActivityExplorerData -StartTime $StartDate -EndTime $EndDate -OutputFormat Json -PageSize 5000 -ErrorAction Stop
    $rows = @()
    foreach ($rec in $ae.Data) {
        $o = $rec | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-not $o) { $o = $rec }
        $rows += [pscustomobject]@{
            Date            = $o.Happened
            Workload        = $o.Workload
            Activity        = $o.Activity
            SensitivityLabel= $o.SensitivityLabelId
            RetentionLabel  = $o.RetentionLabel
            DlpPolicy       = $o.PolicyMatchInfo
            Count           = 1
        }
    }
    # aggregate to the contract grain
    $agg = $rows | Group-Object Date, Workload, Activity, SensitivityLabel, RetentionLabel, DlpPolicy |
        ForEach-Object {
            $f = $_.Group[0]
            [pscustomobject]@{ Date=$f.Date; Workload=$f.Workload; Activity=$f.Activity; SensitivityLabel=$f.SensitivityLabel; RetentionLabel=$f.RetentionLabel; DlpPolicy=$f.DlpPolicy; Count=$_.Count }
        }
    Save-Table 'DLP_LabelActivity' $agg
} catch { Write-Warning ("DLP_LabelActivity skipped: {0}" -f $_.Exception.Message); Save-Table 'DLP_LabelActivity' @() }

# --- Alerts ---
try {
    $alerts = Get-ProtectionAlert -ErrorAction Stop
    $rows = $alerts | ForEach-Object {
        [pscustomobject]@{ CreatedTime=$_.LastModifiedTime; PolicyName=$_.Name; Category=$_.Category; Severity=$_.Severity; Status=$_.Disabled; Count=1 }
    }
    $agg = $rows | Group-Object PolicyName, Category, Severity, Status |
        ForEach-Object { $f=$_.Group[0]; [pscustomobject]@{ CreatedTime=$f.CreatedTime; PolicyName=$f.PolicyName; Category=$f.Category; Severity=$f.Severity; Status=$f.Status; Count=$_.Count } }
    Save-Table 'Alerts' $agg
} catch { Write-Warning ("Alerts skipped: {0}" -f $_.Exception.Message); Save-Table 'Alerts' @() }

# --- AuditActivity ---
try {
    $audit = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -ResultSize 5000 -ErrorAction Stop
    $rows = $audit | ForEach-Object {
        [pscustomobject]@{ Date=$_.CreationDate; Workload=$_.Workload; Operation=$_.Operations; RecordType=$_.RecordType; Count=1 }
    }
    $agg = $rows | Group-Object { ([datetime]$_.Date).ToString('yyyy-MM-dd') }, Workload, Operation, RecordType |
        ForEach-Object { $f=$_.Group[0]; [pscustomobject]@{ Date=([datetime]$f.Date).ToString('yyyy-MM-dd'); Workload=$f.Workload; Operation=$f.Operation; RecordType=$f.RecordType; Count=$_.Count } }
    Save-Table 'AuditActivity' $agg
} catch { Write-Warning ("AuditActivity skipped: {0}" -f $_.Exception.Message); Save-Table 'AuditActivity' @() }

# --- Posture (secure score via Graph) ---
try {
    $ss = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/security/secureScores?$top=1' -ErrorAction Stop).value | Select-Object -First 1
    $rows = @()
    if ($ss) {
        foreach ($c in $ss.controlScores) {
            $max = if ($c.maxScore) { [double]$c.maxScore } else { 0 }
            $rows += [pscustomobject]@{
                Date=$ss.createdDateTime; ControlCategory=$c.controlCategory; CurrentScore=$c.score; MaxScore=$max;
                Percent= if ($max -gt 0) { [math]::Round(([double]$c.score/$max)*100,1) } else { 0 }
            }
        }
    }
    Save-Table 'Posture' $rows
} catch { Write-Warning ("Posture skipped: {0}" -f $_.Exception.Message); Save-Table 'Posture' @() }

Write-Host '--- Export summary ---' -ForegroundColor Cyan
$script:summary | Format-Table -AutoSize
Write-Host 'NOTE: Insider-risk / communication-compliance are aggregate-only and are NOT exported here (no case content).' -ForegroundColor Yellow
Write-Host ("Export set written: {0}" -f $outDir) -ForegroundColor Green
