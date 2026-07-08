<#
.SYNOPSIS
    Records & file-plan compliance report — coverage + mapping completeness (READ-ONLY; makes no changes).

.DESCRIPTION
    Compiles record/regulatory label counts, file-plan mapping completeness (every record label ->
    authority/citation/category/department/reference ID), label-policy locations + enabled state, and
    disposition-reviewer pointers into CSV + HTML. Flags any UNMAPPED record label. Points reviewers to
    the portal Disposition queue rather than approving disposals.

.EXAMPLE
    .\Get-RecordsFilePlanReport.ps1 -OutputDir .\out
    Produces 'Records & File Plan - Tenant - Report' (CSV + HTML) in .\out.
    PowerShell 5.1+/7+. Connect first: Connect-IPPSSession (add -ConnectionUri for Gov clouds).

.NOTES
    Expected results (PASS): the report lists all record/regulatory labels, shows each MAPPED with an
    authority + citation, and label-policy coverage consistent with configuration. FAIL: any in-scope
    record label reports UNMAPPED, or the report disagrees with observed state.
#>
[CmdletBinding()]
param(
    [string]$OutputDir = ".",
    [string]$ReportName = "Records & File Plan - Tenant - Report"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Write-Host "== Records & File Plan report (read-only) ==" -ForegroundColor Cyan

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($t in (Get-ComplianceTag -ErrorAction Stop)) {
    $isRecord = [bool]$t.IsRecordLabel
    $isReg    = [bool]($t.PSObject.Properties.Match('IsRegulatory').Count -gt 0 -and $t.IsRegulatory)
    if (-not ($isRecord -or $isReg)) { continue }   # this report covers immutable records only
    $fpp = $t.FilePlanProperty
    $authority = if ($fpp) { $fpp.FilePlanPropertyAuthority } else { $null }
    $citation  = if ($fpp) { $fpp.FilePlanPropertyCitation }  else { $null }
    $category  = if ($fpp) { $fpp.FilePlanPropertyCategory }  else { $null }
    $dept      = if ($fpp) { $fpp.FilePlanPropertyDepartment } else { $null }
    $refId     = if ($fpp) { $fpp.FilePlanPropertyReferenceId } else { $null }
    $mapped    = ($authority -and $citation)
    $rows.Add([pscustomobject]@{
        Label        = $t.Name
        Rung         = if ($isReg) { 'REGULATORY (one-way)' } else { 'record (reversible)' }
        RetentionDays= $t.RetentionDuration
        Action       = $t.RetentionAction
        Reviewed     = [bool]$t.ReviewerEmail
        Authority    = $authority
        Citation     = $citation
        Category     = $category
        Department   = $dept
        ReferenceId  = $refId
        Mapping      = if ($mapped) { 'MAPPED' } else { 'UNMAPPED' }
    })
}

# Label-policy coverage
$policies = @()
foreach ($p in (Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
    $policies += [pscustomobject]@{
        Policy   = $p.Name
        Enabled  = $p.Enabled
        Exchange = $p.ExchangeLocation -join ';'
        SPO      = $p.SharePointLocation -join ';'
        OneDrive = $p.OneDriveLocation -join ';'
    }
}

$csvPath = Join-Path $OutputDir ("{0} - {1}.csv" -f $ReportName, $stamp)
$rows | Sort-Object Mapping, Label | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$unmapped = @($rows | Where-Object Mapping -eq 'UNMAPPED')
$regCount = @($rows | Where-Object Rung -like 'REGULATORY*').Count

# HTML summary
$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:6px 8px;font-size:13px;text-align:left}th{background:#f3f3f3}.bad{color:#b00020;font-weight:600}.ok{color:#0a7d33;font-weight:600}</style>"
$head = "<h1>Records &amp; File Plan — Tenant — Report</h1><p>Generated $(Get-Date -Format u). Read-only. Disposition is actioned in the Purview portal (Records management &rarr; Disposition), not by this report.</p>"
$summary = "<h2>Summary</h2><ul>" +
    "<li>Immutable record labels: <b>$($rows.Count)</b> (regulatory/one-way: <b>$regCount</b>)</li>" +
    "<li>File-plan mapping: <span class='$([string]::Format('{0}',(if($unmapped.Count -eq 0){'ok'}else{'bad'})))'>$(($rows.Count-$unmapped.Count))/$($rows.Count) MAPPED</span>" +
    $(if ($unmapped.Count -gt 0) { " — <span class='bad'>$($unmapped.Count) UNMAPPED (locked without a documented authority/citation)</span>" } else { "" }) + "</li></ul>"
$labelTable = $rows | Sort-Object Mapping, Label | ConvertTo-Html -Fragment
$polTable   = $policies | ConvertTo-Html -Fragment
$html = "<html><head>$style</head><body>$head$summary<h2>Immutable record labels &amp; file-plan mapping</h2>$labelTable<h2>Label-policy coverage</h2>$polTable</body></html>"
$htmlPath = Join-Path $OutputDir ("{0} - {1}.html" -f $ReportName, $stamp)
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host ("Immutable record labels: {0} (regulatory: {1}); UNMAPPED: {2}" -f $rows.Count, $regCount, $unmapped.Count) -ForegroundColor Cyan
if ($unmapped.Count -gt 0) {
    Write-Host "UNMAPPED record labels (fix before expanding):" -ForegroundColor Red
    $unmapped | ForEach-Object { Write-Host ("  - {0}" -f $_.Label) -ForegroundColor Red }
}
Write-Host ("Wrote: {0}" -f $csvPath)
Write-Host ("Wrote: {0}" -f $htmlPath)
Write-Host "Report complete (read-only)." -ForegroundColor Green
