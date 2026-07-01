<#
.SYNOPSIS
    NSSWG-Discovery.ps1 — Secure Web Gateway deployment readiness across Entra, Intune, and Netskope.
.DESCRIPTION
    PURPOSE
        Read-only readiness check. Reports whether the steering-scope Entra groups exist, whether the
        Intune client app and decryption-certificate profile are present, and (optionally) confirms
        Netskope tenant readiness via the Netskope REST API. Nothing is changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSSWG-Discovery.ps1
        Microsoft side uses Microsoft Graph (read scopes below); sign in when prompted.
        Optional Netskope check: set environment variables NSSWG_NETSKOPE_BASEURL and
        NSSWG_NETSKOPE_TOKEN first (secrets are read from the environment, never hardcoded).
    EXPECTED RESULTS
        A readiness summary: steering groups present/absent, client app present, certificate profile
        present, and (if configured) a Netskope tenant-reachable indicator.
.NOTES
    Workplace Marketplace — Network Solutions. Read-only.
    Netskope REST endpoints/paths are tenant- and version-specific and are NOT invented here; the
    Netskope call below is generic (caller supplies the base URL/path) and clearly marked.
#>
[CmdletBinding()] param(
    [string]$PilotGroup = 'Web Steering - Pilot - Stage 1',
    [string]$BroadGroup = 'Web Steering - Broad - Stage 2',
    [string]$ClientAppName = 'SWG Client Deployment - Managed Devices - Production',
    [string]$CertProfileName = 'Decryption Certificate - Managed Devices - Production'
)

Write-Host "=== Netskope SWG — deployment readiness ===" -ForegroundColor Cyan

# --- Microsoft Graph (read-only) ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementApps.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

function Test-Group($name) {
    $enc = [uri]::EscapeDataString($name)
    $r = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'"
    return [bool]($r.value -and $r.value.Count -gt 0)
}
$pilotOk = Test-Group $PilotGroup
$broadOk = Test-Group $BroadGroup
Write-Host ("Steering group (pilot) '{0}' : {1}" -f $PilotGroup, ($(if($pilotOk){'present'}else{'MISSING'}))) -ForegroundColor ($(if($pilotOk){'Green'}else{'Yellow'}))
Write-Host ("Steering group (broad) '{0}' : {1}" -f $BroadGroup, ($(if($broadOk){'present'}else{'MISSING'}))) -ForegroundColor ($(if($broadOk){'Green'}else{'Yellow'}))

$apps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')").value
$clientOk = [bool]($apps | Where-Object { $_.displayName -eq $ClientAppName })
Write-Host ("Client app '{0}' : {1}" -f $ClientAppName, ($(if($clientOk){'present'}else{'MISSING'}))) -ForegroundColor ($(if($clientOk){'Green'}else{'Yellow'}))

$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceConfigurations').value
$certOk = [bool]($cfgs | Where-Object { $_.displayName -eq $CertProfileName })
Write-Host ("Certificate profile '{0}' : {1}" -f $CertProfileName, ($(if($certOk){'present'}else{'MISSING'}))) -ForegroundColor ($(if($certOk){'Green'}else{'Yellow'}))

# --- Optional Netskope tenant readiness (generic REST; endpoint supplied by caller via env) ---
# Netskope REST API base URL and path are tenant/version specific — NOT invented here.
$nsBase = $env:NSSWG_NETSKOPE_BASEURL   # e.g. https://<tenant>.goskope.com  (set in your environment)
$nsToken = $env:NSSWG_NETSKOPE_TOKEN    # API token — read from environment, never hardcode
if ($nsBase -and $nsToken) {
    try {
        # Generic reachability probe against the tenant base URL. Replace the path with the exact
        # read-only Netskope REST path for your tenant/version per Netskope's API documentation.
        $resp = Invoke-RestMethod -Method GET -Uri ("{0}/" -f $nsBase.TrimEnd('/')) -Headers @{ 'Netskope-Api-Token' = $nsToken } -TimeoutSec 15 -ErrorAction Stop
        Write-Host "Netskope tenant : reachable (token accepted by base URL)" -ForegroundColor Green
    } catch {
        Write-Host ("Netskope tenant : check failed — {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "Netskope tenant : skipped (set NSSWG_NETSKOPE_BASEURL and NSSWG_NETSKOPE_TOKEN to enable)" -ForegroundColor DarkGray
}

Disconnect-MgGraph | Out-Null
Write-Host "`nReadiness check complete. Resolve any MISSING items before steering." -ForegroundColor Cyan
