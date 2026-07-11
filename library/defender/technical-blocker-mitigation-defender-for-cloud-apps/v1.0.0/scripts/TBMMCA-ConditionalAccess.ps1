<#
.SYNOPSIS
    TBMMCA-ConditionalAccess.ps1 — read-only analysis of the Conditional Access App Control policies
    that route sessions to the Defender for Cloud Apps reverse proxy.
.DESCRIPTION
    PURPOSE
        Session policies never engage unless an Entra Conditional Access policy with the "Conditional
        Access App Control" session control applies to the session. This script enumerates (read-only)
        every CA policy whose session controls use App Control, reports its enabled state, the target
        users/groups and apps, and any conditions that might exclude the affected users — pinpointing a
        session-control blocker. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMCA-ConditionalAccess.ps1
        Requires Microsoft.Graph.Authentication and Policy.Read.All consent.
    EXPECTED RESULTS
        A per-policy report (name, state, target apps/users) and a verdict on whether a correctly scoped,
        enabled App Control policy exists, written to MDCA-conditionalaccess.json.
.NOTES
    White-label. Read-only — reads Conditional Access policy definitions only; changes nothing.
    VERIFY the intended policy 'Use Conditional Access App Control - Pilot Apps - Diagnose' against your
    tenant; App Control behavior evolves.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDCA-conditionalaccess.json"
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome | Out-Null }

Write-Host "`n=== TBMMCA — Conditional Access App Control analysis (read-only) ===" -ForegroundColor Cyan
$out = @()
try {
    $pol = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
    foreach ($p in $pol.value) {
        $sc = $p.sessionControls
        if ($sc -and $sc.cloudAppSecurity -and $sc.cloudAppSecurity.isEnabled) {
            $apps    = @($p.conditions.applications.includeApplications)
            $exApps  = @($p.conditions.applications.excludeApplications)
            $users   = @($p.conditions.users.includeUsers) + @($p.conditions.users.includeGroups)
            $exUsers = @($p.conditions.users.excludeUsers) + @($p.conditions.users.excludeGroups)
            $color = if ($p.state -eq 'enabled') { 'Green' } else { 'Yellow' }
            Write-Host ("`n   Policy : {0}" -f $p.displayName) -ForegroundColor $color
            Write-Host ("   State  : {0}   AppControlType: {1}" -f $p.state, $sc.cloudAppSecurity.cloudAppSecurityType)
            Write-Host ("   Apps   : include={0}  exclude={1}" -f ($apps -join ','), ($exApps -join ','))
            Write-Host ("   Users  : include={0}  exclude={1}" -f ($users -join ','), ($exUsers -join ','))
            $out += [ordered]@{ Name=$p.displayName; State=$p.state; Type=$sc.cloudAppSecurity.cloudAppSecurityType;
                IncludeApps=$apps; ExcludeApps=$exApps; IncludeUsers=$users; ExcludeUsers=$exUsers }
        }
    }
} catch { Write-Host ("   Could not read Conditional Access policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

$enabled = @($out | Where-Object { $_.State -eq 'enabled' }).Count
Write-Host ("`nApp Control policies: {0} total, {1} enabled." -f $out.Count, $enabled) -ForegroundColor ($(if ($enabled -gt 0) { 'Green' } else { 'Yellow' }))
if ($enabled -eq 0) { Write-Host "No ENABLED App Control policy => sessions are not routed to MDCA. See Troubleshooting 'Session policy / CA App Control not engaging'." -ForegroundColor Yellow }
else { Write-Host "Confirm the enabled policy targets the affected users/apps and excludes none of them." -ForegroundColor DarkGray }

[ordered]@{ Timestamp=(Get-Date).ToString('s'); AppControlPolicies=$out; EnabledCount=$enabled } |
    ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Analysis snapshot: {0}" -f $OutputPath) -ForegroundColor Green
