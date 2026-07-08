<#
.SYNOPSIS
    IPMIG-Discovery.ps1 — read-only two-sided inventory for a sensitivity-label migration: the target Purview estate vs the legacy classification values.
.DESCRIPTION
    Inventories the TARGET side via Security & Compliance PowerShell — sensitivity labels, label
    policies, service-side auto-labeling policies (and their mode), and custom sensitive information
    types — then cross-references the LEGACY side: a CSV of distinct classification values exported from
    the source classification tool. For each legacy value it reports whether a plausible target label and
    a detection SIT already exist. Read-only — makes no changes. Use it to build the migration baseline.
.EXAMPLE
    .\IPMIG-Discovery.ps1
    Connects with Connect-IPPSSession and prints the target Purview estate only.
.EXAMPLE
    .\IPMIG-Discovery.ps1 -LegacyCsv .\LegacyValues.csv -CsvFolder C:\Temp\IPMIG
    Cross-references the legacy values against the estate and writes one CSV per object type + the crosswalk.
.NOTES
    Requires PowerShell 5.1+/7+ and the ExchangeOnlineManagement module (Connect-IPPSSession).
    Role: Information Protection Reader / Compliance Administrator (read).
    Legacy CSV columns (min): LegacyValue. Optional: Marking, MetadataProperty, EmailHeader, ExampleItem.
    Expected results: PASS = console/CSV inventory of the target estate + a per-legacy-value crosswalk
    (target label found? detection SIT found?). FAIL = Connect-IPPSSession errors or a cmdlet is
    unavailable (verify your licensing/tenant — service-side auto-labeling is E5 / E5 Compliance).
#>
[CmdletBinding()]
param(
    [string]$LegacyCsv,
    [string]$CsvFolder
)

function Connect-SCC {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Warning 'ExchangeOnlineManagement module not found. Install-Module ExchangeOnlineManagement -Scope CurrentUser'
        throw 'Module missing.'
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        Write-Host 'Connecting to Security & Compliance PowerShell...' -ForegroundColor Cyan
        Connect-IPPSSession -ShowBanner:$false
    }
}

function Save-Csv($data, $name) {
    if ($CsvFolder -and $data) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null }
        $path = Join-Path $CsvFolder ("IPMIG-{0}.csv" -f $name)
        $data | Export-Csv -Path $path -NoTypeInformation
        Write-Host ("  saved -> {0}" -f $path) -ForegroundColor DarkGray
    }
}

Connect-SCC
Write-Host '=== IPMIG two-sided migration inventory (read-only) ===' -ForegroundColor Cyan

# --- TARGET: sensitivity labels ---
Write-Host "`n--- Target sensitivity labels (Get-Label) ---" -ForegroundColor Cyan
$labels = Get-Label -ErrorAction SilentlyContinue
$labelView = $labels | Select-Object DisplayName, Name,
    @{n='HasParent';e={[bool]$_.ParentId}},
    @{n='Encryption';e={[bool]$_.EncryptionEnabled}},
    Priority
$labelView | Sort-Object Priority | Format-Table -AutoSize
Save-Csv $labelView 'TargetLabels'

# --- TARGET: label policies ---
Write-Host "`n--- Target label policies (Get-LabelPolicy) ---" -ForegroundColor Cyan
$labelPolicies = Get-LabelPolicy -ErrorAction SilentlyContinue
$lpView = $labelPolicies | Select-Object Name, Mode, Enabled, @{n='Labels';e={($_.Labels -join ', ')}}
$lpView | Format-Table -AutoSize
Save-Csv $lpView 'LabelPolicies'

# --- TARGET: auto-labeling policies (the reclassification engine; mode matters) ---
Write-Host "`n--- Auto-labeling policies (Get-AutoSensitivityLabelPolicy) ---" -ForegroundColor Cyan
$autoPol = Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue
if ($autoPol) {
    $apView = $autoPol | Select-Object Name, Mode,
        @{n='ApplyLabel';e={$_.ApplySensitivityLabel}},
        @{n='SharePoint';e={($_.SharePointLocation.Name -join ',')}},
        @{n='OneDrive';e={($_.OneDriveLocation.Name -join ',')}},
        @{n='Exchange';e={($_.ExchangeLocation.Name -join ',')}}
    $apView | Format-Table -AutoSize
    Save-Csv $apView 'AutoLabelPolicies'
    Write-Host '  NOTE: reclassification policies must be a Test* (simulation) mode until precision is signed off.' -ForegroundColor Yellow
} else {
    Write-Host '  (none found — or feature not licensed; service-side auto-labeling is typically E5 — verify your licensing/tenant)' -ForegroundColor Yellow
}

# --- TARGET: custom sensitive information types (the detections) ---
Write-Host "`n--- Custom sensitive information types (Get-DlpSensitiveInformationType) ---" -ForegroundColor Cyan
$allSits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
$customSits = $allSits | Where-Object { $_.Publisher -notlike 'Microsoft*' }
$sitView = $customSits | Select-Object Name, Publisher, Id
if ($sitView) { $sitView | Format-Table -AutoSize } else { Write-Host '  (no custom SITs found — author detection SITs per legacy value in the portal)' -ForegroundColor Yellow }
Save-Csv $sitView 'CustomSITs'

# --- LEGACY: cross-reference the source-tool classification values ---
if ($LegacyCsv) {
    if (-not (Test-Path $LegacyCsv)) { Write-Warning "Legacy CSV not found: $LegacyCsv"; return }
    Write-Host "`n--- Legacy classification values crosswalk (from $LegacyCsv) ---" -ForegroundColor Cyan
    $legacy = Import-Csv $LegacyCsv
    $labelNames = @($labels | ForEach-Object { $_.DisplayName; $_.Name })
    $sitNames   = @($customSits | ForEach-Object { $_.Name })
    $cross = foreach ($row in $legacy) {
        $val = $row.LegacyValue
        # Heuristic only: does a target label or a 'SIT - Legacy <value>' detection already look present?
        $labelHit = @($labelNames | Where-Object { $_ -and $val -and ($_ -like "*$val*" -or $val -like "*$_*") }) -join '; '
        $sitHit   = @($sitNames   | Where-Object { $_ -and $val -and $_ -like "*Legacy*$val*" }) -join '; '
        [pscustomobject]@{
            LegacyValue      = $val
            Marking          = $row.Marking
            WrittenAs        = @($row.MetadataProperty, $row.EmailHeader | Where-Object { $_ }) -join ' / '
            PossibleTarget   = if ($labelHit) { $labelHit } else { '(none — map in matrix)' }
            DetectionSIT     = if ($sitHit)   { $sitHit }   else { '(none — author SIT)' }
        }
    }
    $cross | Format-Table -AutoSize
    Save-Csv $cross 'LegacyCrosswalk'
    $unmapped = @($cross | Where-Object { $_.PossibleTarget -like '(none*' }).Count
    Write-Host ("  {0} legacy value(s); {1} with no obvious target label — resolve in Label Mapping Matrix - Design." -f $cross.Count, $unmapped) -ForegroundColor Yellow
    Write-Host '  NOTE: the label/SIT match above is a NAME heuristic only — the authoritative mapping is the human-reviewed matrix.' -ForegroundColor DarkGray
} else {
    Write-Host "`n(no -LegacyCsv supplied — target-side inventory only. Supply the source-tool export to build the crosswalk.)" -ForegroundColor DarkGray
}

Write-Host "`n=== Inventory complete (no changes made) ===" -ForegroundColor Green
