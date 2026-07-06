<#
.SYNOPSIS
    MACVPP-Report.ps1 — tenant-wide report of macOS app deployment and VPP license consumption.
.DESCRIPTION
    PURPOSE
        Exports every macOS app in Intune with the fields that matter for this solution: app type
        (App Store/VPP vs. LOB/DMG/PKG), VPP licensing model, VPP total vs. consumed licenses,
        remaining headroom, and install counts. Flags any VPP app that is out of licenses. Use a
        path like C:\Temp\macvpp-report.csv, not an angle-bracket placeholder.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Report.ps1 -CsvPath C:\Temp\macvpp-report.csv
        Required Graph scopes: DeviceManagementApps.Read.All
        Reads only — makes no changes.
    EXPECTED RESULTS
        A summary (macOS apps, VPP apps, total vs. consumed licenses, apps out of licenses) plus a
        CSV with one row per app.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "$PSScriptRoot\macvpp-report.csv"
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' | Out-Null

function Short($odata) { ("$odata" -replace '#microsoft.graph.','') }

$rows = New-Object System.Collections.Generic.List[object]
# All macOS app types: VPP, LOB, DMG, PKG, Office suite, Company Portal, etc.
$uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.macOsVppApp') or isof('microsoft.graph.macOSLobApp') or isof('microsoft.graph.macOSDmgApp') or isof('microsoft.graph.macOSPkgApp')"

do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($a in $page.value) {
        $type      = Short $a.'@odata.type'
        $isVpp     = ($type -eq 'macOsVppApp')
        $total     = if ($isVpp) { [int]$a.totalLicenseCount } else { $null }
        $used      = if ($isVpp) { [int]$a.usedLicenseCount }  else { $null }
        $remaining = if ($isVpp) { $total - $used } else { $null }
        $rows.Add( [pscustomobject]@{
            AppName        = $a.displayName
            AppType        = $type
            Publisher      = $a.publisher
            LicensingModel = if ($isVpp) { $a.appAssignedLicenses; $a.licensingType.supportsDeviceLicensing } else { 'n/a (LOB/DMG/PKG)' }
            VppTotal       = $total
            VppUsed        = $used
            VppRemaining   = $remaining
            OutOfLicenses  = if ($isVpp) { ($total -gt 0 -and $used -ge $total) } else { $false }
            BundleId       = $a.bundleId
        } )
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)

$rows | Sort-Object AppType, AppName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

$vpp = @($rows | Where-Object AppType -eq 'macOsVppApp')
Write-Host "macOS apps (all types):   $($rows.Count)"
Write-Host "App Store (VPP) apps:     $($vpp.Count)"
Write-Host "VPP licenses total:       $((($vpp | Measure-Object VppTotal -Sum).Sum))"
Write-Host "VPP licenses consumed:    $((($vpp | Measure-Object VppUsed  -Sum).Sum))"
Write-Host "VPP apps OUT of licenses: $((@($vpp | Where-Object OutOfLicenses).Count))" -ForegroundColor $(if (@($vpp | Where-Object OutOfLicenses).Count) { 'Yellow' } else { 'Green' })
Write-Host ''
Write-Host "CSV written to: $CsvPath" -ForegroundColor Green
