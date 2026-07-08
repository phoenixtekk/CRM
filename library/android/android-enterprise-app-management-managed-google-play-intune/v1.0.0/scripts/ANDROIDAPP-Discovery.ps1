<#
.SYNOPSIS
    ANDROIDAPP-Discovery.ps1 — inventory managed Google Play apps + assignment posture (read-only, Graph).
.DESCRIPTION
    PURPOSE
        Lists Android Enterprise (managed Google Play) apps published to Intune — store, private, and
        web — with each app's assignments: intent, target group, update track(s), and auto-update mode.
        Read-only; safe to run any time to baseline your app-delivery posture.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDAPP-Discovery.ps1 -CsvPath C:\Temp\android-apps.csv
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        One line per app+assignment (Intent / GroupId / Tracks / AutoUpdate), plus an optional CSV.
        PASS = every intended app appears with the expected intent, group, and track.
.NOTES
    White-label — Android Solutions. Read-only against Microsoft Graph. No credentials stored.
.EXAMPLE
    .\ANDROIDAPP-Discovery.ps1 -WhatIf
#>
[CmdletBinding()] param([string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

# Managed Google Play app @odata.types (store / web). Private LOB apps also surface as store apps.
$androidTypes = @(
    '#microsoft.graph.androidManagedStoreApp',
    '#microsoft.graph.androidManagedStoreWebApp'
)
$intentMap = @{ required='Required'; available='Available'; availableWithoutEnrollment='Available (no enrollment)'; uninstall='Uninstall' }

$rows = @()
$uri  = "/v1.0/deviceAppManagement/mobileApps?`$expand=assignments"
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($app in $resp.value) {
        if ($androidTypes -notcontains $app.'@odata.type') { continue }
        $pkg = $app.packageId; if (-not $pkg) { $pkg = $app.appIdentifier }
        if (-not $app.assignments -or $app.assignments.Count -eq 0) {
            $rows += [pscustomobject]@{ App=$app.displayName; Package=$pkg; Intent='(unassigned)'; GroupId=''; Tracks=''; AutoUpdate='' }
            continue
        }
        foreach ($a in $app.assignments) {
            $s = $a.settings
            $tracks = ''
            if ($s.androidManagedStoreAppTrackIds) { $tracks = ($s.androidManagedStoreAppTrackIds -join ';') }
            $rows += [pscustomobject]@{
                App        = $app.displayName
                Package    = $pkg
                Intent     = $(if ($intentMap[$a.intent]) { $intentMap[$a.intent] } else { $a.intent })
                GroupId    = $a.target.groupId
                Tracks     = $tracks
                AutoUpdate = $s.autoUpdateMode
            }
        }
    }
    $uri = $resp.'@odata.nextLink'
} while ($uri)

if (-not $rows) {
    Write-Host "No managed Google Play apps found — confirm the connection is bound and apps are synced (ANDROIDAPP-Scope.ps1)." -ForegroundColor Yellow
} else {
    $rows | Sort-Object App, Intent | Format-Table -AutoSize
    $unassigned = ($rows | Where-Object Intent -eq '(unassigned)').Count
    Write-Host ("`nApps/assignments: {0} | Unassigned apps: {1}" -f $rows.Count, $unassigned) -ForegroundColor Cyan
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
}
Disconnect-MgGraph | Out-Null
