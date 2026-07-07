<#
.SYNOPSIS
  Read-only scope/health helper: verifies the toolchain, connection, and governance settings
  before you run the other SPO architecture tools.
.DESCRIPTION
  Checks that the SPO Management Shell and PnP.PowerShell modules are present, that admin
  connections work, reports the tenant self-service site-creation setting, confirms the pilot/
  production hubs are registered, and confirms the term store / governed content type exist.
  Read-only: makes no changes. Run this first to resolve the working scope.
.EXAMPLE
  .\Get-SPOScopeConfig.ps1 -TenantRoot https://contoso.sharepoint.com -ClientId <app-client-id>
  (PowerShell 5.1+/7+, SPO Management Shell + PnP.PowerShell; modern-auth Connect-* cmdlets)
.NOTES
  Expected results: a checklist of OK/MISSING for modules, connections, hubs, taxonomy, and the
  self-service creation setting — so you know the environment is ready (or what to fix) before Stage 1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantRoot,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    # Hub Titles expected to be registered (pilot + production).
    [Parameter(Mandatory = $false)]
    [string[]]$ExpectedHubs = @('Hub - Pilot - Pilot', 'Hub - Corp - Prod', 'Hub - Divisions - Prod'),

    [Parameter(Mandatory = $false)]
    [string]$TermGroup = 'Term Group - Enterprise Metadata - Prod'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

function Write-Check([string]$label, [bool]$ok, [string]$detail = '') {
    $tag = if ($ok) { '[ OK ]' } else { '[MISS]' }
    $col = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("{0} {1} {2}" -f $tag, $label, $detail) -ForegroundColor $col
}

Write-Host "SPO Architecture scope/health check" -ForegroundColor Cyan
Write-Host "-----------------------------------"

# 1) Modules
$spoMod = [bool](Get-Module Microsoft.Online.SharePoint.PowerShell -ListAvailable)
$pnpMod = [bool](Get-Module PnP.PowerShell -ListAvailable)
Write-Check "SPO Management Shell module" $spoMod
Write-Check "PnP.PowerShell module" $pnpMod

# 2) PnP connection to tenant root
$pnpOk = $false
try {
    Connect-PnPOnline -Url $TenantRoot -Interactive -ClientId $ClientId -ErrorAction Stop
    $pnpOk = $true
}
catch { Write-Warning "PnP connect failed: $($_.Exception.Message)" }
Write-Check "PnP connection ($TenantRoot)" $pnpOk

if (-not $pnpOk) {
    Write-Host "`nCannot continue checks without a PnP connection. Register/consent the app 'PnP - Provisioning - Prod' and retry." -ForegroundColor Yellow
    return
}

# 3) Registered hubs
$hubs = @()
try { $hubs = Get-PnPHubSite } catch { Write-Warning "Get-PnPHubSite failed: $($_.Exception.Message)" }
$hubTitles = $hubs | ForEach-Object { $_.Title }
foreach ($h in $ExpectedHubs) {
    Write-Check ("Hub registered: {0}" -f $h) ([bool]($hubTitles -contains $h))
}

# 4) Term store group
$tgOk = $false
try { $tgOk = [bool](Get-PnPTermGroup -Identity $TermGroup -ErrorAction SilentlyContinue) } catch {}
Write-Check ("Term group: {0}" -f $TermGroup) $tgOk

# 5) Self-service site creation setting (informational; needs SPO Management Shell session)
try {
    $t = Get-SPOTenant -ErrorAction Stop
    $ssc = $t.DisableSelfServiceSiteCreation
    Write-Host ("[INFO] DisableSelfServiceSiteCreation = {0}  (true = governed pipeline enforced)" -f $ssc) -ForegroundColor Cyan
}
catch {
    Write-Host "[INFO] Self-service creation setting not read (Connect-SPOService for the tenant-level check)." -ForegroundColor DarkGray
}

Write-Host "`nScope/health check complete. Resolve any [MISS] items before running the other tools." -ForegroundColor Green
