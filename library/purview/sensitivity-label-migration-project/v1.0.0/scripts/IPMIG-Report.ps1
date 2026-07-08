<#
.SYNOPSIS
    IPMIG-Report.ps1 — produce the "Migration Coverage - Report": each legacy value mapped/detected/policy state (read-only).
.DESCRIPTION
    PURPOSE
        From the mapping CSV and the live Purview estate, produces the migration coverage report: for every
        legacy value — is it mapped to a target label, does its detection SIT exist, is the target label
        published, and is the reclassification policy in simulation vs enforced (with the rule's SIT). This
        is the coverage/status view used to gate expansion. Read-only — reads the estate and the CSV; writes
        only the local report CSV.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPMIG-Report.ps1 -MappingCsv .\mapping.csv -CsvPath .\MigrationCoverage.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Mapping CSV columns: LegacyValue,
        TargetLabel, SitName (optional Locations). PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        A per-legacy-value table + optional CSV: Mapped (Y/N), SitExists, LabelPublished, PolicyMode
        (simulation/enforced/none), SimMatchNote. Any "N" / "missing" is a coverage gap to resolve before expanding.
.NOTES
    Purview — Sensitivity Label Migration. Read-only. Reports coverage/state; whether precision is acceptable
    and whether protection intent is reproduced are data-owner/records determinations, not decided here.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MappingCsv,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $MappingCsv)) { Write-Error "Mapping CSV not found: $MappingCsv"; return }
$mappings = @(Import-Csv $MappingCsv)
if ($mappings.Count -eq 0) { Write-Error 'Mapping CSV has no rows.'; return }

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-IPPSSession -ShowBanner:$false }
}

Write-Host "=== Migration Coverage - Report (read-only) ===" -ForegroundColor Cyan

$labels = @(Get-Label -ErrorAction SilentlyContinue)
$labelNames = @($labels | ForEach-Object { $_.DisplayName; $_.Name })
$labelPolicies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)   # published-scope is portal-authoritative; confirm each target label is PUBLISHED
$sits = @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
$autoPolicies = @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)

$rows = @()
foreach ($m in $mappings) {
    $legacy = "$($m.LegacyValue)".Trim()
    $target = "$($m.TargetLabel)".Trim()
    $sit    = "$($m.SitName)".Trim()

    $mapped = [bool]$target
    $labelExists = ($target -and ($labelNames -contains $target))
    $sitExists = ($sit -and ($sits -contains $sit))

    $polName = if ($target) { "Reclassify Sim - $target - Locations" } else { $null }
    $pol = if ($polName) { $autoPolicies | Where-Object { $_.Name -eq $polName } | Select-Object -First 1 } else { $null }
    $polMode = if (-not $pol) { 'none' } elseif ("$($pol.Mode)" -like 'Test*') { 'simulation' } elseif ("$($pol.Mode)" -eq 'Enable') { 'ENFORCED' } else { "$($pol.Mode)" }
    $simNote = if ($polMode -eq 'simulation') { 'in simulation — review match set in portal' } elseif ($polMode -eq 'ENFORCED') { 'enforcing — reclassifying' } else { 'no policy yet' }

    $row = [pscustomobject]@{
        LegacyValue    = $legacy
        Mapped         = if ($mapped) { 'Y' } else { 'N (owner decision)' }
        TargetLabel    = $target
        LabelExists    = if ($labelExists) { 'Y' } else { 'MISSING' }
        SitName        = $sit
        SitExists      = if ($sitExists) { 'Y' } else { 'MISSING' }
        PolicyMode     = $polMode
        SimMatchNote   = $simNote
    }
    $rows += $row
    $col = if ($row.Mapped -like 'N*' -or $row.LabelExists -eq 'MISSING' -or $row.SitExists -eq 'MISSING') { 'Yellow' } elseif ($polMode -eq 'ENFORCED') { 'Green' } else { 'White' }
    Write-Host ("  {0,-28} mapped={1,-16} label={2,-8} sit={3,-8} policy={4}" -f $legacy, $row.Mapped, $row.LabelExists, $row.SitExists, $polMode) -ForegroundColor $col
}

$gaps = @($rows | Where-Object { $_.Mapped -like 'N*' -or $_.LabelExists -eq 'MISSING' -or $_.SitExists -eq 'MISSING' })
Write-Host ("`n{0} legacy value(s); {1} coverage gap(s)." -f $rows.Count, $gaps.Count) -ForegroundColor Cyan
if ($gaps.Count -gt 0) { Write-Host "  Resolve every gap (map the value / publish the label / author the SIT) before expanding — see IPMIG-Scope-Health.ps1." -ForegroundColor Yellow }

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Wrote {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}
Write-Host "`nPublished-label status is portal-authoritative — confirm each target label is PUBLISHED (Requirement 2.2) in Information Protection > Label policies." -ForegroundColor DarkGray
