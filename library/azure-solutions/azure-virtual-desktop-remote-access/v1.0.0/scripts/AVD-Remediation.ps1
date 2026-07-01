<#
.SYNOPSIS
    AVD-Remediation.ps1 — safely recover unhealthy AVD session hosts (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Finds session hosts in a host pool that are not 'Available', puts each into drain mode
        (no new sessions), and restarts the underlying VM so the AVD agent re-registers. By default
        it only REPORTS what it would do; pass -Execute to actually act.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\AVD-Remediation.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot'
        Act:                    add  -Execute
        Requires Az.Accounts, Az.DesktopVirtualization, Az.Compute; run Connect-AzAccount first.
    EXPECTED RESULTS
        In preview, a list of unhealthy hosts and the planned drain+restart. With -Execute, the
        hosts are drained and their VMs restarted; re-run AVD-Validation.ps1 afterward.
.NOTES
    Azure Solutions — Azure Virtual Desktop. Defaults to -WhatIf (preview only).
#>
[CmdletBinding(SupportsShouldProcess=$true)] param(
    [string]$ResourceGroupName = 'AVD - Resource Group - Core',
    [string]$HostPoolName      = 'AVD - Host Pool - Pilot',
    [switch]$Execute
)
foreach ($m in 'Az.Accounts','Az.DesktopVirtualization','Az.Compute') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
# Default posture is preview unless -Execute is supplied.
if (-not $Execute) { $WhatIfPreference = $true }

Write-Host "=== AVD Remediation — $HostPoolName ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "(preview / -WhatIf — no changes will be made; add -Execute to act)" -ForegroundColor Yellow }

$bad = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue |
    Where-Object { $_.Status -ne 'Available' })
if (-not $bad) { Write-Host "All session hosts are Available — nothing to remediate." -ForegroundColor Green; return }

foreach ($sh in $bad) {
    $shName = ($sh.Name -split '/')[-1]          # host pool prefix is stripped to the host name
    $vmName = ($shName -split '\.')[0]            # short VM name from the FQDN
    Write-Host ("Unhealthy host: {0}  (status: {1})" -f $shName, $sh.Status) -ForegroundColor Yellow

    if ($PSCmdlet.ShouldProcess($shName, "Enable drain mode (AllowNewSession = false)")) {
        Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $shName -AllowNewSession:$false | Out-Null
        Write-Host "  drain mode enabled." -ForegroundColor Green
    }
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -ErrorAction SilentlyContinue
    if ($vm -and $PSCmdlet.ShouldProcess($vmName, "Restart VM")) {
        Restart-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName | Out-Null
        Write-Host "  VM restart requested." -ForegroundColor Green
    }
}
Write-Host "`nRe-run AVD-Validation.ps1 after the hosts re-register." -ForegroundColor Green
