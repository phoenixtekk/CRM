<#
.SYNOPSIS
    ODFBGOV-Report.ps1 — OneDrive for Business governance report (storage, activity, sharing, quota headroom). Read-only.
.DESCRIPTION
    PURPOSE
        Produces the recurring governance report leadership and admins review: per-OneDrive storage
        used vs quota (headroom %), last activity date, external sharing capability, and flags for
        near-quota (>=90%) and stale (no activity in the window) accounts. Combines the SharePoint
        Online site inventory with the Microsoft Graph OneDrive usage report. Read-only — no changes.
    HOW TO RUN
        .\ODFBGOV-Report.ps1 -AdminUrl https://contoso-admin.sharepoint.com -HtmlPath C:\Temp\ODFBGOV-Report.html -StaleDays 90
        (PowerShell 5.1+/7+; Microsoft.Online.SharePoint.PowerShell + Microsoft.Graph.
         Connect-SPOService modern auth; Graph scope Reports.Read.All.)
    EXPECTED RESULTS
        Console top-N tables plus an HTML/CSV artifact "OneDrive Governance - Tenant - Report":
        one row per OneDrive with quota, used, headroom %, last activity, sharing, and NearQuota/Stale flags.
.NOTES
    SharePoint category — OneDrive for Business Deployment & Governance. Read-only against SPO + Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AdminUrl,
    [string]$HtmlPath,
    [string]$CsvPath,
    [int]$StaleDays = 90,
    [ValidateSet('D7','D30','D90','D180')][string]$UsagePeriod = 'D90'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking -ErrorAction Stop
Connect-SPOService -Url $AdminUrl

# --- Graph OneDrive usage (last activity per account) ---
$usage = @{}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Reports.Read.All' -NoWelcome
$resp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getOneDriveUsageAccountDetail(period='$UsagePeriod')" -OutputType HttpResponseMessage
($resp.Content.ReadAsStringAsync().Result | ConvertFrom-Csv) | ForEach-Object {
    if ($_.'Owner Principal Name') { $usage[$_.'Owner Principal Name'.ToLower()] = $_.'Last Activity Date' }
}
Disconnect-MgGraph | Out-Null

# --- SPO inventory + compose rows ---
$now = Get-Date
$od = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"
$rows = foreach ($s in $od) {
    $quota = [double]$s.StorageQuota
    $used  = [double]$s.StorageUsageCurrent
    $head  = if ($quota -gt 0) { [math]::Round(100 - (($used / $quota) * 100), 1) } else { $null }
    $last  = if ($s.Owner -and $usage.ContainsKey($s.Owner.ToLower())) { $usage[$s.Owner.ToLower()] } else { $null }
    $stale = if ($last) { ($now - [datetime]$last).Days -gt $StaleDays } else { $true }
    [pscustomobject]@{
        Owner        = $s.Owner
        Url          = $s.Url
        Quota_MB     = $quota
        Used_MB      = $used
        Headroom_Pct = $head
        LastActivity = $last
        Sharing      = $s.SharingCapability
        NearQuota    = ($head -ne $null -and $head -le 10)
        Stale        = $stale
    }
}

Write-Host '=== OneDrive Governance - Tenant - Report ===' -ForegroundColor Cyan
Write-Host ('Total OneDrive sites: {0} | Near quota (>=90%): {1} | Stale (> {2}d): {3}' -f `
    $rows.Count, @($rows | Where-Object NearQuota).Count, $StaleDays, @($rows | Where-Object Stale).Count)
$rows | Sort-Object Headroom_Pct | Select-Object -First 15 | Format-Table Owner, Used_MB, Quota_MB, Headroom_Pct, LastActivity -AutoSize

if ($CsvPath)  { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "CSV: $CsvPath" -ForegroundColor Green }
if ($HtmlPath) {
    $style = '<style>body{font-family:Segoe UI,Arial} table{border-collapse:collapse} th,td{border:1px solid #ccc;padding:4px 8px}</style>'
    ($rows | Sort-Object Headroom_Pct | ConvertTo-Html -Title 'OneDrive Governance Report' -Head $style) |
        Out-File -FilePath $HtmlPath -Encoding utf8
    Write-Host "HTML: $HtmlPath" -ForegroundColor Green
}

Disconnect-SPOService
