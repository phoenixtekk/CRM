<#
.SYNOPSIS
  Recurring-incident / problem-candidate analyzer (read-only). From an exported ticket CSV, clusters
  incidents to surface the repeat offenders that should become Problem records for root-cause.
.DESCRIPTION
  Reads a CSV export from any ITSM tool and groups incidents by category and by a normalized subject
  (lower-cased, numbers/IDs/GUIDs stripped) to reveal clusters that recur over threshold. Reads only the
  CSV - no Microsoft 365 connection, no changes. Output is the ranked list of problem candidates for the
  Problem Lifecycle - Messaging - Configure loop.
.EXAMPLE
  .\Find-RecurringMessagingIncidents.ps1 -TicketCsv .\tickets.csv
  # Lists categories and normalized subjects whose incident count >= the threshold (default 3).
.EXAMPLE
  .\Find-RecurringMessagingIncidents.ps1 -TicketCsv .\tickets.csv -Threshold 5 -ColumnMap @{ Subject='short_description' }
  # (PowerShell 5.1+/7+. No tenant access required.)
.NOTES
  Expected results: a ranked table of repeat clusters (category / normalized subject / count). PASS =
  the top cluster maps to a real recurring pain and becomes a Problem record (Testing T6).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TicketCsv,

    [int]$Threshold = 3,
    [hashtable]$ColumnMap = @{},
    [int]$Top = 20
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $TicketCsv)) { Write-Error "CSV not found: $TicketCsv"; return }

$col = @{ Category = 'Category'; Subject = 'Subject' }
foreach ($k in $ColumnMap.Keys) { $col[$k] = $ColumnMap[$k] }

$rows = Import-Csv -LiteralPath $TicketCsv
if (-not $rows) { Write-Warning "CSV has no data rows."; return }

$headers = ($rows[0].psobject.Properties.Name)
foreach ($needed in $col.Values) {
    if ($headers -notcontains $needed) {
        Write-Warning "Column '$needed' not found. Available: $($headers -join ', '). Use -ColumnMap to map it."
    }
}

function Get-NormalizedSubject([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) { return '(blank)' }
    $t = $s.ToLower()
    $t = $t -replace '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', '<guid>'  # GUIDs
    $t = $t -replace '\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b', '<email>'                      # emails
    $t = $t -replace '\d+', '<n>'                                                                # numbers/IDs
    $t = $t -replace '\s+', ' '
    return $t.Trim()
}

Write-Host "`n=== Repeat clusters by CATEGORY (>= $Threshold) ===" -ForegroundColor Cyan
$rows | Group-Object { $_.($col.Category) } |
    Where-Object { $_.Count -ge $Threshold } |
    Sort-Object Count -Descending |
    Select-Object @{n='Category'; e={ $_.Name }}, Count |
    Format-Table -AutoSize

Write-Host "=== Repeat clusters by NORMALIZED SUBJECT (>= $Threshold) — top $Top problem candidates ===" -ForegroundColor Cyan
$candidates = $rows |
    Group-Object { Get-NormalizedSubject $_.($col.Subject) } |
    Where-Object { $_.Count -ge $Threshold } |
    Sort-Object Count -Descending |
    Select-Object -First $Top |
    ForEach-Object {
        [pscustomobject]@{
            Count             = $_.Count
            NormalizedSubject = $_.Name
            SampleCategory    = ($_.Group | Select-Object -First 1).($col.Category)
        }
    }

if (-not $candidates) {
    Write-Host "No clusters at or above the threshold of $Threshold. Lower -Threshold to see more." -ForegroundColor Yellow
} else {
    $candidates | Format-Table -AutoSize
    Write-Host "Open a Problem record for the top candidate(s); drive root-cause and publish a Known-Error + workaround." -ForegroundColor DarkGray
}
