<#
.SYNOPSIS
    Inventory existing records labels and the file plan (READ-ONLY; makes no changes).

.DESCRIPTION
    Enumerates every compliance/retention label with its record and regulatory flags, action, and
    duration, and every file-plan descriptor (authority/category/sub-category/citation/department/
    reference ID). Flags each label as MAPPED (has file-plan descriptors) or UNMAPPED, and lists
    reusable descriptors — the baseline before designing the record/regulatory labels.

.EXAMPLE
    .\Assess-RecordsFilePlanPosture.ps1 -OutputDir .\out
    Writes the discovery CSVs to .\out (default: current directory).
    PowerShell 5.1+/7+. Connect first: Connect-IPPSSession (add -ConnectionUri for Gov clouds).

.NOTES
    Expected results (PASS): 'Records Posture - Tenant - Discovery' CSVs list all labels with correct
    record/regulatory flags and all file-plan descriptors; labels are correctly flagged mapped/unmapped.
    FAIL: the export is incomplete, or any change was made (this script only reads).
#>
[CmdletBinding()]
param(
    [string]$OutputDir = ".",
    [string]$Prefix = "Records Posture - Tenant - Discovery"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host "== Records + File Plan posture assessment (read-only) ==" -ForegroundColor Cyan

# --- Labels ---
$labels = @()
try {
    foreach ($t in (Get-ComplianceTag -ErrorAction Stop)) {
        $isRecord     = [bool]$t.IsRecordLabel
        $isRegulatory = [bool]($t.PSObject.Properties.Match('IsRegulatory').Count -gt 0 -and $t.IsRegulatory)
        # A label is "mapped" if any file-plan descriptor is populated on it.
        $fpp = $t.FilePlanProperty
        $mapped = $false
        if ($fpp) {
            $mapped = @($fpp.FilePlanPropertyAuthority, $fpp.FilePlanPropertyCategory,
                        $fpp.FilePlanPropertyCitation, $fpp.FilePlanPropertyDepartment,
                        $fpp.FilePlanPropertyReferenceId) -join '' -ne ''
        }
        $labels += [pscustomobject]@{
            Name            = $t.Name
            IsRecordLabel   = $isRecord
            IsRegulatory    = $isRegulatory
            RetentionAction = $t.RetentionAction
            RetentionDays   = $t.RetentionDuration
            RetentionType   = $t.RetentionType
            HasReviewer     = [bool]$t.ReviewerEmail
            FilePlanMapped  = if ($isRecord -or $isRegulatory) { if ($mapped) { 'MAPPED' } else { 'UNMAPPED' } } else { 'n/a (not a record)' }
            Authority       = if ($fpp) { $fpp.FilePlanPropertyAuthority } else { $null }
            Citation        = if ($fpp) { $fpp.FilePlanPropertyCitation } else { $null }
        }
    }
    Write-Host ("Labels found: {0}" -f $labels.Count) -ForegroundColor Green
} catch {
    Write-Warning "Could not enumerate labels: $($_.Exception.Message)"
}
$labelsPath = Join-Path $OutputDir ("{0} - Labels - {1}.csv" -f $Prefix, $stamp)
$labels | Sort-Object Name | Export-Csv -Path $labelsPath -NoTypeInformation -Encoding UTF8

# --- File-plan descriptors ---
$descriptors = @()
$descMap = @{
    'Authority'   = 'Get-FilePlanPropertyAuthority'
    'Category'    = 'Get-FilePlanPropertyCategory'
    'SubCategory' = 'Get-FilePlanPropertySubCategory'
    'Citation'    = 'Get-FilePlanPropertyCitation'
    'Department'  = 'Get-FilePlanPropertyDepartment'
    'ReferenceId' = 'Get-FilePlanPropertyReferenceId'
}
foreach ($kind in $descMap.Keys) {
    $cmd = $descMap[$kind]
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        try {
            foreach ($d in (& $cmd -ErrorAction Stop)) {
                $descriptors += [pscustomobject]@{ Kind = $kind; Name = $d.Name; DisplayName = $d.DisplayName }
            }
        } catch {
            Write-Warning "$cmd failed: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "$cmd not available — verify Records management licensing/role."
    }
}
$descPath = Join-Path $OutputDir ("{0} - FilePlanDescriptors - {1}.csv" -f $Prefix, $stamp)
$descriptors | Sort-Object Kind, Name | Export-Csv -Path $descPath -NoTypeInformation -Encoding UTF8

# --- Summary ---
$recordLabels = @($labels | Where-Object { $_.IsRecordLabel -or $_.IsRegulatory })
$unmapped     = @($recordLabels | Where-Object { $_.FilePlanMapped -eq 'UNMAPPED' })
Write-Host ""
Write-Host ("Record/regulatory labels: {0}  |  UNMAPPED: {1}  |  Descriptors: {2}" -f `
    $recordLabels.Count, $unmapped.Count, $descriptors.Count) -ForegroundColor Cyan
if ($unmapped.Count -gt 0) {
    Write-Host ("  Unmapped record labels (locked without a documented authority/citation):" ) -ForegroundColor Yellow
    $unmapped | ForEach-Object { Write-Host ("   - {0}" -f $_.Name) -ForegroundColor Yellow }
}
Write-Host ""
Write-Host ("Wrote: {0}" -f $labelsPath)
Write-Host ("Wrote: {0}" -f $descPath)
Write-Host "Assessment complete (read-only)." -ForegroundColor Green
