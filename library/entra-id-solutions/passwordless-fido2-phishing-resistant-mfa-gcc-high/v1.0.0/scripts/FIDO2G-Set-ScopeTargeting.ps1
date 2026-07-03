<#
.SYNOPSIS
    FIDO2G-Set-ScopeTargeting.ps1 — build the GCC High pilot and all-staff groups for phishing-resistant rollout.
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the security groups the phishing-resistant rollout targets in a US
        Government (GCC High/DoD) tenant: a pilot group and an all-staff group used by the
        Authentication methods policy targeting, the registration drive, and Conditional Access
        enforcement. Optionally seeds members by UPN. Consistent group names make method targeting,
        registration, and CA policies repeatable. Runs in -WhatIf (preview) mode by default; add
        -WhatIf:$false to create/modify. Use -Environment USGovDoD on the DoD cloud.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\FIDO2G-Set-ScopeTargeting.ps1 -PilotUpns "alice@your-tenant.onmicrosoft.us","bob@your-tenant.onmicrosoft.us"
        Apply:            add -WhatIf:$false to the same command after reviewing the preview.
        Connects to US Gov Graph (-Environment USGov). Scopes: Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The pilot and all-staff groups exist (created if missing) with the requested members; their
        object IDs are printed for use in the Authentication methods policy target, the registration
        drive, and the Conditional Access authentication-strength policies.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$PilotGroupName    = 'Phishing-Resistant - Pilot - Users',
    [string]$AllStaffGroupName = 'Phishing-Resistant - All Staff - Users',
    [string[]]$PilotUpns    = @(),
    [string[]]$AllStaffUpns = @(),
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

# US Gov vs DoD directoryObjects host for $ref bodies
$graphHost = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us' } else { 'https://graph.microsoft.us' }
Write-Host "=== FIDO2G Scope Targeting (GCC High, env: $Environment) ===" -ForegroundColor Cyan
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { Write-Host "Running in PREVIEW (-WhatIf) mode — no changes will be made. Add -WhatIf:`$false to apply." -ForegroundColor Yellow }

function Get-OrNewGroup([string]$name) {
    $esc = $name.Replace("'","''")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
    if ($g) { Write-Host ("  exists : {0} ({1})" -f $name, $g.id); return $g }
    if (-not $PSCmdlet.ShouldProcess($name, "Create security group")) { Write-Host ("  WHATIF would create group: {0}" -f $name) -ForegroundColor Yellow; return $null }
    $mail = ($name -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mail; securityEnabled=$true }
    $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("  created: {0} ({1})" -f $name, $g.id) -ForegroundColor Green
    return $g
}
function Add-Members($group, [string[]]$upns) {
    if (-not $group) { return }
    foreach ($upn in $upns) {
        if (-not $PSCmdlet.ShouldProcess($upn, "Add to group $($group.displayName)")) { Write-Host ("    WHATIF would add: {0}" -f $upn) -ForegroundColor Yellow; continue }
        try {
            $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn")
            $ref = @{ '@odata.id' = "$graphHost/v1.0/directoryObjects/$($u.id)" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($group.id)/members/`$ref" -Body ($ref | ConvertTo-Json) | Out-Null
            Write-Host ("    + {0}" -f $upn) -ForegroundColor Green
        } catch { Write-Host ("    ! {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
    }
}

$pilot    = Get-OrNewGroup $PilotGroupName
$allStaff = Get-OrNewGroup $AllStaffGroupName
if ($PilotUpns)    { Write-Host "Adding pilot members:";    Add-Members $pilot    $PilotUpns }
if ($AllStaffUpns) { Write-Host "Adding all-staff members:"; Add-Members $allStaff $AllStaffUpns }

Write-Host "`nUse these group IDs in the Authentication methods policy target, the registration drive, and Conditional Access:" -ForegroundColor Cyan
if ($pilot)    { Write-Host ("  Pilot group     : {0}" -f $pilot.id) }
if ($allStaff) { Write-Host ("  All-staff group : {0}" -f $allStaff.id) }
Write-Host "Reminder: exclude the two break-glass accounts from every enforcement policy." -ForegroundColor DarkCyan
Disconnect-MgGraph | Out-Null
