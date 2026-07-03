<#
.SYNOPSIS
    EGRESSG-Report.ps1 — produce a dated, point-in-time audit report of the derived Microsoft 365 GCC High required set (read-only).
.DESCRIPTION
    PURPOSE
        Derives the current GCC High set from the USGOVGCCHigh instance (or reads an existing
        Discovery export) and produces a dated audit report grouped by service area and category,
        with ports, ExpressRoute flags, and the no-inspect endpoints called out. Suitable for
        change control and government compliance evidence. No Microsoft IPs are hardcoded. Writes to
        your-output-folder.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESSG-Report.ps1
        (note the GCC High endpoints web-service instance: USGOVGCCHigh)
    EXPECTED RESULTS
        A dated report file (EGRESSG-Report-<version>.md/.csv) summarizing the required set. PASS
        when the report is generated from the USGovGCCHigh instance; FAIL on wrong instance.
.NOTES
    White-label — the repeatable way. Read-only; queries the GCC High endpoints web service.
#>

#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('USGOVGCCHigh')]
    [string]$Instance = 'USGOVGCCHigh',
    [string]$OutputFolder = (Join-Path $PSScriptRoot 'output'),
    [string]$WebServiceRoot = 'https://endpoints.office.com',
    # Reuse an existing Discovery export instead of re-querying.
    [string]$FromExport
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$clientRequestId = [guid]::NewGuid().Guid

# --- Acquire the endpoint data --------------------------------------------------------------------
if ($FromExport -and (Test-Path $FromExport)) {
    Write-Host "Reading existing export: $FromExport"
    $export       = Get-Content $FromExport -Raw | ConvertFrom-Json
    $endpointSets = $export.endpointSets
    $reportVersion = $export.version
    $instanceName  = $export.instance
} else {
    $version = Invoke-RestMethod -Uri "$WebServiceRoot/version/$Instance`?clientRequestId=$clientRequestId"
    if ($version.instance -ne 'USGovGCCHigh') {
        Write-Error "FAIL: web service returned instance '$($version.instance)', expected 'USGovGCCHigh'."
        exit 1
    }
    $endpointSets  = Invoke-RestMethod -Uri "$WebServiceRoot/endpoints/$Instance`?clientRequestId=$clientRequestId"
    $reportVersion = $version.latest
    $instanceName  = $version.instance
}

if ($instanceName -ne 'USGovGCCHigh') {
    Write-Error "FAIL: report source instance is '$instanceName', expected 'USGovGCCHigh'."
    exit 1
}

# --- Build report rows ----------------------------------------------------------------------------
$rows = foreach ($set in $endpointSets) {
    [pscustomobject]@{
        Id           = $set.id
        ServiceArea  = $set.serviceArea
        Category     = $set.category
        Required     = $set.required
        ExpressRoute = $set.expressRoute
        TcpPorts     = $set.tcpPorts
        UdpPorts     = $set.udpPorts
        Urls         = ($set.urls -join '; ')
        IpCount      = @($set.ips).Count
    }
}

$noInspect = @('*.manage.microsoft.us','has.spserv.microsoft.com','*.dm.microsoft.us')

# --- CSV -----------------------------------------------------------------------------------------
$csvPath = Join-Path $OutputFolder ("EGRESSG-Report-{0}.csv" -f $reportVersion)
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# --- Markdown ------------------------------------------------------------------------------------
$mdPath = Join-Path $OutputFolder ("EGRESSG-Report-{0}.md" -f $reportVersion)
$md = @()
$md += "# EGRESSG Audit Report — Microsoft 365 GCC High Egress Allow-List"
$md += ""
$md += "- Instance: **$instanceName**"
$md += "- Version: **$reportVersion**"
$md += "- Generated: $((Get-Date).ToString('s'))"
$md += "- Endpoint sets: $($endpointSets.Count)"
$md += ""
$md += "## Required endpoint sets by service area"
$md += ""
$md += "| ID | Service | Category | Required | ER | TCP | UDP | URLs | IPs |"
$md += "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"
foreach ($r in ($rows | Sort-Object ServiceArea, Id)) {
    $md += ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f `
        $r.Id, $r.ServiceArea, $r.Category, $r.Required, $r.ExpressRoute, $r.TcpPorts, $r.UdpPorts, $r.Urls, $r.IpCount)
}
$md += ""
$md += "## SSL-inspection bypass (EGRESSG-NoInspect-GCCHigh)"
$md += "These endpoints must NOT be SSL-inspected:"
$md += ($noInspect | ForEach-Object { "- ``$_``" })
$md += ""
$md += "> Microsoft IP ranges are derived from the USGovGCCHigh web service and change monthly; this"
$md += "> report is a point-in-time snapshot for change control. Re-run to refresh."
$md | Out-File $mdPath -Encoding utf8

Write-Host "Report written:"
Write-Host "  $mdPath"
Write-Host "  $csvPath"
Write-Host ""
Write-Host "PASS: GCC High audit report generated for version $reportVersion."
