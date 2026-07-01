<#
.SYNOPSIS
    MSLICGOV-Discovery.ps1 — read the deployed Microsoft licensing position from the tenant.
.DESCRIPTION
    PURPOSE
        Enumerates the tenant's subscribed SKUs (owned/prepaid units, consumed units, warning units)
        via Microsoft Graph, so you can capture the deployed/assigned side of the license position
        into the License Position Register. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MSLICGOV-Discovery.ps1 -CsvPath C:\Temp\skus.csv
        Requires the Microsoft Graph PowerShell SDK and the Organization.Read.All scope.
    EXPECTED RESULTS
        A per-SKU table (part number, enabled/prepaid units, consumed units, available) and an
        optional CSV. No tenant changes are made.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome

Write-Host "`n=== Subscribed SKUs (owned vs consumed) ===" -ForegroundColor Cyan
$skus = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus'
$report = $skus.value | ForEach-Object {
    $enabled  = [int]$_.prepaidUnits.enabled
    $consumed = [int]$_.consumedUnits
    [pscustomobject]@{
        SkuPartNumber = $_.skuPartNumber
        SkuId         = $_.skuId
        Owned         = $enabled
        Consumed      = $consumed
        Available     = $enabled - $consumed
        Warning       = [int]$_.prepaidUnits.warning
        Suspended     = [int]$_.prepaidUnits.suspended
    }
}
$report | Sort-Object SkuPartNumber | Format-Table SkuPartNumber, Owned, Consumed, Available, Warning -AutoSize
Write-Host ("Total SKUs: {0}" -f $report.Count) -ForegroundColor Cyan
Write-Host "Note: Owned here is the tenant-visible prepaid count; confirm contractual owned quantity from the agreement." -ForegroundColor DarkYellow

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
