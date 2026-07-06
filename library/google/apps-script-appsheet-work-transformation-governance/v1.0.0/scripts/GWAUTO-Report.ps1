<#
.SYNOPSIS
    GWAUTO-Report.ps1 — report Apps Script/AppSheet automation coverage and governance risk.
.DESCRIPTION
    PURPOSE
        Turns the automation inventory (from GWAUTO-Discovery.ps1) into a coverage-and-risk report:
        how many automations are governed vs ungoverned, a per-artifact risk score (broad scope +
        external sharing + confidential data + no owner), and the top items to remediate first.
        Read-only — it reads the inventory export you supply and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWAUTO-Report.ps1 -InventoryCsv C:\Temp\automation-inventory.csv -CsvPath C:\Temp\automation-risk.csv
        InventoryCsv columns: Platform,ArtifactId,Name,Owner,Scopes,DataSources,Sharing,Environment,Tier
        Optionally add a Sensitivity column (Public/Internal/Confidential/Regulated) to sharpen scoring;
        absent, sensitivity contributes 0. Read-only Workspace/AppSheet admin visibility produces it.
    EXPECTED RESULTS
        Coverage counts (governed vs ungoverned, by environment and tier), a ranked risk table, and the
        highest-risk artifacts to address first. Optional CSV export of the scored inventory. No system
        is changed. Pass = coverage and risk are understood and the top risks have named owners/actions.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [string]$CsvPath
)

if (-not (Test-Path $InventoryCsv)) {
    Write-Host "Inventory CSV not found: $InventoryCsv" -ForegroundColor Red
    Write-Host "Columns: Platform,ArtifactId,Name,Owner,Scopes,DataSources,Sharing,Environment,Tier[,Sensitivity]" -ForegroundColor DarkYellow
    exit 2
}
$rows = Import-Csv $InventoryCsv
if (-not $rows) { Write-Host "No automation artifacts found." -ForegroundColor DarkYellow; exit 0 }

$BroadScopePatterns = 'auth/gmail\b','auth/drive\b','auth/spreadsheets\b','mail.google.com','auth/admin'
function Test-BroadScope([string]$s) { foreach ($p in $BroadScopePatterns) { if ($s -match $p) { return $true } }; return $false }
function Get-SensitivityScore([string]$v) {
    switch ($v) { 'Regulated' { 3 } 'Confidential' { 2 } 'Internal' { 1 } default { 0 } }
}

Write-Host "`n=== Automation coverage & risk report ===" -ForegroundColor Cyan
$scored = foreach ($a in $rows) {
    $risk = 0
    if (Test-BroadScope $a.Scopes)                      { $risk += 2 }
    if ($a.Sharing -in 'External','Anyone')             { $risk += 2 }
    if ([string]::IsNullOrWhiteSpace($a.Owner))         { $risk += 1 }
    $risk += Get-SensitivityScore $a.Sensitivity
    $band = if ($risk -ge 5) { 'High' } elseif ($risk -ge 3) { 'Medium' } elseif ($risk -ge 1) { 'Low' } else { 'Minimal' }
    [pscustomobject]@{
        Platform = $a.Platform; Name = $a.Name; Owner = $a.Owner
        Sharing = $a.Sharing; Environment = $a.Environment; Tier = $a.Tier
        RiskScore = $risk; RiskBand = $band
    }
}

$governed   = $scored | Where-Object { $_.Owner -and $_.Tier }
$ungoverned = $scored | Where-Object { -not $_.Owner -or -not $_.Tier }
Write-Host ("Total automations : {0}" -f $scored.Count)
Write-Host ("  Governed (owner + tier) : {0}" -f $governed.Count)   -ForegroundColor Green
Write-Host ("  Ungoverned              : {0}" -f $ungoverned.Count) -ForegroundColor Yellow

Write-Host "`n--- By environment ---" -ForegroundColor Cyan
$scored | Group-Object Environment | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-12} {1}" -f $_.Name, $_.Count) }
Write-Host "`n--- By risk band ---" -ForegroundColor Cyan
foreach ($b in 'High','Medium','Low','Minimal') {
    $c = ($scored | Where-Object { $_.RiskBand -eq $b } | Measure-Object).Count
    $col = switch ($b) { 'High' { 'Red' } 'Medium' { 'Yellow' } default { 'Gray' } }
    Write-Host ("  {0,-8} {1}" -f $b, $c) -ForegroundColor $col
}

Write-Host "`n--- Top risks to remediate first ---" -ForegroundColor Cyan
$scored | Sort-Object RiskScore -Descending | Select-Object -First 10 |
    Format-Table Platform, Name, Owner, Sharing, RiskScore, RiskBand -AutoSize

if ($CsvPath) { $scored | Sort-Object RiskScore -Descending | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Write-Host "Drive remediation from the top of this list; assign each high risk an owner and an action." -ForegroundColor DarkYellow
