<#
.SYNOPSIS
    M365LIC-Discovery.ps1 — read-only Microsoft 365 license inventory (subscriptions + per-user assignments) via Microsoft Graph.
.DESCRIPTION
    PURPOSE
        Builds the authoritative license baseline: every subscribed SKU with purchased vs assigned
        counts, and every user's assigned licenses. Flags seats inherited from group-based licensing
        so they can later be reclaimed via group membership, not by stripping the user license.
        Read-only — makes no changes. Writes the export "License Inventory - M365 - Discovery".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365LIC-Discovery.ps1 -CsvPath C:\Temp\M365LIC-Inventory.csv
        Requires the Microsoft Graph PowerShell SDK and scopes:
        Organization.Read.All, User.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        A console summary of each SKU (purchased / assigned / available) and a per-user CSV
        (UPN, SKU part number, whether the seat was assigned directly or by group).
.NOTES
    Asset Mgt — Microsoft 365 License Optimization & Reharvesting. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$ReportName = 'License Inventory - M365 - Discovery'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All','Directory.Read.All' -NoWelcome

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- Subscriptions (subscribedSkus): purchased vs assigned ---
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$skuMap = @{}
$skuSummary = foreach ($s in $skus) {
    $skuMap[$s.skuId] = $s.skuPartNumber
    $purchased = $s.prepaidUnits.enabled
    [pscustomobject]@{
        SkuPartNumber = $s.skuPartNumber
        Purchased     = $purchased
        Assigned      = $s.consumedUnits
        Available     = ($purchased - $s.consumedUnits)
    }
}
Write-Host '--- Subscriptions ---' -ForegroundColor Cyan
$skuSummary | Sort-Object SkuPartNumber | Format-Table -AutoSize

# --- Per-user assignments (direct vs group-based) ---
$rows = @()
$uri = '/v1.0/users?$select=userPrincipalName,displayName,accountEnabled,assignedLicenses&$top=999'
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($u in $r.value) {
        foreach ($lic in $u.assignedLicenses) {
            # assignedByGroup is populated on licenseDetails; pull it per user to detect inherited seats.
            $detail = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}/licenseDetails" -f $u.userPrincipalName)).value |
                      Where-Object { $_.skuId -eq $lic.skuId } | Select-Object -First 1
            $byGroup = $false
            if ($detail -and $detail.PSObject.Properties.Name -contains 'assignedByGroup') { $byGroup = [bool]$detail.assignedByGroup }
            $rows += [pscustomobject]@{
                UserPrincipalName = $u.userPrincipalName
                DisplayName       = $u.displayName
                AccountEnabled    = $u.accountEnabled
                SkuPartNumber     = $(if ($skuMap.ContainsKey($lic.skuId)) { $skuMap[$lic.skuId] } else { $lic.skuId })
                AssignedByGroup   = $byGroup
            }
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

$groupAssigned = @($rows | Where-Object { $_.AssignedByGroup }).Count
Write-Host ('--- Assignments: {0} total, {1} group-assigned ---' -f $rows.Count, $groupAssigned) -ForegroundColor Cyan
$rows | Group-Object SkuPartNumber | Sort-Object Name | Select-Object Count, @{n='SkuPartNumber';e={$_.Name}} | Format-Table -AutoSize

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
