<#
.SYNOPSIS
    ENTPASSKEYG-Set-ScopeTargeting.ps1 — build and preview the passwordless rollout groups.
.DESCRIPTION
    PURPOSE
        Creates (or previews) the security groups the rollout targets, following the naming
        convention <Purpose> - <Scope> - <Stage>:
            Passwordless Rollout - Pilot - Pilot
            Passwordless Rollout - Admins - Pilot
            Passwordless Rollout - Wave1 - Expand
            Passwordless Registration Campaign - Pilot - Pilot
        Defaults to -WhatIf (preview only). Optionally seeds members from a CSV of userPrincipalNames.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\ENTPASSKEYG-Set-ScopeTargeting.ps1
        Create the groups:
            powershell -ExecutionPolicy Bypass -File .\ENTPASSKEYG-Set-ScopeTargeting.ps1 -WhatIf:$false
        Optional: -PilotMembersCsv .\pilot.csv (column: userPrincipalName) to add pilot members.
        Consents to Group.ReadWrite.All, User.Read.All.
        GCC High / US Gov: Connect-MgGraph uses -Environment USGov (login.microsoftonline.us / graph.microsoft.us).
        For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us). *Verify the correct cloud for your tenant.*
    EXPECTED RESULTS
        In preview: the groups that WOULD be created and members that WOULD be added. When applied: the
        groups exist and are populated. Idempotent — existing groups are reused, not duplicated.
.NOTES
    White-label — Entra ID Solutions. Write action — preview (-WhatIf) by default.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$PilotMembersCsv
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# US Government cloud (GCC High). For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "`n=== Passwordless Scope Targeting — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$groupNames = @(
    'Passwordless Rollout - Pilot - Pilot',
    'Passwordless Rollout - Admins - Pilot',
    'Passwordless Rollout - Wave1 - Expand',
    'Passwordless Registration Campaign - Pilot - Pilot'
)

function Get-OrCreateGroup($name) {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value | Select-Object -First 1
    if ($existing) { Write-Host ("  exists: {0}" -f $name) -ForegroundColor DarkGray; return $existing }
    if ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]','')
        $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  CREATED: {0}" -f $name) -ForegroundColor Green
        return $g
    } else { Write-Host ("  [WhatIf] would create: {0}" -f $name) -ForegroundColor Yellow; return $null }
}

$groups = @{}
foreach ($n in $groupNames) { $groups[$n] = Get-OrCreateGroup $n }

if ($PilotMembersCsv -and (Test-Path $PilotMembersCsv)) {
    $pilot = $groups['Passwordless Rollout - Pilot - Pilot']
    Write-Host "`n-- Pilot members --" -ForegroundColor Cyan
    foreach ($row in Import-Csv $PilotMembersCsv) {
        $upn = $row.userPrincipalName
        $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn?`$select=id" -ErrorAction SilentlyContinue
        if (-not $u.id) { Write-Host ("  skip (not found): {0}" -f $upn) -ForegroundColor Yellow; continue }
        if ($pilot -and $PSCmdlet.ShouldProcess($upn, "Add to $($pilot.displayName)")) {
            # US Gov cloud: directoryObjects @odata.id must use the national-cloud Graph host (graph.microsoft.us).
            # For DoD (IL5) use https://dod-graph.microsoft.us. *Verify the correct host for your cloud.*
            $ref = @{ '@odata.id' = "https://graph.microsoft.us/v1.0/directoryObjects/$($u.id)" }
            try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($pilot.id)/members/`$ref" -Body ($ref | ConvertTo-Json); Write-Host ("  added: {0}" -f $upn) -ForegroundColor Green }
            catch { Write-Host ("  already a member / error: {0}" -f $upn) -ForegroundColor DarkGray }
        } else { Write-Host ("  [WhatIf] would add: {0}" -f $upn) -ForegroundColor Yellow }
    }
}

Write-Host "`nUse these groups as the Target in the authentication methods policy, registration campaign, and CA policy scope." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
