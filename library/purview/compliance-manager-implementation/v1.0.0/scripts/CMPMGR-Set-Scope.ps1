<#
.SYNOPSIS
    CMPMGR-Set-Scope.ps1 — manage Compliance Manager role-group membership for least-privilege separation (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Adds or removes a member of a Compliance Manager role group (Administrators / Assessors /
        Contributors / Readers) to enforce least-privilege separation — administrators separate from
        contributors, readers/auditors read-only. Safe by default: -WhatIf only describes the change;
        it modifies membership only when -Commit is supplied. Uses the real Add-RoleGroupMember /
        Remove-RoleGroupMember cmdlets via Security & Compliance PowerShell.
    HOW TO RUN
        # Dry-run (default) — describe what it WOULD change:
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Set-Scope.ps1 -RoleGroup 'Compliance Manager Contributors' -Member user@contoso.com -Action Add -WhatIf
        # Apply:
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Set-Scope.ps1 -RoleGroup 'Compliance Manager Readers' -Member auditor@contoso.com -Action Add -Commit
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Sign in with an admin who can manage
        role-group membership. Verify the exact role-group name in your tenant; Purview naming evolves.
    EXPECTED RESULTS
        -WhatIf: prints the current membership and the single add/remove it WOULD perform; no change.
        -Commit: performs the add/remove, then reprints the group's membership as confirmation. A
        post-change separation note warns if the member is now both an Administrator and a Contributor.
.NOTES
    Purview — Microsoft Purview Compliance Manager Implementation. Safe-by-default (-WhatIf). No
    credentials are stored. Change membership under change control; grant the minimum role needed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Compliance Manager Administrators','Compliance Manager Assessors','Compliance Manager Contributors','Compliance Manager Readers')]
    [string]$RoleGroup,
    [Parameter(Mandatory)][string]$Member,
    [Parameter(Mandatory)][ValidateSet('Add','Remove')][string]$Action,
    [switch]$Commit,
    [switch]$WhatIf
)

if (-not $Commit) { $WhatIf = $true }

# --- Connect (Security & Compliance PowerShell) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement module...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
} catch {
    Write-Error "Connect-IPPSSession failed: $($_.Exception.Message). Confirm licensing and your admin role."
    return
}

# --- Confirm the role group exists ---
if (-not (Get-RoleGroup -Identity $RoleGroup -ErrorAction SilentlyContinue)) {
    Write-Error "Role group '$RoleGroup' not found. Verify the exact name in your tenant (Purview role naming evolves)."
    return
}

function Show-Members($g) {
    $m = @(Get-RoleGroupMember -Identity $g -ErrorAction SilentlyContinue)
    Write-Host ("Current membership of '{0}' ({1}):" -f $g, $m.Count) -ForegroundColor Cyan
    if ($m.Count -eq 0) { Write-Host '    (empty)' -ForegroundColor DarkGray }
    foreach ($x in $m) { Write-Host ("    {0}" -f ($(if ($x.PrimarySmtpAddress) { $x.PrimarySmtpAddress } else { $x.Name }))) }
}

Show-Members $RoleGroup

$already = @(Get-RoleGroupMember -Identity $RoleGroup -ErrorAction SilentlyContinue | Where-Object { $_.PrimarySmtpAddress -eq $Member -or $_.Name -eq $Member -or $_.WindowsLiveID -eq $Member }).Count -gt 0

Write-Host ''
if ($Action -eq 'Add' -and $already)      { Write-Host ("[skip] {0} is already a member of '{1}'." -f $Member, $RoleGroup) -ForegroundColor DarkYellow; return }
if ($Action -eq 'Remove' -and -not $already) { Write-Host ("[skip] {0} is not a member of '{1}'." -f $Member, $RoleGroup) -ForegroundColor DarkYellow; return }

if ($WhatIf) {
    Write-Host ("[WhatIf] WOULD {0} '{1}' {2} role group '{3}'. No change made. Re-run with -Commit to apply." -f $Action.ToUpper(), $Member, ($(if ($Action -eq 'Add') { 'to' } else { 'from' })), $RoleGroup) -ForegroundColor Yellow
    return
}

# --- Commit ---
try {
    if ($Action -eq 'Add') {
        Add-RoleGroupMember -Identity $RoleGroup -Member $Member -Confirm:$false -ErrorAction Stop
        Write-Host ("[Commit] Added {0} to '{1}'." -f $Member, $RoleGroup) -ForegroundColor Green
    } else {
        Remove-RoleGroupMember -Identity $RoleGroup -Member $Member -Confirm:$false -ErrorAction Stop
        Write-Host ("[Commit] Removed {0} from '{1}'." -f $Member, $RoleGroup) -ForegroundColor Green
    }
} catch {
    Write-Error "Membership change failed: $($_.Exception.Message)"
    return
}

Write-Host ''
Show-Members $RoleGroup

# --- Post-change separation note ---
$admins       = @(Get-RoleGroupMember -Identity 'Compliance Manager Administrators' -ErrorAction SilentlyContinue | ForEach-Object { if ($_.PrimarySmtpAddress) { $_.PrimarySmtpAddress } else { $_.Name } })
$contributors = @(Get-RoleGroupMember -Identity 'Compliance Manager Contributors' -ErrorAction SilentlyContinue | ForEach-Object { if ($_.PrimarySmtpAddress) { $_.PrimarySmtpAddress } else { $_.Name } })
$overlap = $admins | Where-Object { $contributors -contains $_ } | Select-Object -Unique
if ($overlap) {
    Write-Host ''
    Write-Host '[SEPARATION NOTE] These identities are now BOTH Administrators and Contributors — grant the minimum role or record governance acceptance:' -ForegroundColor Yellow
    $overlap | ForEach-Object { Write-Host ("    - {0}" -f $_) -ForegroundColor Yellow }
}
