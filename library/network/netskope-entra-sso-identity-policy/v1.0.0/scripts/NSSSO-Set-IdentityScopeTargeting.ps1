<#
.SYNOPSIS
    NSSSO-Set-IdentityScopeTargeting.ps1 — create/ensure the Netskope identity scope groups (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Ensures the pilot and production identity scope groups exist in Entra ID so they can be
        assigned to the Netskope enterprise application (for SSO + SCIM scope) and targeted by the
        identity-based policy. Optionally adds members by UPN. Creates the groups only; assigning
        them to the app is done by NSSSO-Remediation.ps1, and Netskope policy is configured in the
        Netskope console (deferred). Default -WhatIf; pass -Apply to make changes.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\NSSSO-Set-IdentityScopeTargeting.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\NSSSO-Set-IdentityScopeTargeting.ps1 -Apply
        Add pilot members:  ... -Apply -PilotMembers user1@contoso.com,user2@contoso.com
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The pilot/production security groups exist (created if missing); any supplied members are
        added. Re-run NSSSO-Report.ps1 to confirm membership.
.NOTES
    Network Solutions — Netskope + Entra ID SSO. Default -WhatIf. Netskope policy configured in Netskope (deferred).
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$PilotGroup    = 'Netskope Identity - Pilot - Stage',
    [string]$ProdGroup     = 'Netskope Identity - Corp - Prod',
    [string[]]$PilotMembers = @(),
    [string[]]$ProdMembers  = @(),
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "=== Netskope identity scope targeting ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "(preview mode — re-run with -Apply to make changes)" -ForegroundColor Yellow }

function Ensure-Group([string]$name) {
    $ne = $name.Replace("'","''")
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ne'").value | Select-Object -First 1
    if ($grp) { Write-Host ("  OK   : group '{0}' exists (id {1})." -f $name, $grp.id) -ForegroundColor Green; return $grp }

    if ($PSCmdlet.ShouldProcess($name, "Create security group")) {
        $nick = ($name -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $nick; securityEnabled = $true } | ConvertTo-Json
        try {
            $new = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $body -ContentType 'application/json'
            Write-Host ("  DONE : created '{0}' (id {1})." -f $name, $new.id) -ForegroundColor Green
            return $new
        } catch { Write-Host ("  FAIL : could not create '{0}': {1}" -f $name, $_.Exception.Message) -ForegroundColor Yellow; return $null }
    } else {
        Write-Host ("  WOULD: create security group '{0}'." -f $name) -ForegroundColor Cyan
        return $null
    }
}

function Add-Members($grp, [string[]]$upns) {
    if (-not $grp -or $upns.Count -eq 0) { return }
    foreach ($upn in $upns) {
        $ue = $upn.Replace("'","''")
        $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userPrincipalName eq '$ue'").value | Select-Object -First 1
        if (-not $u) { Write-Host ("    user '{0}' not found — skipped." -f $upn) -ForegroundColor Yellow; continue }
        if ($PSCmdlet.ShouldProcess($upn, "Add to '$($grp.displayName)'")) {
            $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" } | ConvertTo-Json
            try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body $body -ContentType 'application/json' | Out-Null
                  Write-Host ("    added '{0}'." -f $upn) -ForegroundColor Green }
            catch { Write-Host ("    could not add '{0}': {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
        } else {
            Write-Host ("    WOULD: add '{0}'." -f $upn) -ForegroundColor Cyan
        }
    }
}

$pg = Ensure-Group $PilotGroup
Add-Members $pg $PilotMembers
$rg = Ensure-Group $ProdGroup
Add-Members $rg $ProdMembers

Write-Host "`nNext: assign these groups to the Netskope app (NSSSO-Remediation.ps1) and target the Netskope identity policy by group (Netskope console, deferred)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
