<#
.SYNOPSIS
    FIDO2G-Report.ps1 — tenant phishing-resistant coverage report for a GCC High tenant (from registration details).
.DESCRIPTION
    PURPOSE
        Produces a tenant-wide credential-method coverage report for a US Government (GCC High/DoD)
        tenant from Microsoft Graph authentication-method registration details: how many users are
        capable of passwordless / phishing-resistant sign-in, and lists users who are NOT yet ready.
        Use this to confirm coverage before requiring a phishing-resistant strength. Read-only, and can
        write a CSV. Use -Environment USGovDoD on the DoD cloud.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FIDO2G-Report.ps1 -CsvPath .\fido2g-coverage.csv
        Connects to US Gov Graph (-Environment USGov). Read-only scopes:
        AuditLog.Read.All, UserAuthenticationMethod.Read.All.
    EXPECTED RESULTS
        Counts and percentages for passwordless-capable and MFA-registered users, and a list (and
        optional CSV) of users lacking a phishing-resistant method. Pass = report renders against
        graph.microsoft.us; fail = a connection/redirect error means -Environment was omitted.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'AuditLog.Read.All','UserAuthenticationMethod.Read.All' -NoWelcome

Write-Host "`n=== Phishing-resistant coverage report — GCC High (env: $Environment) ===" -ForegroundColor Cyan

# Page through registration details
$users = New-Object System.Collections.Generic.List[object]
$uri = '/v1.0/reports/authenticationMethods/userRegistrationDetails?$top=999'
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($u in $resp.value) { $users.Add($u) }
    $uri = $resp.'@odata.nextLink'
} while ($uri)

$total = $users.Count
if ($total -eq 0) { Write-Host "No registration details returned." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

# Phishing-resistant methods to look for in methodsRegistered
$prMethods = @('fido2SecurityKey','windowsHelloForBusiness','x509Certificate','passKeyDeviceBound','passKeyDeviceBoundAuthenticator')
function Test-PhishingResistant($u) {
    $mr = @($u.methodsRegistered)
    foreach ($m in $mr) { if ($prMethods -contains $m) { return $true } }
    return [bool]$u.isPasswordlessCapable
}

$prReady   = @($users | Where-Object { Test-PhishingResistant $_ })
$mfaReady  = @($users | Where-Object { $_.isMfaRegistered })
$notReady  = @($users | Where-Object { -not (Test-PhishingResistant $_) })

function Pct($n) { if ($total) { '{0:N1}%' -f (100.0 * $n / $total) } else { '0%' } }
Write-Host ("Users evaluated              : {0}" -f $total)
Write-Host ("MFA-registered               : {0} ({1})" -f $mfaReady.Count, (Pct $mfaReady.Count))
Write-Host ("Phishing-resistant capable   : {0} ({1})" -f $prReady.Count, (Pct $prReady.Count)) -ForegroundColor Green
Write-Host ("NOT phishing-resistant yet   : {0} ({1})" -f $notReady.Count, (Pct $notReady.Count)) -ForegroundColor $(if ($notReady.Count) { 'Yellow' } else { 'Green' })

if ($notReady.Count) {
    Write-Host "`nUsers lacking a phishing-resistant method (first 40):" -ForegroundColor Yellow
    $notReady | Select-Object -First 40 | ForEach-Object {
        Write-Host ("  - {0}  [methods: {1}]" -f $_.userPrincipalName, ((@($_.methodsRegistered)) -join ','))
    }
}

if ($CsvPath) {
    $notReady | Select-Object userPrincipalName,
        @{n='methodsRegistered';e={ (@($_.methodsRegistered)) -join ';' }},
        isMfaRegistered, isPasswordlessCapable |
        Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nNot-ready list written to: {0}" -f $CsvPath) -ForegroundColor Cyan
}

Write-Host "`nDo not require a phishing-resistant strength until this coverage is high (see Testing Guide gate)." -ForegroundColor DarkCyan
Disconnect-MgGraph | Out-Null
