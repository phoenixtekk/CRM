<#
.SYNOPSIS
    GPOM-Discovery.ps1 — export and inventory every Group Policy Object for migration.
.DESCRIPTION
    PURPOSE
        Uses the GroupPolicy module to enumerate all GPOs (Get-GPO) and export each one to an XML
        report (Get-GPOReport) into an output folder. The XML exports are the input for Intune's
        Group Policy analytics and are your retained rollback source. Read-only against the domain.
    HOW TO RUN
        On a domain-joined admin workstation with RSAT Group Policy Management Tools installed:
        powershell -ExecutionPolicy Bypass -File .\GPOM-Discovery.ps1 -OutputPath .\GPO-Export
    EXPECTED RESULTS
        One <GPOName>.xml per GPO in the output folder, plus a console inventory table
        (DisplayName, Id, GpoStatus, Created/Modified) and a CSV summary you can review and keep.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only. Requires the GroupPolicy module
    (Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0).
#>
[CmdletBinding()]
param(
    [string] $OutputPath = ".\GPO-Export"
)

Write-Host "`n=== Group Policy discovery / export ($($env:USERDNSDOMAIN)) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
    Write-Host "GroupPolicy module not found. Install RSAT Group Policy Management Tools first." -ForegroundColor Yellow
    return
}
Import-Module GroupPolicy -ErrorAction Stop

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$gpos = Get-GPO -All | Sort-Object DisplayName
Write-Host ("Found {0} GPOs. Exporting XML reports to {1}" -f $gpos.Count, (Resolve-Path $OutputPath)) -ForegroundColor Green

$summary = foreach ($g in $gpos) {
    $safe = ($g.DisplayName -replace '[\\/:*?"<>|]', '_')
    $xml  = Join-Path $OutputPath ("{0}.xml" -f $safe)
    try {
        Get-GPOReport -Guid $g.Id -ReportType Xml -Path $xml -ErrorAction Stop
        $status = "exported"
    } catch {
        $status = "FAILED: $($_.Exception.Message)"
    }
    [pscustomobject]@{
        DisplayName  = $g.DisplayName
        Id           = $g.Id
        GpoStatus    = $g.GpoStatus
        CreationTime = $g.CreationTime
        ModifiedTime = $g.ModificationTime
        Export       = $status
    }
}

$summary | Format-Table DisplayName, GpoStatus, ModifiedTime, Export -AutoSize
$csv = Join-Path $OutputPath "GPOM-Inventory.csv"
$summary | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ("`nInventory saved: {0}" -f $csv) -ForegroundColor Green

# Flag a live WSUS/legacy update authority that often travels with GPO estates (informational).
$failed = @($summary | Where-Object { $_.Export -like 'FAILED*' })
if ($failed.Count) { Write-Host ("{0} GPO export(s) failed — see table above." -f $failed.Count) -ForegroundColor Yellow }
Write-Host "Retain this export folder as your rollback source. Import the XML into Group Policy analytics next." -ForegroundColor Green
