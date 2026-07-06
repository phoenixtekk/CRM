<#
.SYNOPSIS
    GWINTEG-Set-ScopeTargeting.ps1 — build and preview the pilot-scope and pattern-owner groups.
.DESCRIPTION
    PURPOSE
        Creates (or previews) the security groups this solution targets for a staged pattern rollout:
        the pilot scope "Integration Patterns Pilot Scope - Pilot" (the representative apps/users you
        validate the target patterns on) and the pattern-owner group "Integration Patterns Owners -
        Tenant - Steady" (the architects who own the catalog and review exceptions). Use the pilot scope
        to stage P1-P7 on a small app set before expanding across the estate. By default it PREVIEWS (no
        changes); pass -Create to create groups that do not yet exist.
    HOW TO RUN
        Preview which groups exist / would be created (read-only):
            powershell -ExecutionPolicy Bypass -File .\GWINTEG-Set-ScopeTargeting.ps1
        Create the groups if missing:
            powershell -ExecutionPolicy Bypass -File .\GWINTEG-Set-ScopeTargeting.ps1 -Create
        Required Graph scopes: Group.Read.All + Directory.Read.All (preview); Group.ReadWrite.All +
        Directory.Read.All (with -Create).
    EXPECTED RESULTS
        In preview: whether each named group exists and its member count. With -Create: the missing
        groups are created (empty) and their object IDs returned so you can add members.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph unless -Create is supplied.
#>
[CmdletBinding()]
param(
    [switch]$Create
)

$targetGroups = @(
    'Integration Patterns Pilot Scope - Pilot',
    'Integration Patterns Owners - Tenant - Steady'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Create) { @('Group.ReadWrite.All','Directory.Read.All') } else { @('Group.Read.All','Directory.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "`n=== Integration Patterns Scope Targeting — $(Get-Date -Format s) ===" -ForegroundColor Cyan

foreach ($name in $targetGroups) {
    $existing = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
    if ($existing) {
        $members = Get-MgGroupMember -GroupId $existing.Id -All -ErrorAction SilentlyContinue
        Write-Host ("  EXISTS : {0}  (id {1}, members {2})" -f $name, $existing.Id, @($members).Count) -ForegroundColor Green
    }
    elseif ($Create) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]','')
        $mailNick = $mailNick.Substring(0,[Math]::Min(60,$mailNick.Length))
        $g = New-MgGroup -DisplayName $name -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -ErrorAction Stop
        Write-Host ("  CREATED: {0}  (id {1}) — add members next." -f $name, $g.Id) -ForegroundColor Green
    }
    else {
        Write-Host ("  MISSING: {0}  — re-run with -Create to create it." -f $name) -ForegroundColor Yellow
    }
}

Write-Host "`nUse the pilot scope to stage patterns P1-P7 on a small app set before expanding (Implementation Step N)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
