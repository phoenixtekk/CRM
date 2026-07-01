<#
.SYNOPSIS
    AVD-Discovery.ps1 — Azure Virtual Desktop readiness and current AVD posture.
.DESCRIPTION
    PURPOSE
        Reports the signed-in Azure context (subscription/tenant), the target resource group, and an
        inventory of existing AVD host pools, their type (Pooled/Personal), session hosts, and
        published application groups — so you can see what already exists before configuring.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVD-Discovery.ps1 -ResourceGroupName 'AVD - Resource Group - Core'
        Requires the Az.Accounts and Az.DesktopVirtualization modules. Run Connect-AzAccount first
        (or the script will prompt). Read-only.
    EXPECTED RESULTS
        Azure context, the resource group, and a list of host pools with type, session-host count,
        and application groups.
.NOTES
    Azure Solutions — Azure Virtual Desktop. Read-only.
#>
[CmdletBinding()] param([string]$ResourceGroupName = 'AVD - Resource Group - Core')

foreach ($m in 'Az.Accounts','Az.DesktopVirtualization') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$ctx = Get-AzContext
Write-Host "`n=== Azure Virtual Desktop — readiness ===" -ForegroundColor Cyan
Write-Host ("Account       : {0}" -f $ctx.Account.Id)
Write-Host ("Subscription  : {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)
Write-Host ("Tenant        : {0}" -f $ctx.Tenant.Id)

$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($rg) { Write-Host ("Resource group: {0} ({1})" -f $rg.ResourceGroupName, $rg.Location) -ForegroundColor Green }
else { Write-Host ("Resource group: '{0}' NOT FOUND — create it before configuring." -f $ResourceGroupName) -ForegroundColor Yellow }

Write-Host "`n=== Host pools ===" -ForegroundColor Cyan
$pools = if ($rg) { Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue } else { @() }
if (-not $pools) { Write-Host "  (none found in this resource group)" -ForegroundColor Yellow }
foreach ($hp in $pools) {
    $name  = $hp.Name
    $hosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $name -ErrorAction SilentlyContinue)
    $ags   = @(Get-AzWvdApplicationGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Where-Object { $_.HostPoolArmPath -eq $hp.Id })
    Write-Host ("  {0}  [type: {1}; load-balancer: {2}; session hosts: {3}; app groups: {4}]" -f `
        $name, $hp.HostPoolType, $hp.LoadBalancerType, $hosts.Count, $ags.Count)
}
Write-Host "`nReview complete." -ForegroundColor Green
