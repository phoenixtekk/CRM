<#
.SYNOPSIS
    CAI-SignInReport.ps1 — summarize recent sign-ins and their Conditional Access results (Graph).
.DESCRIPTION
    PURPOSE
        Pulls recent interactive sign-ins and the Conditional Access outcome (success / failure /
        which policies applied), so you can spot unexpected blocks during a rollout.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAI-SignInReport.ps1 -Top 200 -CsvPath C:\Temp\signins.csv
        Requires Microsoft Graph SDK and AuditLog.Read.All + Directory.Read.All.
    EXPECTED RESULTS
        A table (and optional CSV) of user, app, status, and CA result.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([int]$Top = 200, [string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All','Directory.Read.All' -NoWelcome
$si = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/signIns?`$top=$Top").value
$report = $si | ForEach-Object {
    [pscustomobject]@{
        Time = $_.createdDateTime; User = $_.userPrincipalName; App = $_.appDisplayName
        Status = $(if ($_.status.errorCode -eq 0) { 'success' } else { "fail($($_.status.errorCode))" })
        CA = ($_.appliedConditionalAccessPolicies | Where-Object { $_.result -in 'success','failure','reportOnlyFailure' } | ForEach-Object { "$($_.displayName):$($_.result)" }) -join ' | '
    }
}
$report | Select-Object -First 40 | Format-Table -AutoSize
$fail = ($report | Where-Object Status -like 'fail*').Count
Write-Host ("`nSign-ins: {0} | failures: {1}" -f $report.Count, $fail) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
