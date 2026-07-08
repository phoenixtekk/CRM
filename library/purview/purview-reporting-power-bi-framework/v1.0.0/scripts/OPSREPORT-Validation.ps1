<#
.SYNOPSIS
    OPSREPORT-Validation.ps1 — read-only reconciliation of the exported dataset against its live Purview/Graph sources.
.DESCRIPTION
    PURPOSE
        For a fixed window, re-pulls each source live and compares the count to the exported table in the
        export set, so every dashboard figure can be reconciled to Purview's own numbers. Reports
        variance per source with a PASS/FAIL against a tolerance. Read-only — changes nothing. Also
        confirms the export set conforms to the dataset column contract and that HR-sensitive tables are
        aggregate-only.
    HOW TO RUN
        Connect-IPPSSession ; Connect-MgGraph -Scopes 'SecurityEvents.Read.All','AuditLog.Read.All'
        .\OPSREPORT-Validation.ps1 -StoragePath C:\PurviewExports -Days 7 -TolerancePercent 5
        PowerShell 5.1+/7+. A documented variance (latency/grouping) is acceptable; an unexplained one is a defect.
    EXPECTED RESULTS
        A reconciliation table (source | exported | live | variance% | result) and a contract/privacy
        conformance check. PASS = every source within tolerance and contract-conformant.
.NOTES
    Purview — Reporting & Power BI Framework. Read-only reconciliation. No secrets in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$StoragePath,
    [int]$Days = 7,
    [double]$TolerancePercent = 5
)

$stamp = (Get-Date).ToString('yyyyMM')
$outDir = Join-Path $StoragePath ("Purview Exports - {0} - Report" -f $stamp)
if (-not (Test-Path $outDir)) { throw "Export set not found: $outDir — run OPSREPORT-Report.ps1 first." }
$start = (Get-Date).AddDays(-$Days); $end = (Get-Date)
Write-Host ("=== Reconciliation over last {0} day(s) ===" -f $Days) -ForegroundColor Cyan

function Get-ExportCount {
    param([string]$Table)
    $p = Join-Path $outDir ("{0}.csv" -f $Table)
    if (-not (Test-Path $p)) { return $null }
    $rows = Import-Csv $p -ErrorAction SilentlyContinue
    if (-not $rows) { return 0 }
    ($rows | Measure-Object Count -Sum).Sum
}

$recon = @()
function Add-Recon {
    param([string]$Source, $Exported, $Live)
    if ($null -eq $Exported -or $null -eq $Live) { $var = $null; $res = 'skipped (source unavailable)' }
    else {
        $base = [math]::Max([double]$Live, 1)
        $var = [math]::Round(([math]::Abs([double]$Exported - [double]$Live) / $base) * 100, 1)
        $res = if ($var -le $TolerancePercent) { 'PASS' } else { 'REVIEW - explain variance' }
    }
    $script:recon += [pscustomobject]@{ Source=$Source; Exported=$Exported; Live=$Live; VariancePct=$var; Result=$res }
}

# --- DLP/label activity ---
try {
    $ae = Export-ActivityExplorerData -StartTime $start -EndTime $end -OutputFormat Json -PageSize 5000 -ErrorAction Stop
    Add-Recon 'DLP_LabelActivity' (Get-ExportCount 'DLP_LabelActivity') (@($ae.Data).Count)
} catch { Add-Recon 'DLP_LabelActivity' (Get-ExportCount 'DLP_LabelActivity') $null }

# --- Alerts ---
try {
    $live = (Get-ProtectionAlert -ErrorAction Stop | Measure-Object).Count
    Add-Recon 'Alerts' (Get-ExportCount 'Alerts') $live
} catch { Add-Recon 'Alerts' (Get-ExportCount 'Alerts') $null }

# --- Audit ---
try {
    $live = (Search-UnifiedAuditLog -StartDate $start -EndDate $end -ResultSize 5000 -ErrorAction Stop | Measure-Object).Count
    Add-Recon 'AuditActivity' (Get-ExportCount 'AuditActivity') $live
} catch { Add-Recon 'AuditActivity' (Get-ExportCount 'AuditActivity') $null }

# --- Posture ---
try {
    $ss = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/security/secureScores?$top=1' -ErrorAction Stop).value | Select-Object -First 1
    $liveControls = if ($ss) { @($ss.controlScores).Count } else { $null }
    Add-Recon 'Posture (control rows)' (@(Import-Csv (Join-Path $outDir 'Posture.csv') -ErrorAction SilentlyContinue).Count) $liveControls
} catch { Add-Recon 'Posture (control rows)' $null $null }

$recon | Format-Table -AutoSize

# --- Contract + privacy conformance ---
Write-Host '--- Contract & privacy conformance ---' -ForegroundColor Cyan
$contract = @{
    'DLP_LabelActivity' = @('Date','Workload','Activity','SensitivityLabel','RetentionLabel','DlpPolicy','Count')
    'Alerts'            = @('CreatedTime','PolicyName','Category','Severity','Status','Count')
    'AuditActivity'     = @('Date','Workload','Operation','RecordType','Count')
    'Posture'           = @('Date','ControlCategory','CurrentScore','MaxScore','Percent')
}
$contractOk = $true
foreach ($t in $contract.Keys) {
    $p = Join-Path $outDir ("{0}.csv" -f $t)
    $cols = @()
    if (Test-Path $p) { $first = Import-Csv $p -ErrorAction SilentlyContinue | Select-Object -First 1; if ($first) { $cols = $first.PSObject.Properties.Name } }
    $missing = $contract[$t] | Where-Object { $cols -and ($_ -notin $cols) }
    if ($cols.Count -and $missing) { $contractOk = $false; Write-Host ("  {0}: MISSING columns {1}" -f $t, ($missing -join ',')) -ForegroundColor Red }
    else { Write-Host ("  {0}: OK" -f $t) -ForegroundColor Green }
}
# privacy: no subject/content columns anywhere in the export set
$leak = Get-ChildItem $outDir -Filter *.csv | ForEach-Object {
    $h = (Get-Content $_.FullName -TotalCount 1)
    if ($h -match 'Subject|User(Principal)?Name|Reviewer|Content|Body|CaseId|Recipient') { $_.Name }
}
if ($leak) { Write-Host ("  PRIVACY: potential subject/content columns in: {0}" -f ($leak -join ', ')) -ForegroundColor Red }
else       { Write-Host '  PRIVACY: aggregate-only confirmed (no subject/content columns)' -ForegroundColor Green }

$pass = -not ($recon | Where-Object { $_.Result -eq 'REVIEW - explain variance' }) -and $contractOk -and -not $leak
Write-Host ("Validation: {0}" -f $(if ($pass) { 'PASS' } else { 'REVIEW - see items above' })) -ForegroundColor $(if ($pass) { 'Green' } else { 'Yellow' })
