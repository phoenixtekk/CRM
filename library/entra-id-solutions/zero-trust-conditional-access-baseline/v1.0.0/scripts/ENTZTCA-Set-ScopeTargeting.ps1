<#
.SYNOPSIS
    ENTZTCA-Set-ScopeTargeting.ps1 — build and preview the persona, break-glass, and pilot groups.
.DESCRIPTION
    PURPOSE
        Creates (or previews) the security groups the CA baseline targets, following the naming
        convention <Purpose> - <Scope> - <Stage>:
            CA Exclusion - Break-Glass - Steady
            CA Persona - Admins - Steady
            CA Persona - Internals - Steady
            CA Persona - Externals-Guests - Steady   (dynamic: userType eq 'Guest')
            CA Persona - Service-Accounts - Steady
            CA Pilot Ring - Pilot - Pilot
        Defaults to -WhatIf (preview only). Optionally seeds break-glass members from -BreakGlassUpn.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\ENTZTCA-Set-ScopeTargeting.ps1
        Create the groups:
            powershell -ExecutionPolicy Bypass -File .\ENTZTCA-Set-ScopeTargeting.ps1 -WhatIf:$false -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com
        Consents to Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        In preview: the groups that WOULD be created. When applied: the groups exist (guests group is
        dynamic). Idempotent — existing groups are reused, not duplicated.
.NOTES
    White-label — Entra ID Solutions. Write action — preview (-WhatIf) by default.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string[]]$BreakGlassUpn
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "`n=== CA Scope Targeting — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# name -> optional dynamic membership rule
$groupDefs = @(
    @{ Name='CA Exclusion - Break-Glass - Steady';      Rule=$null },
    @{ Name='CA Persona - Admins - Steady';             Rule=$null },
    @{ Name='CA Persona - Internals - Steady';          Rule=$null },
    @{ Name='CA Persona - Externals-Guests - Steady';   Rule='(user.userType -eq "Guest")' },
    @{ Name='CA Persona - Service-Accounts - Steady';   Rule=$null },
    @{ Name='CA Pilot Ring - Pilot - Pilot';            Rule=$null }
)

function Get-OrCreateGroup($def) {
    $name = $def.Name
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value | Select-Object -First 1
    if ($existing) { Write-Host ("  exists: {0}" -f $name) -ForegroundColor DarkGray; return $existing }
    if ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
        $body = @{ displayName=$name; mailEnabled=$false; mailNickname=(($name -replace '[^a-zA-Z0-9]','')); securityEnabled=$true }
        if ($def.Rule) {
            $body.groupTypes = @('DynamicMembership')
            $body.membershipRule = $def.Rule
            $body.membershipRuleProcessingState = 'On'
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  CREATED: {0}{1}" -f $name, ($(if($def.Rule){" (dynamic: $($def.Rule))"}else{''}))) -ForegroundColor Green
        return $g
    } else { Write-Host ("  [WhatIf] would create: {0}" -f $name) -ForegroundColor Yellow; return $null }
}

$groups = @{}
foreach ($d in $groupDefs) { $groups[$d.Name] = Get-OrCreateGroup $d }

# Seed break-glass members
if ($BreakGlassUpn) {
    $bgGroup = $groups['CA Exclusion - Break-Glass - Steady']
    Write-Host "`n-- Break-glass members --" -ForegroundColor Cyan
    foreach ($upn in $BreakGlassUpn) {
        $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn?`$select=id" -ErrorAction SilentlyContinue
        if (-not $u.id) { Write-Host ("  skip (not found): {0}" -f $upn) -ForegroundColor Yellow; continue }
        if ($bgGroup -and $PSCmdlet.ShouldProcess($upn, "Add to CA Exclusion - Break-Glass - Steady")) {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" }
            try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($bgGroup.id)/members/`$ref" -Body ($ref | ConvertTo-Json); Write-Host ("  added: {0}" -f $upn) -ForegroundColor Green }
            catch { Write-Host ("  already a member / error: {0}" -f $upn) -ForegroundColor DarkGray }
        } else { Write-Host ("  [WhatIf] would add: {0}" -f $upn) -ForegroundColor Yellow }
    }
}

Write-Host "`nExclude 'CA Exclusion - Break-Glass - Steady' on EVERY CA policy. Target personas as the include scope." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
