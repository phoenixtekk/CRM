<#
.SYNOPSIS
    NSCASB-Set-ScopeTargeting.ps1 — build/maintain the CASB scope groups in Entra ID.
.DESCRIPTION
    PURPOSE
        Creates (if missing) the CASB scope groups used to target policy — the pilot group and the
        broad group — and optionally adds members to the pilot group. These Entra security groups are
        what the Netskope CASB policies are scoped to (Assess -> ... -> Expand). Group-to-policy
        binding inside Netskope is performed in the Netskope console and is deferred to its docs.
    HOW TO RUN
        Create the groups (idempotent):
            powershell -ExecutionPolicy Bypass -File .\NSCASB-Set-ScopeTargeting.ps1
        Add pilot members by UPN:
            .\NSCASB-Set-ScopeTargeting.ps1 -PilotMember user1@contoso.com,user2@contoso.com
        Requires the Microsoft Graph PowerShell SDK and Group.ReadWrite.All (+ User.Read.All to add members).
    EXPECTED RESULTS
        The pilot and broad scope groups exist; any supplied pilot members are added. Idempotent —
        re-running makes no duplicate groups and skips members already present.
.NOTES
    Network / CASB. Creates/updates Entra groups. Netskope policy binding deferred to the vendor docs.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]   $PilotGroup = 'CASB Pilot - Pilot users - Pilot',
    [string]   $BroadGroup = 'CASB Broad - All users - Expand',
    [string[]] $PilotMember = @()
)

Write-Host "`n=== NSCASB Set-ScopeTargeting — CASB scope groups ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

function Get-OrNewGroup([string]$name) {
    $f = "displayName eq '$($name.Replace("'","''"))'"
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value
    if ($existing) { Write-Host ("  OK   {0} exists." -f $name) -ForegroundColor Green; return $existing[0] }
    if ($PSCmdlet.ShouldProcess($name, "Create Entra security group")) {
        $body = @{
            displayName     = $name
            mailEnabled     = $false
            mailNickname    = ($name -replace '[^a-zA-Z0-9]','')
            securityEnabled = $true
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body ($body | ConvertTo-Json)
        Write-Host ("  FIXED created {0}" -f $name) -ForegroundColor Green
        return $g
    }
}

$pilot = Get-OrNewGroup $PilotGroup
$null  = Get-OrNewGroup $BroadGroup

# --- Add pilot members ---
if ($PilotMember.Count -gt 0 -and $pilot) {
    Write-Host "`n[Pilot membership]" -ForegroundColor Cyan
    $current = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($pilot.id)/members?`$select=id,userPrincipalName").value
    foreach ($upn in $PilotMember) {
        $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn`?`$select=id,userPrincipalName" -ErrorAction SilentlyContinue)
        if (-not $u) { Write-Host ("  MISS user not found: {0}" -f $upn) -ForegroundColor Yellow; continue }
        if ($current.id -contains $u.id) { Write-Host ("  SKIP already member: {0}" -f $upn) -ForegroundColor DarkGray; continue }
        if ($PSCmdlet.ShouldProcess($upn, "Add to $PilotGroup")) {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($pilot.id)/members/`$ref" -Body ($ref | ConvertTo-Json) | Out-Null
            Write-Host ("  ADDED {0}" -f $upn) -ForegroundColor Green
        }
    }
}

Write-Host "`n[Next] Scope the CASB policies to these groups in the Netskope console (deferred to vendor docs)." -ForegroundColor DarkYellow
Disconnect-MgGraph | Out-Null
