<#
.SYNOPSIS
    APPGOVG-Set-ScopeTargeting.ps1 — build and preview the governance consent-scope and reviewer groups (GCC High).
.DESCRIPTION
    PURPOSE
        Creates (or previews) the two security groups this solution targets on a US Government
        (GCC High) tenant: the pilot consent scope "App Governance Consent Scope - Pilot - Pilot" and
        the admin-consent reviewer group "App Governance Consent Reviewers - Tenant - Steady". Use the
        reviewer group in the admin-consent workflow (Implementation Step 5) and the pilot scope to
        stage the rollout. By default it PREVIEWS (no changes); pass -Create to create groups that do
        not yet exist. Connects to US Gov Microsoft Graph (graph.microsoft.us).
    HOW TO RUN
        Preview which groups exist / would be created (read-only):
            powershell -ExecutionPolicy Bypass -File .\APPGOVG-Set-ScopeTargeting.ps1
        Create the groups if missing:
            powershell -ExecutionPolicy Bypass -File .\APPGOVG-Set-ScopeTargeting.ps1 -Create
        Graph scopes: Group.ReadWrite.All, Directory.Read.All (Group.Read.All in preview);
        connects with -Environment USGov.
    EXPECTED RESULTS
        In preview: whether each named group already exists and its member count. With -Create: the
        missing groups are created (empty) and their object IDs returned so you can add members.
.NOTES
    White-label — the repeatable way. Read-only unless -Create is supplied. US Gov Graph endpoints.
#>
[CmdletBinding()]
param(
    [switch]$Create
)

$targetGroups = @(
    'App Governance Consent Scope - Pilot - Pilot',
    'App Governance Consent Reviewers - Tenant - Steady'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Create) { @('Group.ReadWrite.All','Directory.Read.All') } else { @('Group.Read.All','Directory.Read.All') }
Connect-MgGraph -Environment USGov -Scopes $scopes -NoWelcome

$ctx = Get-MgContext
if ($ctx.Environment -ne 'USGov') {
    Write-Host ("WARNING: connected environment is '{0}', expected 'USGov' (GCC High). Reconnect with -Environment USGov." -f $ctx.Environment) -ForegroundColor Yellow
}

Write-Host "`n=== App Governance Scope Targeting (GCC High) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

foreach ($name in $targetGroups) {
    $existing = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
    if ($existing) {
        $members = Get-MgGroupMember -GroupId $existing.Id -All -ErrorAction SilentlyContinue
        Write-Host ("  EXISTS: {0}  (id {1}, members {2})" -f $name, $existing.Id, @($members).Count) -ForegroundColor Green
    }
    elseif ($Create) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]','').Substring(0,[Math]::Min(60,($name -replace '[^a-zA-Z0-9]','').Length))
        $g = New-MgGroup -DisplayName $name -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -ErrorAction Stop
        Write-Host ("  CREATED: {0}  (id {1}) — add members next." -f $name, $g.Id) -ForegroundColor Green
    }
    else {
        Write-Host ("  MISSING: {0}  — re-run with -Create to create it." -f $name) -ForegroundColor Yellow
    }
}

Write-Host "`nUse the reviewer group in entra.microsoft.us -> Enterprise apps -> Consent and permissions -> Admin consent settings (Step 5)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
