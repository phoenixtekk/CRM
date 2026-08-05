<#
.SYNOPSIS
    INTBASE-Remediation.ps1 — guarded fix for the two common first-time enrollment blockers.

.DESCRIPTION
    PURPOSE
        Optionally repair the two settings that most often block first-time Windows enrollment:
          (1) the Intune Provisioning Client is not an OWNER of the Autopilot device group used for
              enrollment-time grouping, and
          (2) Windows automatic-enrollment MDM user scope does not include the pilot group.
        Defaults to a safe preview (-WhatIf behaviour): it reports what it WOULD change and makes no
        changes unless -Apply is passed.

    HOW TO RUN
        Connect-MgGraph -Environment Global -Scopes "Group.ReadWrite.All","Directory.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All"
        # Government: Connect-MgGraph -Environment USGov   (or USGovDoD)
        .\INTBASE-Remediation.ps1                 # preview only (default, no changes)
        .\INTBASE-Remediation.ps1 -Apply          # actually add the group owner

    EXPECTED RESULTS
        Preview mode: a list of intended changes, nothing modified. -Apply: adds the Intune Provisioning
        Client as an owner of the Autopilot group if missing. Scope changes are reported for manual
        confirmation.

.NOTES
    Intune Solutions — write-capable ONLY with -Apply; otherwise read-only preview.
#>
[CmdletBinding()]
param(
    [string]$AutopilotGroupName = "INTBASE - Autopilot Devices",
    [string]$ProvisioningClientAppId = "f1346770-5b25-470b-88bd-d5744ab7952c",
    [switch]$Apply
)

if (-not (Get-MgContext)) { Write-Host "Not connected. Run Connect-MgGraph first." -ForegroundColor Red; exit 1 }
$mode = if ($Apply) { 'APPLY' } else { 'PREVIEW (-WhatIf) — no changes' }
Write-Host "`n=== INTBASE Remediation — mode: $mode ===" -ForegroundColor Cyan

# Resolve the Autopilot group
$g = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f ($AutopilotGroupName -replace "'", "''"))
$grp = $g.value | Select-Object -First 1
if (-not $grp) { Write-Host "Group '$AutopilotGroupName' not found. Create it (Assigned) first." -ForegroundColor Yellow; exit 2 }

# Resolve the Intune Provisioning Client service principal
$sp = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/servicePrincipals?`$filter=appId eq '{0}'" -f $ProvisioningClientAppId)
$spObj = $sp.value | Select-Object -First 1
if (-not $spObj) {
    Write-Host "Intune Provisioning Client SP not found in tenant. Open the Intune admin center once as Global Admin to provision it, then retry." -ForegroundColor Yellow
    exit 3
}

# Is it already an owner?
$owners = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/owners" -f $grp.id)
$already = @($owners.value | ForEach-Object { $_.appId }) -contains $ProvisioningClientAppId

if ($already) {
    Write-Host "OK: Intune Provisioning Client already OWNS '$AutopilotGroupName'. No change needed." -ForegroundColor Green
} else {
    Write-Host "NEEDS FIX: Intune Provisioning Client is NOT an owner of '$AutopilotGroupName'." -ForegroundColor Yellow
    if ($Apply) {
        $body = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($spObj.id)" }
        Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/owners/`$ref" -f $grp.id) -Body ($body | ConvertTo-Json)
        Write-Host "APPLIED: added Intune Provisioning Client as owner of '$AutopilotGroupName'." -ForegroundColor Green
    } else {
        Write-Host "WOULD ADD: Intune Provisioning Client (AppId $ProvisioningClientAppId) as owner. Re-run with -Apply." -ForegroundColor Cyan
    }
}

Write-Host "`nReminder: confirm Windows Automatic Enrollment MDM user scope includes 'INTBASE - Windows Users - Pilot'" -ForegroundColor Cyan
Write-Host "(Intune admin center > Devices > Enrollment > Windows > Automatic Enrollment). Scope is set in the portal." -ForegroundColor Cyan
