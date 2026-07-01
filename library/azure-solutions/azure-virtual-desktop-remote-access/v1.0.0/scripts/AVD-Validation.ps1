<#
.SYNOPSIS
    AVD-Validation.ps1 — confirm an AVD host pool, session hosts, workspace, and app group are healthy.
.DESCRIPTION
    PURPOSE
        Validates that the named host pool exists, its session hosts are Available, a Desktop
        application group is published, and that application group is registered to the workspace
        and has at least one assignment — the readiness gate before users connect.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVD-Validation.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot' `
            -WorkspaceName 'AVD - Workspace - Core'
        Requires Az.Accounts and Az.DesktopVirtualization; run Connect-AzAccount first. Read-only.
    EXPECTED RESULTS
        "HOST POOL READY" when hosts are Available and the Desktop app group is published and
        registered to the workspace; otherwise a list of what is missing.
.NOTES
    Azure Solutions — Azure Virtual Desktop. Read-only.
#>
[CmdletBinding()] param(
    [string]$ResourceGroupName = 'AVD - Resource Group - Core',
    [string]$HostPoolName      = 'AVD - Host Pool - Pilot',
    [string]$WorkspaceName     = 'AVD - Workspace - Core'
)
foreach ($m in 'Az.Accounts','Az.DesktopVirtualization') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Write-Host "=== AVD Validation — $HostPoolName ===" -ForegroundColor Cyan
$issues = @()

$hp = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $HostPoolName -ErrorAction SilentlyContinue
if (-not $hp) { $issues += "Host pool '$HostPoolName' not found" }
else { Write-Host ("Host pool             : OK ({0})" -f $hp.HostPoolType) -ForegroundColor Green }

$hosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue)
$avail = @($hosts | Where-Object { $_.Status -eq 'Available' })
if ($hosts.Count -eq 0) { $issues += "No session hosts in the pool" }
elseif ($avail.Count -lt $hosts.Count) { $issues += "$($avail.Count)/$($hosts.Count) session hosts Available" }
Write-Host ("Session hosts         : {0}/{1} Available" -f $avail.Count, $hosts.Count) -ForegroundColor ($(if($hosts.Count -and $avail.Count -eq $hosts.Count){'Green'}else{'Yellow'}))

$desktop = Get-AzWvdApplicationGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
    Where-Object { $hp -and $_.HostPoolArmPath -eq $hp.Id -and $_.ApplicationGroupType -eq 'Desktop' } | Select-Object -First 1
if (-not $desktop) { $issues += "No Desktop application group for this host pool" }
else { Write-Host ("Desktop app group     : OK ({0})" -f $desktop.Name) -ForegroundColor Green }

$ws = Get-AzWvdWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) { $issues += "Workspace '$WorkspaceName' not found" }
elseif ($desktop -and ($ws.ApplicationGroupReference -notcontains $desktop.Id)) { $issues += "Desktop app group not registered to the workspace" }
else { Write-Host ("Workspace registration: OK ({0})" -f $WorkspaceName) -ForegroundColor Green }

if ($desktop) {
    $assign = @(Get-AzRoleAssignment -Scope $desktop.Id -ErrorAction SilentlyContinue | Where-Object { $_.RoleDefinitionName -eq 'Desktop Virtualization User' })
    if ($assign.Count -eq 0) { $issues += "No 'Desktop Virtualization User' assignment on the Desktop app group" }
    else { Write-Host ("Assignment            : OK ({0} principal(s))" -f $assign.Count) -ForegroundColor Green }
}

if ($issues.Count -eq 0) { Write-Host "`nResult: HOST POOL READY" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT READY —" -ForegroundColor Yellow; $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }; exit 1 }
