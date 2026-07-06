<#
.SYNOPSIS
    GWSSO-Report.ps1 — identity coverage / exception report for Entra->Google SSO & provisioning.
.DESCRIPTION
    PURPOSE
        Read-only coverage report for the Entra->Google identity foundation. Across the scoped users it
        summarizes readiness for federation and provisioning and surfaces the exceptions: users assigned
        to the Google connector app (in scope for SSO/SCIM) versus not, users on a verified custom domain
        versus onmicrosoft.com (which Google rejects), and users missing a mail value to serve as the
        SAML NameID / Google primaryEmail. Use it to build the exception register and to target
        GWSSO-Remediation.ps1. Google-side provisioned state is confirmed in the Google Admin console.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWSSO-Report.ps1
        Optional: -AppFilter 'Google'; -CsvPath .\gwsso-coverage.csv to export the per-user coverage.
        Required Graph scopes (read-only): Application.Read.All, Directory.Read.All, Policy.Read.All,
        Synchronization.Read.All, User.Read.All, Group.Read.All. Use 'your-tenant-id' if prompted.
    EXPECTED RESULTS
        A coverage summary (in scope / on custom domain / mail present) and exception lists (not assigned,
        onmicrosoft UPN, missing mail). No changes are made — pass.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$AppFilter = 'Google',
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All','User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Entra->Google Identity Coverage / Exception Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$sp = Get-MgServicePrincipal -All -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$AppFilter*" } | Select-Object -First 1
if (-not $sp) {
    Write-Host "Google connector app not found — add it from the gallery first (Implementation Step 1)." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

# In-scope users (assigned directly or via an assigned group).
$assignedUserIds = New-Object System.Collections.Generic.HashSet[string]
$assignments = @(Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue)
foreach ($a in $assignments) {
    if ($a.PrincipalType -eq 'User') { [void]$assignedUserIds.Add($a.PrincipalId) }
    elseif ($a.PrincipalType -eq 'Group') {
        Get-MgGroupMember -GroupId $a.PrincipalId -All -ErrorAction SilentlyContinue | ForEach-Object { [void]$assignedUserIds.Add($_.Id) }
    }
}

$rows = @()
$users = @(Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,Mail,AccountEnabled -ErrorAction SilentlyContinue)
foreach ($u in $users) {
    $rows += [pscustomobject]@{
        DisplayName       = $u.DisplayName
        UserPrincipalName = $u.UserPrincipalName
        Mail              = $u.Mail
        InScope           = $assignedUserIds.Contains($u.Id)
        OnCustomDomain    = ($u.UserPrincipalName -notlike '*.onmicrosoft.com')
        HasMail           = [bool]$u.Mail
        AccountEnabled    = $u.AccountEnabled
    }
}

$total = $rows.Count
$inScope   = @($rows | Where-Object InScope).Count
$onDomain  = @($rows | Where-Object OnCustomDomain).Count
$withMail  = @($rows | Where-Object HasMail).Count

Write-Host "`n-- Coverage summary --" -ForegroundColor Cyan
Write-Host ("  Total users              : {0}" -f $total)
Write-Host ("  In scope (assigned)      : {0}" -f $inScope)
Write-Host ("  On verified custom domain: {0}" -f $onDomain)
Write-Host ("  Has mail (NameID source) : {0}" -f $withMail)

$notAssigned = $rows | Where-Object { -not $_.InScope -and $_.AccountEnabled }
Write-Host ("`n-- Not in scope for SSO/provisioning ({0}) --" -f @($notAssigned).Count) -ForegroundColor Yellow
$notAssigned | ForEach-Object { Write-Host ("  • {0} <{1}>" -f $_.DisplayName, $_.UserPrincipalName) }

$onmDomain = $rows | Where-Object { -not $_.OnCustomDomain }
Write-Host ("`n-- On onmicrosoft.com — Google rejects ({0}) --" -f @($onmDomain).Count) -ForegroundColor Yellow
$onmDomain | ForEach-Object { Write-Host ("  • {0} <{1}>" -f $_.DisplayName, $_.UserPrincipalName) }

$noMail = $rows | Where-Object { -not $_.HasMail -and $_.AccountEnabled }
Write-Host ("`n-- Missing mail (no NameID/primaryEmail source) ({0}) --" -f @($noMail).Count) -ForegroundColor Yellow
$noMail | ForEach-Object { Write-Host ("  • {0} <{1}>" -f $_.DisplayName, $_.UserPrincipalName) }

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
Write-Host "`nRecord deliberate exceptions (e.g. service accounts) in the register; close gaps with GWSSO-Remediation.ps1 (preview first)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
