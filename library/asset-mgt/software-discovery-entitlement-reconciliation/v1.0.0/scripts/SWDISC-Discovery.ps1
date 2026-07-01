<#
.SYNOPSIS
    SWDISC-Discovery.ps1 — installed-software discovery from Intune, Configuration Manager, or a Flexera export.
.DESCRIPTION
    PURPOSE
        Reads installed-software data from one or more discovery sources and writes the merged
        "Installed-Software Inventory - All Sources - Discovery" CSV (publisher, title, version,
        device, source). Read-only against all sources.
          - Intune: detected apps via Microsoft Graph (managedDeviceCount expanded to devices).
          - Configuration Manager: software inventory via Get-CM cmdlets, falling back to the SMS
            Provider WMI namespace (SMS_G_System_INSTALLED_SOFTWARE).
          - Flexera: ingests an installed-software export produced from the Flexera console. This
            script consumes that export file; it does NOT call any Flexera API (defer Flexera setup
            and export generation to Flexera's own documentation).
    HOW TO RUN
        Intune  : powershell -ExecutionPolicy Bypass -File .\SWDISC-Discovery.ps1 -Source Intune -OutCsv .\inventory.csv
                  (requires Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All)
        ConfigMgr: powershell -ExecutionPolicy Bypass -File .\SWDISC-Discovery.ps1 -Source ConfigMgr -SiteCode P01 -OutCsv .\inventory.csv
        Flexera : powershell -ExecutionPolicy Bypass -File .\SWDISC-Discovery.ps1 -Source Flexera -FlexeraExportCsv .\flexera-export.csv -OutCsv .\inventory.csv
    EXPECTED RESULTS
        A merged installed-software CSV with columns: Source, Device, Publisher, Title, Version.
        Re-run per source and merge to build the full "All Sources" inventory.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only discovery.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Intune','ConfigMgr','Flexera')][string]$Source,
    [string]$OutCsv = ".\Installed-Software-Inventory.csv",
    [string]$SiteCode,
    [string]$FlexeraExportCsv
)

$rows = New-Object System.Collections.Generic.List[object]

switch ($Source) {

    'Intune' {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
            Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
        Write-Host "Reading Intune detected apps via Microsoft Graph..." -ForegroundColor Cyan
        $uri = "/beta/deviceManagement/detectedApps?`$select=displayName,publisher,version,deviceCount"
        do {
            $r = Invoke-MgGraphRequest -Method GET -Uri $uri
            foreach ($app in $r.value) {
                $devUri = "/beta/deviceManagement/detectedApps/$($app.id)/managedDevices?`$select=deviceName"
                $devs = (Invoke-MgGraphRequest -Method GET -Uri $devUri).value
                foreach ($d in $devs) {
                    $rows.Add([pscustomobject]@{
                        Source='Intune'; Device=$d.deviceName; Publisher=$app.publisher; Title=$app.displayName; Version=$app.version })
                }
            }
            $uri = $r.'@odata.nextLink'
        } while ($uri)
        Disconnect-MgGraph | Out-Null
    }

    'ConfigMgr' {
        if (-not $SiteCode) { throw "ConfigMgr source requires -SiteCode (e.g. P01)." }
        $cmModule = Join-Path $env:SMS_ADMIN_UI_PATH '..\ConfigurationManager.psd1'
        if (Test-Path $cmModule) {
            Import-Module $cmModule -ErrorAction Stop
            if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
                New-PSDrive -Name $SiteCode -PSProvider CMSite -Root (Get-CMSite | Select-Object -First 1 -ExpandProperty ServerName) -ErrorAction Stop | Out-Null
            }
            Push-Location "$($SiteCode):\"
            Write-Host "Reading Configuration Manager installed software (Get-CMInstalledSoftware)..." -ForegroundColor Cyan
            foreach ($dev in (Get-CMDevice)) {
                foreach ($sw in (Get-CMInstalledSoftware -ResourceId $dev.ResourceID -ErrorAction SilentlyContinue)) {
                    $rows.Add([pscustomobject]@{
                        Source='ConfigMgr'; Device=$dev.Name; Publisher=$sw.Publisher; Title=$sw.ProductName; Version=$sw.ProductVersion })
                }
            }
            Pop-Location
        }
        else {
            Write-Host "ConfigMgr console not found; querying SMS Provider WMI namespace..." -ForegroundColor Yellow
            $ns = "root\sms\site_$SiteCode"
            $q = "SELECT ResourceID, ProductName0, Publisher0, ProductVersion0 FROM SMS_G_System_INSTALLED_SOFTWARE"
            foreach ($sw in (Get-CimInstance -Namespace $ns -Query $q -ErrorAction Stop)) {
                $rows.Add([pscustomobject]@{
                    Source='ConfigMgr'; Device=$sw.ResourceID; Publisher=$sw.Publisher0; Title=$sw.ProductName0; Version=$sw.ProductVersion0 })
            }
        }
    }

    'Flexera' {
        if (-not $FlexeraExportCsv -or -not (Test-Path $FlexeraExportCsv)) {
            throw "Flexera source requires -FlexeraExportCsv pointing at an installed-software export produced from the Flexera console. Generating that export is a Flexera task (see Flexera's documentation)."
        }
        Write-Host "Ingesting Flexera installed-software export: $FlexeraExportCsv" -ForegroundColor Cyan
        # Map common Flexera export column names; adjust to match your export's headers.
        $import = Import-Csv $FlexeraExportCsv
        foreach ($r in $import) {
            $dev = $r.'Computer name'; if (-not $dev) { $dev = $r.Device }; if (-not $dev) { $dev = $r.Hostname }
            $pub = $r.Publisher;       if (-not $pub) { $pub = $r.Manufacturer }
            $ttl = $r.'Application name'; if (-not $ttl) { $ttl = $r.Title }; if (-not $ttl) { $ttl = $r.Product }
            $ver = $r.Version;         if (-not $ver) { $ver = $r.'Application version' }
            $rows.Add([pscustomobject]@{ Source='Flexera'; Device=$dev; Publisher=$pub; Title=$ttl; Version=$ver })
        }
    }
}

Write-Host ("`nDiscovered {0} installed-software rows from {1}." -f $rows.Count, $Source) -ForegroundColor Cyan
if (Test-Path $OutCsv) {
    # merge: append to the existing All-Sources inventory
    $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Append
    Write-Host "Appended to existing inventory: $OutCsv" -ForegroundColor Green
} else {
    $rows | Export-Csv -Path $OutCsv -NoTypeInformation
    Write-Host "Wrote inventory: $OutCsv" -ForegroundColor Green
}
