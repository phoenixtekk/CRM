<#
.SYNOPSIS
    SPOMIG-Validation.ps1 — read-only post-migration validation (source vs target item counts + permission spot-check).
.DESCRIPTION
    Reconciles a migrated library: counts files/folders in the source path and compares them to the
    item count in the target SharePoint Online library (via PnP PowerShell), and lists the target
    library/folder permissions so they can be spot-checked against "Permission Map - Source->SPO -
    Design". Read-only — makes no changes. Emits "Post-Migration Validation - <Scope> - Validate", the
    evidence for the wave gate.
.EXAMPLE
    .\SPOMIG-Validation.ps1 -SourcePath \\fs01\PilotFinance -SiteUrl https://contoso.sharepoint.com/sites/PilotProd -Library "Documents" -CsvPath .\PilotValidation.csv
    # PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline (interactive modern auth / app reg).
.NOTES
    Expected results: PASS when target item count >= source count (net of intentional filters) and the
    permission list matches the map; FAIL if the target is short or unexpected principals appear. No
    data is modified.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourcePath,
    [Parameter(Mandatory)][string]$SiteUrl,
    [string]$Library = 'Documents',
    [string]$CsvPath
)

if (-not (Test-Path -LiteralPath $SourcePath)) { throw "Source path not found: $SourcePath" }
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) { throw 'PnP.PowerShell not installed. Install-Module PnP.PowerShell first.' }
Import-Module PnP.PowerShell -ErrorAction Stop

Write-Host '=== Post-Migration Validation - <Scope> - Validate ===' -ForegroundColor Cyan

# --- Source counts (read-only) ---
$srcFiles   = @(Get-ChildItem -LiteralPath $SourcePath -Recurse -File   -Force -ErrorAction SilentlyContinue).Count
$srcFolders = @(Get-ChildItem -LiteralPath $SourcePath -Recurse -Directory -Force -ErrorAction SilentlyContinue).Count
Write-Host ("Source: {0} files, {1} folders" -f $srcFiles, $srcFolders)

# --- Target counts (read-only, PnP) ---
Connect-PnPOnline -Url $SiteUrl -Interactive
$list = Get-PnPList -Identity $Library -ErrorAction Stop
$items = Get-PnPListItem -List $Library -PageSize 2000 -Fields FileLeafRef,FSObjType
$tgtFiles   = @($items | Where-Object { $_['FSObjType'] -eq 0 }).Count
$tgtFolders = @($items | Where-Object { $_['FSObjType'] -eq 1 }).Count
Write-Host ("Target: {0} files, {1} folders (list '{2}')" -f $tgtFiles, $tgtFolders, $Library)

$countPass = ($tgtFiles -ge $srcFiles)

# --- Permission spot-check (read-only): unique-permission scopes on the library ---
$perm = @()
try {
    $perm = Get-PnPGroup | Select-Object Title, @{n='Roles';e={ (Get-PnPGroupPermissions -Identity $_.Title -ErrorAction SilentlyContinue).Name -join ',' }}
} catch { Write-Warning "Could not enumerate site groups: $($_.Exception.Message)" }
Write-Host '--- Target site groups / roles (spot-check vs Permission Map - Source->SPO - Design) ---' -ForegroundColor Cyan
$perm | Format-Table -AutoSize

$result = [pscustomobject]@{
    Scope        = $SiteUrl
    Library      = $Library
    SourceFiles  = $srcFiles
    TargetFiles  = $tgtFiles
    SourceFolders= $srcFolders
    TargetFolders= $tgtFolders
    CountGate    = if ($countPass) {'PASS'} else {'FAIL'}
}
$result | Format-List

if ($CsvPath) {
    $result | Export-Csv -LiteralPath $CsvPath -NoTypeInformation
    $perm | Export-Csv -LiteralPath ([IO.Path]::ChangeExtension($CsvPath,'perms.csv')) -NoTypeInformation
    Write-Host ("Saved 'Post-Migration Validation - <Scope> - Validate' to {0}" -f $CsvPath) -ForegroundColor Green
}
if ($countPass) { Write-Host 'COUNT GATE: PASS (target >= source). Now confirm permission spot-check + delta-clean before retiring the source.' -ForegroundColor Green }
else            { Write-Host 'COUNT GATE: FAIL — target short of source. Investigate before passing the wave gate.' -ForegroundColor Yellow }

Disconnect-PnPOnline
