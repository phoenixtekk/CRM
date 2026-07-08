<#
.SYNOPSIS
    IPMEET-Report.ps1 — Produce the meeting-label coverage report (read-only; optional CSV export).
.DESCRIPTION
    PURPOSE
        Builds 'Meeting Labels - Coverage Report' — for each meeting sensitivity label: its display name,
        scope (whether Meetings is in ContentType), the label policy that publishes it, and the policy's
        target coverage — as the management evidence artifact. Read-only; writing a CSV is opt-in.
    HOW TO RUN
        .\IPMEET-Report.ps1                                   # console table only (no file written)
        .\IPMEET-Report.ps1 -CsvPath .\MeetingLabelsReport.csv  # also export to CSV
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A table (and optional CSV) listing each meeting label, its Meetings scope, publishing policy, and
        target coverage — re-runnable on a schedule to keep coverage healthy. Makes no configuration change.
.NOTES
    Purview — Sensitivity Labeling for Meetings. Read-only reporting. Verify your licensing/tenant: policy
    label-attachment and target property names vary by ExchangeOnlineManagement/S&C module version.
#>
[CmdletBinding()]
param(
    [string]$MeetingScopeMatch = 'Meeting',
    [string]$CsvPath
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== Sensitivity Labeling for Meetings — coverage report (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-Label')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$labels   = @(Get-Label -ErrorAction SilentlyContinue)
$policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)

# Only meeting-relevant labels: Meetings scope in ContentType, or a Meeting- naming convention.
$meetingLabels = $labels | Where-Object {
    ($_.ContentType -match $MeetingScopeMatch) -or ($_.DisplayName -match $MeetingScopeMatch)
}
if (-not $meetingLabels) {
    Write-Host "INFO  No Meetings-scoped labels found. Author them first (Implementation Step 3)." -ForegroundColor DarkGray
    $meetingLabels = @()
}

$rows = foreach ($l in $meetingLabels) {
    # Which policy (if any) publishes this label — property shape varies by module version.
    $publishedBy = @()
    $target      = ''
    foreach ($p in $policies) {
        $attached = @()
        foreach ($prop in 'Labels','ScopedLabels') {
            if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { $attached += @($p.$prop) }
        }
        $blob = ($attached -join ' ')
        if ($blob -match [regex]::Escape($l.DisplayName) -or $blob -match [regex]::Escape(($l.DisplayName -replace ' ',''))) {
            $publishedBy += $p.Name
            foreach ($tprop in 'ExchangeLocation','ModernGroupLocation','Settings') {
                if ($p.PSObject.Properties.Name -contains $tprop -and $p.$tprop) { $target = (@($p.$tprop) -join '; '); break }
            }
        }
    }
    [pscustomobject]@{
        Label        = $l.DisplayName
        MeetingScope = if ($l.ContentType -match $MeetingScopeMatch) { 'Yes' } else { 'Check (naming only)' }
        ContentType  = $l.ContentType
        PublishedBy  = if ($publishedBy) { ($publishedBy -join ', ') } else { '(not published)' }
        TargetCoverage = if ($target) { $target } else { '(none/unknown — verify in portal)' }
    }
}

if ($rows) {
    $rows | Format-Table -AutoSize
    if ($CsvPath) {
        try {
            $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
            Write-Host ("Report written: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Green
        } catch {
            Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    } else {
        Write-Host "INFO  Console-only. Pass -CsvPath to export 'Meeting Labels - Coverage Report'." -ForegroundColor DarkGray
    }
} else {
    Write-Host "No meeting labels to report yet." -ForegroundColor Yellow
}
