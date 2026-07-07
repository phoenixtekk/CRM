<#
.SYNOPSIS
  Validate findability by running representative test queries and checking each returns its expected
  top result plus the required managed properties. Read-only.
.DESCRIPTION
  For each row in a test-query CSV (Query,ExpectedTopUrl,CheckProperties) submits the query with
  Submit-PnPSearchQuery, requests the managed properties, and records pass/fail: expected URL on the
  first page, and each CheckProperties value returned. Writes a JSON validation report. Read-only.
.EXAMPLE
  .\Test-Findability.ps1 -SiteUrl https://contoso.sharepoint.com/sites/policies `
      -QueryCsv .\test-queries.csv -OutputPath .\Findability-Validation-Pilot-Validation.json
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline.)
  CSV header: Query,ExpectedTopUrl,CheckProperties
  Row example: DocType:Policy,https://contoso.sharepoint.com/sites/policies/leave.aspx,Department;DocType
.NOTES
  Expected results: a JSON report with one record per query and an overall pass count. Pass signal =
  every priority query returns its ExpectedTopUrl on the first page and the CheckProperties are
  non-empty (Retrievable) - this is Gate 5 / Gate 6.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SiteUrl,
    [Parameter(Mandatory)] [string] $QueryCsv,
    [string] $OutputPath = ".\Findability-Validation-Pilot-Validation.json",
    [int] $RowLimit = 10
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $QueryCsv)) { throw "Query CSV not found: $QueryCsv" }
$queries = Import-Csv -Path $QueryCsv

Write-Host "Connecting to $SiteUrl ..." -ForegroundColor Cyan
Connect-PnPOnline -Url $SiteUrl -Interactive

$results = @()
$pass = 0
foreach ($q in $queries) {
    $props = @()
    if ($q.CheckProperties) { $props = $q.CheckProperties -split ';' | Where-Object { $_ } }
    $select = (@('Title','Path') + $props | Select-Object -Unique) -join ','

    $rec = [ordered]@{
        Query          = $q.Query
        ExpectedTopUrl = $q.ExpectedTopUrl
        TopUrl         = $null
        ExpectedFound  = $false
        PropsReturned  = [ordered]@{}
        Status         = 'FAIL'
        Error          = $null
    }
    try {
        $r = Submit-PnPSearchQuery -Query $q.Query -SelectProperties $select -MaxResults $RowLimit
        $rowset = @($r.ResultRows)
        if ($rowset.Count -gt 0) {
            $rec.TopUrl = $rowset[0]['Path']
            $urls = $rowset | ForEach-Object { $_['Path'] }
            if ($q.ExpectedTopUrl) {
                $rec.ExpectedFound = [bool]($urls -contains $q.ExpectedTopUrl)
            } else {
                $rec.ExpectedFound = $true  # exploratory query: any result counts
            }
            foreach ($p in $props) {
                $val = $rowset[0][$p]
                $rec.PropsReturned[$p] = if ([string]::IsNullOrWhiteSpace([string]$val)) { $null } else { $val }
            }
        }
        $propsOk = $true
        foreach ($p in $props) { if (-not $rec.PropsReturned[$p]) { $propsOk = $false } }
        if ($rec.ExpectedFound -and $propsOk) { $rec.Status = 'PASS'; $pass++ }
    } catch {
        $rec.Error = $_.Exception.Message
    }
    $color = if ($rec.Status -eq 'PASS') { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}" -f $rec.Status, $q.Query) -ForegroundColor $color
    $results += $rec
}

$out = [ordered]@{
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString('o')
    SiteUrl      = $SiteUrl
    Total        = $results.Count
    Passed       = $pass
    Failed       = ($results.Count - $pass)
    Results      = $results
}
$out | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host ("`nValidation: {0}/{1} passed. Report: {2}" -f $pass, $results.Count, $OutputPath) `
    -ForegroundColor Cyan

Disconnect-PnPOnline
