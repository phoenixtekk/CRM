<#
.SYNOPSIS
    HYBIDG-Set-ScopeTargeting.ps1 — build/confirm the sync target group for staged Pilot/Expand waves.
.DESCRIPTION
    PURPOSE
        Manages the on-premises Active Directory security group used to scope directory
        synchronization for a Microsoft 365 U.S. Government GCC High deployment (for example
        the group named sg-HybridIdentity-Pilot or sg-HybridIdentity-InScope). It can create the
        group if missing and add named members for the next wave. Defaults to -WhatIf: it previews
        every change and applies nothing until you re-run with -WhatIf:$false. Run from a host with
        the ActiveDirectory RSAT module.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HYBIDG-Set-ScopeTargeting.ps1 -GroupName "sg-HybridIdentity-Pilot"                    (preview)
        powershell -ExecutionPolicy Bypass -File .\HYBIDG-Set-ScopeTargeting.ps1 -GroupName "sg-HybridIdentity-Pilot" -Members user1,user2 -WhatIf:$false   (apply)
        (No Graph call required; -Environment USGov accepted for consistency with the other scripts.)
    EXPECTED RESULTS
        A preview (default) or applied change showing the group state and members. Use this to widen
        sync scope one controlled wave at a time. Verify each wave before the next.
.NOTES
    White-label — the repeatable way. Local AD changes are gated behind -WhatIf.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$GroupName,

    # sAMAccountNames to add to the scope group for this wave.
    [string[]]$Members = @(),

    # OU distinguished name to create the group in if it does not exist.
    [string]$GroupOU,

    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',

    # Safety default: preview only. Set -WhatIf:$false to apply.
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
Write-Host "=== HYBIDG Set-ScopeTargeting (Government / GCC High) ===" -ForegroundColor Cyan
if ($WhatIf) { Write-Host "MODE: PREVIEW (-WhatIf). No AD changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Host "[ERROR] ActiveDirectory RSAT module required. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --- Ensure the scope group exists ---
$group = Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue
if (-not $group) {
    if (-not $GroupOU) {
        Write-Host "[INFO] Group '$GroupName' not found. Provide -GroupOU to create it." -ForegroundColor Yellow
    } elseif ($WhatIf) {
        Write-Host "[WOULD CREATE] Group '$GroupName' (Global/Security) in $GroupOU" -ForegroundColor Yellow
    } elseif ($PSCmdlet.ShouldProcess($GroupName,"Create AD security group in $GroupOU")) {
        New-ADGroup -Name $GroupName -GroupScope Global -GroupCategory Security -Path $GroupOU
        Write-Host "[CREATED] Group '$GroupName' in $GroupOU" -ForegroundColor Green
        $group = Get-ADGroup -Filter "Name -eq '$GroupName'"
    }
} else {
    Write-Host "[OK] Group '$GroupName' exists: $($group.DistinguishedName)" -ForegroundColor Green
}

# --- Add wave members ---
foreach ($m in $Members) {
    try {
        $user = Get-ADUser -Filter "sAMAccountName -eq '$m'" -ErrorAction Stop
        $already = Get-ADGroupMember -Identity $GroupName -ErrorAction SilentlyContinue |
                   Where-Object { $_.SamAccountName -eq $m }
        if ($already) {
            Write-Host "[OK] $m already a member of $GroupName" -ForegroundColor Green
        } elseif ($WhatIf) {
            Write-Host "[WOULD ADD] $m -> $GroupName" -ForegroundColor Yellow
        } elseif ($PSCmdlet.ShouldProcess($m,"Add to $GroupName")) {
            Add-ADGroupMember -Identity $GroupName -Members $user
            Write-Host "[ADDED] $m -> $GroupName" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Member '$m': $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Report current membership ---
if ($group) {
    Write-Host "`nCurrent members of ${GroupName}:" -ForegroundColor Cyan
    Get-ADGroupMember -Identity $GroupName -ErrorAction SilentlyContinue |
        Select-Object Name, SamAccountName | Format-Table -AutoSize
}

Write-Host "`nReminder: after updating scope, point Entra Connect group filtering at '$GroupName' and let a sync cycle run, then validate this wave before the next." -ForegroundColor Cyan
if ($WhatIf) { Write-Host "Preview only. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }
exit 0
