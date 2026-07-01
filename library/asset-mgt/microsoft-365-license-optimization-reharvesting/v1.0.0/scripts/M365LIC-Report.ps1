<#
.SYNOPSIS
    M365LIC-Report.ps1 — read-only usage + savings report from Microsoft 365 usage reports and sign-in data.
.DESCRIPTION
    PURPOSE
        Pulls per-user last-activity dates from the Microsoft 365 usage reports (Graph reports
        endpoints) and last sign-in from the directory, joins them to assigned licenses, and reports
        which seats are inactive across the chosen window plus the recoverable monthly cost.
        Read-only — makes no changes. Writes "Usage Activity - M365 - Discovery" and a
        "Savings Report - M365 - Report" summary.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365LIC-Report.ps1 -InactivityDays 90 -MonthlyCost @{ ENTERPRISEPREMIUM = 57; ENTERPRISEPACK = 36 } -CsvPath C:\Temp\M365LIC-Usage.csv
        Requires the Microsoft Graph PowerShell SDK and scopes:
        Reports.Read.All, User.Read.All, Organization.Read.All, AuditLog.Read.All.
        NOTE: usage reports must show real user names (tenant report-concealment turned off) to match per user.
    EXPECTED RESULTS
        A console summary of inactive seats per SKU and the estimated recoverable monthly cost, plus a
        per-user CSV (UPN, SKUs, last sign-in, last service activity, inactive flag).
.NOTES
    Asset Mgt — Microsoft 365 License Optimization & Reharvesting. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [int]$InactivityDays = 90,
    [hashtable]$MonthlyCost = @{},
    [string]$CsvPath,
    [string]$ReportName = 'Savings Report - M365 - Report'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Reports.Read.All','User.Read.All','Organization.Read.All','AuditLog.Read.All' -NoWelcome

# Graph usage reports accept a fixed period (D7, D30, D90, D180). Snap the window to the nearest valid period.
$period = switch ($InactivityDays) { { $_ -le 7 } { 'D7' } { $_ -le 30 } { 'D30' } { $_ -le 90 } { 'D90' } default { 'D180' } }
$cutoff = (Get-Date).AddDays(-$InactivityDays)
Write-Host ("=== Usage Activity - M365 - Discovery (period {0}, inactivity {1}d) ===" -f $period, $InactivityDays) -ForegroundColor Cyan

# --- Pull the Microsoft 365 active-user detail report (last activity per service, per user) ---
$activity = @{}
$csv = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/reports/getMicrosoft365ActiveUserDetail(period='{0}')?`$format=text/csv" -f $period)
($csv -split "`r?`n" | Select-Object -Skip 1) | Where-Object { $_ } | ForEach-Object {
    $c = $_ -split ','
    # Column order: ReportRefreshDate, UPN, DisplayName, IsDeleted, DeletedDate, HasExchange,...,LastActivityDate (last col)
    $upn = $c[1]
    $last = $c[$c.Count - 1]
    if ($upn) { $activity[$upn.Trim('"')] = $last.Trim('"') }
}

# --- SKU map + per-user licenses + last sign-in ---
$skuMap = @{}; (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value | ForEach-Object { $skuMap[$_.skuId] = $_.skuPartNumber }

$rows = @()
$uri = '/v1.0/users?$select=userPrincipalName,assignedLicenses,signInActivity&$top=999'
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($u in $r.value) {
        if (-not $u.assignedLicenses -or $u.assignedLicenses.Count -eq 0) { continue }
        $skuNames = @($u.assignedLicenses | ForEach-Object { if ($skuMap.ContainsKey($_.skuId)) { $skuMap[$_.skuId] } else { $_.skuId } })
        $lastSignIn = $null
        if ($u.signInActivity -and $u.signInActivity.lastSignInDateTime) { $lastSignIn = [datetime]$u.signInActivity.lastSignInDateTime }
        $lastActivity = $null
        if ($activity.ContainsKey($u.userPrincipalName) -and $activity[$u.userPrincipalName]) {
            [datetime]$parsed = [datetime]::MinValue
            if ([datetime]::TryParse($activity[$u.userPrincipalName], [ref]$parsed)) { $lastActivity = $parsed }
        }
        $newest = @($lastSignIn, $lastActivity | Where-Object { $_ }) | Sort-Object -Descending | Select-Object -First 1
        $inactive = (-not $newest) -or ($newest -lt $cutoff)
        $rows += [pscustomobject]@{
            UserPrincipalName = $u.userPrincipalName
            Skus              = ($skuNames -join ';')
            LastSignIn        = $lastSignIn
            LastActivity      = $lastActivity
            Inactive          = $inactive
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host '--- Inactive seats by SKU ---' -ForegroundColor Cyan
$inactiveRows = @($rows | Where-Object { $_.Inactive })
$savings = 0.0
$inactiveRows | ForEach-Object { $_.Skus -split ';' } | Group-Object | Sort-Object Name | ForEach-Object {
    $sku = $_.Name; $cnt = $_.Count
    $cost = if ($MonthlyCost.ContainsKey($sku)) { [double]$MonthlyCost[$sku] } else { 0 }
    $line = $cnt * $cost
    $savings += $line
    "{0,-28} inactive: {1,5}   est. monthly recoverable: {2,10:C}" -f $sku, $cnt, $line
}

Write-Host ("=== {0}: {1} inactive seats, est. recoverable {2:C}/month ({3:C}/year) ===" -f $ReportName, $inactiveRows.Count, $savings, ($savings * 12)) -ForegroundColor Green

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved 'Usage Activity - M365 - Discovery' to {0}" -f $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
