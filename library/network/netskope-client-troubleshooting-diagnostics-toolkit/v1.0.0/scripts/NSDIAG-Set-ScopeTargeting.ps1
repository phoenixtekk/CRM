<#
.SYNOPSIS
    NSDIAG-Set-ScopeTargeting.ps1 — create/confirm the diagnostics scope group (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Creates or confirms the Entra security group used to scope the toolkit's rollout —
        'Diagnostics Scope - Help Desk - Pilot' by default — and reports its membership. SUPPORTS
        -WhatIf AND DEFAULTS TO PREVIEW: with no confirmation it only describes what it would create.
        This is the assign-once scope behind the repeatable, run-everywhere model.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\NSDIAG-Set-ScopeTargeting.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\NSDIAG-Set-ScopeTargeting.ps1 -Confirm:$false
        Requires the Microsoft Graph SDK and Group.ReadWrite.All.
    EXPECTED RESULTS
        Reports whether the group exists; in preview shows the intended create; when applied, creates
        the group if missing and prints the group id and current member count.
.NOTES
    Network category — client troubleshooting toolkit. Uses Microsoft Graph (no Netskope internals).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$GroupName = 'Diagnostics Scope - Help Desk - Pilot',
    [string]$MailNickname = 'diagnostics-scope-helpdesk-pilot'
)

Write-Host "=== Diagnostics scope targeting — '$GroupName' ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

# Look up an existing group by display name (escape single quotes for the OData filter).
$nameEsc = $GroupName.Replace("'", "''")
$lookup = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$nameEsc'"
$group = $lookup.value | Select-Object -First 1

if ($group) {
    Write-Host ("Group exists. id={0}" -f $group.id) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($GroupName, "Create Entra security group")) {
        $body = @{
            displayName     = $GroupName
            mailEnabled     = $false
            mailNickname    = $MailNickname
            securityEnabled = $true
            groupTypes      = @()
            description     = 'Scope group for the Netskope client diagnostics toolkit (help-desk pilot).'
        }
        $group = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Created group. id={0}" -f $group.id) -ForegroundColor Green
    } else {
        Write-Host "Preview only — group not created. Re-run with -Confirm:`$false to create." -ForegroundColor Yellow
        Disconnect-MgGraph | Out-Null
        exit 0
    }
}

# Report current membership count.
if ($group -and $group.id) {
    $members = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($group.id)/members?`$select=id,displayName"
    Write-Host ("Current members: {0}" -f (@($members.value).Count)) -ForegroundColor Cyan
    Write-Host "Add the help-desk pilot devices/users to this group, then run the toolkit against the scope." -ForegroundColor DarkCyan
}

Disconnect-MgGraph | Out-Null
