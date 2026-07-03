<#
.SYNOPSIS
    CAIG-Report.ps1 — report CA policies + recent sign-in CA results on GCC High.
.DESCRIPTION
    PURPOSE
        Read-only reporting for a GCC High tenant. Lists every Conditional Access policy with its
        state (enabled / reportOnly / disabled) and grant controls, then summarizes recent sign-ins
        and the CA outcome (which policies applied and their result). Use it to review Report-only
        impact and to spot unexpected blocks during a rollout. This is the exportable evidence
        substitute for the CA PowerPoint export, which is Commercial-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAIG-Report.ps1 -Top 200 -CsvFolder C:\Temp
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov with
        Policy.Read.All + AuditLog.Read.All + Directory.Read.All.
    EXPECTED RESULTS
        A policy table and a recent sign-in table (with optional CSVs), pulled from graph.microsoft.us.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param([int]$Top = 200, [string]$CsvFolder)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','AuditLog.Read.All','Directory.Read.All' -NoWelcome
if ((Get-MgContext).Environment -ne 'USGov') { Write-Host "WRONG CLOUD: not USGov. Reconnect with -Environment USGov." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
Write-Host "Connected to US Gov Graph (graph.microsoft.us)." -ForegroundColor Green

# --- Policies ---
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$polReport = $pols | ForEach-Object {
    [pscustomobject]@{
        Name  = $_.displayName
        State = switch ($_.state) { 'enabled' {'enforced'} 'enabledForReportingButNotEnforced' {'report-only'} 'disabled' {'disabled'} default { $_.state } }
        Grant = ($_.grantControls.builtInControls -join '+')
        Apps  = ($_.conditions.applications.includeApplications -join ',')
    }
}
Write-Host "`n--- Conditional Access policies ---" -ForegroundColor Cyan
$polReport | Sort-Object State, Name | Format-Table -AutoSize
$enf = ($polReport | Where-Object State -eq 'enforced').Count
$ro  = ($polReport | Where-Object State -eq 'report-only').Count
Write-Host ("Enforced: {0} | Report-only: {1} | Total: {2}" -f $enf, $ro, $polReport.Count) -ForegroundColor Cyan

# --- Recent sign-ins + CA results ---
$si = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/signIns?`$top=$Top").value
$siReport = $si | ForEach-Object {
    [pscustomobject]@{
        Time   = $_.createdDateTime
        User   = $_.userPrincipalName
        App    = $_.appDisplayName
        Status = $(if ($_.status.errorCode -eq 0) { 'success' } else { "fail($($_.status.errorCode))" })
        CA     = ($_.appliedConditionalAccessPolicies | Where-Object { $_.result -in 'success','failure','reportOnlyFailure','reportOnlySuccess' } | ForEach-Object { "$($_.displayName):$($_.result)" }) -join ' | '
    }
}
Write-Host "`n--- Recent sign-ins (CA results) ---" -ForegroundColor Cyan
$siReport | Select-Object -First 40 | Format-Table -AutoSize
$fail = ($siReport | Where-Object Status -like 'fail*').Count
Write-Host ("Sign-ins: {0} | failures: {1}" -f $siReport.Count, $fail) -ForegroundColor Cyan

if ($CsvFolder) {
    if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null }
    $polReport | Export-Csv -Path (Join-Path $CsvFolder 'caig-policies.csv') -NoTypeInformation
    $siReport  | Export-Csv -Path (Join-Path $CsvFolder 'caig-signins.csv')  -NoTypeInformation
    Write-Host ("Saved caig-policies.csv and caig-signins.csv to {0}" -f $CsvFolder) -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
