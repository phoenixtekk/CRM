<#
.SYNOPSIS
    CAI-BreakGlassCheck.ps1 — verify emergency-access accounts are excluded from all CA policies.
.DESCRIPTION
    PURPOSE
        For the break-glass accounts you specify, confirms each Conditional Access policy excludes
        them (directly or via an excluded group). The single most important pre-enforcement check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAI-BreakGlassCheck.ps1 -Upns breakglass1@contoso.onmicrosoft.com,breakglass2@contoso.onmicrosoft.com
        Requires Microsoft Graph SDK and Policy.Read.All + User.Read.All + GroupMember.Read.All.
    EXPECTED RESULTS
        Per policy: EXCLUDED (good) or NOT EXCLUDED (fix before enforcing).
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([Parameter(Mandatory)][string[]]$Upns)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','User.Read.All','GroupMember.Read.All' -NoWelcome

$ids = @{}
foreach ($u in $Upns) { try { $ids[$u] = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$u").id } catch { Write-Host "User not found: $u" -ForegroundColor Red } }
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$allGood = $true
foreach ($p in $pols) {
    $exU = @($p.conditions.users.excludeUsers)
    $exG = @($p.conditions.users.excludeGroups)
    foreach ($u in $Upns) {
        $id = $ids[$u]
        $inExU = $exU -contains $id
        $inExG = $false
        foreach ($g in $exG) { try { $m = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$g/members?`$select=id").value.id; if ($m -contains $id) { $inExG = $true } } catch {} }
        $ok = $inExU -or $inExG
        if (-not $ok) { $allGood = $false }
        Write-Host ("{0,-45} {1,-50} {2}" -f $p.displayName, $u, ($(if($ok){'EXCLUDED'}else{'NOT EXCLUDED'}))) -ForegroundColor ($(if($ok){'Green'}else{'Red'}))
    }
}
Write-Host ("`n{0}" -f ($(if($allGood){'All break-glass accounts are excluded from every policy.'}else{'WARNING: fix exclusions before enforcing any policy!'}))) -ForegroundColor ($(if($allGood){'Green'}else{'Red'}))
Disconnect-MgGraph | Out-Null
