<#
.SYNOPSIS
    IPTAX-Reporting.ps1 — export the full taxonomy + protection/marking mapping and a naming-conformance view (read-only).
.DESCRIPTION
    PURPOSE
        The living record of the designed taxonomy. Reads every sensitivity label and produces the ordered
        taxonomy with, per label: parent/sublabel, order (Priority), encryption yes/no + rights, content
        marking (header/footer/watermark), and internal-name convention conformance — so the built labels
        can be compared to the design sheet at any time. Read-only: reads labels and writes only a local
        report CSV; it changes no label and publishes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPTAX-Reporting.ps1 -CsvPath .\IPTAX-Taxonomy-Report.csv
        powershell -ExecutionPolicy Bypass -File .\IPTAX-Reporting.ps1 -ConformanceOnly
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Role: Information Protection reader.
        PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        The ordered taxonomy + protection/marking mapping table (and optional CSV), plus a naming-conformance
        view flagging any internal name that doesn't match the SL- convention. -ConformanceOnly prints just
        the conformance view.
.NOTES
    Purview — Sensitivity Label Taxonomy Design. Read-only. Which tiers encrypt and the rights model are
    security/compliance/records determinations (design sheet §2.7) — this report records them, it does not decide them.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$NamePrefix = 'SL-',
    [switch]$ConformanceOnly,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-IPPSSession -ShowBanner:$false }
}

$labels = @(Get-Label -ErrorAction SilentlyContinue)
if ($labels.Count -eq 0) { Write-Host 'No sensitivity labels found (nothing built yet, or verify your role/licensing).' -ForegroundColor Yellow; return }

$byGuid = @{}
foreach ($l in $labels) { if ($l.Guid) { $byGuid[[string]$l.Guid] = $l.DisplayName } }

# --- Naming-convention conformance ---
Write-Host ("=== Naming-convention conformance (prefix '{0}') ===" -f $NamePrefix) -ForegroundColor Cyan
$conf = $labels | Select-Object Name, DisplayName, @{n='Conforms';e={ [bool]($_.Name -like ("{0}*" -f $NamePrefix)) }}
$nonConf = @($conf | Where-Object { -not $_.Conforms })
if ($nonConf.Count -gt 0) {
    Write-Host ("  {0} label(s) do NOT match the '{1}*' convention:" -f $nonConf.Count, $NamePrefix) -ForegroundColor Yellow
    $nonConf | Format-Table -AutoSize
} else { Write-Host '  All internal names conform to the convention.' -ForegroundColor Green }

if ($ConformanceOnly) {
    if ($CsvPath) { $conf | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Wrote {0}" -f $CsvPath) -ForegroundColor Green }
    return
}

# --- Full taxonomy + protection/marking mapping ---
Write-Host "`n=== Taxonomy + protection/marking mapping ===" -ForegroundColor Cyan
$report = $labels | Sort-Object Priority | Select-Object `
    @{n='Priority';e={$_.Priority}},
    DisplayName, Name,
    @{n='Parent';e={ if ($_.ParentId) { $byGuid[[string]$_.ParentId] } else { '' } }},
    @{n='IsParentGrouping';e={ [bool]($labels | Where-Object { "$($_.ParentId)" -eq "$($_.Guid)" }) }},
    @{n='Encryption';e={ if ($_.EncryptionEnabled) { 'Yes' } else { 'No' } }},
    @{n='RightsGroups';e={ try { ($_.EncryptionRightsDefinitions | ForEach-Object { $_.Identity }) -join '; ' } catch { '' } }},
    @{n='Header';e={ if ($_.ApplyContentMarkingHeaderEnabled) { $_.ApplyContentMarkingHeaderText } else { '' } }},
    @{n='Footer';e={ if ($_.ApplyContentMarkingFooterEnabled) { $_.ApplyContentMarkingFooterText } else { '' } }},
    @{n='Watermark';e={ if ($_.ApplyWaterMarkingEnabled) { $_.WaterMarkingText } else { '' } }},
    @{n='ConformsName';e={ [bool]($_.Name -like ("{0}*" -f $NamePrefix)) }}

$report | Format-Table Priority, DisplayName, Name, Parent, Encryption, Footer -AutoSize
Write-Host ("`n{0} label(s) total; {1} encrypting; {2} parent grouping label(s)." -f `
    $report.Count, @($report | Where-Object { $_.Encryption -eq 'Yes' }).Count, @($report | Where-Object { $_.IsParentGrouping }).Count) -ForegroundColor Cyan

if ($CsvPath) {
    try { $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Wrote {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}
Write-Host "`nCompare this against the signed-off taxonomy + protection-mapping design sheet (§2.7); they must agree." -ForegroundColor DarkGray
