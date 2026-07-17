<#
.SYNOPSIS
    GRAPHSUB-Discovery.ps1 — inventory Microsoft Graph change-notification subscriptions and the
    managed identity's application-permission grants. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Event-Driven Mail Processing with Microsoft Graph Change
        Notifications" solution. Lists the Graph change-notification subscriptions visible to the
        identity you authenticate as (resource, changeType, expirationDateTime, notificationUrl),
        flags any that are expired or expiring soon, and — for the Logic App's managed identity —
        lists the Microsoft Graph application-permission (app-role) grants. Makes no changes.
    HOW TO RUN
        pwsh -File .\GRAPHSUB-Discovery.ps1
        pwsh -File .\GRAPHSUB-Discovery.ps1 -ManagedIdentityDisplayName 'logic-mailevents-receiver-pilot'
        pwsh -File .\GRAPHSUB-Discovery.ps1 -ManagedIdentityObjectId '<mi object id>'
    GRAPH SCOPES (delegated, for interactive discovery)
        Subscription.Read.All        — read change-notification subscriptions
        Application.Read.All          — read the managed identity's service principal + app-role grants
        Directory.Read.All            — resolve the Microsoft Graph resource service principal
        (Connect with: Connect-MgGraph -Scopes 'Subscription.Read.All','Application.Read.All','Directory.Read.All')
    EXPECTED RESULTS
        A snapshot of current subscriptions with expiry state (OK / EXPIRING / EXPIRED) and the
        managed identity's Graph application-permission grants — the readiness picture before you
        validate or renew. NOTE: Graph subscriptions are owned by the identity that created them; an
        interactive delegated session may not see subscriptions created by the managed identity —
        verify against current Microsoft documentation and cross-check the Logic App run history.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reports on configuration/identifiers only; creates, renews, and deletes nothing.
    Verify all Graph specifics (max lifetime, supported resources, permission names, national-cloud
    endpoints) against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$ManagedIdentityDisplayName = 'logic-mailevents-receiver-pilot',
    [string]$ManagedIdentityObjectId,
    [int]$ExpiringWithinHours = 24,
    [string]$Environment = 'Global'   # 'Global' | 'USGov' | 'USGovDoD' — national clouds: verify with Microsoft
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment `
        -Scopes 'Subscription.Read.All','Application.Read.All','Directory.Read.All' | Out-Null
}

Write-Host "`n=== Event-Driven Mail Processing — Graph subscription discovery ===" -ForegroundColor Cyan
Write-Host ("Tenant: {0}" -f (Get-MgContext).TenantId)

# --- Change-notification subscriptions ---
Write-Host "`n-- Graph change-notification subscriptions --" -ForegroundColor Cyan
try {
    $subs = Get-MgSubscription -All -ErrorAction Stop
    if ($subs) {
        $now = (Get-Date).ToUniversalTime()
        foreach ($s in $subs) {
            $exp = [datetime]$s.ExpirationDateTime
            $state = if ($exp -lt $now) { 'EXPIRED' }
                     elseif ($exp -lt $now.AddHours($ExpiringWithinHours)) { 'EXPIRING' }
                     else { 'OK' }
            $color = switch ($state) { 'EXPIRED' {'Red'} 'EXPIRING' {'Yellow'} default {'Green'} }
            $urlHost = try { ([uri]$s.NotificationUrl).Host } catch { '(unparsable)' }
            Write-Host ("   [{0,-8}] {1}" -f $state, $s.Resource) -ForegroundColor $color
            Write-Host ("             id={0}  changeType={1}  expires={2:u}  url-host={3}" -f `
                        $s.Id, $s.ChangeType, $exp, $urlHost)
        }
    } else {
        Write-Host "   (none visible to this identity)" -ForegroundColor Yellow
        Write-Host "   NOTE: subscriptions are owned by their creator; the MI's subscriptions may not appear here." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("   Could not read subscriptions: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- Managed identity application-permission grants ---
Write-Host "`n-- Managed identity Graph application permissions --" -ForegroundColor Cyan
try {
    if ($ManagedIdentityObjectId) {
        $mi = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction Stop
    } else {
        $mi = Get-MgServicePrincipal -Filter "displayName eq '$ManagedIdentityDisplayName'" -ErrorAction Stop | Select-Object -First 1
    }
    if (-not $mi) {
        Write-Host ("   Managed identity '{0}' not found." -f $ManagedIdentityDisplayName) -ForegroundColor Yellow
    } else {
        Write-Host ("   Identity: {0}  (appId={1}, objectId={2})" -f $mi.DisplayName, $mi.AppId, $mi.Id)
        $graph = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction Stop
        $grants = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mi.Id -ErrorAction Stop
        $graphGrants = $grants | Where-Object { $_.ResourceId -eq $graph.Id }
        if ($graphGrants) {
            foreach ($g in $graphGrants) {
                $roleName = ($graph.AppRoles | Where-Object { $_.Id -eq $g.AppRoleId }).Value
                Write-Host ("   granted: {0}" -f $roleName) -ForegroundColor Green
            }
        } else {
            Write-Host "   (no Microsoft Graph application-permission grants)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host ("   Could not read app-role grants: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
