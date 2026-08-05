<#
.SYNOPSIS
    WIFIMGT-Preflight.ps1 — checks tenant readiness for Intune Wi-Fi profile deployment (read-only, cloud-aware).
.DESCRIPTION
    PURPOSE
        Confirms the tenant is ready to deploy Wi-Fi configuration profiles: the Microsoft.Graph SDK is
        available, Graph connects with the required read scopes, an Apple MDM Push (APNs) certificate is
        present (for iOS/iPadOS), the Android Enterprise (managed Google Play) binding exists, and the
        pilot assignment group is present. Nothing is changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Preflight.ps1
        Sovereign cloud:  .\WIFIMGT-Preflight.ps1 -Environment USGov      (or USGovDoD)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementServiceConfig.Read.All, Group.Read.All
    EXPECTED RESULTS
        A PASS/GAP checklist and an overall verdict. Read-only against Microsoft Graph.
.NOTES
    White-label — Intune Solutions. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string] $PilotGroup = 'WIFIMGT - Pilot Devices'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph SDK not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes @(
    'DeviceManagementConfiguration.Read.All',
    'DeviceManagementServiceConfig.Read.All',
    'Group.Read.All'
) -NoWelcome
Write-Host "Connected to Graph ($Environment) tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan

function Get-All($uri) {
    $out = @(); $next = $uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}
function Show-Check($label, $ok, $note) {
    $tag = if ($ok) { 'PASS' } else { 'GAP ' }
    Write-Host ("  [{0}] {1} {2}" -f $tag, $label, $note) -ForegroundColor ($(if($ok){'Green'}else{'Red'}))
}

Write-Host "`n=== WIFIMGT preflight ===" -ForegroundColor Yellow

# 1) Graph scopes
$ctx = Get-MgContext
$scopeOk = ($ctx.Scopes -contains 'DeviceManagementConfiguration.Read.All')
Show-Check 'Graph read scopes granted' $scopeOk ''

# 2) Apple MDM Push (APNs) — required for iOS/iPadOS Wi-Fi
$apnsOk = $false; $apnsNote = '(iOS/iPadOS)'
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/applePushNotificationCertificate'
    if ($apns -and $apns.expirationDateTime) {
        $apnsOk = ([datetime]$apns.expirationDateTime -gt (Get-Date))
        $apnsNote = "expires $($apns.expirationDateTime)"
    }
} catch { $apnsNote = '(not configured — iOS/iPadOS Wi-Fi will not deploy)' }
Show-Check 'Apple MDM Push (APNs) valid' $apnsOk $apnsNote

# 3) Android Enterprise binding — required for Android Wi-Fi
$aeOk = $false
try {
    $ae = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
    $aeOk = ($ae -and $ae.bindStatus -eq 'boundAndValidated')
    Show-Check 'Android Enterprise (managed Google Play) bound' $aeOk "($($ae.bindStatus))"
} catch { Show-Check 'Android Enterprise (managed Google Play) bound' $false '(not configured)' }

# 4) Pilot group present
$grp = @()
try { $grp = Get-All "/v1.0/groups?`$filter=displayName eq '$($PilotGroup.Replace("'","''"))'&`$select=id,displayName" } catch {}
Show-Check "Pilot group '$PilotGroup' exists" ($grp.Count -gt 0) ''

Write-Host "`nOverall: review any [GAP] lines above before authoring Wi-Fi profiles." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
