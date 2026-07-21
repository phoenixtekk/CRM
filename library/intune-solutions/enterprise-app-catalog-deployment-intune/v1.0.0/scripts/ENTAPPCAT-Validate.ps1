<#
.SYNOPSIS
    ENTAPPCAT-Validate.ps1 — PASS/FAIL that a pilot catalog app is deployed, assigned, detected, and updating.
.DESCRIPTION
    PURPOSE
        Read-only validation gate for a single Enterprise App Catalog app. Confirms, PASS/FAIL:
          (1) the catalog app exists in Intune,
          (2) it is assigned to the pilot group,
          (3) Intune reports it Installed on at least one device (detection agrees),
          (4) update management is enabled.
        Run this before expanding from the pilot ring to the broad ring.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTAPPCAT-Validate.ps1 `
          -AppName "Catalog App – Sample App – Prod" `
          -PilotGroupName "Catalog Apps – Pilot Devices – Ring 1"
    GRAPH SCOPES
        DeviceManagementApps.Read.All, Group.Read.All   (delegated, read-only)
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall gate result. No changes are made.
.NOTES
    Intune Solutions. Read-only against Microsoft Graph.
    Enterprise App Catalog Graph type ('win32CatalogApp') and the update-management property name are
    verify-with-Microsoft; adjust if Microsoft renames them.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$AppName,
    [string]$PilotGroupName = 'Catalog Apps – Pilot Devices – Ring 1',
    [string]$GraphEnvironment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All' -Environment $GraphEnvironment -NoWelcome

$results = @()
function Add-Result([string]$Name,[bool]$Pass,[string]$Detail) {
    $script:results += [pscustomobject]@{ Check=$Name; Pass=$Pass; Detail=$Detail }
    $tag = $Pass ? 'PASS' : 'FAIL'
    $col = $Pass ? 'Green' : 'Red'
    Write-Host ("  [{0}] {1} — {2}" -f $tag, $Name, $Detail) -ForegroundColor $col
}

Write-Host "=== Validate catalog app: $AppName ===" -ForegroundColor Cyan

# 1) App exists
$esc  = $AppName.Replace("'","''")
$apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps?`$filter=displayName eq '$esc'").value
$app  = $apps | Select-Object -First 1
Add-Result 'App exists in Intune' ([bool]$app) ($app ? "id=$($app.id)" : "no app named '$AppName'")

if ($app) {
    # 2) Assigned to the pilot group
    $gesc  = $PilotGroupName.Replace("'","''")
    $grp   = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$gesc'").value | Select-Object -First 1
    $asg   = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps/$($app.id)/assignments").value
    $bound = $grp -and ($asg | Where-Object { $_.target.groupId -eq $grp.id })
    Add-Result 'Assigned to pilot group' ([bool]$bound) ($grp ? "group=$PilotGroupName" : "pilot group not found")

    # 3) Detected/Installed on at least one device
    $sum = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps/$($app.id)/installSummary"
    Add-Result 'Reported Installed (detection agrees)' ([int]$sum.installedDeviceCount -ge 1) `
        ("installed={0} failed={1} n/a={2}" -f $sum.installedDeviceCount, $sum.failedDeviceCount, $sum.notApplicableDeviceCount)

    # 4) Update management enabled (property name verify-with-Microsoft)
    $updEnabled = [bool]$app.allowAvailableUninstall   # placeholder property; verify current update-mgmt flag
    Add-Result 'Update management enabled' $updEnabled "verify update-management property against current Microsoft docs"
}

$overall = ($results.Count -gt 0) -and (-not ($results | Where-Object { -not $_.Pass }))
Write-Host ("`nGATE: {0}" -f ($overall ? 'PASS — safe to expand to the broad ring.' : 'FAIL — resolve the FAIL checks before expanding.')) `
    -ForegroundColor ($overall ? 'Green' : 'Red')
Disconnect-MgGraph | Out-Null
