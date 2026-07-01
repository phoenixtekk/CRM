<#
.SYNOPSIS
    ABMPROV-Set-ScopeTargeting.ps1 — build the provisioning + per-scenario enrollment scope groups (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Ensures the Entra security groups this solution relies on exist, using the solution's naming
        convention: the Managed Apple ID provisioning scope groups (pilot + prod) and the per-scenario
        enrollment groups for Corporate-Owned, BYOD, and Shared. Optionally adds members by UPN.
        Creates the groups only; assigning the provisioning group to the Apple Business Manager app is
        done by ABMPROV-Remediation.ps1, and federation is configured in ABM (deferred to Apple docs).
        Default -WhatIf; pass -Apply to make changes.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\ABMPROV-Set-ScopeTargeting.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\ABMPROV-Set-ScopeTargeting.ps1 -Apply
        Add pilot members:  ... -Apply -ProvisioningPilotMembers user1@contoso.com,user2@contoso.com
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The provisioning (pilot/prod) and per-scenario (COD devices, BYOD users, Shared devices)
        security groups exist (created if missing); any supplied members are added. Re-run
        ABMPROV-Report.ps1 to confirm membership.
.NOTES
    Entra ID Solutions — Entra ID + ABM federation & auto-provisioning. Default -WhatIf. ABM/federation deferred.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ProvisioningPilotGroup = 'Managed Apple ID Provisioning - Pilot - Stage',
    [string]$ProvisioningProdGroup  = 'Managed Apple ID Provisioning - Corp - Prod',
    [string]$CodGroup               = 'iOS COD - Devices - Pilot',
    [string]$ByodGroup              = 'iOS BYOD - Users - Pilot',
    [string]$SharedGroup            = 'iOS Shared - Devices - Pilot',
    [string[]]$ProvisioningPilotMembers = @(),
    [string[]]$ByodMembers              = @(),
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "=== ABM provisioning + enrollment scope targeting ===" -ForegroundColor Cyan
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

Write-Host "`n-- Provisioning scope groups --" -ForegroundColor Cyan
$pg = Ensure-Group $ProvisioningPilotGroup
Add-Members $pg $ProvisioningPilotMembers
$null = Ensure-Group $ProvisioningProdGroup

Write-Host "`n-- Per-scenario enrollment groups --" -ForegroundColor Cyan
$null = Ensure-Group $CodGroup
$bg = Ensure-Group $ByodGroup
Add-Members $bg $ByodMembers
$null = Ensure-Group $SharedGroup

Write-Host "`nNote: COD and Shared groups hold DEVICES; the BYOD group holds USERS (account-driven User Enrollment)." -ForegroundColor DarkGray
Write-Host "Next: assign the provisioning group to the Apple Business Manager app (ABMPROV-Remediation.ps1); federate ABM in the ABM console (deferred to Apple docs)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
