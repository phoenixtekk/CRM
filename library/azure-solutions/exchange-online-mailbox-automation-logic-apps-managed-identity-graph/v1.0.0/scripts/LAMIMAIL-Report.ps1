<#
.SYNOPSIS
    LAMIMAIL-Report.ps1 — report the application-permission grants on the managed identity and the
    mailbox-scope binding; export to CSV.
.DESCRIPTION
    PURPOSE
        Evidence/audit report for the "Exchange Online Mailbox Automation with Logic Apps Managed
        Identity (Graph)" solution. Produces two things:
          * a row per Microsoft Graph APPLICATION permission (app role) granted to the identity's
            service principal (permission name, app-role id, and whether it equals the least-privilege
            target Mail.Read);
          * the mailbox-scope binding as reported by Exchange Online — the Application Access Policy
            scoping the app (by AppId) to the scope group, when the ExchangeOnlineManagement module is
            available (best-effort). (Graph RBAC-for-Exchange scoping: verify + report via that model's
            cmdlets — see the scoping sibling product.)
        Makes NO changes. Exports the permission report to CSV.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Report.ps1 `
            -IdentityDisplayName 'la-mailbox-automation-pilot' `
            -OutCsv .\LAMIMAIL-permissions.csv
    REQUIRED GRAPH SCOPES (delegated, for the operator)
        Application.Read.All, AppRoleAssignment.Read.All, Directory.Read.All
        (verify the exact scope names against current Microsoft Graph documentation)
    EXPECTED RESULTS
        A printed table of the identity's Graph application permissions plus (best-effort) the
        Application Access Policy binding, and a CSV of the permission grants for the audit record.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reporting only; makes no changes. Exchange scope reporting is best-effort and depends on the
    ExchangeOnlineManagement module and the scoping model in use (App Access Policy vs Graph RBAC).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$IdentityDisplayName,
    [string]$OutCsv = ".\LAMIMAIL-permissions.csv",
    [string]$LeastPrivPermission = 'Mail.Read'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Red
    return
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

try {
    Connect-MgGraph -Scopes 'Application.Read.All','AppRoleAssignment.Read.All','Directory.Read.All' -NoWelcome -ErrorAction Stop
} catch {
    Write-Host ("Connect-MgGraph failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}

Write-Host "`n=== LAMIMAIL — application-permission & scope report ===" -ForegroundColor Cyan
$sp = Get-MgServicePrincipal -Filter "displayName eq '$IdentityDisplayName'" -All -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $sp) { Write-Host ("No service principal named '{0}'." -f $IdentityDisplayName) -ForegroundColor Yellow; return }

$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue | Select-Object -First 1
$assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue

$rows = foreach ($a in $assignments) {
    $roleName = ($graphSp.AppRoles | Where-Object Id -eq $a.AppRoleId | Select-Object -First 1).Value
    if (-not $roleName) { $roleName = [string]$a.AppRoleId }
    [pscustomobject]@{
        Identity        = $sp.DisplayName
        IdentityAppId   = $sp.AppId
        Permission      = $roleName
        AppRoleId       = $a.AppRoleId
        IsLeastPriv     = ($roleName -eq $LeastPrivPermission)
        GrantedOn       = $a.CreatedDateTime
    }
}

if ($rows) {
    $rows | Format-Table Identity, Permission, IsLeastPriv, GrantedOn -AutoSize
    try { $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8; Write-Host ("`nExported: {0}" -f (Resolve-Path $OutCsv)) -ForegroundColor Green }
    catch { Write-Host ("CSV export failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
} else {
    Write-Host "   (no application permissions granted to this identity)" -ForegroundColor Yellow
}

# --- Mailbox scope binding (best-effort, Application Access Policy model) ---
Write-Host "`n-- Mailbox scope binding (Exchange Online, best-effort) --" -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
    try {
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction SilentlyContinue | Out-Null }
        $policies = Get-ApplicationAccessPolicy -ErrorAction SilentlyContinue | Where-Object { $_.AppId -eq $sp.AppId }
        if ($policies) {
            foreach ($p in $policies) {
                Write-Host ("   Policy: AppId {0} -> {1} on group {2}" -f $p.AppId, $p.AccessRight, $p.ScopeName)
            }
        } else {
            Write-Host "   No Application Access Policy found for this AppId. If you scope via Graph RBAC-for-Exchange, report it with that model's cmdlets (see the scoping sibling product)." -ForegroundColor Yellow
        }
    } catch {
        Write-Host ("   Could not query Exchange Online: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "   ExchangeOnlineManagement module not installed — skipping scope binding read (Install-Module ExchangeOnlineManagement)." -ForegroundColor DarkGray
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
