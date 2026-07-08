<#
.SYNOPSIS
    CMPFRAME-Set-Scope.ps1 — manage Compliance Manager role-group membership, -WhatIf by default (writes only with -Commit).
.DESCRIPTION
    PURPOSE
        Applies least-privilege separation for the Regulatory Assessment Framework by adding or removing a
        member from a Compliance Manager role group (Administrators / Assessors / Contributors / Readers).
        Previews the exact Add-RoleGroupMember / Remove-RoleGroupMember it would run under -WhatIf and
        changes membership ONLY with -Commit — so an over-grant is caught before it is applied.
    HOW TO RUN
        # Preview (default): show what would change
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Set-Scope.ps1 -RoleGroup Contributors -Member user@contoso.com -Action Add -WhatIf
        # Apply
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Set-Scope.ps1 -RoleGroup Contributors -Member user@contoso.com -Action Add -Commit
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and a role that can manage role groups.
        Interactive modern-auth / MFA; no secrets in code.
    EXPECTED RESULTS
        Under -WhatIf: prints the membership change it WOULD make and lists current members. Under -Commit:
        applies it and re-reads the group. Grant the MINIMUM role each person needs; keep administrators
        separated from contributors and readers/auditors read-only.
.NOTES
    Purview — Regulatory Assessment Framework. Safe-by-default (-WhatIf). No credentials stored. Role-group
    names are the Purview defaults — verify they exist in your tenant (Settings > Roles & scopes).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Administrators','Assessors','Contributors','Readers')]
    [string]$RoleGroup,

    [Parameter(Mandatory = $true)][string]$Member,     # UPN of the person to add/remove (e.g. user@contoso.com)
    [Parameter(Mandatory = $true)][ValidateSet('Add','Remove')][string]$Action,
    [switch]$Commit,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "  $m" -ForegroundColor White }
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }

if (-not $Commit) { $WhatIfPreference = $true; Info "No -Commit: preview only (-WhatIf) — no membership change will be made." }

$groupName = "Compliance Manager $RoleGroup"

$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession @connectParams | Out-Null

Write-Host "`n=== $Action '$Member' $([string]::Format('{0}', ($Action -eq 'Add' ? 'to' : 'from'))) '$groupName' ===" -ForegroundColor Cyan

# Confirm the group exists
try { $rg = Get-RoleGroup -Identity $groupName -ErrorAction Stop }
catch { Warn "Role group '$groupName' not found or not readable — verify the name in Settings > Roles & scopes. $($_.Exception.Message)"; return }

$before = @(Get-RoleGroupMember -Identity $groupName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
Info ("Current members ({0}): {1}" -f $before.Count, (($before | Sort-Object) -join ', '))

$already = ($before -contains $Member) -or ($before -contains ($Member.Split('@')[0]))
if ($Action -eq 'Add' -and $already) { Warn "'$Member' already appears to be a member of '$groupName' — nothing to add."; return }
if ($Action -eq 'Remove' -and -not $already) { Warn "'$Member' does not appear to be a member of '$groupName' — nothing to remove."; return }

if ($Action -eq 'Add') {
    Info "Would run: Add-RoleGroupMember -Identity '$groupName' -Member '$Member'"
    Add-RoleGroupMember -Identity $groupName -Member $Member -Confirm:$false
    if ($Commit) { Ok "Added '$Member' to '$groupName'." }
} else {
    Info "Would run: Remove-RoleGroupMember -Identity '$groupName' -Member '$Member'"
    Remove-RoleGroupMember -Identity $groupName -Member $Member -Confirm:$false
    if ($Commit) { Ok "Removed '$Member' from '$groupName'." }
}

if ($Commit) {
    $after = @(Get-RoleGroupMember -Identity $groupName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    Info ("Members now ({0}): {1}" -f $after.Count, (($after | Sort-Object) -join ', '))
} else {
    Info "Preview complete. Re-run with -Commit to apply."
}
