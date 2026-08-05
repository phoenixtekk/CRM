<#
.SYNOPSIS
    AGBINV-Filter-AgentBuilderOnly.ps1 — reduce any Copilot packages export to Agent Builder
    (declarative) agents only, excluding Copilot Studio and Microsoft/partner agents.
.DESCRIPTION
    PURPOSE
        A standalone filter. Given a CSV that contains a mixed packages/agents export (from Graph or
        the admin center Registry export), keeps only rows whose Platform is the Agent Builder platform
        and whose ElementTypes include a declarative agent — so the governance register never mixes in
        Copilot Studio agents (which are governed separately by your Copilot Studio approval gates).
        Read-only; operates on files, never calls Graph.
    HOW TO RUN
        pwsh -File .\AGBINV-Filter-AgentBuilderOnly.ps1 `
             -InputCsv  C:\AgentGovernance\Exports\all-agents-export.csv `
             -OutputPath C:\AgentGovernance\Exports
        Optional: -PlatformColumn / -ElementTypesColumn if your source uses different headers
        (the admin center export labels the column 'Platform').
    EXPECTED RESULTS
        AgentBuilder-Filtered_<yyyyMMdd-HHmm>.csv containing only Agent Builder declarative agents, plus
        a console summary of how many rows were kept vs excluded and which platforms were dropped.
.NOTES
    Copilot Solutions — the repeatable way. File-only; no Graph calls, no changes to Intune/Entra.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $InputCsv,
    [string] $OutputPath = '.',
    [string] $PlatformColumn = 'Platform',
    [string] $ElementTypesColumn = 'ElementTypes',
    [string] $AgentBuilderPlatform = 'Microsoft 365 Copilot Agent Builder'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }

$data = Import-Csv -Path $InputCsv
if (-not $data) { Write-Host "Input CSV is empty." -ForegroundColor Yellow; return }

if ($data[0].PSObject.Properties.Name -notcontains $PlatformColumn) {
    throw "Column '$PlatformColumn' not found. Columns present: $($data[0].PSObject.Properties.Name -join ', '). Pass -PlatformColumn to match your export."
}
$hasElementTypes = $data[0].PSObject.Properties.Name -contains $ElementTypesColumn

$kept = $data | Where-Object {
    $platformOk = ("$($_.$PlatformColumn)".Trim() -eq $AgentBuilderPlatform)
    $elementOk  = if ($hasElementTypes) { "$($_.$ElementTypesColumn)".ToLower() -match 'declarativeagent' } else { $true }
    $platformOk -and $elementOk
}

$excludedPlatforms = ($data | Where-Object { "$($_.$PlatformColumn)".Trim() -ne $AgentBuilderPlatform } |
    Select-Object -ExpandProperty $PlatformColumn -Unique)

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$csv = Join-Path $OutputPath "AgentBuilder-Filtered_$stamp.csv"
$kept | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

Write-Host ("Kept {0} Agent Builder agents; excluded {1} rows." -f @($kept).Count, ($data.Count - @($kept).Count)) -ForegroundColor Green
if ($excludedPlatforms) { Write-Host ("Excluded platforms: {0}" -f ($excludedPlatforms -join ', ')) -ForegroundColor DarkCyan }
Write-Host "Wrote $csv" -ForegroundColor Green
