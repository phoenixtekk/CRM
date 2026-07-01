<#
.SYNOPSIS
    W365-Report.ps1 — Cloud PC fleet inventory and Windows 365 license utilization.
.DESCRIPTION
    PURPOSE
        Produces a fleet report: every Cloud PC with its user, status, size/SKU, and provisioning
        policy, plus Windows 365 license utilization (assigned vs. available). Optionally exports to
        CSV. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\W365-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\W365-Report.ps1 -CsvPath .\cloudpc-report.csv
        Requires the Microsoft Graph PowerShell SDK; consents to read-only scopes.
    EXPECTED RESULTS
        An on-screen inventory table + license-utilization line; with -CsvPath, a CSV of the fleet.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    Cloud PC data is read from /deviceManagement/virtualEndpoint (beta) via Graph REST.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'CloudPC.Read.All','Organization.Read.All' -NoWelcome

Write-Host "`n=== Windows 365 Cloud PC fleet report ===" -ForegroundColor Cyan

$cloudPCs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/virtualEndpoint/cloudPCs').value

$rows = foreach ($c in $cloudPCs) {
    [pscustomobject]@{
        CloudPC            = $c.displayName
        User               = $c.userPrincipalName
        Status             = $c.status
        ServicePlan        = $c.servicePlanName    # the SKU / size, e.g. '2vCPU/8GB/128GB'
        ProvisioningPolicy = $c.provisioningPolicyName
        LastModified       = $c.lastModifiedDateTime
    }
}

if ($rows) {
    $rows | Format-Table -AutoSize
    Write-Host ("Total Cloud PCs: {0}" -f $rows.Count) -ForegroundColor Green
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("CSV written: {0}" -f $CsvPath) -ForegroundColor Green }
} else {
    Write-Host "  No Cloud PCs found." -ForegroundColor Yellow
}

# --- Windows 365 license utilization ---
Write-Host "`n-- Windows 365 license utilization --" -ForegroundColor Cyan
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$w365 = $skus | Where-Object { $_.skuPartNumber -match 'WINDOWS_365' }
if ($w365) {
    foreach ($s in $w365) {
        $free = $s.prepaidUnits.enabled - $s.consumedUnits
        Write-Host ("  {0,-32} used {1} / {2}  (free: {3})" -f $s.skuPartNumber, $s.consumedUnits, $s.prepaidUnits.enabled, $free)
    }
} else {
    Write-Host "  No Windows 365 SKU found." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
