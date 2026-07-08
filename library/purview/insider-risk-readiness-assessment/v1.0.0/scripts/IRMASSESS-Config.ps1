<#
.SYNOPSIS
    IRMASSESS-Config.ps1 — readiness-scaffold helper: create the EMPTY backing security group for the IRM priority-user scope (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates the LEAST-EXPOSING readiness scaffold that IS scriptable: the backing Microsoft Entra
        security group (default name 'IRM Priority Users - Readiness - Scope') that a Purview Insider Risk
        Management PRIORITY USER GROUP will be bound to in the portal. The group is created EMPTY (no members)
        so the scaffold exposes no one. Safe by default: with -WhatIf it only reports the intended change; it
        creates nothing unless -Commit is passed. This helper does NOT create an IRM policy, does NOT bind the
        priority-user group, and NEVER enables IRM or any enforcement — IRM policy/priority configuration is
        portal-only (verify in the Purview portal). Members are added deliberately and minimally with
        IRMASSESS-Set-Scope.ps1.
    HOW TO RUN
        # Preview creating the empty backing scope group:
        powershell -File .\IRMASSESS-Config.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -WhatIf
        # Actually create it (empty):
        powershell -File .\IRMASSESS-Config.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -Commit
        Requires Microsoft Graph (Connect-MgGraph -Scopes Group.ReadWrite.All).
.EXAMPLE
    .\IRMASSESS-Config.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -WhatIf
    Prints the New-MgGroup call it WOULD run to create the empty backing security group.
.NOTES
    Purview — Insider Risk Readiness Assessment. Writes gated behind -Commit; creates an EMPTY group only.
    Never creates/enables an IRM policy. No credentials in code. No individual data.
    Expected results: -Commit creates the empty backing group; bind it as a priority user group in the portal (PASS).
#>
[CmdletBinding()]
param(
    [string]$ScopeGroupName = 'IRM Priority Users - Readiness - Scope',
    [string]$MailNickname   = 'irm-priority-users-readiness-scope',
    [switch]$Commit
)

# --- Connect Microsoft Graph. Reuses an existing session if present. ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph.Groups -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
$ctx = $null
try { $ctx = Get-MgContext } catch {}
if (-not $ctx) {
    Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome
}

Write-Host ("=== IRM readiness scaffold — backing scope group '{0}' ===" -f $ScopeGroupName) -ForegroundColor Cyan
Write-Host 'This creates ONLY the empty backing security group. IRM policy/priority-user binding is portal-only.' -ForegroundColor DarkCyan

# Is the group already present?
$existing = Get-MgGroup -Filter "displayName eq '$ScopeGroupName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue

if ($existing) {
    $memberCount = 0
    try { $memberCount = @(Get-MgGroupMember -GroupId $existing.Id -All -ErrorAction SilentlyContinue).Count } catch {}
    Write-Host ("Backing group already exists (Id={0}, members={1}). Nothing to create." -f $existing.Id, $memberCount) -ForegroundColor Green
    Write-Host 'Bind it as a priority user group in: Purview portal > Insider Risk Management > Settings > Priority user groups.' -ForegroundColor DarkCyan
    return
}

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    Write-Host ("New-MgGroup -DisplayName '{0}' -MailEnabled:`$false -MailNickname '{1}' -SecurityEnabled:`$true -GroupTypes @()  (created EMPTY)" -f $ScopeGroupName, $MailNickname)
    Write-Host 'Re-run with -Commit to create the empty backing group. No policy is created; IRM is never enabled.' -ForegroundColor Yellow
    return
}

# --- Commit path: create the EMPTY security group only ---
$params = @{
    DisplayName     = $ScopeGroupName
    MailEnabled     = $false
    MailNickname    = $MailNickname
    SecurityEnabled = $true
    GroupTypes      = @()
    Description     = 'Readiness scope (backing group) for a Purview Insider Risk Management priority user group. Created empty; add members minimally via IRMASSESS-Set-Scope.ps1. Not bound to any policy from here.'
}
$g = New-MgGroup @params -ErrorAction Stop
Write-Host ("Created EMPTY backing scope group '{0}' (Id={1})." -f $g.DisplayName, $g.Id) -ForegroundColor Green
Write-Host 'PASS: scaffold ready (empty). Next (portal): bind it as a priority user group, then create the readiness policy DISABLED/MINIMAL.' -ForegroundColor Green
Write-Host '  Purview portal > Insider Risk Management > Settings > Priority user groups  (then Policies > Create policy, scoped to this group, disabled/minimal).' -ForegroundColor DarkCyan
