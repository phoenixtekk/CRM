<#
.SYNOPSIS
    IPPBI-Report.ps1 — Produce the analytics-label coverage report (read-only; optional CSV export).
.DESCRIPTION
    PURPOSE
        Builds 'Analytics Labels - Coverage Report' — for each sensitivity label: its display name, the
        label policy that publishes it, and the policy's target coverage — plus a count of in-scope Power
        BI/Fabric workspaces (when the Power BI module is connected) — as the management evidence artifact.
        Read-only; writing a CSV is opt-in.
    HOW TO RUN
        .\IPPBI-Report.ps1
        .\IPPBI-Report.ps1 -CsvPath .\AnalyticsLabelsReport.csv
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession (and optionally
        Connect-PowerBIServiceAccount). No secret is stored in the script.
    EXPECTED RESULTS
        A table (and optional CSV) of each label, its publishing policy, and target coverage — re-runnable
        on a schedule. Makes no configuration change.
.NOTES
    Purview — Sensitivity Labeling for Power BI & Fabric. Read-only reporting. Verify your licensing/tenant:
    policy label-attachment and target property names vary by module version.
#>
[CmdletBinding()]
param(
    [string[]]$Labels = @('General','Confidential','Highly Confidential'),
    [string]$CsvPath
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== Power BI/Fabric labeling — coverage report (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-Label')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$labelObjs = @(Get-Label -ErrorAction SilentlyContinue)
$policies  = @(Get-LabelPolicy -ErrorAction SilentlyContinue)

$rows = foreach ($name in $Labels) {
    $exists = [bool]($labelObjs | Where-Object { $_.DisplayName -eq $name })
    $publishedBy = @(); $target = ''
    foreach ($p in $policies) {
        $attached = @()
        foreach ($prop in 'Labels','ScopedLabels') { if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { $attached += @($p.$prop) } }
        if (($attached -join ' ') -match [regex]::Escape($name)) {
            $publishedBy += $p.Name
            foreach ($tprop in 'ExchangeLocation','ModernGroupLocation') { if ($p.PSObject.Properties.Name -contains $tprop -and $p.$tprop) { $target = (@($p.$tprop) -join '; '); break } }
        }
    }
    [pscustomobject]@{
        Label          = $name
        Exists         = if ($exists) { 'Yes' } else { 'No' }
        PublishedBy    = if ($publishedBy) { ($publishedBy -join ', ') } else { '(not published)' }
        TargetCoverage = if ($target) { $target } else { '(none/unknown — verify in portal)' }
    }
}

$rows | Format-Table -AutoSize

if (Test-Command 'Get-PowerBIWorkspace') {
    try {
        $wsCount = @(Get-PowerBIWorkspace -Scope Organization -First 5000 -ErrorAction Stop).Count
        Write-Host ("In-scope Power BI/Fabric workspaces (organization): {0}" -f $wsCount) -ForegroundColor Green
    } catch { Write-Host "Workspace count unavailable (need Power BI admin)." -ForegroundColor DarkGray }
}

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Report written: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Green }
    catch { Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Red }
} else {
    Write-Host "INFO  Console-only. Pass -CsvPath to export 'Analytics Labels - Coverage Report'." -ForegroundColor DarkGray
}
