<#
.SYNOPSIS
    CAI-PolicyReport.ps1 — list Conditional Access policies and their state (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Enumerates all Conditional Access policies with their enabled state (enabled /
        disabled / reportOnly), so you can audit coverage and confirm what's enforced.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAI-PolicyReport.ps1 -CsvPath C:\Temp\ca-policies.csv
        Requires Microsoft Graph SDK and Policy.Read.All.
    EXPECTED RESULTS
        A table (and optional CSV) of policy name + state + grant controls.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$report = $pols | ForEach-Object {
    [pscustomobject]@{
        Name = $_.displayName; State = $_.state
        Grant = ($_.grantControls.builtInControls -join '+')
        Apps = ($_.conditions.applications.includeApplications -join ',')
    }
}
$report | Sort-Object State, Name | Format-Table -AutoSize
$enf = ($report | Where-Object State -eq 'enabled').Count
$ro  = ($report | Where-Object State -eq 'enabledForReportingButNotEnforced').Count
Write-Host ("`nEnforced: {0} | Report-only: {1} | Total: {2}" -f $enf, $ro, $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
