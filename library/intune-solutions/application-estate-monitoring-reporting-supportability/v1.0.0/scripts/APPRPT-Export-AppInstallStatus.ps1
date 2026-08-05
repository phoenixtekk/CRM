<#
.SYNOPSIS
    APPRPT-Export-AppInstallStatus.ps1 — extract per-device app install/detection status from
    Microsoft Graph to CSV/JSON for the Power BI reporting pipeline.
.DESCRIPTION
    PURPOSE
        The backbone extractor. For every managed app (or a filtered subset), reads the per-device
        install state (installed / failed / notApplicable / pending) and, where available, the
        detection state, and writes a flat CSV and/or JSON snapshot that the Power BI dataset
        'App Estate Reporting - Dataset - v1' consumes. Read-only; never changes Intune.
    HOW TO RUN
        Interactive (delegated):
          pwsh -File .\APPRPT-Export-AppInstallStatus.ps1 -Environment Global `
               -OutputPath C:\AppEstateReporting\Exports -Format Both
        Filter to specific apps:
          ... -AppNameLike "Acme"
        Unattended (app-only) is driven by the scheduled task the bootstrap script creates.
        Government cloud: pass -Environment USGov (GCC High) or -Environment USGovDoD (DoD).
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        One file per run: app-install-status_<yyyyMMdd-HHmm>.csv and/or .json in -OutputPath.
        Each row = one app x one device with its install and detection state. Row count roughly
        equals (apps with assignments) x (targeted devices). Feed this file to Power BI.
.NOTES
    Intune Solutions - the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string] $OutputPath = '.',
    [string] $AppNameLike,
    [string] $BlobContainer,
    [ValidateSet('Csv','Json','Both')]
    [string] $Format = 'Csv'
)

$ErrorActionPreference = 'Stop'

# --- Map -Environment to the Graph base URL + Connect-MgGraph environment name ---
$graphEnv = switch ($Environment) {
    'USGov'    { @{ Env = 'USGov';    Base = 'https://graph.microsoft.us' } }
    'USGovDoD' { @{ Env = 'USGovDoD'; Base = 'https://dod-graph.microsoft.us' } }
    default    { @{ Env = 'Global';   Base = 'https://graph.microsoft.com' } }
}
$base = "$($graphEnv.Base)/beta"

function Connect-Graph {
    $scopes = @('DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Environment $graphEnv.Env -Scopes $scopes | Out-Null }
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

Connect-Graph
Write-Host "Reading apps from $base ..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"
if ($AppNameLike) { $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" } }

$rows = foreach ($app in $apps) {
    $statuses = @()
    try { $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses" } catch {}
    foreach ($s in $statuses) {
        [pscustomobject]@{
            SnapshotUtc     = (Get-Date).ToUniversalTime().ToString('s')
            AppId           = $app.id
            AppName         = $app.displayName
            AppType         = ($app.'@odata.type' -replace '#microsoft.graph.','')
            DeviceId        = $s.deviceId
            DeviceName      = $s.deviceName
            UserPrincipal   = $s.userPrincipalName
            InstallState    = $s.installState
            InstallStateDetail = $s.installStateDetail
            ErrorCode       = $s.errorCode
            LastModifiedUtc = $s.lastModifiedDateTime
        }
    }
}

if (-not $rows) { Write-Host "No app device-status data found." -ForegroundColor Yellow; return }

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$csv  = Join-Path $OutputPath "app-install-status_$stamp.csv"
$json = Join-Path $OutputPath "app-install-status_$stamp.json"

if ($Format -in 'Csv','Both')  { $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8; Write-Host "Wrote $csv" -ForegroundColor Green }
if ($Format -in 'Json','Both') { $rows | ConvertTo-Json -Depth 4 | Out-File -FilePath $json -Encoding UTF8; Write-Host "Wrote $json" -ForegroundColor Green }

if ($BlobContainer) {
    Write-Host "To upload to Azure Storage container '$BlobContainer', use Az.Storage or azcopy with the export identity granted 'Storage Blob Data Contributor'." -ForegroundColor DarkCyan
}

Write-Host ("Rows: {0}  Apps: {1}" -f $rows.Count, ($rows.AppId | Sort-Object -Unique).Count) -ForegroundColor Cyan
