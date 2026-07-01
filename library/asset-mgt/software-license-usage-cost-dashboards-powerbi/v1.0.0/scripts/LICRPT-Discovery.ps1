<#
.SYNOPSIS
    LICRPT-Discovery.ps1 — discover the license and usage data sources available for reporting.
.DESCRIPTION
    PURPOSE
        Reports the tenant's subscribed license SKUs (entitled vs. consumed) and confirms that the
        Microsoft 365 usage reports are reachable, so you know which products and usage signals are
        available to feed the Power BI license usage and cost reporting layer. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LICRPT-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and the read scopes
        Organization.Read.All and Reports.Read.All.
    EXPECTED RESULTS
        A table of subscribed SKUs with prepaid (entitled) and consumed (assigned) units, plus a
        confirmation that the usage report endpoint returned data.
.NOTES
    Software Asset Management — License Reporting. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','Reports.Read.All' -NoWelcome

Write-Host "`n=== License entitlement sources (subscribed SKUs) ===" -ForegroundColor Cyan
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
if ($skus) {
    $skus | ForEach-Object {
        [pscustomobject]@{
            SkuPartNumber = $_.skuPartNumber
            Entitled      = $_.prepaidUnits.enabled
            Consumed      = $_.consumedUnits
        }
    } | Sort-Object SkuPartNumber | Format-Table -AutoSize
    Write-Host ("Subscribed SKUs found: {0}" -f $skus.Count) -ForegroundColor Green
} else {
    Write-Host "No subscribed SKUs returned — check Organization.Read.All consent." -ForegroundColor Yellow
}

Write-Host "`n=== Usage data source (Microsoft 365 usage reports) ===" -ForegroundColor Cyan
try {
    $usage = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getOffice365ActiveUserDetail(period='D7')"
    if ($usage) { Write-Host "Usage report endpoint reachable (Office 365 active user detail, D7)." -ForegroundColor Green }
} catch {
    Write-Host ("Usage report not reachable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm Reports.Read.All is consented and usage reporting is enabled." -ForegroundColor Yellow
}

Write-Host "`nReady to feed the Power BI dataset 'License Usage & Cost - Software Assets - Dataset'." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
