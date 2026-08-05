<#
.SYNOPSIS
    APPASMT-Estate-Inventory.ps1 — inventory and classify the Intune application estate (READ-ONLY).
.DESCRIPTION
    PURPOSE
        Builds the baseline picture of the application estate for the "APPASMT - Maturity Model
        (9 Dimensions x 5 Levels)" assessment: every Intune app classified by type (Win32, MSI/LOB,
        store, web link, iOS/Android, macOS), by publisher, and by assignment intent (required /
        available / uninstall / none). Feeds dimensions D1 (Governance) and D9 (Migration Debt).
        READ-ONLY: it reads Microsoft Graph with .Read.All scopes only and never changes the tenant.
    HOW TO RUN
        # 1) Commercial tenant:
        #    Connect-MgGraph -Scopes "DeviceManagementApps.Read.All","Group.Read.All"
        # 2) Government (GCC High) tenant:
        #    Connect-MgGraph -Environment USGov -Scopes "DeviceManagementApps.Read.All","Group.Read.All"
        # 3) run:
        powershell -ExecutionPolicy Bypass -File .\APPASMT-Estate-Inventory.ps1 -OutDir .\APPASMT-EvidencePack
        # Access-only check (no export): .\APPASMT-Estate-Inventory.ps1 -WhatIfAccessCheck
    EXPECTED RESULTS
        Console summary (apps by type, top publishers, assignment intent mix) and, unless
        -WhatIfAccessCheck, two files in the Evidence Pack:
          APPASMT-Estate-Inventory.csv   (one row per app)
          APPASMT-Estate-Summary.json    (aggregate counts consumed by APPASMT-Maturity-Evidence.ps1)
.NOTES
    Intune Solutions — application management assessment. READ-ONLY (inventory/analysis; no tenant writes).
    Least-privilege: Intune "Read Only Operator" + Graph *.Read.All. Government: use -Environment USGov
    (GCC High) / USGovDoD (DoD) on Connect-MgGraph; verify feature parity for GCC High where uncertain.
#>
[CmdletBinding()]
param(
    [string]$OutDir = ".\APPASMT-EvidencePack",
    [switch]$WhatIfAccessCheck
)

function Assert-Graph {
    $ctx = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $ctx) { throw "Not connected. Run Connect-MgGraph with read-only scopes first (see .NOTES)." }
    $writeScopes = $ctx.Scopes | Where-Object { $_ -match 'ReadWrite|\.Write' }
    if ($writeScopes) { Write-Warning "Session holds write scopes ($($writeScopes -join ', ')). This assessment only READS — no writes are performed." }
    Write-Host ("Connected as {0} | Environment: {1}" -f $ctx.Account, $ctx.Environment) -ForegroundColor Cyan
    Write-Host ("Scopes: {0}" -f ($ctx.Scopes -join ', ')) -ForegroundColor DarkGray
    return $ctx
}

$ctx = Assert-Graph

if ($WhatIfAccessCheck) {
    Write-Host "`n[Access check] Attempting a single read of deviceManagement/mobileApps ..." -ForegroundColor Yellow
    try {
        $probe = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/mobileApps?`$top=1"
        Write-Host "READABLE: deviceManagement/mobileApps returned data. Read-only access confirmed." -ForegroundColor Green
    } catch {
        Write-Host "NOT READABLE: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Fix per Requirement 2.1 (Read Only Operator) / 2.2 (read scopes)." -ForegroundColor Red
    }
    return
}

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

Write-Host "`nReading all mobileApps (paged) ..." -ForegroundColor Cyan
$apps = @()
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/mobileApps?`$top=50&`$expand=assignments"
while ($uri) {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $apps += $page.value
    $uri = $page.'@odata.nextLink'
}

function Get-AppTypeLabel($odataType) {
    switch -Regex ($odataType) {
        'win32LobApp'                 { 'Win32' ; break }
        'windowsMobileMSI|windowsUniversalAppX|windowsAppX|microsoftStoreForBusiness' { 'Windows-MSI/Store' ; break }
        'winGetApp'                   { 'WinGet-Store' ; break }
        'officeSuiteApp'              { 'M365-Apps' ; break }
        'webApp'                      { 'Web-Link' ; break }
        'ios(Store|Lob|Vpp)App'       { 'iOS' ; break }
        'android(Store|Managed|Lob|ForWork)App|managedAndroidStoreApp' { 'Android' ; break }
        'macOS'                       { 'macOS' ; break }
        default                       { ($odataType -replace '#microsoft.graph.','') }
    }
}
function Get-IntentMix($assignments) {
    if (-not $assignments -or $assignments.Count -eq 0) { return 'none' }
    ($assignments | ForEach-Object { $_.intent } | Sort-Object -Unique) -join '+'
}
function Is-AllDevicesOrUsers($assignments) {
    foreach ($a in $assignments) {
        $t = [string]$a.target.'@odata.type'
        if ($t -match 'allDevices|allLicensedUsers') { return $true }
    }
    return $false
}

$rows = foreach ($a in $apps) {
    [pscustomobject]@{
        DisplayName    = $a.displayName
        Publisher      = $a.publisher
        Type           = Get-AppTypeLabel ([string]$a.'@odata.type')
        Version        = $a.displayVersion
        AssignmentIntent = Get-IntentMix $a.assignments
        AssignmentCount  = ($a.assignments | Measure-Object).Count
        AllDevicesOrUsers = Is-AllDevicesOrUsers $a.assignments
        Featured       = $a.isFeatured
        Id             = $a.id
    }
}

$byType   = $rows | Group-Object Type      | Sort-Object Count -Descending
$byPub    = $rows | Group-Object Publisher | Sort-Object Count -Descending | Select-Object -First 10
$noAssign = ($rows | Where-Object { $_.AssignmentIntent -eq 'none' }).Count
$allDev   = ($rows | Where-Object { $_.AllDevicesOrUsers }).Count

Write-Host ("`n=== APPASMT Estate Inventory — {0} apps ===" -f $rows.Count) -ForegroundColor Cyan
Write-Host "`nApps by type:" -ForegroundColor Yellow
$byType | ForEach-Object { Write-Host ("  {0,-20} {1}" -f $_.Name, $_.Count) }
Write-Host "`nTop publishers:" -ForegroundColor Yellow
$byPub | ForEach-Object { Write-Host ("  {0,-30} {1}" -f $_.Name, $_.Count) }
Write-Host ("`nApps with NO assignment (D6 lifecycle signal): {0}" -f $noAssign)
Write-Host ("Apps targeting All Devices/All Users (D3 ring signal): {0}" -f $allDev)

$summary = [ordered]@{
    generatedUtc      = (Get-Date).ToUniversalTime().ToString('o')
    environment       = $ctx.Environment
    totalApps         = $rows.Count
    byType            = @{};
    win32Count        = ($rows | Where-Object Type -eq 'Win32').Count
    storeCount        = ($rows | Where-Object { $_.Type -match 'Store|iOS|Android|Web' }).Count
    noAssignmentCount = $noAssign
    allDevicesOrUsers = $allDev
    distinctPublishers = ($rows | Select-Object -ExpandProperty Publisher -Unique | Where-Object { $_ }).Count
}
$byType | ForEach-Object { $summary.byType[$_.Name] = $_.Count }

$rows | Sort-Object Type, DisplayName | Export-Csv (Join-Path $OutDir 'APPASMT-Estate-Inventory.csv') -NoTypeInformation -Encoding UTF8
$summary | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutDir 'APPASMT-Estate-Summary.json') -Encoding UTF8

Write-Host ("`nWrote APPASMT-Estate-Inventory.csv and APPASMT-Estate-Summary.json to {0}" -f $OutDir) -ForegroundColor Green
Write-Host "Read-only complete. No tenant changes were made." -ForegroundColor Green
