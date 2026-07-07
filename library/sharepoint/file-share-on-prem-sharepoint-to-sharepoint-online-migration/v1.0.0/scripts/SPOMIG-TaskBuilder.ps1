<#
.SYNOPSIS
    SPOMIG-TaskBuilder.ps1 — build an SPMT/Migration Manager bulk CSV from the IA map, then (only with -Commit) run SPMT.
.DESCRIPTION
    Turns the destination map "Target IA Map - SPO - Design" (source path -> destination site/library/
    folder) into a SharePoint Migration Tool bulk-migration CSV, validates every row, and — SAFE BY
    DEFAULT — stops there (dry-run). It registers and starts an SPMT migration ONLY when -Commit is
    passed, using the Microsoft.SharePoint.MigrationTool.PowerShell module with modern-auth sign-in
    (no stored credentials). The emitted CSV is also compatible with Migration Manager bulk upload,
    whose console is deferred to Microsoft's docs.
.EXAMPLE
    .\SPOMIG-TaskBuilder.ps1 -MapCsv .\TargetIAMap.csv -BulkCsvOut .\SPMT-Bulk.csv            # dry-run: build + validate only
    .\SPOMIG-TaskBuilder.ps1 -MapCsv .\TargetIAMap.csv -BulkCsvOut .\SPMT-Bulk.csv -Commit    # register + START the SPMT migration
    # PowerShell 5.1+/7+, SharePoint Migration Tool + Microsoft.SharePoint.MigrationTool.PowerShell module.
.NOTES
    Expected results (dry-run): a well-formed bulk CSV + a validation summary; NO migration is started.
    With -Commit: SPMT registers the tasks and starts; watch Get-SPMTMigration for progress. Input
    MapCsv columns: SourcePath, TargetSiteUrl, TargetList, TargetFolder (TargetFolder optional).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$MapCsv,
    [Parameter(Mandatory)][string]$BulkCsvOut,
    [switch]$Commit,           # without this, only builds + validates the CSV (no data moved)
    [switch]$MigratePermissions = $true
)

if (-not (Test-Path -LiteralPath $MapCsv)) { throw "Map CSV not found: $MapCsv" }
$map = Import-Csv -LiteralPath $MapCsv
if (-not $map) { throw "Map CSV is empty: $MapCsv" }

Write-Host '=== SPMT Task Builder (Migration Task - <Scope> - Wave<N>) ===' -ForegroundColor Cyan

# --- Validate + build the SPMT bulk CSV (headerless: Source, '', '', TargetWeb, TargetList, TargetFolder) ---
$bulk   = New-Object System.Collections.Generic.List[string]
$errors = 0
foreach ($row in $map) {
    if (-not (Test-Path -LiteralPath $row.SourcePath)) { Write-Warning "Source missing: $($row.SourcePath)"; $errors++; continue }
    if ([string]::IsNullOrWhiteSpace($row.TargetSiteUrl) -or [string]::IsNullOrWhiteSpace($row.TargetList)) {
        Write-Warning "Row missing TargetSiteUrl/TargetList for $($row.SourcePath)"; $errors++; continue
    }
    # SPMT bulk CSV format: <source>,<sourcedoclib/subfolder>,<>,<targetweb>,<targetdoclib>,<targetfolder>
    $bulk.Add(('{0},,,{1},{2},{3}' -f $row.SourcePath, $row.TargetSiteUrl, $row.TargetList, $row.TargetFolder))
}
$bulk | Set-Content -LiteralPath $BulkCsvOut -Encoding UTF8
Write-Host ("Built bulk CSV: {0} valid task row(s), {1} error(s) -> {2}" -f $bulk.Count, $errors, $BulkCsvOut) -ForegroundColor Cyan

if ($errors -gt 0) { Write-Host 'Fix the flagged rows before committing.' -ForegroundColor Yellow }

if (-not $Commit) {
    Write-Host 'DRY-RUN complete — no migration started. Re-run with -Commit to register and start SPMT.' -ForegroundColor Green
    return
}
if ($errors -gt 0) { throw 'Refusing to -Commit with invalid rows. Resolve them and re-run.' }

# --- Commit path: register + start SPMT (modern auth, no stored creds) ---
if (-not (Get-Module -ListAvailable -Name Microsoft.SharePoint.MigrationTool.PowerShell)) {
    throw 'Microsoft.SharePoint.MigrationTool.PowerShell not installed. Install the SharePoint Migration Tool / module first.'
}
Import-Module Microsoft.SharePoint.MigrationTool.PowerShell -ErrorAction Stop

if ($PSCmdlet.ShouldProcess($BulkCsvOut, 'Register + Start SPMT migration')) {
    # Interactive modern-auth sign-in to the destination tenant (no credentials in code).
    Register-SPMTMigration -Force -MigrateFilePermissions:$MigratePermissions
    Add-SPMTTask -FileShareSource '' -BulkCSVFile $BulkCsvOut   # bulk file drives all tasks
    Start-SPMTMigration                                          # runs pre-stage / delta per SPMT's incremental model
    Write-Host 'SPMT migration started. Track with Get-SPMTMigration.' -ForegroundColor Green
}
