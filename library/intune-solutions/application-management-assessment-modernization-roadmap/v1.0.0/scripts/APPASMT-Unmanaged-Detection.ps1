<#
.SYNOPSIS
    APPASMT-Unmanaged-Detection.ps1 — detect unmanaged / sideloaded software on managed devices (READ-ONLY).
.DESCRIPTION
    PURPOSE
        Evidences dimensions D5 (Security & Application Control), D6 (Lifecycle & Retirement) and
        D9 (Migration Debt) by comparing the software actually DETECTED on managed devices
        (deviceManagement detectedApps) against the catalog of apps Intune deploys. Software present
        on devices but NOT deployed by Intune is manually installed / sideloaded — the shadow estate
        that app-control and lifecycle processes are supposed to govern. READ-ONLY: Graph .Read.All
        scopes only.
    HOW TO RUN
        Connect-MgGraph -Scopes "DeviceManagementApps.Read.All","DeviceManagementManagedDevices.Read.All"
        #   GCC High: add -Environment USGov
        powershell -ExecutionPolicy Bypass -File .\APPASMT-Unmanaged-Detection.ps1 -OutDir .\APPASMT-EvidencePack
    EXPECTED RESULTS
        Console summary plus:
          APPASMT-Unmanaged-Apps.csv        (detected software not managed by Intune, with device counts)
          APPASMT-Unmanaged-Summary.json
.NOTES
    Intune Solutions — application management assessment. READ-ONLY (detection/analysis; no tenant writes).
    Least-privilege: Intune "Read Only Operator" + Graph *.Read.All. Government: -Environment USGov
    (GCC High) / USGovDoD (DoD); verify GCC High detectedApps parity where uncertain.
#>
[CmdletBinding()]
param([string]$OutDir = ".\APPASMT-EvidencePack")

$ctx = Get-MgContext -ErrorAction SilentlyContinue
if (-not $ctx) { throw "Not connected. Run Connect-MgGraph with read-only scopes first (see .NOTES)." }
Write-Host ("Connected as {0} | Environment: {1}" -f $ctx.Account, $ctx.Environment) -ForegroundColor Cyan
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

# 1) Managed catalog: the display names Intune actually deploys (to subtract from detected).
Write-Host "Reading Intune-managed app catalog ..." -ForegroundColor Cyan
$managedNames = New-Object System.Collections.Generic.HashSet[string]
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/mobileApps?`$top=50&`$select=displayName"
while ($uri) {
    $p = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($a in $p.value) { if ($a.displayName) { [void]$managedNames.Add((($a.displayName -replace '\s*\d+(\.\d+)+.*$','').Trim().ToLower())) } }
    $uri = $p.'@odata.nextLink'
}

# 2) Detected apps across managed devices (software actually present).
Write-Host "Reading detectedApps across the estate (paged) ..." -ForegroundColor Cyan
$detected = @()
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/detectedApps?`$top=100"
while ($uri) { $p = Invoke-MgGraphRequest -Method GET -Uri $uri; $detected += $p.value; $uri = $p.'@odata.nextLink' }

# Common OS/agent components that aren't "applications" for governance purposes.
$noise = 'update for|microsoft visual c\+\+|redistributable|\.net|windows sdk|driver|runtime|hotfix|security update'

$unmanaged = New-Object System.Collections.Generic.List[object]
foreach ($d in $detected) {
    $name = [string]$d.displayName
    if (-not $name) { continue }
    if ($name -match $noise) { continue }
    $norm = ($name -replace '\s*\d+(\.\d+)+.*$','').Trim().ToLower()
    if (-not $managedNames.Contains($norm)) {
        $unmanaged.Add([pscustomobject]@{
            DetectedApp = $name; Publisher = $d.publisher; Version = $d.version;
            DeviceCount = [int]$d.deviceCount; Platform = $d.platform
        })
    }
}
$unmanaged = @($unmanaged | Sort-Object DeviceCount -Descending)
$wideSpread = @($unmanaged | Where-Object { $_.DeviceCount -ge 5 })

Write-Host ("`n=== APPASMT Unmanaged / Sideloaded Detection ===" ) -ForegroundColor Cyan
Write-Host ("  Distinct detected titles:                 {0}" -f $detected.Count)
Write-Host ("  NOT managed by Intune (shadow estate):    {0}" -f $unmanaged.Count)
Write-Host ("  Unmanaged on >=5 devices (D5/D9 signal):  {0}" -f $wideSpread.Count)
if ($unmanaged.Count) { $unmanaged | Select-Object -First 10 | ForEach-Object { Write-Host ("    {0,-40} {1} device(s)" -f $_.DetectedApp, $_.DeviceCount) } }

$summary = [ordered]@{
    generatedUtc          = (Get-Date).ToUniversalTime().ToString('o')
    detectedTitles        = $detected.Count
    unmanagedTitles       = $unmanaged.Count
    unmanagedWideSpread   = $wideSpread.Count
    managedCatalogTitles  = $managedNames.Count
}
$unmanaged | Export-Csv (Join-Path $OutDir 'APPASMT-Unmanaged-Apps.csv') -NoTypeInformation -Encoding UTF8
$summary   | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $OutDir 'APPASMT-Unmanaged-Summary.json') -Encoding UTF8
Write-Host ("`nWrote APPASMT-Unmanaged-Apps.csv and APPASMT-Unmanaged-Summary.json to {0}" -f $OutDir) -ForegroundColor Green
Write-Host "Read-only complete. No tenant changes were made." -ForegroundColor Green
