<#
.SYNOPSIS
    AKSSEC-Validate.ps1 — confirm the deployed AKS cluster meets the secure baseline:
    private API, Entra + Azure RBAC, Azure Policy add-on, OIDC issuer, and workload identity.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Azure Kubernetes Service (AKS) Secure Baseline" solution.
        After the IaC apply (non-prod first), checks the five baseline controls on a named
        cluster and prints a PASS/REVIEW line for each: private API endpoint, Microsoft Entra +
        Azure RBAC for Kubernetes with local accounts disabled, the Azure Policy add-on
        (Gatekeeper), the OIDC issuer, and workload identity. Optionally checks operator tooling.
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AKSSEC-Validate.ps1 `
            -ResourceGroup '<rg>' -ClusterName '<cluster>'
        Add -CheckTools to verify terraform / kubectl / kubelogin are installed locally.
        Requires Az.Accounts, Az.Aks. Run Connect-AzAccount first, or the script prompts.
    EXPECTED RESULTS
        A per-control PASS/REVIEW summary. All PASS means the cluster is at the secure baseline
        and ready for the kubectl RBAC/policy manifests and Defender for Containers.
.NOTES
    White-label · Azure Solutions. Read-only. The repeatable way.
    Reports state only; makes no changes to the cluster.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$ClusterName,
    [switch]$CheckTools
)

Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Aks      -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

function Write-Check($label, $ok, $detail) {
    if ($ok) { Write-Host ("   [PASS]   {0} — {1}" -f $label, $detail) -ForegroundColor Green }
    else     { Write-Host ("   [REVIEW] {0} — {1}" -f $label, $detail) -ForegroundColor Yellow }
}

Write-Host "`n=== AKS Secure Baseline — validation ===" -ForegroundColor Cyan
try {
    $c = Get-AzAksCluster -ResourceGroupName $ResourceGroup -Name $ClusterName -ErrorAction Stop
} catch {
    Write-Host ("Could not read cluster '{0}': {1}" -f $ClusterName, $_.Exception.Message) -ForegroundColor Red
    return
}
Write-Host ("Cluster: {0}  (rg: {1})" -f $c.Name, $ResourceGroup)

# 1. Private API endpoint
$private = [bool]$c.ApiServerAccessProfile.EnablePrivateCluster
Write-Check "Private API endpoint" $private ("enablePrivateCluster = {0}" -f $private)

# 2. Entra + Azure RBAC for Kubernetes, local accounts disabled
$aadRbac = ($null -ne $c.AadProfile) -and [bool]$c.AadProfile.EnableAzureRbac
$localOff = [bool]$c.DisableLocalAccounts
Write-Check "Entra + Azure RBAC for Kubernetes" $aadRbac ("azureRbac = {0}" -f $aadRbac)
Write-Check "Local (cluster-admin) accounts disabled" $localOff ("disableLocalAccounts = {0}" -f $localOff)

# 3. Azure Policy add-on (Gatekeeper)
$policyAddon = ($null -ne $c.AddonProfiles.azurepolicy) -and [bool]$c.AddonProfiles.azurepolicy.Enabled
Write-Check "Azure Policy add-on (Gatekeeper)" $policyAddon ("azurepolicy addon enabled = {0}" -f $policyAddon)

# 4. OIDC issuer
$oidc = ($null -ne $c.OidcIssuerProfile) -and [bool]$c.OidcIssuerProfile.Enabled
Write-Check "OIDC issuer" $oidc ("oidcIssuer enabled = {0}" -f $oidc)

# 5. Workload identity
$wi = ($null -ne $c.SecurityProfile) -and ($null -ne $c.SecurityProfile.WorkloadIdentity) -and [bool]$c.SecurityProfile.WorkloadIdentity.Enabled
Write-Check "Workload identity" $wi ("workloadIdentity enabled = {0}" -f $wi)

# Optional: operator tooling presence
if ($CheckTools) {
    Write-Host "`n-- Operator tooling --" -ForegroundColor Cyan
    foreach ($tool in 'terraform','kubectl','kubelogin','az') {
        $found = Get-Command $tool -ErrorAction SilentlyContinue
        Write-Check $tool ([bool]$found) ($(if ($found) { $found.Source } else { 'not found on PATH' }))
    }
}

Write-Host "`nValidation complete (read-only). All PASS = cluster at the secure baseline." -ForegroundColor Green
