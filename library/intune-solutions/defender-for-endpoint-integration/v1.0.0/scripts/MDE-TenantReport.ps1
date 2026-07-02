<#
.SYNOPSIS
    MDE-TenantReport.ps1 — tenant-wide Defender for Endpoint device health + risk report (Graph).
.DESCRIPTION
    PURPOSE
        Lists onboarded machines with health status and risk score so you can measure coverage
        and chase unhealthy/risky devices.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDE-TenantReport.ps1 -CsvPath C:\Temp\mde.csv
        Requires Microsoft Graph SDK and SecurityIdentitiesHealth.Read.All / Machine.Read.All
        (Microsoft Defender for Endpoint API permissions).
    EXPECTED RESULTS
        A table (and optional CSV) of machine, OS, health, risk score, last seen.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# MDE machines are exposed via the Security API surface in Graph (beta) / WDATP API.
Connect-MgGraph -Scopes 'Machine.Read.All' -NoWelcome
try {
    $machines = (Invoke-MgGraphRequest -Method GET -Uri 'https://api.securitycenter.microsoft.com/api/machines' -ErrorAction Stop).value
} catch {
    Write-Host "Could not reach the Defender API with the current token. Use a token with WDATP Machine.Read.All, or run from the Defender portal > Devices." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; exit 1
}
$report = $machines | ForEach-Object { [pscustomobject]@{ Device=$_.computerDnsName; OS=$_.osPlatform; Health=$_.healthStatus; Risk=$_.riskScore; LastSeen=$_.lastSeen } }
$report | Sort-Object Risk -Descending | Format-Table -AutoSize
$active = ($report | Where-Object Health -eq 'Active').Count
Write-Host ("Active sensors: {0}/{1}" -f $active, $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
