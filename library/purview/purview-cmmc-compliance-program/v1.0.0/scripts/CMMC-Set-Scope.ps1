<#
.SYNOPSIS
    CMMC-Set-Scope.ps1 — assign least-privilege Compliance Manager role-group membership (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Manages membership of the Compliance Manager role groups so administrators are separated from
        action contributors and read-only readers/assessors (the CMMC Access Control / least-privilege
        guardrail). It composes Add-RoleGroupMember / Remove-RoleGroupMember for a named role group and
        the supplied members. It runs with -WhatIf by DEFAULT (previews only); pass -Commit to apply.
        It never deletes a role group and never grants more than the named role.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\CMMC-Set-Scope.ps1 -RoleGroup 'Compliance Manager Contributors' -Add user1@contoso.com,user2@contoso.com
        Apply:                   powershell -ExecutionPolicy Bypass -File .\CMMC-Set-Scope.ps1 -RoleGroup 'Compliance Manager Contributors' -Add user1@contoso.com -Commit
        Remove:                  powershell -ExecutionPolicy Bypass -File .\CMMC-Set-Scope.ps1 -RoleGroup 'Compliance Manager Administrators' -Remove olduser@contoso.com -Commit
        Sign in with rights to manage role groups when prompted. For GCC High pass -ExoConnectionUri.
    EXPECTED RESULTS
        WhatIf: the exact Add/Remove it WOULD perform. -Commit: the membership changes applied, then a
        re-print of the group's membership. Verify the exact role-group name in your tenant first.
.NOTES
    White-label — Purview Solutions. Default is a dry run; changes only with -Commit. No credentials.
    Uses Add-RoleGroupMember / Remove-RoleGroupMember / Get-RoleGroupMember (S&C PowerShell). Purview
    role naming evolves — confirm the role-group name (e.g. via CMMC-Discovery.ps1) before committing.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(
        'Compliance Manager Administrators',
        'Compliance Manager Assessors',
        'Compliance Manager Contributors',
        'Compliance Manager Readers')]
    [string]$RoleGroup,
    [string[]]$Add = @(),
    [string[]]$Remove = @(),
    [switch]$Commit,
    [string]$ExoConnectionUri
)
$WhatIf = -not $Commit
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'COMMIT (applying changes)'})

if (-not $Add -and -not $Remove) { Write-Host "Nothing to do: supply -Add and/or -Remove." -ForegroundColor Yellow; exit 0 }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if ($ExoConnectionUri) { Connect-IPPSSession -ConnectionUri $ExoConnectionUri -ShowBanner:$false }
else                   { Connect-IPPSSession -ShowBanner:$false }

Write-Host ("`n=== CMMC role scope — '{0}' [{1}] ===" -f $RoleGroup, $mode) -ForegroundColor Cyan

# Confirm the role group exists (naming evolves)
$rg = $null
try { $rg = Get-RoleGroup -Identity $RoleGroup -ErrorAction Stop } catch {}
if (-not $rg) {
    Write-Host ("  Role group '{0}' not found — verify the exact name in your tenant (Requirement 2.3)." -f $RoleGroup) -ForegroundColor Red
    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    exit 1
}

$current = @(Get-RoleGroupMember -Identity $RoleGroup -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)

foreach ($m in $Add) {
    if ($current -contains $m) { Write-Host ("  {0} already a member — skip." -f $m) -ForegroundColor Green; continue }
    Write-Host ("  ADD {0} -> {1}" -f $m, $RoleGroup) -ForegroundColor Yellow
    if (-not $WhatIf) {
        try { Add-RoleGroupMember -Identity $RoleGroup -Member $m -Confirm:$false -ErrorAction Stop; Write-Host "    added." -ForegroundColor Green }
        catch { Write-Host ("    could not add {0}: {1}" -f $m, $_.Exception.Message) -ForegroundColor Red }
    }
}
foreach ($m in $Remove) {
    if ($current -notcontains $m) { Write-Host ("  {0} not a member — skip." -f $m) -ForegroundColor Green; continue }
    Write-Host ("  REMOVE {0} <- {1}" -f $m, $RoleGroup) -ForegroundColor Yellow
    if (-not $WhatIf) {
        try { Remove-RoleGroupMember -Identity $RoleGroup -Member $m -Confirm:$false -ErrorAction Stop; Write-Host "    removed." -ForegroundColor Green }
        catch { Write-Host ("    could not remove {0}: {1}" -f $m, $_.Exception.Message) -ForegroundColor Red }
    }
}

if ($WhatIf) {
    Write-Host "`nPreview only. Re-run with -Commit to apply. Grant the minimum role each person needs (least privilege)." -ForegroundColor Cyan
} else {
    Write-Host "`nMembership now:" -ForegroundColor Cyan
    Get-RoleGroupMember -Identity $RoleGroup -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | ForEach-Object { Write-Host "  - $_" }
    Write-Host "Re-run CMMC-Discovery.ps1 to refresh the 'CMMC Roles - Separation Evidence' snapshot." -ForegroundColor Cyan
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
