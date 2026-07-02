<#
.SYNOPSIS
    VOIPSUP-Set-ScopeTargeting.ps1 — build/assign the pilot security group for controlled VOIP rollout.
.DESCRIPTION
    PURPOSE
        Creates (if missing) a Microsoft Entra security group for the VOIP/softphone endpoint-support
        pilot and adds the specified members (users or devices) via Microsoft Graph, so you validate the
        method and scripts on a controlled set before fleet-wide use. Defaults to preview only (-WhatIf)
        so you review the planned group and membership changes before anything is written to Entra.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Set-ScopeTargeting.ps1 -GroupName VOIPSUP-Pilot -MemberUpns user1@your-domain,user2@your-domain
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Set-ScopeTargeting.ps1 -GroupName VOIPSUP-Pilot -MemberUpns user1@your-domain -Execute
        (Requires the Microsoft.Graph modules and Group.ReadWrite.All / GroupMember.ReadWrite.All consent.)
    EXPECTED RESULTS
        In preview mode: the group that WOULD be created/reused and the members that WOULD be added, no
        changes made. With -Execute: the group is created if absent and members are added, with a
        confirmation line per member.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
    Scope-targeting defaults to -WhatIf; pass -Execute (or -WhatIf:$false) to apply.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]   $GroupName,
    [string]   $GroupDescription = 'Pilot group for VOIP/softphone endpoint-support validation.',
    # UPNs of users to add, e.g. user1@your-domain,user2@your-domain
    [string[]] $MemberUpns = @(),
    # Object IDs of devices to add (optional).
    [string[]] $MemberDeviceIds = @(),
    [switch]   $Execute
)

if ($Execute) { $WhatIfPreference = $false }
elseif (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Write-Host '=== VOIPSUP Set-ScopeTargeting — pilot group builder (Microsoft Graph) ===' -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host 'MODE: PREVIEW (-WhatIf). No changes will be made. Add -Execute to apply.' -ForegroundColor Yellow }
else { Write-Host 'MODE: EXECUTE. Group / membership changes will be written to Entra.' -ForegroundColor Red }
Write-Host ''

# ---- Ensure Microsoft Graph modules ----
foreach ($mod in @('Microsoft.Graph.Authentication','Microsoft.Graph.Groups')) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Warning "Module '$mod' is not installed. Install with: Install-Module $mod -Scope CurrentUser"
        Write-Host 'Cannot proceed without the Microsoft.Graph modules. Exiting.' -ForegroundColor Red
        return
    }
    Import-Module $mod -ErrorAction Stop
}

# ---- Connect ----
try {
    Connect-MgGraph -Scopes 'Group.ReadWrite.All','GroupMember.ReadWrite.All','User.Read.All','Device.Read.All' -NoWelcome -ErrorAction Stop
    Write-Host ("Connected to Graph as: {0}" -f (Get-MgContext).Account) -ForegroundColor Green
} catch {
    Write-Warning "Graph connection failed: $($_.Exception.Message)"
    return
}
Write-Host ''

# ---- Find or create the group ----
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($group) {
    Write-Host ("Group already exists: {0} ({1})" -f $group.DisplayName,$group.Id) -ForegroundColor Green
} else {
    Write-Host ("Group '{0}' not found; it will be created." -f $GroupName) -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($GroupName,'Create Entra security group')) {
        try {
            $mailNick = ($GroupName -replace '[^0-9A-Za-z]', '')
            $group = New-MgGroup -DisplayName $GroupName -Description $GroupDescription `
                -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -ErrorAction Stop
            Write-Host ("Created group: {0} ({1})" -f $group.DisplayName,$group.Id) -ForegroundColor Green
        } catch {
            Write-Warning "Group creation failed: $($_.Exception.Message)"
            return
        }
    }
}

if (-not $group) {
    Write-Host '(Preview) Group would be created; member additions below are shown against the new group.' -ForegroundColor Yellow
}

# ---- Add user members ----
foreach ($upn in $MemberUpns) {
    if (-not $upn) { continue }
    $user = $null
    try { $user = Get-MgUser -UserId $upn -ErrorAction Stop } catch { }
    if (-not $user) { Write-Warning ("User not found: {0}" -f $upn); continue }
    if ($PSCmdlet.ShouldProcess($upn, ("Add user to group '{0}'" -f $GroupName))) {
        if ($group) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction Stop
                Write-Host ("Added user: {0}" -f $upn) -ForegroundColor Green
            } catch {
                if ($_.Exception.Message -match 'already exist') { Write-Host ("Already a member: {0}" -f $upn) }
                else { Write-Warning ("Failed to add {0}: {1}" -f $upn,$_.Exception.Message) }
            }
        } else {
            Write-Host ("(Preview) Would add user: {0}" -f $upn)
        }
    }
}

# ---- Add device members ----
foreach ($devId in $MemberDeviceIds) {
    if (-not $devId) { continue }
    if ($PSCmdlet.ShouldProcess($devId, ("Add device to group '{0}'" -f $GroupName))) {
        if ($group) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $devId -ErrorAction Stop
                Write-Host ("Added device: {0}" -f $devId) -ForegroundColor Green
            } catch {
                if ($_.Exception.Message -match 'already exist') { Write-Host ("Already a member: {0}" -f $devId) }
                else { Write-Warning ("Failed to add device {0}: {1}" -f $devId,$_.Exception.Message) }
            }
        } else {
            Write-Host ("(Preview) Would add device: {0}" -f $devId)
        }
    }
}

Write-Host ''
Write-Host 'Scope-targeting routine complete. Assign your VOIP endpoint policies/apps to this pilot group,' -ForegroundColor Cyan
Write-Host 'validate with VOIPSUP-Validation.ps1 / VOIPSUP-Report.ps1, then expand to the fleet.' -ForegroundColor Cyan
try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch { }
