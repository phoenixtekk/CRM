<#
.SYNOPSIS
  Compile a SharePoint records/retention compliance report (read-only).
.DESCRIPTION
  Across the in-scope sites, computes retention-label coverage per library (labeled vs total),
  summarizes the tenant's record labels, and (best-effort) reports pending disposition counts from the
  disposition solution. Writes a CSV and an HTML summary. Makes no changes.
.EXAMPLE
  .\Get-SpoRecordsComplianceReport.ps1 -Sites @("https://contoso.sharepoint.com/sites/RecordsPilot") -OutputPath .\out
  # (PowerShell 5.1+/7+; PnP.PowerShell + ExchangeOnlineManagement; Connect-PnPOnline + Connect-IPPSSession)
.NOTES
  Expected results: "Records Compliance - SPO - Report" as CSV + HTML showing coverage %, record-label
  inventory, and pending-disposition counts for the reporting period. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Sites,

    [string]$OutputPath = ".\out"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# --- 1. Per-library coverage (PnP) ---
$coverage = New-Object System.Collections.Generic.List[object]
foreach ($site in $Sites) {
    try { Connect-PnPOnline -Url $site -Interactive }
    catch { Write-Warning "Skip $site : $_"; continue }

    $libs = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and -not $_.Hidden }
    foreach ($lib in $libs) {
        $default = $null
        try { $default = (Get-PnPLabel -List $lib.Title -ErrorAction Stop).TagName } catch {}
        $coverage.Add([pscustomobject]@{
            Site           = $site
            Library        = $lib.Title
            Items          = $lib.ItemCount
            DefaultLabel   = if ([string]::IsNullOrWhiteSpace($default)) { "(none)" } else { $default }
            LibraryCovered = -not [string]::IsNullOrWhiteSpace($default)
        })
    }
}

$totalLibs   = $coverage.Count
$coveredLibs = ($coverage | Where-Object LibraryCovered).Count
$coveragePct = if ($totalLibs -gt 0) { [math]::Round(($coveredLibs / $totalLibs) * 100, 1) } else { 0 }

# --- 2. Record-label inventory (Security & Compliance) ---
$records = @()
try {
    $records = Get-ComplianceTag | Where-Object IsRecordLabel |
        Select-Object Name, Regulatory, RetentionAction, RetentionDuration,
            @{n='Reviewers';e={($_.ReviewerEmail) -join ';'}}
}
catch { Write-Warning "Could not read record labels (Connect-IPPSSession?): $_" }

# --- 3. Pending disposition (best-effort; solution/cmdlet availability is plan-dependent) ---
$pendingDisposition = "n/a (verify in your tenant)"
try {
    $disp = Get-Command Get-DispositionItem -ErrorAction SilentlyContinue
    if ($disp) { $pendingDisposition = (Get-DispositionItem -ErrorAction Stop | Measure-Object).Count }
}
catch { Write-Warning "Disposition count unavailable: $_" }

# --- Output ---
$csv = Join-Path $OutputPath "Records-Compliance-SPO-Report.csv"
$coverage | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

$html = Join-Path $OutputPath "Records-Compliance-SPO-Report.html"
$body = @"
<h1>Records Compliance - SPO - Report</h1>
<p>Generated: $(Get-Date -Format s)</p>
<ul>
 <li>Libraries in scope: $totalLibs</li>
 <li>Libraries with a default label: $coveredLibs</li>
 <li>Library label coverage: $coveragePct%</li>
 <li>Record labels defined: $($records.Count)</li>
 <li>Pending disposition items: $pendingDisposition</li>
</ul>
"@
$coverageHtml = $coverage | ConvertTo-Html -Fragment -Property Site,Library,Items,DefaultLabel,LibraryCovered
$recordsHtml  = if ($records) { $records | ConvertTo-Html -Fragment } else { "<p>(no record labels)</p>" }
ConvertTo-Html -Head "<style>body{font-family:Segoe UI,Arial}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:4px}</style>" `
    -Body ($body + "<h2>Coverage</h2>" + $coverageHtml + "<h2>Record labels</h2>" + $recordsHtml) |
    Out-File -FilePath $html -Encoding UTF8

Write-Host "Library label coverage: $coveragePct% ($coveredLibs/$totalLibs). Record labels: $($records.Count). Pending disposition: $pendingDisposition" -ForegroundColor Green
Write-Host "Wrote: $csv" -ForegroundColor Green
Write-Host "Wrote: $html" -ForegroundColor Green
