<#
.SYNOPSIS
    SPMAM-Discovery.ps1 — inventory App Protection Policies + Conditional Access policies for
    SharePoint Online mobile access, with their assignments (Microsoft Graph). Read-only.
.DESCRIPTION
    PURPOSE
        Lists the iOS/Android App Protection Policies (MAM) and the Conditional Access policies that
        gate SharePoint Online / Office 365, showing which apps and which groups each targets — the
        starting point for aligning APP + CA before deploying or when diagnosing a mobile-access block.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SPMAM-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. Consented scopes (read-only):
        DeviceManagementApps.Read.All, Policy.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A list of App Protection Policies (with targeted apps + assigned groups) and a list of
        Conditional Access policies that target Office 365 with an app-protection / approved-app
        grant (with included/excluded groups).
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Policy.Read.All','Group.Read.All' -NoWelcome

function Resolve-GroupName([string]$id) {
    if (-not $id) { return '' }
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id?`$select=displayName").displayName }
    catch { $id }
}

Write-Host "`n=== App Protection Policies (MAM) ===" -ForegroundColor Cyan
$appPolicies = @()
foreach ($seg in 'iosManagedAppProtections','androidManagedAppProtections') {
    $uri = "/beta/deviceAppManagement/$seg`?`$expand=apps,assignments"
    try {
        do {
            $r = Invoke-MgGraphRequest -Method GET -Uri $uri
            $appPolicies += $r.value
            $uri = $r.'@odata.nextLink'
        } while ($uri)
    } catch { Write-Host "  (could not read $seg): $($_.Exception.Message)" -ForegroundColor Yellow }
}
if (-not $appPolicies) { Write-Host "  No App Protection Policies found." -ForegroundColor Yellow }
foreach ($p in $appPolicies) {
    $apps    = ($p.apps      | ForEach-Object { $_.mobileAppIdentifier.bundleId; $_.mobileAppIdentifier.packageId } | Where-Object { $_ }) -join ', '
    $groups  = ($p.assignments | ForEach-Object { Resolve-GroupName $_.target.groupId } | Where-Object { $_ }) -join ', '
    Write-Host ("  {0}" -f $p.displayName) -ForegroundColor Green
    Write-Host ("     apps   : {0}" -f $apps)
    Write-Host ("     groups : {0}" -f $groups)
}

Write-Host "`n=== Conditional Access policies gating SharePoint Online / Office 365 ===" -ForegroundColor Cyan
$ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$spo = $ca | Where-Object {
    ($_.grantControls.builtInControls -contains 'compliantApplication') -or
    ($_.grantControls.builtInControls -contains 'approvedApplication')
}
if (-not $spo) { Write-Host "  No CA policy with an app-protection / approved-app grant found." -ForegroundColor Yellow }
foreach ($c in $spo) {
    $inc = ($c.conditions.users.includeGroups | ForEach-Object { Resolve-GroupName $_ }) -join ', '
    $exc = ($c.conditions.users.excludeGroups | ForEach-Object { Resolve-GroupName $_ }) -join ', '
    Write-Host ("  {0}  [state: {1}]" -f $c.displayName, $c.state) -ForegroundColor Green
    Write-Host ("     grant     : {0}" -f (($c.grantControls.builtInControls) -join ', '))
    Write-Host ("     platforms : {0}" -f (($c.conditions.platforms.includePlatforms) -join ', '))
    Write-Host ("     include   : {0}" -f $inc)
    Write-Host ("     exclude   : {0}" -f $exc)
}

Disconnect-MgGraph | Out-Null
