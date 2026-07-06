<#
.SYNOPSIS
    GWVEND-Set-ScopeTargeting.ps1 — build and preview the design-authority reviewer and pilot groups.
.DESCRIPTION
    PURPOSE
        Creates (or previews) the two security groups this governance model targets: the
        design-authority reviewer group "Vendor Governance Design Authority - Tenant - Steady" (the
        enterprise architects who disposition vendor designs at the gate) and the pilot scope
        "Vendor Governance Pilot Scope - Pilot - Pilot" (the first workstream the gate is applied
        to). Use the reviewer group as the named architectural authority in the RACI and the pilot
        scope to stage the rollout. By default it PREVIEWS (no changes); pass -Create to create
        groups that do not yet exist. These are placeholder names — rename to your convention.
    HOW TO RUN
        Preview which groups exist / would be created (read-only):
            powershell -ExecutionPolicy Bypass -File .\GWVEND-Set-ScopeTargeting.ps1
        Create the groups if missing:
            powershell -ExecutionPolicy Bypass -File .\GWVEND-Set-ScopeTargeting.ps1 -Create
        Uses the Microsoft Graph PowerShell SDK; consents to Group.ReadWrite.All, Directory.Read.All
        (read-only in preview mode). Install once: Install-Module Microsoft.Graph -Scope CurrentUser.
    EXPECTED RESULTS
        In preview: whether each named group already exists and its member count. With -Create: the
        missing groups are created (empty) and their object IDs returned so you can add members.
        No changes are made in preview mode.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [switch]$Create
)

$targetGroups = @(
    'Vendor Governance Design Authority - Tenant - Steady',
    'Vendor Governance Pilot Scope - Pilot - Pilot'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Create) { @('Group.ReadWrite.All','Directory.Read.All') } else { @('Group.Read.All','Directory.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "`n=== Vendor Governance Scope Targeting — $(Get-Date -Format s) ===" -ForegroundColor Cyan

foreach ($name in $targetGroups) {
    $existing = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
    if ($existing) {
        $members = Get-MgGroupMember -GroupId $existing.Id -All -ErrorAction SilentlyContinue
        Write-Host ("  EXISTS: {0}  (id {1}, members {2})" -f $name, $existing.Id, @($members).Count) -ForegroundColor Green
    }
    elseif ($Create) {
        $clean = ($name -replace '[^a-zA-Z0-9]','')
        $mailNick = $clean.Substring(0, [Math]::Min(60, $clean.Length))
        $g = New-MgGroup -DisplayName $name -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -ErrorAction Stop
        Write-Host ("  CREATED: {0}  (id {1}) — add members next." -f $name, $g.Id) -ForegroundColor Green
    }
    else {
        Write-Host ("  MISSING: {0}  — re-run with -Create to create it." -f $name) -ForegroundColor Yellow
    }
}

Write-Host "`nUse the Design Authority group as the enterprise architectural authority in the RACI (Step 3)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
