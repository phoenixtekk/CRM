<#
.SYNOPSIS
    AVDDEP-Discovery.ps1 — Inventory the AVD build estate: Compute Gallery images, host pools, session hosts, FSLogix storage, and scaling plans.
.DESCRIPTION
    PURPOSE
        Captures a read-only baseline of everything on the deployment/image side of AVD before you build
        or change anything: the signed-in Azure context, Azure Compute Galleries with their image
        definitions and versions, host pools with their session hosts and source image, any profile
        storage accounts, and scaling plans. Use it as your pre-change baseline (rollback reference).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVDDEP-Discovery.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' `
            -ImagingResourceGroupName 'AVD - Resource Group - Imaging'
        Requires Az.Accounts, Az.Compute, Az.DesktopVirtualization, Az.Storage. Run Connect-AzAccount
        first (or the script prompts). Read-only.
    EXPECTED RESULTS
        Azure context; galleries/definitions/versions; host pools with session-host counts and image
        provenance; profile storage accounts; scaling plans. Nothing is modified.
.NOTES
    Azure Solutions — Azure Virtual Desktop (deployment/image/FSLogix/scaling). Read-only.
#>
[CmdletBinding()]
param(
    [string]$ResourceGroupName        = 'AVD - Resource Group - Core',
    [string]$ImagingResourceGroupName = 'AVD - Resource Group - Imaging'
)

foreach ($m in 'Az.Accounts','Az.Compute','Az.DesktopVirtualization','Az.Storage') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$ctx = Get-AzContext
Write-Host "`n=== AVD deployment estate — discovery ===" -ForegroundColor Cyan
Write-Host ("Account       : {0}" -f $ctx.Account.Id)
Write-Host ("Subscription  : {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)
Write-Host ("Tenant        : {0}" -f $ctx.Tenant.Id)

# --- Compute Galleries, image definitions and versions ---
Write-Host "`n=== Azure Compute Gallery — image versions ===" -ForegroundColor Cyan
$galleries = Get-AzGallery -ErrorAction SilentlyContinue
if (-not $galleries) { Write-Host "  (no compute galleries found in this subscription)" -ForegroundColor Yellow }
foreach ($g in $galleries) {
    Write-Host ("  Gallery: {0}  (RG: {1})" -f $g.Name, $g.ResourceGroupName) -ForegroundColor Green
    $defs = Get-AzGalleryImageDefinition -ResourceGroupName $g.ResourceGroupName -GalleryName $g.Name -ErrorAction SilentlyContinue
    foreach ($d in $defs) {
        $vers = Get-AzGalleryImageVersion -ResourceGroupName $g.ResourceGroupName -GalleryName $g.Name -GalleryImageDefinitionName $d.Name -ErrorAction SilentlyContinue
        Write-Host ("    Definition: {0}  [OS: {1}; Gen: {2}; versions: {3}]" -f $d.Name, $d.OsType, $d.HyperVGeneration, @($vers).Count)
        foreach ($v in $vers) {
            Write-Host ("      version {0}  provisioning: {1}" -f $v.Name, $v.ProvisioningState)
        }
    }
}

# --- Host pools and session hosts (with image provenance) ---
Write-Host "`n=== Host pools & session hosts ===" -ForegroundColor Cyan
$pools = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $pools) { Write-Host ("  (no host pools in '{0}')" -f $ResourceGroupName) -ForegroundColor Yellow }
foreach ($hp in $pools) {
    $hosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $hp.Name -ErrorAction SilentlyContinue)
    Write-Host ("  {0}  [type: {1}; load-balancer: {2}; session hosts: {3}]" -f $hp.Name, $hp.HostPoolType, $hp.LoadBalancerType, $hosts.Count) -ForegroundColor Green
    foreach ($h in $hosts) {
        $vmName = ($h.Name -split '/')[-1]
        Write-Host ("      host: {0}  status: {1}  agent: {2}" -f $vmName, $h.Status, $h.AgentVersion)
    }
}

# --- Profile storage accounts (FSLogix candidates) ---
Write-Host "`n=== Storage accounts (FSLogix profile share candidates) ===" -ForegroundColor Cyan
$sa = Get-AzStorageAccount -ErrorAction SilentlyContinue | Where-Object { $_.ResourceGroupName -in @($ResourceGroupName,$ImagingResourceGroupName) -or $_.StorageAccountName -match 'profile' }
if (-not $sa) { Write-Host "  (no obvious profile storage accounts found — verify manually)" -ForegroundColor Yellow }
foreach ($s in $sa) {
    Write-Host ("  {0}  [kind: {1}; sku: {2}; RG: {3}]" -f $s.StorageAccountName, $s.Kind, $s.Sku.Name, $s.ResourceGroupName)
}

# --- Scaling plans ---
Write-Host "`n=== Scaling plans ===" -ForegroundColor Cyan
$plans = Get-AzWvdScalingPlan -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $plans) { Write-Host ("  (no scaling plans in '{0}')" -f $ResourceGroupName) -ForegroundColor Yellow }
foreach ($p in $plans) {
    Write-Host ("  {0}  [type: {1}; schedules: {2}]" -f $p.Name, $p.HostPoolType, @($p.Schedule).Count)
}

Write-Host "`nDiscovery complete — this is your pre-change baseline." -ForegroundColor Green
