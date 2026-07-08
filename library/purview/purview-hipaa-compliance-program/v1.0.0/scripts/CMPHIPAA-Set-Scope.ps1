<#
.SYNOPSIS
    CMPHIPAA-Set-Scope.ps1 — manage least-privilege Compliance Manager role-group membership for the HIPAA
    program (-WhatIf by default; applies with -Commit).
.DESCRIPTION
    PURPOSE
        Adds or removes a member of a Compliance Manager role group (Administrators / Assessors /
        Contributors / Readers) to enforce the least-privilege separation the program requires — the HIPAA
        Security/Privacy Officer and auditors as Readers, action owners as Contributors, assessment leads as
        Assessors, program owners as Administrators. Runs with -WhatIf by default and only PRINTS the
        Add-/Remove-RoleGroupMember it would run; add -Commit to apply.
    HOW TO RUN
        Preview:  powershell -ExecutionPolicy Bypass -File .\CMPHIPAA-Set-Scope.ps1 -Action Add \
                    -RoleGroup 'Compliance Manager Readers' -Member officer@contoso.com
        Apply:    ... -Action Add -RoleGroup 'Compliance Manager Readers' -Member officer@contoso.com -Commit
        PowerShell 5.1+ / 7+. Requires ExchangeOnlineManagement (Connect-IPPSSession) with an admin able to
        manage role groups. Interactive modern-auth sign-in; no secrets in code.
    EXPECTED RESULTS
        Dry-run prints the exact membership change it would make (no change applied). With -Commit, the
        member is added/removed and the resulting membership is printed for confirmation.
.NOTES
    Purview category — HIPAA compliance program. Write-capable (role membership only); -WhatIf by default.
    Grant the MINIMUM role each person needs; keep the Security/Privacy Officer and auditors read-only.
    Verify the exact role-group names in your tenant — Purview role naming evolves.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Add','Remove')] [string]$Action,
    [Parameter(Mandatory)][ValidateSet(
        'Compliance Manager Administrators',
        'Compliance Manager Assessors',
        'Compliance Manager Contributors',
        'Compliance Manager Readers')] [string]$RoleGroup,
    [Parameter(Mandatory)][string]$Member,          # UPN / identity of the person
    [string]$UserPrincipalName,                      # optional admin UPN for Connect-*
    [switch]$Commit                                  # apply; without it, dry-run only
)

$ErrorActionPreference = 'Stop'
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Info($m){ Write-Host $m -ForegroundColor Gray }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }
if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# Guardrail: warn on privilege escalation into Administrators.
if ($Action -eq 'Add' -and $RoleGroup -eq 'Compliance Manager Administrators') {
    Warn "You are adding an ADMINISTRATOR. Confirm this person needs full config rights — most owners need Contributor; oversight needs Reader."
}

$cmd = if ($Action -eq 'Add') { "Add-RoleGroupMember" } else { "Remove-RoleGroupMember" }
$preview = "$cmd -Identity '$RoleGroup' -Member '$Member'"
if ($Action -eq 'Remove') { $preview += " -Confirm:`$false" }

if (-not $Commit) {
    Write-Host "`n=== DRY-RUN (-WhatIf) — no change applied ===" -ForegroundColor Cyan
    Info "Would run: $preview"
    Warn "Add -Commit to apply. Grant the minimum role the person needs."
    return
}

Write-Host "`n=== Applying membership change ===" -ForegroundColor Cyan
try {
    if ($Action -eq 'Add') { Add-RoleGroupMember -Identity $RoleGroup -Member $Member -ErrorAction Stop }
    else { Remove-RoleGroupMember -Identity $RoleGroup -Member $Member -Confirm:$false -ErrorAction Stop }
    Ok "$Action complete: '$Member' on '$RoleGroup'."
} catch {
    Warn "Change failed: $($_.Exception.Message)"; return
}

Info "Resulting membership of '$RoleGroup':"
try {
    $m = @(Get-RoleGroupMember -Identity $RoleGroup -ErrorAction Stop | Select-Object -ExpandProperty Name)
    Info ("  " + $(if ($m){ $m -join ', ' } else { '(empty)' }))
} catch { Warn "Could not re-read membership: $($_.Exception.Message)" }
Warn "Re-run CMPHIPAA-Discovery.ps1 to refresh the HIPAA Roles - Separation Evidence snapshot."
