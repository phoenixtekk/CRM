<#
.SYNOPSIS
    SAASLIC-Report.ps1 — SaaS spend and right-sizing report: entitled seats vs active users.
.DESCRIPTION
    PURPOSE
        Produces the data behind 'Right-Sizing Register - SaaS - Pilot': per app, the entitled seats
        and annual cost (from your spend baseline), the count of distinct users who actually signed in
        over the window, the wasted (idle) seats, and the estimated annual saving from reclaiming them.
        Read-only — it reads sign-in telemetry from Graph and your owner-map CSV; it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SAASLIC-Report.ps1 -OwnerMapCsv .\owner-map.csv -Days 30 -CsvPath C:\Temp\rightsizing.csv
        OwnerMapCsv columns expected: AppId, App, Owner, EntitledSeats, AnnualCost
        (AnnualCost is the total annual cost for the app; per-seat cost is derived).
        Requires Microsoft Graph SDK and scopes AuditLog.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        A per-app table (entitled / active / wasted seats / estimated saving) to record as the
        'Right-Sizing Register - SaaS - Pilot'. Use it to choose reclaim / consolidate / downgrade.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$OwnerMapCsv,
    [int]$Days = 30,
    [string]$CsvPath
)
if (-not (Test-Path $OwnerMapCsv)) { throw "OwnerMapCsv not found: $OwnerMapCsv (build 'Owner Map - SaaS - Mapped' first)." }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All','Directory.Read.All' -NoWelcome

$owners = Import-Csv $OwnerMapCsv
$since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')

# Distinct active users per app over the window
$activeUsers = @{}
$siUri = "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since&`$select=appId,userId&`$top=1000"
do {
    $sr = Invoke-MgGraphRequest -Method GET -Uri $siUri
    foreach ($e in $sr.value) {
        if (-not $e.appId -or -not $e.userId) { continue }
        if (-not $activeUsers.ContainsKey($e.appId)) { $activeUsers[$e.appId] = New-Object System.Collections.Generic.HashSet[string] }
        [void]$activeUsers[$e.appId].Add($e.userId)
    }
    $siUri = $sr.'@odata.nextLink'
} while ($siUri)

$report = foreach ($o in $owners) {
    $entitled = [int]$o.EntitledSeats
    $cost     = [double]$o.AnnualCost
    $active   = if ($activeUsers.ContainsKey($o.AppId)) { $activeUsers[$o.AppId].Count } else { 0 }
    $wasted   = [Math]::Max(0, $entitled - $active)
    $perSeat  = if ($entitled -gt 0) { [Math]::Round($cost / $entitled, 2) } else { 0 }
    [pscustomobject]@{
        App           = $o.App
        Owner         = $o.Owner
        EntitledSeats = $entitled
        ActiveUsers   = $active
        WastedSeats   = $wasted
        AnnualCost    = $cost
        EstSaving     = [Math]::Round($wasted * $perSeat, 2)
    }
}
$report = $report | Sort-Object EstSaving -Descending
$report | Format-Table -AutoSize
$totalSave = ($report | Measure-Object EstSaving -Sum).Sum
Write-Host ("Total estimated annual saving from reclaiming idle seats: {0:C}" -f $totalSave) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath (record as 'Right-Sizing Register - SaaS - Pilot')." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
