<#
.SYNOPSIS
    GWAUTO-Discovery.ps1 — inventory Apps Script projects and AppSheet apps and their governance exposure.
.DESCRIPTION
    PURPOSE
        Reads an export of your Apps Script projects and AppSheet apps and emits a governance
        inventory: owner of record, OAuth scopes, connected data sources, sharing exposure, and the
        assigned risk tier. This is the Assess-phase baseline for the whole solution. Read-only — it
        reads an export you supply; it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWAUTO-Discovery.ps1 -InventoryCsv C:\Temp\automation-inventory.csv
        Build the export from the Google Admin console (App access control / OAuth app inventory) and
        the AppSheet Admin Console (apps, owners, sharing), or from the Workspace Admin SDK / OAuth
        token reports for your-domain. Read-only Workspace admin visibility is enough to produce it.
        CSV columns: Platform,ArtifactId,Name,Owner,Scopes,DataSources,Sharing,Environment,Tier
        (Platform = AppsScript or AppSheet; Scopes/DataSources semicolon-separated; Sharing = Internal,
         Domain, External, or Anyone.)
    EXPECTED RESULTS
        A per-artifact table plus counts by platform, sharing exposure, and risk tier. Artifacts with
        no owner, broad scopes, or external/anyone sharing are flagged. No system is changed. Pass =
        the inventory reconciles with your Admin/AppSheet consoles and every artifact has an owner.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [string]$CsvPath
)

# Scopes treated as broad / high-risk for Apps Script (least-scope is the standard).
$BroadScopePatterns = 'auth/gmail\b','auth/drive\b','auth/spreadsheets\b','/auth/gmail$',
                      'mail.google.com','auth/drive$','auth/documents$','auth/admin'
$ExternalSharing = 'External','Anyone'

if (-not (Test-Path $InventoryCsv)) {
    Write-Host "Inventory CSV not found: $InventoryCsv" -ForegroundColor Red
    Write-Host "Columns: Platform,ArtifactId,Name,Owner,Scopes,DataSources,Sharing,Environment,Tier" -ForegroundColor DarkYellow
    exit 2
}
$rows = Import-Csv $InventoryCsv
if (-not $rows) { Write-Host "No automation artifacts found." -ForegroundColor DarkYellow; exit 0 }

function Test-BroadScope([string]$scopes) {
    foreach ($p in $BroadScopePatterns) { if ($scopes -match $p) { return $true } }
    return $false
}

Write-Host "`n=== Apps Script / AppSheet automation inventory ===" -ForegroundColor Cyan
$inventory = foreach ($a in $rows) {
    $broad    = Test-BroadScope $a.Scopes
    $extShare = $ExternalSharing -contains $a.Sharing
    [pscustomobject]@{
        Platform    = $a.Platform
        ArtifactId  = $a.ArtifactId
        Name        = $a.Name
        Owner       = $a.Owner
        BroadScope  = if ($broad) { 'yes' } else { 'no' }
        Sharing     = $a.Sharing
        Environment = $a.Environment
        Tier        = $a.Tier
        HasOwner    = if ([string]::IsNullOrWhiteSpace($a.Owner)) { 'no' } else { 'yes' }
        ExternalShare = if ($extShare) { 'yes' } else { 'no' }
    }
}
$inventory | Sort-Object Platform, Name |
    Format-Table Platform, Name, Owner, BroadScope, Sharing, Environment, Tier -AutoSize

Write-Host "`n--- By platform ---" -ForegroundColor Cyan
$inventory | Group-Object Platform | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count)
}
Write-Host "`n--- By sharing exposure ---" -ForegroundColor Cyan
$inventory | Group-Object Sharing | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count)
}

$noOwner   = $inventory | Where-Object { $_.HasOwner -eq 'no' }
$broadList = $inventory | Where-Object { $_.BroadScope -eq 'yes' }
$extList   = $inventory | Where-Object { $_.ExternalShare -eq 'yes' }

Write-Host ("`nArtifacts with no owner of record : {0}" -f $noOwner.Count)   -ForegroundColor Yellow
Write-Host ("Artifacts with broad/high-risk scopes: {0}" -f $broadList.Count) -ForegroundColor Yellow
Write-Host ("Artifacts shared externally / anyone : {0}" -f $extList.Count)   -ForegroundColor Yellow

if ($CsvPath) { $inventory | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved $CsvPath" -ForegroundColor Green }
Write-Host "Record this inventory as the Assess-phase baseline for Apps Script & AppSheet governance." -ForegroundColor DarkYellow
