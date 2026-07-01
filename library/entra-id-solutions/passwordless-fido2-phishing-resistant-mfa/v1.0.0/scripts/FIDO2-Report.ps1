<#
.SYNOPSIS
    FIDO2-Report.ps1 — tenant credential-method coverage report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Summarizes phishing-resistant credential coverage across the tenant from the authentication
        method registration details: how many users are capable of / registered for passwordless
        and FIDO2, so you can see readiness before enforcing an authentication strength. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FIDO2-Report.ps1 -CsvPath C:\Temp\fido2.csv
        Requires Microsoft Graph SDK and AuditLog.Read.All (registration details).
    EXPECTED RESULTS
        Counts of passwordless-capable / FIDO2-registered users and an optional per-user CSV.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All' -NoWelcome
$rows = @(); $uri = '/v1.0/reports/authenticationMethods/userRegistrationDetails'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $rows += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$report = $rows | ForEach-Object {
    [pscustomobject]@{
        User                 = $_.userPrincipalName
        PasswordlessCapable  = $_.isPasswordlessCapable
        Methods              = ($_.methodsRegistered -join ';')
        Fido2                = ($_.methodsRegistered -contains 'fido2SecurityKey')
        WindowsHello         = ($_.methodsRegistered -contains 'windowsHelloForBusiness')
    }
}
$total = $report.Count
$pwless = ($report | Where-Object { $_.PasswordlessCapable }).Count
$fido2  = ($report | Where-Object { $_.Fido2 }).Count
$whfb   = ($report | Where-Object { $_.WindowsHello }).Count
Write-Host "=== Phishing-resistant credential coverage ===" -ForegroundColor Cyan
Write-Host ("  Total users           : {0}" -f $total)
Write-Host ("  Passwordless-capable  : {0}" -f $pwless)
Write-Host ("  FIDO2 registered      : {0}" -f $fido2)
Write-Host ("  Windows Hello (WHfB)  : {0}" -f $whfb)
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
