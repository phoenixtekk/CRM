<#
.SYNOPSIS
    ANDROIDENT-Set-ScopeTargeting.ps1 — build the pilot/prod + per-model scope groups (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Ensures the Entra security groups this solution relies on exist, using the solution's naming
        convention: the Android Enterprise pilot/prod scope groups plus the per-model groups (BYOD work
        profile = USERS; fully managed / corporate-owned work profile / dedicated = DEVICES). Optionally
        adds BYOD users by UPN. Creating the groups only; assigning the enrollment restriction to a group
        is done in Intune (or by ANDROIDENT-Set-EnrollmentRestrictions.ps1). Default -WhatIf; pass -Apply.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\ANDROIDENT-Set-ScopeTargeting.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\ANDROIDENT-Set-ScopeTargeting.ps1 -Apply
        Add BYOD members:   ... -Apply -ByodMembers user1@contoso.com,user2@contoso.com
        Requires the Microsoft Graph PowerShell SDK and delegated scopes: Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The pilot/prod and per-model security groups exist (created if missing); any supplied BYOD users
        are added. Re-run ANDROIDENT-Report.ps1 to confirm membership.
.NOTES
    Android category — Android Enterprise connection & managed Google Play setup. Default -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$PilotGroup   = 'Android AE - Pilot - Stage',
    [string]$ProdGroup    = 'Android AE - Prod',
    [string]$ByodGroup    = 'Android WP - Users - Pilot',
    [string]$FmGroup      = 'Android FM - Devices - Pilot',
    [string]$CopeGroup    = 'Android COPE - Devices - Pilot',
    [string]$CosuGroup    = 'Android COSU - Devices - Pilot',
    [string[]]$ByodMembers = @(),
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "=== Android Enterprise scope targeting ===" -ForegroundColor Cyan
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

Write-Host "`n-- Scope groups --" -ForegroundColor Cyan
$null = Ensure-Group $PilotGroup
$null = Ensure-Group $ProdGroup

Write-Host "`n-- Per-model groups --" -ForegroundColor Cyan
$bg = Ensure-Group $ByodGroup
Add-Members $bg $ByodMembers
$null = Ensure-Group $FmGroup
$null = Ensure-Group $CopeGroup
$null = Ensure-Group $CosuGroup

Write-Host "`nNote: BYOD work-profile group holds USERS (Company Portal enrollment); FM/COPE/COSU groups hold DEVICES." -ForegroundColor DarkGray
Write-Host "Next: configure the Android platform restriction and assign it to the pilot (ANDROIDENT-Set-EnrollmentRestrictions.ps1)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
