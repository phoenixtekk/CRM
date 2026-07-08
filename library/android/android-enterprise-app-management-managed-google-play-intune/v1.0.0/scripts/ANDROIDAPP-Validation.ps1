<#
.SYNOPSIS
    ANDROIDAPP-Validation.ps1 — per-app delivery/config/protection/track validation report (read-only, Graph).
.DESCRIPTION
    PURPOSE
        For each managed Google Play app, reports whether it has (1) an assignment, (2) a managed app
        configuration for its package, (3) an Android app protection policy referencing it, and (4) a
        defined update track / auto-update mode — the four validation gates. Flags gaps so you know an
        app is fully governed before you expand.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDAPP-Validation.ps1 -CsvPath C:\Temp\android-validate.csv
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A table: App / Assigned / HasConfig / HasAPP / Track-or-AutoUpdate, with a gap count.
        PASS = intended apps are Assigned + Configured (+ Protected where required) + track defined.
.NOTES
    White-label — Android Solutions. Read-only against Microsoft Graph. No credentials stored.
.EXAMPLE
    .\ANDROIDAPP-Validation.ps1 -WhatIf
#>
[CmdletBinding()] param([string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

$androidTypes = @('#microsoft.graph.androidManagedStoreApp','#microsoft.graph.androidManagedStoreWebApp')

# App-config policies keyed by package.
$configPkgs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileAppConfigurations").value |
              Where-Object { $_.'@odata.type' -eq '#microsoft.graph.androidManagedStoreAppConfiguration' } |
              ForEach-Object { $_.packageId } | Where-Object { $_ } | Sort-Object -Unique

# Android APP policies + the apps they reference (bundleId/packageId).
$appProtPkgs = @()
foreach ($p in (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/androidManagedAppProtections?`$expand=apps").value) {
    foreach ($a in $p.apps) { if ($a.mobileAppIdentifier.packageId) { $appProtPkgs += $a.mobileAppIdentifier.packageId } }
}
$appProtPkgs = $appProtPkgs | Sort-Object -Unique

$rows = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$expand=assignments"
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($app in $resp.value) {
        if ($androidTypes -notcontains $app.'@odata.type') { continue }
        $pkg = $app.packageId; if (-not $pkg) { $pkg = $app.appIdentifier }
        $assigned = [bool]($app.assignments -and $app.assignments.Count -gt 0)
        $trackDef = $false
        if ($assigned) {
            foreach ($a in $app.assignments) {
                if ($a.settings.autoUpdateMode -or $a.settings.androidManagedStoreAppTrackIds) { $trackDef = $true }
            }
        }
        $rows += [pscustomobject]@{
            App        = $app.displayName
            Package    = $pkg
            Assigned   = $assigned
            HasConfig  = ($configPkgs -contains $pkg)
            HasAPP     = ($appProtPkgs -contains $pkg)
            TrackMode  = $trackDef
        }
    }
    $uri = $resp.'@odata.nextLink'
} while ($uri)

if (-not $rows) { Write-Host "No managed Google Play apps found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows | Sort-Object App | Format-Table -AutoSize
$gaps = ($rows | Where-Object { -not $_.Assigned -or -not $_.HasConfig }).Count
Write-Host ("`nApps: {0} | Assigned: {1} | With config: {2} | With APP: {3} | Delivery/config gaps: {4}" -f `
    $rows.Count, ($rows | Where-Object Assigned).Count, ($rows | Where-Object HasConfig).Count, ($rows | Where-Object HasAPP).Count, $gaps) `
    -ForegroundColor ($(if ($gaps) { 'Yellow' } else { 'Green' }))
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
