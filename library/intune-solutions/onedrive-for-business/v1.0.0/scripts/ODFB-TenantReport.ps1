<#
.SYNOPSIS
    ODFB-TenantReport.ps1 — tenant-wide OneDrive for Business usage report via Microsoft Graph.

.DESCRIPTION
    PURPOSE
        Reports each user's OneDrive provisioning and usage (storage used, file count, last
        activity) so you can measure rollout coverage and adoption.

    HOW TO RUN
        Requires the Microsoft Graph PowerShell SDK (installs if missing) and an account with
        Reports.Read.All:
            powershell -ExecutionPolicy Bypass -File .\ODFB-TenantReport.ps1 -CsvPath C:\Temp\odfb-usage.csv

    EXPECTED RESULTS
        A table (and optional CSV) of OwnerPrincipalName, StorageUsedGB, FileCount, LastActivity.
        Provisioned pilot users show non-zero storage/files once syncing.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
    Note: report data may be display-name anonymized if that tenant setting is on
    (Admin center > Settings > Org settings > Reports). Turn it off for named results.
#>
[CmdletBinding()]
param([string]$CsvPath, [ValidateSet('D7','D30','D90','D180')][string]$Period = 'D30')

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Reports.Read.All' -NoWelcome

$tmp = New-TemporaryFile
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getOneDriveUsageAccountDetail(period='$Period')" -OutputFilePath $tmp.FullName
$rows = Import-Csv $tmp.FullName
Remove-Item $tmp.FullName -ErrorAction SilentlyContinue

$report = $rows | ForEach-Object {
    [pscustomobject]@{
        OwnerPrincipalName = $_.'Owner Principal Name'
        StorageUsedGB      = [math]::Round([double]$_.'Storage Used (Byte)'/1GB, 2)
        FileCount          = [int]$_.'File Count'
        ActiveFileCount    = [int]$_.'Active File Count'
        LastActivity       = $_.'Last Activity Date'
    }
}

$report | Sort-Object StorageUsedGB -Descending | Format-Table -AutoSize
$prov = ($report | Where-Object { $_.FileCount -gt 0 }).Count
Write-Host ("`nProvisioned with content: {0}/{1} OneDrive accounts." -f $prov, $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
