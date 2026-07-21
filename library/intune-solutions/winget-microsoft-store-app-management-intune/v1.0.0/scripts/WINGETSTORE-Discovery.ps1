<#
.SYNOPSIS
    WINGETSTORE-Discovery.ps1 — inventory the Microsoft Store (new / winget-backed) apps deployed in
    Intune, their assignments, and self-service availability (Microsoft Graph, read-only).
.DESCRIPTION
    PURPOSE
        Read-only discovery of Windows Store (new) / winget apps in Intune. Lists each app, its
        publisher, and its assignments broken down as Required / Available (self-service via Company
        Portal) / Uninstall — so you can see, at a glance, which mainstream apps are deployed and which
        are offered for self-service. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK.
    GRAPH SCOPES
        DeviceManagementApps.Read.All   (read app definitions + assignments)
    EXPECTED RESULTS
        A per-app summary: display name, publisher, and each assignment's intent (required / available /
        uninstall) with the target group id. No data is modified.
.NOTES
    Intune Solutions — read-only. The Graph type for the new Store app is 'microsoft.graph.winGetApp';
    confirm the current type/behavior against Microsoft documentation (verify-with-Microsoft).
#>
[CmdletBinding()]
param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

# Microsoft Store app (new) = winGetApp
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.winGetApp')"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

if (-not $apps) {
    Write-Host "No Microsoft Store (new) / winget apps found in this tenant." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

Write-Host ("=== {0} Microsoft Store (new) / winget app(s) ===" -f $apps.Count) -ForegroundColor Cyan
foreach ($app in $apps) {
    Write-Host ("`n{0}" -f $app.displayName) -ForegroundColor Green
    Write-Host ("  Publisher: {0}" -f $app.publisher)
    $as = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($app.id)/assignments").value
    if (-not $as) { Write-Host "  Assignments: (none)" -ForegroundColor Yellow; continue }
    foreach ($a in $as) {
        $intent = $a.intent                      # required | available | uninstall
        $grp    = $a.target.groupId
        $self   = if ($intent -eq 'available') { ' (self-service via Company Portal)' } else { '' }
        Write-Host ("  Assignment: {0}{1}  -> group {2}" -f $intent, $self, $grp)
    }
}
Disconnect-MgGraph | Out-Null
