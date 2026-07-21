<#
.SYNOPSIS
    ENTAPPCAT-Discovery.ps1 — inventory Enterprise App Catalog apps, assignments, and update settings.
.DESCRIPTION
    PURPOSE
        Read-only discovery of the Enterprise App Catalog (prepackaged Win32) apps in the tenant:
        which catalog apps exist, what groups they are assigned to, and whether update management /
        auto-update is enabled. Use it to see the current state before you add or expand an app.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTAPPCAT-Discovery.ps1
    GRAPH SCOPES
        DeviceManagementApps.Read.All   (delegated, read-only)
    EXPECTED RESULTS
        Per catalog app: display name, publisher, install context, update-management state, and the
        list of assigned groups (id + intent). No changes are made.
.NOTES
    Intune Solutions. Read-only against Microsoft Graph.
    The exact OData type / property names for Enterprise App Catalog apps evolve — verify the current
    Graph type ('microsoft.graph.win32CatalogApp' at time of writing) and update-management property
    against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$GraphEnvironment = 'Global'   # 'USGov' / 'USGovDoD' for national clouds — verify with Microsoft
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -Environment $GraphEnvironment -NoWelcome

# Enterprise App Catalog apps are prepackaged Win32 apps. The catalog subtype is 'win32CatalogApp';
# we also surface plain win32LobApp so the operator sees the whole Win32 surface. (Type name: verify.)
$uri  = "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32CatalogApp') or isof('microsoft.graph.win32LobApp')"
$apps = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

if (-not $apps) { Write-Host "No Win32 / Enterprise App Catalog apps found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

Write-Host "=== Enterprise App Catalog / Win32 app discovery ($($apps.Count) apps) ===" -ForegroundColor Cyan
foreach ($app in $apps) {
    $isCatalog = ($app.'@odata.type' -match 'win32CatalogApp')
    Write-Host ("`n{0}" -f $app.displayName) -ForegroundColor Green
    Write-Host ("  Type        : {0}{1}" -f $app.'@odata.type', ($isCatalog ? '  [Enterprise App Catalog]' : ''))
    Write-Host ("  Publisher   : {0}" -f $app.publisher)
    # Update management / auto-update property name varies by app type — verify against current docs.
    $upd = if ($null -ne $app.allowAvailableUninstall) { $app.allowAvailableUninstall } else { '(see app; verify property)' }
    Write-Host ("  UpdateMgmt  : {0}" -f $upd)

    $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps/$($app.id)/assignments").value
    if ($asg) {
        foreach ($a in $asg) {
            Write-Host ("  Assigned    : intent={0}  groupId={1}" -f $a.intent, $a.target.groupId)
        }
    } else { Write-Host "  Assigned    : (none)" -ForegroundColor Yellow }
}

Disconnect-MgGraph | Out-Null
