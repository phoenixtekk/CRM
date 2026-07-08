<#
.SYNOPSIS
    DLPCLOUD-SessionScope.ps1 — read-only session-control scope/health helper for cloud-app DLP (MDCA).
.DESCRIPTION
    PURPOSE
        Reports the scope and state of the Microsoft Entra Conditional Access App Control policies that
        drive MDCA session/access controls: which users/groups and apps are routed to the reverse proxy,
        and whether each policy is still in report-only (test) mode or is enforcing. It flags any policy
        that is ENFORCING beyond the intended pilot ring so you catch accidental tenant-wide enforcement.
        Read-only by default; any change to policy state is intentionally left to the portal under change
        control (the -WhatIf switch only prints what a scope change WOULD be, it never writes).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCLOUD-SessionScope.ps1 -PilotGroupName 'MDCA Pilot Ring - Stage1'
        Requires Microsoft Graph PowerShell (Connect-MgGraph, Policy.Read.All + Group.Read.All).
    EXPECTED RESULTS
        A table of CA App Control policies with State, session type, and included/excluded users/groups.
        PASS signal: during pilot, the enforcing CA policy is scoped only to the pilot ring (or is still
        report-only); anything enforcing tenant-wide is flagged RED for review.
.NOTES
    Purview — Cloud-App DLP. Read-only. No credentials in code. State changes are deferred to the portal (change control).
#>
[CmdletBinding()]
param(
    [string]$PilotGroupName = 'MDCA Pilot Ring - Stage1',
    [switch]$WhatIf
)

Write-Host '=== Cloud-App DLP — Session-Control Scope & Health (read-only) ===' -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
    Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Policy.Read.All','Group.Read.All' -NoWelcome }

try {
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
} catch {
    Write-Host ("Could not read Conditional Access policies: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}

$mcas = foreach ($ca in $caPolicies) {
    $s = $ca.SessionControls.CloudAppSecurity
    if ($s -and $s.IsEnabled) {
        [pscustomobject]@{
            Name        = $ca.DisplayName
            State       = $ca.State
            SessionType = $s.CloudAppSecurityType
            IncludeUsers= ($ca.Conditions.Users.IncludeUsers -join ', ')
            IncludeGroup= ($ca.Conditions.Users.IncludeGroups -join ', ')
            ExcludeGroup= ($ca.Conditions.Users.ExcludeGroups -join ', ')
            Apps        = ($ca.Conditions.Applications.IncludeApplications -join ', ')
        }
    }
}

if (-not $mcas) {
    Write-Host 'No Conditional Access App Control policies found — the session plane is not enabled (Req 2.4).' -ForegroundColor Yellow
    return
}

$mcas | Format-Table Name, State, SessionType, Apps -AutoSize

# Resolve the pilot group id (to check scope) if present.
$pilotId = $null
try {
    if (-not (Get-Command Get-MgGroup -ErrorAction SilentlyContinue)) { Import-Module Microsoft.Graph.Groups -ErrorAction SilentlyContinue }
    $g = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ErrorAction SilentlyContinue
    if ($g) { $pilotId = $g.Id; Write-Host ("Pilot ring '{0}' resolved to group id {1}." -f $PilotGroupName, $pilotId) -ForegroundColor Green }
    else { Write-Host ("Pilot ring '{0}' not found as a group — scope check will be name-only." -f $PilotGroupName) -ForegroundColor DarkGray }
} catch { }

foreach ($p in $mcas) {
    if ($p.State -eq 'enabledForReportingButNotEnforced') {
        Write-Host ("  OK (test): '{0}' is report-only — no enforcement yet." -f $p.Name) -ForegroundColor Green
    } elseif ($p.State -eq 'enabled') {
        $scopedToPilot = ($pilotId -and $p.IncludeGroup -match [regex]::Escape($pilotId)) -or ($p.IncludeGroup -match [regex]::Escape($PilotGroupName))
        $allUsers = ($p.IncludeUsers -match 'All')
        if ($allUsers) {
            Write-Host ("  REVIEW: '{0}' is ENFORCING for ALL USERS — confirm this is intended, not an accidental tenant-wide rollout." -f $p.Name) -ForegroundColor Red
        } elseif ($scopedToPilot) {
            Write-Host ("  OK (pilot): '{0}' is enforcing but scoped to the pilot ring." -f $p.Name) -ForegroundColor Green
        } else {
            Write-Host ("  REVIEW: '{0}' is ENFORCING and not obviously scoped to '{1}' — verify the assignment." -f $p.Name, $PilotGroupName) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  '{0}' state = {1}." -f $p.Name, $p.State) -ForegroundColor DarkGray
    }
}

if ($WhatIf) {
    Write-Host '-- WhatIf: to roll back enforcement, set the CA policy State to enabledForReportingButNotEnforced (report-only) in Entra --' -ForegroundColor Yellow
    Write-Host '   This helper does NOT change policy state; make state changes in the portal under change control (instant, non-destructive rollback).' -ForegroundColor Yellow
}

Write-Host 'Done. During pilot, only the pilot-ring policy should enforce; everything else should be report-only.' -ForegroundColor Cyan
