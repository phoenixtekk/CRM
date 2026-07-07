<#
.SYNOPSIS
  SPOEXT-Scope.ps1 — read-only readiness/health check: modules, connections, cloud, and pilot-scope resolution. Makes NO changes.
.DESCRIPTION
  Scope/health helper for Stage 0. Verifies the toolchain (SPO Management Shell, PnP, Graph) is present,
  confirms the SPO admin connection, resolves and validates the pilot site list (each URL exists and is
  reachable), warns if OneDriveSharingCapability is looser than the tenant, and flags Government-cloud
  hosts so you use the right admin/Graph endpoints. Read-only — it never changes settings. Run it before
  Configure to catch environment gaps early.
.EXAMPLE
  .\SPOEXT-Scope.ps1 -SiteScope (Get-Content .\pilot-sites.txt)
  # Check readiness and confirm every pilot site URL resolves.
  # (PowerShell 5.1+/7+, Microsoft.Online.SharePoint.PowerShell; connect with Connect-SPOService.)
.NOTES
  Expected results: a checklist of PASS/WARN lines. Any WARN is an environment gap to fix before Stage 2.
  SharePoint — External Sharing & Access Governance.
#>
[CmdletBinding()]
param(
    [string[]]$SiteScope
)

$warn = 0
function Show-Check { param($ok,$msg) if ($ok) { Write-Host ("  PASS  {0}" -f $msg) -ForegroundColor Green } else { Write-Host ("  WARN  {0}" -f $msg) -ForegroundColor Yellow; $script:warn++ } }

Write-Host '=== SPOEXT readiness / health (read-only) ===' -ForegroundColor Cyan

# 1. Modules
Show-Check ([bool](Get-Module -ListAvailable Microsoft.Online.SharePoint.PowerShell)) 'SharePoint Online Management Shell installed'
Show-Check ([bool](Get-Module -ListAvailable PnP.PowerShell))                          'PnP.PowerShell installed (for exposure report)'
Show-Check ([bool](Get-Module -ListAvailable Microsoft.Graph))                          'Microsoft.Graph installed (for guests / access reviews)'

# 2. SPO admin connection
$t = $null
try { $t = Get-SPOTenant -ErrorAction Stop; Show-Check $true 'Connected to the SharePoint admin endpoint' }
catch { Show-Check $false 'NOT connected — run Connect-SPOService -Url https://<tenant>-admin.sharepoint.com'; }

if ($t) {
    # 3. Cloud detection (Commercial vs Government)
    $siteHost = ''
    try { $siteHost = (Get-SPOSite -Limit 1 -ErrorAction SilentlyContinue | Select-Object -First 1).Url } catch {}
    if ($siteHost -match '\.sharepoint\.us') {
        Write-Host '  INFO  Government cloud detected (*.sharepoint.us) — use the .us admin host and Connect-MgGraph -Environment USGov/USGovDoD.' -ForegroundColor Cyan
    } elseif ($siteHost) {
        Write-Host '  INFO  Commercial cloud (*.sharepoint.com).' -ForegroundColor Cyan
    }

    # 4. OneDrive not looser than tenant
    $order = @{ Disabled=0; ExistingExternalUserSharingOnly=1; ExternalUserSharingOnly=2; ExternalUserAndGuestSharing=3 }
    Show-Check ($order[$t.OneDriveSharingCapability] -le $order[$t.SharingCapability]) `
        ("OneDrive ({0}) is not looser than tenant ({1})" -f $t.OneDriveSharingCapability, $t.SharingCapability)

    Write-Host ("  INFO  Tenant SharingCapability = {0} | DomainMode = {1}" -f $t.SharingCapability, $t.SharingDomainRestrictionMode) -ForegroundColor Cyan
}

# 5. Resolve pilot scope
if ($SiteScope) {
    Write-Host '--- Resolving pilot scope (Sharing Scope - Pilot - Stage1) ---' -ForegroundColor Cyan
    foreach ($url in $SiteScope) {
        try {
            $s = Get-SPOSite -Identity $url -ErrorAction Stop
            Show-Check $true ("{0} — reachable (SharingCapability {1})" -f $url, $s.SharingCapability)
        } catch {
            Show-Check $false ("{0} — NOT reachable: {1}" -f $url, $_.Exception.Message)
        }
    }
}

Write-Host ''
if ($warn -eq 0) { Write-Host 'READY — environment checks passed.' -ForegroundColor Green }
else { Write-Host ("{0} warning(s) — resolve before Stage 2 (Configure)." -f $warn) -ForegroundColor Yellow }
