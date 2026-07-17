<#
.SYNOPSIS
    O365GRAPH-Report.ps1 — program dashboard: total connector flows, migrated, remaining, and risk
    buckets, with a CSV export.
.DESCRIPTION
    PURPOSE
        Read-only program reporting for the migration program. Reads the migration register
        ("Migration-Register - Estate - Program.csv") and, optionally, a fresh validation pass, then
        summarizes program progress: total connector-based flows, how many are migrated (managed
        identity + Graph, no stored credential), how many remain, and the risk-band buckets. Prints a
        dashboard and writes a dated CSV. Makes NO changes.

        Run it at the pilot gate, after each wave, and as the recurring governance scan — a falling
        "remaining connector/credential flows" count is the evidence the program is working.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Report.ps1 `
            -Register '.\Migration-Register - Estate - Program.csv'
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Report.ps1 -Register '.\...csv' -OutputCsv '.\program-status.csv'
    SCOPES / ROLES
        Read access to the register CSV. (If -LiveValidate is added in your environment, the same
        Reader / Microsoft.Graph read roles that O365GRAPH-Validate.ps1 uses.)
    EXPECTED RESULTS
        A dashboard — Total / Migrated / Remaining, a High/Med/Low risk-band breakdown of what
        remains, and a per-wave rollup — plus a CSV snapshot for trend tracking across cycles.
.NOTES
    Azure Solutions — read-only. Summarizes register state; makes no changes.
    White-label sample values use contoso.com.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Register,
    [string]$OutputCsv = (".\program-status-{0}.csv" -f (Get-Date -Format 'yyyyMMdd'))
)

if (-not (Test-Path $Register)) { throw "Register not found: $Register (run O365GRAPH-Classify.ps1 first)." }
$flows = Import-Csv -Path $Register

# A flow counts as "migrated" when the register marks it done. Convention: MigratedStatus column,
# or SuggestedWave cleared + a 'Done' tag. Here we read an optional 'Migrated' column (Yes/No).
function Get-Migrated($row) {
    if ($row.PSObject.Properties.Name -contains 'Migrated') { return ($row.Migrated -match '^(y|yes|true|done)$') }
    return $false
}

$total     = ($flows | Measure-Object).Count
$migrated  = ($flows | Where-Object { Get-Migrated $_ } | Measure-Object).Count
$remaining = $total - $migrated
$remRows   = $flows | Where-Object { -not (Get-Migrated $_) }

Write-Host "`n=== O365 Connector Workflows -> Graph — program dashboard ===" -ForegroundColor Cyan
Write-Host ("Total connector flows : {0}" -f $total)
Write-Host ("Migrated (MI + Graph) : {0}" -f $migrated) -ForegroundColor Green
Write-Host ("Remaining             : {0}" -f $remaining) -ForegroundColor Yellow

Write-Host "`n-- Remaining by risk band --" -ForegroundColor Cyan
foreach ($band in 'High','Med','Low') {
    $n = ($remRows | Where-Object RiskBand -eq $band | Measure-Object).Count
    Write-Host ("  {0,-5} : {1}" -f $band, $n)
}

Write-Host "`n-- Remaining by platform --" -ForegroundColor Cyan
foreach ($p in ($remRows | Group-Object Platform)) {
    Write-Host ("  {0,-14} : {1}" -f $p.Name, $p.Count)
}

Write-Host "`n-- Per-wave rollup --" -ForegroundColor Cyan
foreach ($w in ($flows | Group-Object SuggestedWave | Sort-Object Name)) {
    $wm = ($w.Group | Where-Object { Get-Migrated $_ } | Measure-Object).Count
    Write-Host ("  {0,-40} {1}/{2} migrated" -f ($(if($w.Name){$w.Name}else{'(unassigned)'}), $wm, $w.Count))
}

# CSV snapshot for trend tracking
[pscustomobject]@{
    Date             = (Get-Date -Format 'yyyy-MM-dd')
    TotalFlows       = $total
    Migrated         = $migrated
    Remaining        = $remaining
    RemainingHigh    = ($remRows | Where-Object RiskBand -eq 'High' | Measure-Object).Count
    RemainingMed     = ($remRows | Where-Object RiskBand -eq 'Med'  | Measure-Object).Count
    RemainingLow     = ($remRows | Where-Object RiskBand -eq 'Low'  | Measure-Object).Count
} | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host ("`nSnapshot written to {0}" -f $OutputCsv) -ForegroundColor Green
if ($remaining -eq 0) { Write-Host "Estate is credential-free — governance scan should keep it that way." -ForegroundColor Green }
