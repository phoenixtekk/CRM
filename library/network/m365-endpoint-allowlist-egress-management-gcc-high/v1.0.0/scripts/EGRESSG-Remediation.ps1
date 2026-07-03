<#
.SYNOPSIS
    EGRESSG-Remediation.ps1 — regenerate the corrected GCC High allow-list export and flag drift (safe by default: -WhatIf).
.DESCRIPTION
    PURPOSE
        Compares a saved allow-list export against the current GCC High set from the USGOVGCCHigh
        instance and reports drift (ranges/URLs to add or remove). By default it only previews
        (-WhatIf) and writes nothing. With -Execute it writes a corrected export file for you to
        import into your egress device — it never edits a firewall or proxy directly. No Microsoft
        IPs are hardcoded. Point it at your-output-folder and your-previous-export.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESSG-Remediation.ps1            (preview only)
        powershell -ExecutionPolicy Bypass -File .\EGRESSG-Remediation.ps1 -Execute   (write corrected export)
        (note the GCC High endpoints web-service instance: USGOVGCCHigh)
    EXPECTED RESULTS
        A drift summary (added/removed ranges and URLs). In preview mode nothing is written. With
        -Execute a corrected export is written. PASS when the current set is USGovGCCHigh; FAIL on
        wrong instance.
.NOTES
    White-label — the repeatable way. Read-only by default (-WhatIf); queries the GCC High endpoints web service.
#>

#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('USGOVGCCHigh')]
    [string]$Instance = 'USGOVGCCHigh',
    [string]$OutputFolder = (Join-Path $PSScriptRoot 'output'),
    [string]$WebServiceRoot = 'https://endpoints.office.com',
    # Prior export to compare against (defaults to the standard Discovery export).
    [string]$PreviousExport = (Join-Path $PSScriptRoot 'output\EGRESSG-Endpoints-USGovGCCHigh.json'),
    # Actually write the corrected export. Without this the script only previews (-WhatIf behavior).
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$clientRequestId = [guid]::NewGuid().Guid

# --- Current GCC High set -------------------------------------------------------------------------
$version = Invoke-RestMethod -Uri "$WebServiceRoot/version/$Instance`?clientRequestId=$clientRequestId"
if ($version.instance -ne 'USGovGCCHigh') {
    Write-Error "FAIL: web service returned instance '$($version.instance)', expected 'USGovGCCHigh'. Aborting."
    exit 1
}
$currentSets = Invoke-RestMethod -Uri "$WebServiceRoot/endpoints/$Instance`?clientRequestId=$clientRequestId"
$currentIps  = $currentSets | ForEach-Object { $_.ips } | Where-Object { $_ } | Sort-Object -Unique
$currentUrls = $currentSets | ForEach-Object { $_.urls } | Where-Object { $_ } | Sort-Object -Unique

# --- Prior set ------------------------------------------------------------------------------------
if (Test-Path $PreviousExport) {
    $prev     = Get-Content $PreviousExport -Raw | ConvertFrom-Json
    $prevIps  = $prev.endpointSets | ForEach-Object { $_.ips } | Where-Object { $_ } | Sort-Object -Unique
    $prevUrls = $prev.endpointSets | ForEach-Object { $_.urls } | Where-Object { $_ } | Sort-Object -Unique
} else {
    Write-Warning "No previous export at $PreviousExport — treating all current entries as additions."
    $prevIps = @(); $prevUrls = @()
}

# --- Diff -----------------------------------------------------------------------------------------
$ipsToAdd    = $currentIps  | Where-Object { $_ -notin $prevIps }
$ipsToRemove = $prevIps     | Where-Object { $_ -notin $currentIps }
$urlsToAdd   = $currentUrls | Where-Object { $_ -notin $prevUrls }
$urlsToRemove= $prevUrls    | Where-Object { $_ -notin $currentUrls }

Write-Host "GCC High drift summary (version $($version.latest)):"
Write-Host ("  IP ranges to ADD    : {0}" -f @($ipsToAdd).Count)
Write-Host ("  IP ranges to REMOVE : {0}" -f @($ipsToRemove).Count)
Write-Host ("  URLs to ADD         : {0}" -f @($urlsToAdd).Count)
Write-Host ("  URLs to REMOVE      : {0}" -f @($urlsToRemove).Count)
if (@($ipsToAdd).Count)  { Write-Host "`n  + IPs:";  $ipsToAdd  | ForEach-Object { Write-Host "    + $_" } }
if (@($urlsToAdd).Count) { Write-Host "`n  + URLs:"; $urlsToAdd | ForEach-Object { Write-Host "    + $_" } }
if (@($ipsToRemove).Count)  { $ipsToRemove  | ForEach-Object { Write-Host "    - $_" } }
if (@($urlsToRemove).Count) { $urlsToRemove | ForEach-Object { Write-Host "    - $_" } }

# --- Write corrected export (only with -Execute + ShouldProcess) ----------------------------------
$correctedPath = Join-Path $OutputFolder ("EGRESSG-Endpoints-USGovGCCHigh-corrected-{0}.json" -f $version.latest)

if (-not $Execute) {
    Write-Host ""
    Write-Host "PREVIEW ONLY (-WhatIf default). Re-run with -Execute to write the corrected export."
    Write-Host "No changes were made. This script never edits your firewall/proxy directly."
    exit 0
}

if ($PSCmdlet.ShouldProcess($correctedPath, 'Write corrected GCC High allow-list export')) {
    $corrected = [pscustomobject]@{
        instance     = $version.instance
        version      = $version.latest
        generated    = (Get-Date).ToString('s')
        endpointSets = $currentSets
    }
    $corrected | ConvertTo-Json -Depth 8 | Out-File $correctedPath -Encoding utf8
    Write-Host ""
    Write-Host "Corrected export written: $correctedPath"
    Write-Host "Import this into your egress device objects (EGRESSG-M365-GCCHigh-Allow / -URLs). No device was modified by this script."
    Write-Host "PASS: remediation export generated."
}
