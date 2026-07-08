<#
.SYNOPSIS
    ANDROIDAPP-AssignConfig.ps1 — stage a managed Google Play app assignment (intent/track/auto-update) and report managed-config attachment (-WhatIf by default, Graph).
.DESCRIPTION
    PURPOSE
        Previews (and, with -Commit, applies) an assignment for one managed Google Play app: intent,
        target group, update track(s), and auto-update mode. Because the Graph 'assign' action REPLACES
        ALL of an app's assignments, this reads the current set and writes the current set PLUS the new
        assignment — never clobbering existing groups. Also reports whether an app-config policy is
        attached for the app's package.
    HOW TO RUN
        Preview:  powershell -ExecutionPolicy Bypass -File .\ANDROIDAPP-AssignConfig.ps1 -PackageId com.microsoft.office.outlook -GroupId <entra-group-guid> -Intent required -AutoUpdateMode default -WhatIf
        Apply:    ...same... -Commit
        Requires the Microsoft Graph SDK; read uses DeviceManagementApps.Read.All, -Commit needs DeviceManagementApps.ReadWrite.All.
    EXPECTED RESULTS
        Prints current assignments + the intended new assignment (and app-config status). With -Commit,
        the app has the new assignment. PASS = the app shows the intended intent/group/track afterward.
.NOTES
    White-label — Android Solutions. Safe by default (-WhatIf); writes only with -Commit. No credentials stored.
.EXAMPLE
    .\ANDROIDAPP-AssignConfig.ps1 -PackageId com.microsoft.office.outlook -GroupId 1111-2222 -Intent required -WhatIf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PackageId,
    [Parameter(Mandatory)][string]$GroupId,
    [ValidateSet('required','available','availableWithoutEnrollment','uninstall')][string]$Intent = 'required',
    [ValidateSet('default','postponed','priority','unavailable')][string]$AutoUpdateMode = 'default',
    [string[]]$TrackIds,
    [switch]$Commit,
    [switch]$WhatIf
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Commit) { 'DeviceManagementApps.ReadWrite.All' } else { 'DeviceManagementApps.Read.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

# 1) Find the managed Google Play app by package id.
$apps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$expand=assignments").value |
        Where-Object { ($_.packageId -eq $PackageId) -or ($_.appIdentifier -eq $PackageId) }
if (-not $apps) { Write-Host "No managed Google Play app with package '$PackageId' — approve+sync it first." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
$app = $apps | Select-Object -First 1
Write-Host ("App: {0}  (id {1})" -f $app.displayName, $app.id) -ForegroundColor Cyan

# 2) Show current assignments (the set the 'assign' action will otherwise overwrite).
Write-Host "`nCurrent assignments:" -ForegroundColor Cyan
if ($app.assignments) { $app.assignments | ForEach-Object { Write-Host ("  intent={0} groupId={1} track(s)={2} autoUpdate={3}" -f $_.intent, $_.target.groupId, ($_.settings.androidManagedStoreAppTrackIds -join ';'), $_.settings.autoUpdateMode) } }
else { Write-Host "  (none)" }

# 3) Report app-config attachment for this package.
$cfg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileAppConfigurations").value |
       Where-Object { $_.'@odata.type' -eq '#microsoft.graph.androidManagedStoreAppConfiguration' -and $_.packageId -eq $PackageId }
Write-Host ("`nManaged app configuration for {0}: {1}" -f $PackageId, ($(if ($cfg) { ($cfg.displayName -join ', ') } else { 'NONE — app will arrive unconfigured' }))) -ForegroundColor ($(if ($cfg) { 'Green' } else { 'Yellow' }))

# 4) Build the FULL intended assignment set = existing (minus same group) + the new one.
$settings = @{ '@odata.type' = '#microsoft.graph.androidManagedStoreAppAssignmentSettings'; autoUpdateMode = $AutoUpdateMode }
if ($TrackIds) { $settings.androidManagedStoreAppTrackIds = @($TrackIds) }
$newAssignment = @{
    '@odata.type' = '#microsoft.graph.mobileAppAssignment'
    intent        = $Intent
    target        = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId }
    settings      = $settings
}
$preserved = @()
foreach ($a in $app.assignments) {
    if ($a.target.groupId -eq $GroupId) { continue }  # replace any existing assignment for the same group
    $preserved += @{ '@odata.type'='#microsoft.graph.mobileAppAssignment'; intent=$a.intent; target=$a.target; settings=$a.settings }
}
$full = @{ mobileAppAssignments = @($preserved + $newAssignment) }

Write-Host "`nINTENDED new assignment:" -ForegroundColor Cyan
Write-Host ("  intent={0} groupId={1} track(s)={2} autoUpdate={3}" -f $Intent, $GroupId, ($TrackIds -join ';'), $AutoUpdateMode)

if ($Commit -and -not $WhatIf) {
    Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceAppManagement/mobileApps/$($app.id)/assign" -Body ($full | ConvertTo-Json -Depth 8)
    Write-Host "`nCOMMIT: assignment applied (full set re-sent to preserve other groups)." -ForegroundColor Green
} else {
    Write-Host "`n-WhatIf: no change written. Re-run with -Commit to apply (the FULL set above is sent to avoid dropping other groups)." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
