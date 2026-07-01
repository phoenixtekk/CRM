<#
.SYNOPSIS
    CPAVPN-Set-ScopeTargeting.ps1 — create/populate the per-app VPN pilot (and broad) Entra group(s) (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates the Entra ID security groups that scope Cisco per-app VPN assignment —
        'PILOT - Per-App VPN Users' and (optionally) 'BROAD - Per-App VPN Users' — and populates the
        pilot group with the members you name. Defaults to -WhatIf so nothing changes until you pass
        -Apply. Assign the VPN profiles and apps to these groups per the Implementation Guide.
    HOW TO RUN
        Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\CPAVPN-Set-ScopeTargeting.ps1 -PilotMembers user1@your-tenant.com,user2@your-tenant.com
        Apply:
        powershell -ExecutionPolicy Bypass -File .\CPAVPN-Set-ScopeTargeting.ps1 -PilotMembers user1@your-tenant.com -Apply

        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Group.ReadWrite.All, GroupMember.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The pilot group (and broad group if requested) exist and the named members are added to the
        pilot group. With -WhatIf (default) it prints the plan only; with -Apply it makes the change.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco internals deferred to vendor docs.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [string]   $PilotGroup   = 'PILOT - Per-App VPN Users',
    [string]   $BroadGroup   = 'BROAD - Per-App VPN Users',
    [string[]] $PilotMembers = @(),          # UPNs to add to the pilot group
    [switch]   $CreateBroad,                  # also create the broad expansion group
    [switch]   $Apply                         # omit = preview (-WhatIf) only
)

if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "`n=== CPAVPN Set-ScopeTargeting — per-app VPN groups ===" -ForegroundColor Cyan
Write-Host ("  Mode: {0}" -f ($(if ($Apply) { 'APPLY (changes will be made)' } else { 'PREVIEW (-WhatIf, no changes)' }))) -ForegroundColor $(if ($Apply) { 'Yellow' } else { 'Green' })

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','GroupMember.ReadWrite.All','User.Read.All' -NoWelcome

function Get-OrCreate-Group {
    param([string] $Name)
    $f = "displayName eq '$($Name.Replace("'","''"))'"
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value | Select-Object -First 1
    if ($existing) { Write-Host ("  OK   group exists: {0}" -f $Name) -ForegroundColor Green; return $existing }

    if ($PSCmdlet.ShouldProcess($Name, "Create Entra security group")) {
        $mailNick = ($Name -replace '[^a-zA-Z0-9]', '')
        $body = @{
            displayName     = $Name
            description     = 'Targeting group for Cisco Secure Client per-app VPN (Intune).'
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body ($body | ConvertTo-Json)
        Write-Host ("  CREATED group: {0}" -f $Name) -ForegroundColor Green
        return $g
    } else {
        Write-Host ("  WHATIF would create group: {0}" -f $Name) -ForegroundColor Yellow
        return $null
    }
}

# --- Pilot group ---
Write-Host "`n[Pilot group]" -ForegroundColor Cyan
$pilot = Get-OrCreate-Group -Name $PilotGroup

# --- Populate pilot members ---
if ($PilotMembers.Count) {
    Write-Host "`n[Pilot members]" -ForegroundColor Cyan
    foreach ($upn in $PilotMembers) {
        try {
            $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn").id
        } catch { Write-Host ("  SKIP user not found: {0}" -f $upn) -ForegroundColor Yellow; continue }
        if ($PSCmdlet.ShouldProcess($upn, "Add to $PilotGroup")) {
            if ($pilot) {
                try {
                    $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$u" }
                    Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($pilot.id)/members/`$ref" -Body ($ref | ConvertTo-Json)
                    Write-Host ("  ADDED  {0}" -f $upn) -ForegroundColor Green
                } catch {
                    if ($_.Exception.Message -match 'already exist') { Write-Host ("  OK     already a member: {0}" -f $upn) -ForegroundColor Green }
                    else { Write-Host ("  ERR    {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
                }
            } else { Write-Host ("  WHATIF would add {0} (group not created in preview)" -f $upn) -ForegroundColor Yellow }
        } else {
            Write-Host ("  WHATIF would add {0} to {1}" -f $upn, $PilotGroup) -ForegroundColor Yellow
        }
    }
}

# --- Broad group (optional) ---
if ($CreateBroad) {
    Write-Host "`n[Broad expansion group]" -ForegroundColor Cyan
    Get-OrCreate-Group -Name $BroadGroup | Out-Null
}

Write-Host "`nAssign 'Cisco Per-App VPN - iOS' / 'Cisco Per-App VPN - Android' to these groups per the Implementation Guide." -ForegroundColor Green
if (-not $Apply) { Write-Host "Preview only. Re-run with -Apply to make changes." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
