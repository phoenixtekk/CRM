<#
.SYNOPSIS
    NSZTNA-Set-AccessGroupTargeting.ps1 — build/update the Entra entitlement groups for ZTNA access.
.DESCRIPTION
    PURPOSE
        Creates (if missing) and populates the Entra security groups that Netskope Private Access
        access policies target — the entitlement layer for least-privilege, per-app access. Group
        names follow the convention 'Access Group - <App or Role> - <Stage>' so policy targeting is
        consistent and auditable. SAFE BY DEFAULT: runs in -WhatIf mode and previews every create/add;
        pass -Commit to apply. Access-affecting — confirm the rollback before committing.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\NSZTNA-Set-AccessGroupTargeting.ps1 ^
                -GroupName "Access Group - HR App - Pilot" ^
                -Members user1@contoso.com,user2@contoso.com
        Apply:
            ...same... -Commit
        Requires the Microsoft Graph PowerShell SDK and sign-in with Group.ReadWrite.All,
        GroupMember.ReadWrite.All, and User.Read.All.
    EXPECTED RESULTS
        In -WhatIf mode: the group create (if needed) and each member add that WOULD happen. With
        -Commit: the group exists and the listed members are added; non-listed members are left as-is
        unless -Exclusive is set. Re-run NSZTNA-Validation.ps1 / NSZTNA-Report.ps1 to confirm.
.NOTES
    Network — ZTNA / Netskope Private Access. Default -WhatIf. Authored the repeatable way.
    Targeting this group from the Netskope access policy is done in the Netskope console (DEFERRED).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string[]]$Members = @(),
    [switch]$Exclusive,   # if set, removes members not in -Members (still honors -WhatIf)
    [switch]$Commit       # omit for -WhatIf (preview-only) behavior
)

$whatIf = -not $Commit
Write-Host "`n=== ZTNA Access-Group Targeting ($(if($whatIf){'WhatIf — preview only'}else{'COMMIT'})) ===" -ForegroundColor Cyan
Write-Host ("Group: '{0}'  (convention: Access Group - <App or Role> - <Stage>)" -f $GroupName)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph.Groups, Microsoft.Graph.Users -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($whatIf) { @('Group.Read.All','User.Read.All') } else { @('Group.ReadWrite.All','GroupMember.ReadWrite.All','User.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

# --- Ensure the group exists ---
$group = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$GroupName'&`$select=id,displayName").value | Select-Object -First 1
if (-not $group) {
    if ($whatIf) {
        Write-Host ("  WHATIF: would CREATE security group '{0}'." -f $GroupName) -ForegroundColor Yellow
    } else {
        $mailNick = (($GroupName -replace '[^a-zA-Z0-9]','')).ToLower()
        $newBody = @{ displayName = $GroupName; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true } | ConvertTo-Json
        $group = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $newBody
        Write-Host ("  CREATED security group '{0}'." -f $GroupName) -ForegroundColor Green
    }
}

# Resolve current members (only meaningful if the group already/just exists)
$currentIds = @()
if ($group -and $group.id) {
    $currentIds = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($group.id)/members?`$select=id,userPrincipalName").value
}

# --- Add listed members ---
foreach ($upn in $Members) {
    $u = $null
    try { $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn" } catch {}
    if (-not $u) { Write-Host ("  SKIP: user not found — {0}" -f $upn) -ForegroundColor Red; continue }
    if ($currentIds.id -contains $u.id) { Write-Host ("  already a member: {0}" -f $upn) -ForegroundColor DarkGray; continue }
    if ($whatIf -or -not $group.id) {
        Write-Host ("  WHATIF: would ADD {0} to '{1}'." -f $upn, $GroupName) -ForegroundColor Yellow
    } else {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($group.id)/members/`$ref" -Body $ref
        Write-Host ("  ADDED {0} -> '{1}'." -f $upn, $GroupName) -ForegroundColor Green
    }
}

# --- Optionally remove members not in the desired list ---
if ($Exclusive -and $group -and $group.id) {
    $desiredUpns = $Members
    foreach ($m in $currentIds) {
        if ($m.userPrincipalName -and ($desiredUpns -notcontains $m.userPrincipalName)) {
            if ($whatIf) {
                Write-Host ("  WHATIF: would REMOVE {0} from '{1}' (-Exclusive)." -f $m.userPrincipalName, $GroupName) -ForegroundColor Yellow
            } else {
                Invoke-MgGraphRequest -Method DELETE -Uri "/v1.0/groups/$($group.id)/members/$($m.id)/`$ref"
                Write-Host ("  REMOVED {0} from '{1}'." -f $m.userPrincipalName, $GroupName) -ForegroundColor Magenta
            }
        }
    }
}

Write-Host "`nDone. Target this group from 'Access Policy - <App or Role> - <Stage>' in the Netskope console (DEFERRED)." -ForegroundColor Green
Write-Host "Rollback (access-affecting): remove added members and/or re-enable VPN access if access misbehaves." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
