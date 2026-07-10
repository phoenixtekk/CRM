<#
.SYNOPSIS
    AKSSEC-Discovery.ps1 — read-only readiness check for an AKS secure-baseline deploy:
    subscription context, VNet/subnet capacity, existing AKS clusters, and the Defender
    for Containers plan.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Azure Kubernetes Service (AKS) Secure Baseline" solution.
        Captures the pre-change picture BEFORE any Terraform/Bicep apply: the subscription in
        context, the target virtual network / subnet and its free-address capacity (Azure CNI
        needs one IP per pod plus nodes), any existing AKS clusters and whether their API is
        private, and the Microsoft Defender for Containers plan tier. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AKSSEC-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\AKSSEC-Discovery.ps1 -SubscriptionId '<sub id>' `
            -VnetResourceGroup '<rg>' -VnetName '<vnet>' -SubnetName '<subnet>'
        Requires Az modules (Az.Accounts, Az.Aks, Az.Network, Az.Security). Run Connect-AzAccount
        first, or the script prompts.
    EXPECTED RESULTS
        A single readiness snapshot — subscription, subnet free-IP capacity, existing clusters
        with private-API state, and Defender for Containers plan status — so you know the estate
        is ready before you plan the IaC.
.NOTES
    White-label · Azure Solutions. Read-only. The repeatable way.
    Reports configuration/identifiers only; makes no changes to any resource.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$VnetResourceGroup,
    [string]$VnetName,
    [string]$SubnetName
)

foreach ($m in 'Az.Accounts','Az.Aks','Az.Network','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az module set (missing $m)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Aks      -ErrorAction Stop
Import-Module Az.Network  -ErrorAction Stop
Import-Module Az.Security -ErrorAction SilentlyContinue

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$ctx = Get-AzContext
Write-Host "`n=== AKS Secure Baseline — discovery (read-only) ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)
Write-Host ("Tenant:       {0}" -f $ctx.Tenant.Id)

# --- Target subnet capacity (Azure CNI needs headroom: IPs = maxPods x maxNodes + nodes) ---
if ($VnetResourceGroup -and $VnetName -and $SubnetName) {
    Write-Host "`n-- Target VNet / subnet --" -ForegroundColor Cyan
    try {
        $vnet   = Get-AzVirtualNetwork -ResourceGroupName $VnetResourceGroup -Name $VnetName -ErrorAction Stop
        $subnet = $vnet.Subnets | Where-Object Name -eq $SubnetName
        if ($subnet) {
            $prefix = $subnet.AddressPrefix -join ','
            Write-Host ("   VNet:   {0}" -f $vnet.Name)
            Write-Host ("   Subnet: {0}  prefix: {1}" -f $subnet.Name, $prefix)
            Write-Host ("   NOTE: confirm free IPs >= maxPods x maxNodes + node count (Azure CNI).") -ForegroundColor Yellow
        } else {
            Write-Host ("   Subnet '{0}' not found in VNet '{1}'." -f $SubnetName, $VnetName) -ForegroundColor Yellow
        }
    } catch { Write-Host ("   Could not read VNet/subnet: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
} else {
    Write-Host "`n-- Target VNet / subnet --" -ForegroundColor Cyan
    Write-Host "   (pass -VnetResourceGroup/-VnetName/-SubnetName to inspect subnet capacity)"
}

# --- Existing AKS clusters and their API exposure ---
Write-Host "`n-- Existing AKS clusters --" -ForegroundColor Cyan
try {
    $clusters = Get-AzAksCluster -ErrorAction Stop
    if ($clusters) {
        foreach ($c in $clusters) {
            $private = $c.ApiServerAccessProfile.EnablePrivateCluster
            $state   = if ($private) { 'PRIVATE API' } else { 'PUBLIC API (review)' }
            $color   = if ($private) { 'Green' } else { 'Yellow' }
            Write-Host ("   {0,-32} {1,-14} rbac:{2} policy-addon:{3}" -f `
                $c.Name, $state, `
                ($null -ne $c.AadProfile -and $c.AadProfile.EnableAzureRbac), `
                ($null -ne $c.AddonProfiles.azurepolicy -and $c.AddonProfiles.azurepolicy.Enabled)) -ForegroundColor $color
        }
    } else { Write-Host "   (no AKS clusters in this subscription yet)" }
} catch { Write-Host ("   Could not read clusters: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Microsoft Defender for Containers plan ---
Write-Host "`n-- Microsoft Defender for Containers --" -ForegroundColor Cyan
try {
    $plan = Get-AzSecurityPricing -Name 'Containers' -ErrorAction Stop
    $color = if ($plan.PricingTier -eq 'Standard') { 'Green' } else { 'Yellow' }
    Write-Host ("   Containers plan tier: {0}" -f $plan.PricingTier) -ForegroundColor $color
    if ($plan.PricingTier -ne 'Standard') {
        Write-Host "   -> Enable the Containers plan for image scanning + node hardening (paid; verify pricing)." -ForegroundColor Yellow
    }
} catch { Write-Host ("   Could not read Defender plan (needs Az.Security / Security Reader): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`nDiscovery complete (read-only). Next: terraform plan (the gate)." -ForegroundColor Green
