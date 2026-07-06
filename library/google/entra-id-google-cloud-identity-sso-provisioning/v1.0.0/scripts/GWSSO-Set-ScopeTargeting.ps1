<#
.SYNOPSIS
    GWSSO-Set-ScopeTargeting.ps1 — build and preview the pilot-scope and owner groups for a staged rollout.
.DESCRIPTION
    PURPOSE
        Creates (or previews) the security groups this solution targets for a staged SSO + provisioning
        rollout: the pilot scope 'Entra Google SSO Pilot Scope - Pilot' (the representative users you
        validate federation and provisioning on before org-wide enforcement) and the owner group 'Entra
        Google SSO Owners - Tenant - Steady' (the identity admins who own the source-of-truth decision
        and review exceptions). Assign the pilot-scope group to the Google connector app so only its
        members federate and provision until the gate passes; mirror it to the matching Google OU/group
        and scope the Google SSO profile the same way. By default it PREVIEWS (no changes); pass -Create
        to create groups that do not yet exist.
    HOW TO RUN
        Preview which groups exist / would be created (read-only):
            powershell -ExecutionPolicy Bypass -File .\GWSSO-Set-ScopeTargeting.ps1
        Create the groups if missing:
            powershell -ExecutionPolicy Bypass -File .\GWSSO-Set-ScopeTargeting.ps1 -Create
        Required Graph scopes: Group.Read.All + Directory.Read.All (preview); Group.ReadWrite.All +
        Directory.Read.All (with -Create). Use 'your-tenant-id' if prompted.
    EXPECTED RESULTS
        In preview: whether each named group exists and its member count. With -Create: the missing
        groups are created (empty) and their object IDs returned so you can add members.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph unless -Create is supplied.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Create
)

$targetGroups = @(
    'Entra Google SSO Pilot Scope - Pilot',
    'Entra Google SSO Owners - Tenant - Steady'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Create) { @('Group.ReadWrite.All','Directory.Read.All') } else { @('Group.Read.All','Directory.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "`n=== Entra->Google SSO Scope Targeting — $(Get-Date -Format s) ===" -ForegroundColor Cyan

foreach ($name in $targetGroups) {
    $existing = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
    if ($existing) {
        $members = Get-MgGroupMember -GroupId $existing.Id -All -ErrorAction SilentlyContinue
        Write-Host ("  EXISTS : {0}  (id {1}, members {2})" -f $name, $existing.Id, @($members).Count) -ForegroundColor Green
    }
    elseif ($Create) {
        if ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
            $mailNick = ($name -replace '[^a-zA-Z0-9]','')
            $mailNick = $mailNick.Substring(0,[Math]::Min(60,$mailNick.Length))
            $g = New-MgGroup -DisplayName $name -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -ErrorAction Stop
            Write-Host ("  CREATED: {0}  (id {1}) — add members next." -f $name, $g.Id) -ForegroundColor Green
        } else {
            Write-Host ("  [WhatIf] would create: {0}" -f $name) -ForegroundColor Yellow
        }
    }
    else {
        Write-Host ("  MISSING: {0}  — re-run with -Create to create it." -f $name) -ForegroundColor Yellow
    }
}

Write-Host "`nAssign 'Entra Google SSO Pilot Scope - Pilot' to the Google connector app and scope the Google SSO profile to the matching OU/group (Implementation Steps 2b, 3, 4)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
