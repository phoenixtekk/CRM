<#
.SYNOPSIS
    WS1POL-Discovery.ps1 — normalize a Workspace ONE policy/compliance export into a per-platform inventory.
.DESCRIPTION
    PURPOSE
        Reads a Workspace ONE UEM export (configuration profiles + compliance policies) and produces a
        normalized, per-platform inventory list that the mapping and parity-validation steps measure
        against. The Workspace ONE export itself is vendor-owned and version-specific: the console
        paths, UEM REST API, and payload format are documented by VMware/Omnissa, not here. This
        script consumes an export you have already produced (JSON or CSV) and normalizes it.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1POL-Discovery.ps1 -ExportPath C:\Temp\ws1-export.json -CsvPath C:\Temp\ws1-inventory.csv
        -ExportPath : a Workspace ONE export file (JSON array or CSV). DEFERRED: produce it per the
                      current VMware/Omnissa Workspace ONE UEM documentation.
    EXPECTED RESULTS
        A per-platform count of profiles and compliance policies, and (optional) a normalized CSV with
        one row per source setting: Platform, Type (Profile/Compliance), Name, Setting.
.NOTES
    Workspace ONE to Intune migration — read-only. Source export deferred to VMware/Omnissa docs.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$ExportPath,
    [string]$CsvPath
)

if (-not (Test-Path $ExportPath)) {
    Write-Host "Export not found: $ExportPath" -ForegroundColor Yellow
    Write-Host "DEFERRED: produce the Workspace ONE UEM profile + compliance export per the current" -ForegroundColor Yellow
    Write-Host "VMware/Omnissa Workspace ONE UEM documentation, then re-run with -ExportPath." -ForegroundColor Yellow
    exit 1
}

# Load the vendor export (JSON preferred; CSV fallback). Shape is normalized below.
$raw = $null
try {
    if ($ExportPath -match '\.json$') { $raw = Get-Content -Raw -Path $ExportPath | ConvertFrom-Json }
    else { $raw = Import-Csv -Path $ExportPath }
} catch {
    Write-Host "Could not parse export ($($_.Exception.Message)). Expect a Workspace ONE JSON array or CSV." -ForegroundColor Yellow
    exit 1
}

# Normalize to a flat inventory. Expected fields per item: Platform, Type, Name, Setting.
# (Field names vary by Workspace ONE version/export tool — adjust the mapping to your export.)
$inv = foreach ($item in @($raw)) {
    [pscustomobject]@{
        Platform = ($item.Platform   | ForEach-Object { $_ }) -as [string]
        Type     = ($item.Type       | ForEach-Object { $_ }) -as [string]
        Name     = ($item.Name        | ForEach-Object { $_ }) -as [string]
        Setting  = ($item.Setting     | ForEach-Object { $_ }) -as [string]
    }
}

Write-Host "`n=== Workspace ONE source inventory (normalized) ===" -ForegroundColor Cyan
$inv | Group-Object Platform | Sort-Object Name | ForEach-Object {
    $p = $_.Name; if (-not $p) { $p = '(unspecified)' }
    $prof = ($_.Group | Where-Object Type -match 'Profile').Count
    $comp = ($_.Group | Where-Object Type -match 'Compliance').Count
    Write-Host ("  {0,-12} profiles: {1,-4} compliance: {2}" -f $p, $prof, $comp)
}
Write-Host ("Total source settings: {0}" -f $inv.Count) -ForegroundColor Cyan

if ($CsvPath) {
    $inv | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Saved normalized inventory: $CsvPath" -ForegroundColor Green
}
Write-Host "`nNext: open 'Policy Translation - All Platforms - Gap Register' with one row per setting." -ForegroundColor Green
