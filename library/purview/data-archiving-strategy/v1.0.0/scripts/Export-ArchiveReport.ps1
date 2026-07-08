<#
.SYNOPSIS
    Reports archive adoption, archive growth, and primary-store reduction (READ-ONLY).
.DESCRIPTION
    Builds an adoption/tiering report across the target mailboxes: archive enablement rate, primary
    vs. archive sizes, and (when given an earlier discovery baseline CSV) the change in primary and
    archive size per mailbox. Outputs CSV and a simple HTML summary. Makes no changes.
.EXAMPLE
    .\Export-ArchiveReport.ps1 -PilotGroup grp-archive-pilot -OutputPath .\reports
    .\Export-ArchiveReport.ps1 -OutputPath .\reports -BaselineCsv .\discovery\mailbox-archive-status-20260707-090000.csv
    Runs on PowerShell 5.1+/7+. Connect first with Connect-ExchangeOnline.
    Expected results: a CSV and an HTML report showing adoption and, if a baseline is supplied, the
    reduction in primary-store size since the baseline.
.NOTES
    Expected results: evidence of adoption and primary-store reduction over time. Read-only; no
    credentials or secrets are used.
#>
[CmdletBinding()]
param(
    [string]$PilotGroup,
    [string]$BaselineCsv,
    [string]$OutputPath = '.\archive-reports'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function ConvertTo-Bytes {
    param($SizeString)   # e.g. "1.23 GB (1,320,702,443 bytes)"
    if (-not $SizeString) { return $null }
    if ("$SizeString" -match '\(([\d,]+) bytes\)') { return [int64](($matches[1] -replace ',','')) }
    return $null
}

# Target set
if ($PilotGroup) {
    $targets = Get-DistributionGroupMember -Identity $PilotGroup |
        Where-Object { $_.RecipientType -like '*Mailbox*' } | ForEach-Object { $_.PrimarySmtpAddress }
} else {
    $targets = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox |
        ForEach-Object { $_.PrimarySmtpAddress }
}

# Optional baseline lookup
$baseline = @{}
if ($BaselineCsv -and (Test-Path $BaselineCsv)) {
    Import-Csv $BaselineCsv | ForEach-Object { $baseline[$_.PrimarySmtpAddress] = $_ }
}

$rows = foreach ($t in $targets) {
    $m  = Get-Mailbox -Identity $t
    $ps = Get-MailboxStatistics -Identity $t -ErrorAction SilentlyContinue
    $as = if ($m.ArchiveStatus -eq 'Active') { Get-MailboxStatistics -Identity $t -Archive -ErrorAction SilentlyContinue } else { $null }
    $primaryNow = if ($ps) { $ps.TotalItemSize.ToString() } else { '' }
    $delta = ''
    if ($baseline.ContainsKey("$t") -and $baseline["$t"].PrimarySize) {
        $b = ConvertTo-Bytes $baseline["$t"].PrimarySize
        $n = ConvertTo-Bytes $primaryNow
        if ($b -and $n) { $delta = "{0:N0}" -f ($n - $b) }
    }
    [pscustomobject]@{
        PrimarySmtpAddress = $t
        ArchiveEnabled     = ($m.ArchiveStatus -eq 'Active')
        RetentionPolicy    = $m.RetentionPolicy
        PrimarySize        = $primaryNow
        PrimaryItems       = if ($ps) { $ps.ItemCount } else { '' }
        ArchiveSize        = if ($as) { $as.TotalItemSize.ToString() } else { '' }
        ArchiveItems       = if ($as) { $as.ItemCount } else { '' }
        PrimaryDeltaBytes  = $delta
    }
}

$enabled = ($rows | Where-Object ArchiveEnabled).Count
$total   = $rows.Count
$rate    = if ($total) { [math]::Round(100 * $enabled / $total, 1) } else { 0 }

$csv = Join-Path $OutputPath "archive-report-$stamp.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

$html = Join-Path $OutputPath "archive-report-$stamp.html"
$style = "<style>body{font-family:Segoe UI,Arial,sans-serif}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:4px 8px}th{background:#f2f2f2}</style>"
$summary = "<h2>Archive adoption report</h2><p>Generated $stamp. Archive-enabled: <b>$enabled / $total ($rate%)</b>.</p>"
$rows | ConvertTo-Html -Head $style -PreContent $summary | Out-File -FilePath $html -Encoding UTF8

Write-Host "Adoption: $enabled / $total ($rate%)" -ForegroundColor Cyan
Write-Host "  -> $csv"  -ForegroundColor Green
Write-Host "  -> $html" -ForegroundColor Green
