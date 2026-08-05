<#
.SYNOPSIS
    APPRPT-Report-VersionDrift.ps1 — report installed-version spread and patch currency for a
    managed application across the fleet.
.DESCRIPTION
    PURPOSE
        Answers "how far behind the approved version is the fleet?" For a named application, reads
        the detected-app inventory across managed devices, groups devices by installed version,
        computes version drift % and patch currency (n-1) against an approved version you supply,
        and lists the outdated devices. Read-only.
    HOW TO RUN
        pwsh -File .\APPRPT-Report-VersionDrift.ps1 -Environment Global `
             -AppDisplayNameLike "Google Chrome" -ApprovedVersion "126.0.6478.127" -OutputPath <path>
        Omit -ApprovedVersion to have the script treat the highest observed version as approved.
        Government cloud: -Environment USGov | USGovDoD.
        Required Graph scopes: DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A version histogram (Version, DeviceCount), the drift % and patch-currency % against the
        approved version, and a list of outdated devices. Pass = drift <= 10% and currency >= 95%
        (the KPI healthy range). Fail = below that - schedule the update / supersedence.
.NOTES
    Intune Solutions - the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [Parameter(Mandatory)][string] $AppDisplayNameLike,
    [string] $ApprovedVersion,
    [string] $OutputPath,
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'

$graphEnv = switch ($Environment) {
    'USGov'    { @{ Env = 'USGov';    Base = 'https://graph.microsoft.us' } }
    'USGovDoD' { @{ Env = 'USGovDoD'; Base = 'https://dod-graph.microsoft.us' } }
    default    { @{ Env = 'Global';   Base = 'https://graph.microsoft.com' } }
}
$base = "$($graphEnv.Base)/beta"

function Connect-Graph {
    $scopes = @('DeviceManagementManagedDevices.Read.All')
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
Write-Host "Reading managed devices and detected apps for '$AppDisplayNameLike'..." -ForegroundColor Cyan
$devices = Invoke-GraphGet -Uri "$base/deviceManagement/managedDevices?`$top=100"

$hits = foreach ($d in $devices) {
    $detected = @()
    try { $detected = Invoke-GraphGet -Uri "$base/deviceManagement/managedDevices/$($d.id)/detectedApps" } catch {}
    foreach ($a in ($detected | Where-Object { $_.displayName -like "*$AppDisplayNameLike*" })) {
        [pscustomobject]@{
            DeviceName = $d.deviceName
            DeviceId   = $d.id
            Version    = $a.version
            LastSync   = $d.lastSyncDateTime
        }
    }
}

if (-not $hits) { Write-Host "App '$AppDisplayNameLike' not found in detected-app inventory." -ForegroundColor Yellow; return }

$byVersion = $hits | Group-Object Version | Sort-Object { [version]($_.Name -replace '[^0-9.].*$','') } -Descending -ErrorAction SilentlyContinue
if (-not $ApprovedVersion) { $ApprovedVersion = ($byVersion | Select-Object -First 1).Name; Write-Host "No -ApprovedVersion given; treating highest observed ($ApprovedVersion) as approved." -ForegroundColor DarkCyan }

$total    = $hits.Count
$onApprov = ($hits | Where-Object Version -eq $ApprovedVersion).Count
$versions = @($byVersion.Name)
$prevVersion = ($versions | Where-Object { $_ -ne $ApprovedVersion } | Select-Object -First 1)
$onCurrentOrPrev = ($hits | Where-Object { $_.Version -eq $ApprovedVersion -or $_.Version -eq $prevVersion }).Count

$driftPct    = [math]::Round((($total - $onApprov) / $total) * 100, 1)
$currencyPct = [math]::Round(($onCurrentOrPrev / $total) * 100, 1)

Write-Host "`nVersion histogram:" -ForegroundColor Cyan
$byVersion | Select-Object @{n='Version';e={$_.Name}}, @{n='DeviceCount';e={$_.Count}} | Format-Table -AutoSize

Write-Host ("Approved version : {0}" -f $ApprovedVersion)
Write-Host ("Devices with app : {0}" -f $total)
Write-Host ("Version drift %  : {0}%  (healthy <= 10%)  -> {1}" -f $driftPct, $(if($driftPct -le 10){'PASS'}else{'FAIL'})) -ForegroundColor $(if($driftPct -le 10){'Green'}else{'Red'})
Write-Host ("Patch currency % : {0}%  (healthy >= 95%)  -> {1}" -f $currencyPct, $(if($currencyPct -ge 95){'PASS'}else{'FAIL'})) -ForegroundColor $(if($currencyPct -ge 95){'Green'}else{'Red'})

$outdated = $hits | Where-Object Version -ne $ApprovedVersion | Sort-Object Version
if ($CsvPath)    { $outdated | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Saved outdated devices to $CsvPath" -ForegroundColor Green }
if ($OutputPath) {
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
    $out = Join-Path $OutputPath ("version-drift_{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
    $hits | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
    Write-Host "Saved full inventory to $out" -ForegroundColor Green
}
