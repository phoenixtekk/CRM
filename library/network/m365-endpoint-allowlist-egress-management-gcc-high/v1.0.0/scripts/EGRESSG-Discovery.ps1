<#
.SYNOPSIS
    EGRESSG-Discovery.ps1 — derive the current Microsoft 365 GCC High required IP/URL/port set from the endpoints web service (read-only).
.DESCRIPTION
    PURPOSE
        Queries the GCC High instance (USGOVGCCHigh) of the Microsoft 365 IP Address and URL web
        service, splits the result into IPv4/IPv6 ranges, URLs and ports, flags required and
        no-inspect endpoints, and writes an export plus a human-readable summary. Detects version
        changes against a checkpoint file and emits an add/remove diff. No Microsoft IPs are
        hardcoded — everything is derived at run time. Output goes to your-output-folder.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESSG-Discovery.ps1
        (note the GCC High endpoints web-service instance: USGOVGCCHigh)
    EXPECTED RESULTS
        A JSON export (EGRESSG-Endpoints-USGovGCCHigh.json) and a summary listing *.us sovereign
        endpoints. Reports 'up to date' when the version is unchanged, otherwise a diff. PASS when
        the returned instance is USGovGCCHigh and the set is non-empty; FAIL otherwise.
.NOTES
    White-label — the repeatable way. Read-only; queries the GCC High endpoints web service.
#>

#Requires -Version 5.1
[CmdletBinding()]
param(
    # The GCC High instance of the web service. Do not change this to Worldwide.
    [ValidateSet('USGOVGCCHigh')]
    [string]$Instance = 'USGOVGCCHigh',

    # Folder for the export, summary, and checkpoint file.
    [string]$OutputFolder = (Join-Path $PSScriptRoot 'output'),

    # Web service root.
    [string]$WebServiceRoot = 'https://endpoints.office.com'
)

$ErrorActionPreference = 'Stop'

function New-EgressGuid { [guid]::NewGuid().Guid }

# --- Prepare output folder and checkpoint ---------------------------------------------------------
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$versionPath = Join-Path $OutputFolder 'EGRESSG-latestversion.txt'
$dataPath    = Join-Path $OutputFolder 'EGRESSG-Endpoints-USGovGCCHigh.json'
$summaryPath = Join-Path $OutputFolder 'EGRESSG-Discovery-Summary.txt'

# Reuse a stable ClientRequestId per machine; create one on first run.
if (Test-Path $versionPath) {
    $content         = Get-Content $versionPath
    $clientRequestId = $content[0]
    $lastVersion     = $content[1]
} else {
    $clientRequestId = New-EgressGuid
    $lastVersion     = '0000000000'
    @($clientRequestId, $lastVersion) | Out-File $versionPath
    Write-Host "First run — created checkpoint at $versionPath"
}

Write-Host "Querying GCC High instance: $Instance"

# --- Confirm we are talking to the GCC High instance ----------------------------------------------
$versionUri = "$WebServiceRoot/version/$Instance`?clientRequestId=$clientRequestId"
$version    = Invoke-RestMethod -Uri $versionUri

if ($version.instance -ne 'USGovGCCHigh') {
    Write-Error "FAIL: web service returned instance '$($version.instance)', expected 'USGovGCCHigh'. Wrong cloud — aborting."
    exit 1
}
Write-Host ("Instance confirmed: {0}  (latest version {1})" -f $version.instance, $version.latest)

# --- Pull the endpoints (required parameter Instance) ---------------------------------------------
$endpointsUri = "$WebServiceRoot/endpoints/$Instance`?clientRequestId=$clientRequestId"
$endpointSets = Invoke-RestMethod -Uri $endpointsUri

if (-not $endpointSets -or $endpointSets.Count -eq 0) {
    Write-Error "FAIL: endpoints web method returned an empty set for $Instance."
    exit 1
}

# --- Flatten IPs / URLs / no-inspect --------------------------------------------------------------
$noInspectMatch = @('*.manage.microsoft.us', 'has.spserv.microsoft.com', '*.dm.microsoft.us')

$flatUrls = foreach ($set in $endpointSets) {
    if ($set.urls) {
        foreach ($u in $set.urls) {
            [pscustomobject]@{
                id           = $set.id
                serviceArea  = $set.serviceArea
                category     = $set.category
                required     = $set.required
                url          = $u
                tcpPorts     = $set.tcpPorts
                udpPorts     = $set.udpPorts
                expressRoute = $set.expressRoute
                noInspect    = [bool]($noInspectMatch | Where-Object { $u -like $_ })
            }
        }
    }
}

$flatIps = foreach ($set in $endpointSets) {
    if ($set.ips) {
        foreach ($ip in $set.ips) {
            [pscustomobject]@{
                id           = $set.id
                serviceArea  = $set.serviceArea
                category     = $set.category
                required     = $set.required
                ip           = $ip
                family       = if ($ip -like '*:*') { 'IPv6' } else { 'IPv4' }
                tcpPorts     = $set.tcpPorts
                udpPorts     = $set.udpPorts
                expressRoute = $set.expressRoute
            }
        }
    }
}

# --- Write the export -----------------------------------------------------------------------------
$export = [pscustomobject]@{
    instance     = $version.instance
    version      = $version.latest
    generated    = (Get-Date).ToString('s')
    endpointSets = $endpointSets
    flatUrls     = $flatUrls
    flatIps      = $flatIps
}
$export | ConvertTo-Json -Depth 8 | Out-File $dataPath -Encoding utf8
Write-Host "Export written: $dataPath"

# --- Summary --------------------------------------------------------------------------------------
$ipv4 = ($flatIps | Where-Object family -eq 'IPv4' | Select-Object -Expand ip -Unique)
$ipv6 = ($flatIps | Where-Object family -eq 'IPv6' | Select-Object -Expand ip -Unique)
$urls = ($flatUrls | Select-Object -Expand url -Unique | Sort-Object)
$noInspect = ($flatUrls | Where-Object noInspect | Select-Object -Expand url -Unique | Sort-Object)

$summary = @()
$summary += "EGRESSG Discovery Summary"
$summary += "Instance : $($version.instance)"
$summary += "Version  : $($version.latest)"
$summary += "Generated: $((Get-Date).ToString('s'))"
$summary += ""
$summary += "Endpoint sets : $($endpointSets.Count)"
$summary += "IPv4 ranges   : $($ipv4.Count)"
$summary += "IPv6 ranges   : $($ipv6.Count)"
$summary += "URLs/FQDNs    : $($urls.Count)"
$summary += ""
$summary += "NO-INSPECT endpoints (add these to EGRESSG-NoInspect-GCCHigh):"
$summary += ($noInspect | ForEach-Object { "  $_" })
$summary += ""
$summary += "Sample sovereign FQDNs (should be *.us / *.microsoft.us):"
$summary += (($urls | Where-Object { $_ -like '*.us' -or $_ -like '*.microsoft' } | Select-Object -First 15) | ForEach-Object { "  $_" })
$summary | Out-File $summaryPath -Encoding utf8
$summary | Write-Host

# --- Version compare / change detection -----------------------------------------------------------
if ($version.latest -gt $lastVersion) {
    Write-Host ""
    Write-Host "CHANGE DETECTED: $lastVersion -> $($version.latest). Fetching change diff..."
    $changesUri = "$WebServiceRoot/changes/$Instance/$lastVersion`?clientRequestId=$clientRequestId"
    try {
        $changes = Invoke-RestMethod -Uri $changesUri
        $diffPath = Join-Path $OutputFolder ("EGRESSG-Changes-{0}.json" -f $version.latest)
        $changes | ConvertTo-Json -Depth 8 | Out-File $diffPath -Encoding utf8
        Write-Host "Change diff written: $diffPath  — review and apply additions within the 30-day window."
    } catch {
        Write-Warning "Could not fetch change diff: $($_.Exception.Message)"
    }
    @($clientRequestId, $version.latest) | Out-File $versionPath
} else {
    Write-Host ""
    Write-Host "Up to date — allow-list already reflects version $($version.latest)."
}

Write-Host ""
Write-Host "PASS: GCC High discovery complete."
