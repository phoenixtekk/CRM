<#
.SYNOPSIS
    AKSSEC-Report.ps1 — a consolidated AKS secure-baseline posture report: cluster hardening,
    Azure Policy for Kubernetes assignments/compliance, workload-identity/OIDC state, and
    Defender for Containers coverage.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Azure Kubernetes Service (AKS) Secure Baseline" solution.
        Produces one posture snapshot for a named cluster: the private-API / Azure RBAC / policy
        add-on / OIDC / workload-identity flags, the Azure Policy assignments in the cluster's
        resource group with their compliance summary, and the Defender for Containers plan tier.
        Optionally writes the summary to CSV. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AKSSEC-Report.ps1 `
            -ResourceGroup '<rg>' -ClusterName '<cluster>'
        Add -CsvPath '.\akssec-posture.csv' to export.
        Requires Az.Accounts, Az.Aks, Az.PolicyInsights, Az.Security. Connect-AzAccount first.
    EXPECTED RESULTS
        A single baseline report — hardening flags, policy assignments + compliant/non-compliant
        counts, workload-identity state, and Defender coverage — captured at each stage
        (audit, post-deny, each expansion) so you can show drift over time.
.NOTES
    White-label · Azure Solutions. Read-only. The repeatable way.
    Reports configuration/compliance only; makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$ClusterName,
    [string]$CsvPath
)

Import-Module Az.Accounts      -ErrorAction Stop
Import-Module Az.Aks           -ErrorAction Stop
Import-Module Az.PolicyInsights -ErrorAction SilentlyContinue
Import-Module Az.Security       -ErrorAction SilentlyContinue
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$ctx   = Get-AzContext
$rows  = New-Object System.Collections.Generic.List[object]
$scope = "/subscriptions/$($ctx.Subscription.Id)/resourceGroups/$ResourceGroup"

Write-Host "`n=== AKS Secure Baseline — posture report ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0}" -f $ctx.Subscription.Name)
Write-Host ("Cluster:      {0}  (rg: {1})" -f $ClusterName, $ResourceGroup)
Write-Host ("Generated:    {0}" -f (Get-Date -Format s))

# --- Cluster hardening flags ---
Write-Host "`n-- Cluster hardening --" -ForegroundColor Cyan
try {
    $c = Get-AzAksCluster -ResourceGroupName $ResourceGroup -Name $ClusterName -ErrorAction Stop
    $flags = [ordered]@{
        'PrivateAPI'            = [bool]$c.ApiServerAccessProfile.EnablePrivateCluster
        'AzureRBAC'             = ($null -ne $c.AadProfile) -and [bool]$c.AadProfile.EnableAzureRbac
        'LocalAccountsDisabled' = [bool]$c.DisableLocalAccounts
        'PolicyAddon'           = ($null -ne $c.AddonProfiles.azurepolicy) -and [bool]$c.AddonProfiles.azurepolicy.Enabled
        'OIDCIssuer'            = ($null -ne $c.OidcIssuerProfile) -and [bool]$c.OidcIssuerProfile.Enabled
        'WorkloadIdentity'      = ($null -ne $c.SecurityProfile.WorkloadIdentity) -and [bool]$c.SecurityProfile.WorkloadIdentity.Enabled
    }
    foreach ($k in $flags.Keys) {
        $v = $flags[$k]
        Write-Host ("   {0,-24} {1}" -f $k, $v) -ForegroundColor ($(if ($v) { 'Green' } else { 'Yellow' }))
        $rows.Add([pscustomobject]@{ Category='Hardening'; Item=$k; Value=$v })
    }
} catch { Write-Host ("   Could not read cluster: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Azure Policy for Kubernetes assignments + compliance ---
Write-Host "`n-- Azure Policy assignments (cluster resource group) --" -ForegroundColor Cyan
try {
    $assignments = Get-AzPolicyAssignment -Scope $scope -ErrorAction Stop
    if ($assignments) {
        foreach ($a in $assignments) {
            Write-Host ("   {0}" -f $a.Name)
            $rows.Add([pscustomobject]@{ Category='PolicyAssignment'; Item=$a.Name; Value='(see compliance)' })
        }
        try {
            $states = Get-AzPolicyState -ResourceGroupName $ResourceGroup -ErrorAction Stop
            $nc = ($states | Where-Object ComplianceState -eq 'NonCompliant').Count
            $co = ($states | Where-Object ComplianceState -eq 'Compliant').Count
            Write-Host ("   Compliance: {0} compliant / {1} non-compliant" -f $co, $nc) -ForegroundColor ($(if ($nc -eq 0) { 'Green' } else { 'Yellow' }))
            $rows.Add([pscustomobject]@{ Category='Compliance'; Item='Compliant'; Value=$co })
            $rows.Add([pscustomobject]@{ Category='Compliance'; Item='NonCompliant'; Value=$nc })
        } catch { Write-Host ("   Compliance state not available yet (allow time / run a scan): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    } else { Write-Host "   (no policy assignments at the resource-group scope yet)" -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Defender for Containers ---
Write-Host "`n-- Microsoft Defender for Containers --" -ForegroundColor Cyan
try {
    $plan = Get-AzSecurityPricing -Name 'Containers' -ErrorAction Stop
    Write-Host ("   Containers plan tier: {0}" -f $plan.PricingTier) -ForegroundColor ($(if ($plan.PricingTier -eq 'Standard') { 'Green' } else { 'Yellow' }))
    $rows.Add([pscustomobject]@{ Category='Defender'; Item='ContainersPlan'; Value=$plan.PricingTier })
} catch { Write-Host ("   Could not read Defender plan: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nExported: {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
