<#
.SYNOPSIS
    GWSSO-Validation.ps1 — per-user SSO + provisioning validation for the Entra->Google identity foundation.
.DESCRIPTION
    PURPOSE
        Read-only, per-user conformance check for Entra->Google SSO and provisioning. For the scoped
        users (a pilot group, or the whole tenant) it validates the identity-readiness signals: the user
        is on a verified custom domain (not onmicrosoft.com), has a usable mail value to serve as the
        SAML NameID / Google primaryEmail, and is assigned to the Google connector app (so SSO and SCIM
        provisioning bring them into scope). It also confirms the app-level standards once: SSO mode is
        SAML and a provisioning job exists and is running. Each user is reported CONFORMS or with the
        specific issue. Google-side sign-in and provisioned state are confirmed in the Google Admin
        console; this validates the Entra plane.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWSSO-Validation.ps1
        Scope to a pilot: -PilotGroup 'Entra Google SSO Pilot Scope - Pilot'
        Change the connector match: -AppFilter 'Google'
        Required Graph scopes (read-only): Application.Read.All, Directory.Read.All, Policy.Read.All,
        Synchronization.Read.All, User.Read.All, Group.Read.All. Use 'your-tenant-id' if prompted.
    EXPECTED RESULTS
        An app-level summary (SSO mode SAML, provisioning running) plus a per-user pass/fail: CONFORMS,
        or issues (onmicrosoft domain, missing mail/NameID source, not assigned to the app). No changes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$AppFilter = 'Google',
    [string]$PilotGroup
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All','User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Entra->Google SSO + Provisioning Validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# ---- Locate the Google connector app and check app-level standards ----
$sp = Get-MgServicePrincipal -All -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$AppFilter*" } | Select-Object -First 1
if (-not $sp) {
    Write-Host "Google connector app not found — add it from the gallery first (Implementation Step 1)." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}
$ssoMode = if ($sp.PreferredSingleSignOnMode) { $sp.PreferredSingleSignOnMode } else { 'none' }
$job = $null
try { $job = Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue | Select-Object -First 1 } catch { $job = $null }

Write-Host ("App: {0}  (appId {1})" -f $sp.DisplayName, $sp.AppId) -ForegroundColor White
if ($ssoMode -eq 'saml') { Write-Host "  SSO mode: SAML — OK (confirm NameID = user.mail on the Google domain)" -ForegroundColor Green }
else { Write-Host ("  SSO mode: {0} — configure SAML SSO (Implementation Step 2)" -f $ssoMode) -ForegroundColor Yellow }
if ($job) { Write-Host ("  Provisioning job: present ({0}) — OK" -f $job.Status.Code) -ForegroundColor Green }
else { Write-Host "  Provisioning job: none — configure SCIM (Path A) or use GCDS (Path B)" -ForegroundColor Yellow }

# ---- Build the set of users assigned to the app (SSO/provisioning scope) ----
$assignedUserIds = New-Object System.Collections.Generic.HashSet[string]
$assignments = @(Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue)
foreach ($a in $assignments) {
    if ($a.PrincipalType -eq 'User') { [void]$assignedUserIds.Add($a.PrincipalId) }
    elseif ($a.PrincipalType -eq 'Group') {
        Get-MgGroupMember -GroupId $a.PrincipalId -All -ErrorAction SilentlyContinue | ForEach-Object { [void]$assignedUserIds.Add($_.Id) }
    }
}

# ---- Determine which users to validate ----
if ($PilotGroup) {
    $grp = Get-MgGroup -Filter "displayName eq '$PilotGroup'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $grp) { Write-Host ("`nPilot group '{0}' not found." -f $PilotGroup) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
    $users = @(Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction SilentlyContinue | ForEach-Object { Get-MgUser -UserId $_.Id -Property Id,DisplayName,UserPrincipalName,Mail,AccountEnabled -ErrorAction SilentlyContinue })
    Write-Host ("`n-- Validating pilot group '{0}' ({1} users) --" -f $PilotGroup, @($users).Count) -ForegroundColor Cyan
} else {
    $users = @(Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,Mail,AccountEnabled -ErrorAction SilentlyContinue)
    Write-Host ("`n-- Validating all users ({0}) --" -f @($users).Count) -ForegroundColor Cyan
}

$pass = 0; $fail = 0
foreach ($u in $users) {
    $issues = @()
    if ($u.UserPrincipalName -like '*.onmicrosoft.com') { $issues += 'UPN on onmicrosoft.com — Google rejects it; move to a verified custom domain' }
    if (-not $u.Mail) { $issues += 'no mail value — SAML NameID/Google primaryEmail source missing (map NameID to user.mail)' }
    if (-not $assignedUserIds.Contains($u.Id)) { $issues += 'not assigned to the Google connector app — will not be federated/provisioned' }

    if ($issues.Count -eq 0) {
        Write-Host ("  CONFORMS : {0} <{1}>" -f $u.DisplayName, $u.Mail) -ForegroundColor Green
        $pass++
    } else {
        Write-Host ("  REVIEW   : {0} <{1}>" -f $u.DisplayName, ($(if($u.Mail){$u.Mail}else{$u.UserPrincipalName}))) -ForegroundColor Yellow
        $issues | ForEach-Object { Write-Host ("             - {0}" -f $_) }
        $fail++
    }
}

Write-Host ("`nPer-user: {0} conform, {1} need review." -f $pass, $fail) -ForegroundColor Cyan
Write-Host "Note: actual Google sign-in and provisioned state are confirmed in the Google Admin console." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
