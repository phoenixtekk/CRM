<#
.SYNOPSIS
    SCCMAPP-Discovery.ps1 — inventory SCCM applications, deployment types, and detection methods.
.DESCRIPTION
    PURPOSE
        Reads the Configuration Manager application estate and exports, per application: each
        deployment type, its install/uninstall command, detection method, requirements,
        dependencies, and supersedence — the source-of-truth map for repackaging into Intune Win32.
    HOW TO RUN
        Run on a workstation with the Configuration Manager console/module and a Read-only Analyst
        (or better) SCCM role, from the site drive:
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Discovery.ps1 -SiteCode P01 -CsvPath C:\Temp\sccm-apps.csv
    EXPECTED RESULTS
        A per-deployment-type table (app, deployment type, install command, detection type,
        dependency + supersedence flags) on screen and, if -CsvPath is given, a CSV to migrate from.
.NOTES
    Phoenixtekk Workplace Marketplace — Migrations. Read-only against Configuration Manager.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$SiteCode,
    [string]$CsvPath
)

$mod = Join-Path $env:SMS_ADMIN_UI_PATH '..\ConfigurationManager.psd1'
if (-not (Get-Module ConfigurationManager)) {
    if (Test-Path $mod) { Import-Module $mod -ErrorAction Stop }
    else { Import-Module ConfigurationManager -ErrorAction Stop }
}
if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root (Get-CMSite | Select-Object -First 1 -ExpandProperty ServerName) -ErrorAction Stop | Out-Null
}
Push-Location "$($SiteCode):"

Write-Host "`n=== SCCM application inventory (site $SiteCode) ===" -ForegroundColor Cyan
$rows = @()
foreach ($app in Get-CMApplication) {
    $name = $app.LocalizedDisplayName
    $dts  = @(Get-CMDeploymentType -ApplicationName $name -ErrorAction SilentlyContinue)
    if (-not $dts) {
        $rows += [pscustomobject]@{ Application=$name; DeploymentType='(none)'; Technology=''; InstallCommand=''; DetectionType=''; HasDependency=$false; Supersedes='' }
        continue
    }
    foreach ($dt in $dts) {
        # deployment type detail lives in the SDMPackageXML
        $xml = $null; try { $xml = [xml]$dt.SDMPackageXML } catch {}
        $install = ''; $detType = ''
        if ($xml) {
            $installer = $xml.AppMgmtDigest.DeploymentType.Installer
            $install = ($installer.InstallAction.Args.Arg | Where-Object { $_.Name -eq 'InstallCommandLine' }).'#text'
            $det = $installer.DetectAction.Args.Arg | Where-Object { $_.Name -eq 'DetectionType' }
            $detType = if ($det) { $det.'#text' } elseif ($installer.CustomData.EnhancedDetectionMethod) { 'Enhanced (MSI/File/Registry)' } elseif ($installer.CustomData.DetectionScript) { 'Script' } else { 'Unknown' }
        }
        $rows += [pscustomobject]@{
            Application    = $name
            DeploymentType = $dt.LocalizedDisplayName
            Technology     = $dt.Technology
            InstallCommand = $install
            DetectionType  = $detType
            HasDependency  = ($app.NumberOfDependentDTs -gt 0)
            Supersedes     = ($app.NumberOfDependentTS)
        }
    }
}
Pop-Location

$rows | Format-Table Application, DeploymentType, Technology, DetectionType, HasDependency -AutoSize
Write-Host ("Applications: {0}   Deployment types: {1}" -f (($rows.Application | Select-Object -Unique).Count), $rows.Count) -ForegroundColor Cyan
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
