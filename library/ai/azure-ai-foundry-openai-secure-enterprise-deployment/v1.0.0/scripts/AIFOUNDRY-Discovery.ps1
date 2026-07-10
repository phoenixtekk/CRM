<#
.SYNOPSIS
    AIFOUNDRY-Discovery.ps1 — read-only inventory of Azure OpenAI / Cognitive Services AI resources and their security posture.
.DESCRIPTION
    PURPOSE
        Builds your "what's insecure today" baseline before deploying the secure platform. For every
        Cognitive Services / OpenAI account in the subscription it reports the risk posture: public
        network access, whether account keys (local auth) are enabled, whether a custom subdomain is
        set (required for keyless + private endpoints), the model deployments and their TPM capacity,
        private endpoints, and diagnostic settings. It also lists VNets/subnets and existing private
        DNS zones so you can plan the private endpoint (R2). Nothing is changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AIFOUNDRY-Discovery.ps1 -SubscriptionId "<sub id>"
        Requires the Az PowerShell modules (Az.Accounts, Az.CognitiveServices, Az.Network, Az.Monitor).
        Run Connect-AzAccount first. *Verify current Az module versions.*
    EXPECTED RESULTS
        A per-resource posture table (public access / keys / subdomain / deployments / PE / diagnostics)
        and a networking summary (VNets, subnets, private DNS zones). Read-only — no changes made.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$SubscriptionId,
    [string]$OutputCsv = ""
)

$ErrorActionPreference = 'Stop'
Write-Host "AIFOUNDRY discovery — subscription $SubscriptionId (read-only)`n" -ForegroundColor Cyan

try { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
catch { Write-Error "Could not set context to $SubscriptionId. Run Connect-AzAccount first. $_"; exit 1 }

# --- Cognitive Services / OpenAI accounts -----------------------------------
$rows = @()
$accounts = Get-AzCognitiveServicesAccount -ErrorAction SilentlyContinue
if (-not $accounts) { Write-Host "No Cognitive Services / OpenAI accounts found." -ForegroundColor Yellow }

foreach ($a in $accounts) {
    $props        = $a.Properties
    $publicAccess = $props.PublicNetworkAccess
    $localAuth    = if ($null -ne $props.DisableLocalAuth) { -not $props.DisableLocalAuth } else { $true } # keys usable?
    $subdomain    = $props.CustomSubDomainName
    $peCount      = ($props.PrivateEndpointConnections | Measure-Object).Count

    # Model deployments + TPM (best-effort; API surface varies — *verify*)
    $deployments = @()
    try {
        $deployments = Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $a.ResourceGroupName -AccountName $a.AccountName -ErrorAction SilentlyContinue
    } catch { }
    $depSummary = if ($deployments) {
        ($deployments | ForEach-Object { "$($_.Name)=$($_.Sku.Capacity)k" }) -join '; '
    } else { '(none)' }

    # Diagnostic settings
    $diag = @()
    try { $diag = Get-AzDiagnosticSetting -ResourceId $a.Id -ErrorAction SilentlyContinue } catch { }
    $hasDiag = if ($diag) { 'yes' } else { 'NO' }

    $risk = @()
    if ($publicAccess -eq 'Enabled') { $risk += 'PUBLIC' }
    if ($localAuth)                  { $risk += 'KEYS-ON' }
    if (-not $subdomain)             { $risk += 'NO-SUBDOMAIN' }
    if ($hasDiag -eq 'NO')           { $risk += 'NO-DIAG' }

    $rows += [pscustomobject]@{
        Account       = $a.AccountName
        ResourceGroup = $a.ResourceGroupName
        Kind          = $a.Kind
        Location      = $a.Location
        PublicAccess  = $publicAccess
        KeysUsable    = $localAuth
        CustomSubdmn  = if ($subdomain) { $subdomain } else { '(none)' }
        PrivateEPs    = $peCount
        Diagnostics   = $hasDiag
        Deployments   = $depSummary
        Risk          = if ($risk) { ($risk -join ',') } else { 'ok' }
    }
}

if ($rows) {
    Write-Host "--- AI resource posture ---" -ForegroundColor Cyan
    $rows | Format-Table -AutoSize
    $risky = $rows | Where-Object { $_.Risk -ne 'ok' }
    if ($risky) {
        Write-Host "`n$($risky.Count) resource(s) need remediation (see Risk column). Secure them with AIFOUNDRY-main.bicep." -ForegroundColor Yellow
    }
    if ($OutputCsv) { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host "Saved: $OutputCsv" -ForegroundColor Green }
}

# --- Networking: VNets/subnets and private DNS zones (for R2 planning) -------
Write-Host "`n--- VNets / subnets (private-endpoint host candidates) ---" -ForegroundColor Cyan
try {
    Get-AzVirtualNetwork -ErrorAction SilentlyContinue | ForEach-Object {
        $vnet = $_
        $_.Subnets | ForEach-Object {
            [pscustomobject]@{
                VNet   = $vnet.Name
                Subnet = $_.Name
                Prefix = ($_.AddressPrefix -join ',')
                PEPolicy = $_.PrivateEndpointNetworkPolicies
            }
        }
    } | Format-Table -AutoSize
} catch { Write-Host "  (could not enumerate VNets: $($_.Exception.Message))" -ForegroundColor Yellow }

Write-Host "`n--- Private DNS zones (need one for OpenAI, e.g. privatelink.openai.azure.com *verify*) ---" -ForegroundColor Cyan
try {
    $zones = Get-AzPrivateDnsZone -ErrorAction SilentlyContinue
    if ($zones) { $zones | Select-Object Name, ResourceGroupName | Format-Table -AutoSize }
    else { Write-Host "  No private DNS zones found — create/link one before disabling public access." -ForegroundColor Yellow }
} catch { Write-Host "  (could not enumerate private DNS zones)" -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. This is your baseline — no changes were made." -ForegroundColor Green
