<#
.SYNOPSIS
    AILZ-Discovery.ps1 — inventory current Azure state before building the AI landing zone (read-only).
.DESCRIPTION
    PURPOSE
        Discovers the starting reality before any change: your effective role at the target scope,
        registered vs missing resource providers, existing VNets and their address spaces (to check
        for overlap), existing private DNS zones, current policy assignments, any Key Vault, and —
        importantly — any existing AI (Cognitive Services / OpenAI) resources with PUBLIC network
        access still ON. Read-only: it calls only Get/List cmdlets.

    HOW TO RUN
        Connect-AzAccount
        ./AILZ-Discovery.ps1 -SubscriptionId "<pilot-subscription-id>"
        Prereqs: Az PowerShell (Az.Accounts, Az.Resources, Az.Network, Az.KeyVault,
        Az.CognitiveServices, Az.PolicyInsights — VERIFY current module versions). For GCC/GCC-High,
        Connect-AzAccount -Environment AzureUSGovernment first.

    EXPECTED RESULTS
        Printed sections for role, providers, VNets, private DNS, policy, Key Vault, and AI-service
        public-access exposure. PASS = context resolves and the inventory completes.
.NOTES
    White-label. Read-only. No secrets in script. VERIFY provider/feature/pricing availability for
    your cloud (Commercial vs GCC/GCC-High).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'
function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# Providers the AI landing zone needs registered (R5).
$neededProviders = @(
    'Microsoft.CognitiveServices', 'Microsoft.Network', 'Microsoft.KeyVault',
    'Microsoft.OperationalInsights', 'Microsoft.PolicyInsights', 'Microsoft.CostManagement',
    'Microsoft.Search', 'Microsoft.MachineLearningServices'
)

Section "Context (confirm the PILOT subscription)"
try {
    Set-AzContext -Subscription $SubscriptionId | Out-Null
    $ctx = Get-AzContext
    Write-Host ("Account : {0}" -f $ctx.Account.Id)
    Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)
    Write-Host ("Tenant  : {0}" -f $ctx.Tenant.Id)
    Write-Host ("Cloud   : {0}" -f $ctx.Environment.Name)
} catch {
    Write-Host "Cannot set context — run Connect-AzAccount first. $_" -ForegroundColor Red
    exit 1
}

Section "Effective role at the subscription (expect Owner / Contributor+UAA — R1)"
try {
    $me = (Get-AzContext).Account.Id
    Get-AzRoleAssignment -SignInName $me -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue |
        Select-Object DisplayName, RoleDefinitionName, Scope | Format-Table -AutoSize
    Write-Host "Policy assignment + RBAC creation need Owner or Contributor + User Access Administrator."
} catch { Write-Host "Could not read role assignments: $_" -ForegroundColor Yellow }

Section "Resource providers (registered vs MISSING — R5)"
foreach ($p in $neededProviders) {
    $rp = Get-AzResourceProvider -ProviderNamespace $p -ErrorAction SilentlyContinue
    $state = if ($rp) { ($rp | Select-Object -First 1).RegistrationState } else { 'NotFound' }
    $flag = if ($state -eq 'Registered') { 'OK ' } else { 'MISSING' }
    Write-Host ("  [{0}] {1} = {2}" -f $flag, $p, $state)
}
Write-Host "Register any MISSING provider: Register-AzResourceProvider -ProviderNamespace <ns>"

Section "Existing VNets + address spaces (check for OVERLAP before you pick CIDRs — R2)"
Get-AzVirtualNetwork -ErrorAction SilentlyContinue |
    Select-Object Name, ResourceGroupName, @{n='AddressSpace';e={$_.AddressSpace.AddressPrefixes -join ','}} |
    Format-Table -AutoSize
Write-Host "Your hub/spoke CIDRs must NOT overlap any of the above."

Section "Existing private DNS zones (reuse central zones if present — R3)"
Get-AzPrivateDnsZone -ErrorAction SilentlyContinue |
    Select-Object Name, ResourceGroupName | Format-Table -AutoSize
Write-Host "Needed: privatelink.openai.azure.com, .cognitiveservices.azure.com, .search.windows.net, .vaultcore.azure.net, .blob.core.windows.net (VERIFY current names)."

Section "Current policy assignments at the subscription"
Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue |
    Select-Object Name, @{n='DisplayName';e={$_.Properties.DisplayName}}, @{n='Enforcement';e={$_.Properties.EnforcementMode}} |
    Format-Table -AutoSize

Section "Key Vaults (the zone adds a PRIVATE one: kv-ailz-nonprod-<suffix>)"
Get-AzKeyVault -ErrorAction SilentlyContinue |
    Select-Object VaultName, ResourceGroupName, Location | Format-Table -AutoSize

Section "AI services (Cognitive Services / OpenAI) — flag any with PUBLIC access ON"
try {
    $accts = Get-AzCognitiveServicesAccount -ErrorAction SilentlyContinue
    if (-not $accts) { Write-Host "  None found (a clean AI landing zone will place them privately)." }
    foreach ($a in $accts) {
        $pna = $a.Properties.PublicNetworkAccess
        $flag = if ($pna -eq 'Disabled') { 'private ' } else { 'PUBLIC!!' }
        Write-Host ("  [{0}] {1} ({2}) kind={3} publicNetworkAccess={4}" -f $flag, $a.AccountName, $a.ResourceGroupName, $a.Kind, $pna)
    }
    Write-Host "Any 'PUBLIC!!' is exactly what this landing zone removes — plan to make it private."
} catch { Write-Host "Could not enumerate Cognitive Services accounts: $_" -ForegroundColor Yellow }

Section "Discovery complete"
Write-Host "Next: review 03-implementation.md, set main.tf variables, then run the plan-first pipeline (azure-pipelines.yml)."
