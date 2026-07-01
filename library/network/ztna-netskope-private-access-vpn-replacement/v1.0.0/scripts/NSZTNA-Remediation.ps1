<#
.SYNOPSIS
    NSZTNA-Remediation.ps1 — safe fixes for broken ZTNA access (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates the most common cause of a user not reaching an entitled private app: the user is
        missing from the Entra entitlement group ('Access Group - <App or Role> - <Stage>') that the
        Netskope access policy targets. Adds the named user to the named entitlement group via
        Microsoft Graph. SAFE BY DEFAULT: runs in -WhatIf mode and only previews the change; pass
        -Commit to apply. Access-affecting changes — confirm the rollback (re-enable VPN, remove from
        the group) before committing.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\NSZTNA-Remediation.ps1 ^
                -UserPrincipalName user@contoso.com -GroupName "Access Group - HR App - Pilot"
        Apply:
            ...same... -Commit
        Requires the Microsoft Graph PowerShell SDK and sign-in with GroupMember.ReadWrite.All.
    EXPECTED RESULTS
        In -WhatIf mode: a line showing the add that WOULD be made. With -Commit: the user is added to
        the entitlement group and the action is confirmed. Re-run NSZTNA-Validation.ps1 afterward.
.NOTES
    Network — ZTNA / Netskope Private Access. Default -WhatIf. Authored the repeatable way.
    Netskope-side fixes (publisher health, app/policy config) are DEFERRED to the Netskope console.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$UserPrincipalName,
    [Parameter(Mandatory)][string]$GroupName,
    [switch]$Commit   # omit for -WhatIf (preview-only) behavior
)

$whatIf = -not $Commit
Write-Host "`n=== ZTNA Remediation ($(if($whatIf){'WhatIf — preview only'}else{'COMMIT'})) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph.Groups, Microsoft.Graph.Users -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($whatIf) { @('Group.Read.All','User.Read.All') } else { @('GroupMember.ReadWrite.All','User.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

# Resolve user and group
$user = $null; $group = $null
try { $user = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$UserPrincipalName" } catch {}
if (-not $user) { Write-Host "  User not found: $UserPrincipalName" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
$group = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$GroupName'&`$select=id,displayName").value | Select-Object -First 1
if (-not $group) { Write-Host "  Entitlement group not found: '$GroupName'" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# Already a member?
$members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($group.id)/members?`$select=id").value
if ($members.id -contains $user.id) {
    Write-Host ("  No action: {0} is already in '{1}'." -f $UserPrincipalName, $GroupName) -ForegroundColor Green
    Disconnect-MgGraph | Out-Null; return
}

if ($whatIf) {
    Write-Host ("  WHATIF: would add {0} to '{1}'. Re-run with -Commit to apply." -f $UserPrincipalName, $GroupName) -ForegroundColor Yellow
} else {
    $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" }
    Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($group.id)/members/`$ref" -Body ($body | ConvertTo-Json)
    Write-Host ("  ADDED: {0} -> '{1}'. Re-run NSZTNA-Validation.ps1 after a policy cycle." -f $UserPrincipalName, $GroupName) -ForegroundColor Green
    Write-Host "  Rollback: remove the user from this group (and re-enable VPN access) if access misbehaves." -ForegroundColor DarkGray
}

Disconnect-MgGraph | Out-Null
