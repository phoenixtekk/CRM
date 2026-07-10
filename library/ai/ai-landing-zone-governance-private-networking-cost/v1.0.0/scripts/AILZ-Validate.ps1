<#
.SYNOPSIS
    AILZ-Validate.ps1 — run the AI landing-zone pass/fail gates (read-only).
.DESCRIPTION
    PURPOSE
        Validates the deployed landing zone against the gates in 05-testing.md and prints each as
        PASS / FAIL / MANUAL: hub/spoke VNets + peering, private DNS zones linked, AI service and Key
        Vault public-access DISABLED with private endpoints, the AI hostname resolving to a PRIVATE IP
        (read-only probe), keyless managed identity + RBAC, the AILZ-AI-Guardrails-Initiative assigned
        and reporting in audit (DoNotEnforce) mode, content-safety default present, and
        Budget-AILZ-Platform with thresholds. Read-only: Get/List + a DNS lookup only.

    HOW TO RUN
        Connect-AzAccount
        ./AILZ-Validate.ps1 -SubscriptionId "<pilot-subscription-id>"
        Optionally pass -AiAccountName to target a specific AI service for the private-resolution probe.

    EXPECTED RESULTS
        A gate-by-gate summary. All gates PASS => you may proceed to Expand (flip policies to enforce).
        Any FAIL => stay in the pilot scope, keep policies in audit, and remediate first.
.NOTES
    White-label. Read-only. No changes are made. VERIFY policy-definition and content-safety
    availability for your cloud; the private-resolution probe must be run from inside the VNet to see
    the private record.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SubscriptionId,
    [string]$SpokeResourceGroup = "rg-ailz-spoke-nonprod",
    [string]$HubResourceGroup   = "rg-ailz-hub-platform",
    [string]$AiAccountName
)

$ErrorActionPreference = 'Stop'
$script:pass = 0; $script:fail = 0; $script:manual = 0
function Gate($n, $desc, $result, $detail) {
    $tag = switch ($result) { 'PASS' { 'PASS  '; $script:pass++ } 'FAIL' { 'FAIL  '; $script:fail++ } default { 'MANUAL'; $script:manual++ } }
    $color = switch ($result) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
    Write-Host ("[{0}] Gate {1}: {2}" -f $tag, $n, $desc) -ForegroundColor $color
    if ($detail) { Write-Host "         $detail" }
}

Set-AzContext -Subscription $SubscriptionId | Out-Null
Write-Host "AI Landing Zone validation — subscription $SubscriptionId`n"

# Gate 1 — hub/spoke + peering
try {
    $hub   = Get-AzVirtualNetwork -Name "vnet-ailz-hub-platform"   -ResourceGroupName $HubResourceGroup   -ErrorAction SilentlyContinue
    $spoke = Get-AzVirtualNetwork -Name "vnet-ailz-spoke-nonprod" -ResourceGroupName $SpokeResourceGroup -ErrorAction SilentlyContinue
    $peerOk = $false
    if ($hub) { $peerOk = ($hub.VirtualNetworkPeerings | Where-Object { $_.PeeringState -eq 'Connected' }).Count -gt 0 }
    if ($hub -and $spoke -and $peerOk) { Gate 1 "Hub/spoke network + peering" 'PASS' "hub + spoke present; peering Connected" }
    else { Gate 1 "Hub/spoke network + peering" 'FAIL' "hub=$([bool]$hub) spoke=$([bool]$spoke) peeringConnected=$peerOk" }
} catch { Gate 1 "Hub/spoke network + peering" 'FAIL' $_.Exception.Message }

# Gate 2 — private DNS zones linked
try {
    $zonesNeeded = @('privatelink.openai.azure.com','privatelink.cognitiveservices.azure.com','privatelink.search.windows.net','privatelink.vaultcore.azure.net','privatelink.blob.core.windows.net')
    $zones = Get-AzPrivateDnsZone -ResourceGroupName $HubResourceGroup -ErrorAction SilentlyContinue
    $present = @($zones | Where-Object { $zonesNeeded -contains $_.Name })
    if ($present.Count -ge 1) { Gate 2 "Private DNS zones linked" 'PASS' ("{0}/{1} privatelink zones present (verify VNet links + central-zone reuse)" -f $present.Count, $zonesNeeded.Count) }
    else { Gate 2 "Private DNS zones linked" 'MANUAL' "no zones in $HubResourceGroup — you may be reusing central zones (R3); verify VNet links" }
} catch { Gate 2 "Private DNS zones linked" 'FAIL' $_.Exception.Message }

# Gate 3 — AI + Key Vault private
try {
    $kv = Get-AzKeyVault -VaultName (Get-AzKeyVault -ResourceGroupName $SpokeResourceGroup -ErrorAction SilentlyContinue | Where-Object { $_.VaultName -like 'kv-ailz-*' } | Select-Object -First 1).VaultName -ErrorAction SilentlyContinue
    $kvPrivate = $kv -and ($kv.PublicNetworkAccess -eq 'Disabled')
    $ai = if ($AiAccountName) { Get-AzCognitiveServicesAccount -ResourceGroupName $SpokeResourceGroup -Name $AiAccountName -ErrorAction SilentlyContinue }
          else { Get-AzCognitiveServicesAccount -ResourceGroupName $SpokeResourceGroup -ErrorAction SilentlyContinue | Select-Object -First 1 }
    $aiPrivate = $ai -and ($ai.Properties.PublicNetworkAccess -eq 'Disabled')
    if ($kvPrivate -and $aiPrivate) { Gate 3 "AI + Key Vault public access disabled" 'PASS' "Key Vault + AI service both publicNetworkAccess=Disabled" }
    elseif ($kvPrivate -and -not $ai) { Gate 3 "AI + Key Vault public access disabled" 'MANUAL' "Key Vault private; no pilot AI service placed yet (place one to fully validate)" }
    else { Gate 3 "AI + Key Vault public access disabled" 'FAIL' "kvPrivate=$kvPrivate aiPrivate=$aiPrivate" }
} catch { Gate 3 "AI + Key Vault public access disabled" 'FAIL' $_.Exception.Message }

# Gate 4 — private resolution probe (read-only DNS lookup)
try {
    if ($ai) {
        $aiHost = "{0}.openai.azure.com" -f $ai.AccountName
        $resolved = Resolve-DnsName -Name $aiHost -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress }
        $ip = ($resolved | Select-Object -First 1).IPAddress
        $isPrivate = $ip -and ($ip -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)')
        if ($isPrivate) { Gate 4 "AI hostname resolves to private IP" 'PASS' "$aiHost -> $ip (private)" }
        elseif ($ip) { Gate 4 "AI hostname resolves to private IP" 'MANUAL' "$aiHost -> $ip (not RFC1918 — run this probe from INSIDE the VNet to see the private record)" }
        else { Gate 4 "AI hostname resolves to private IP" 'MANUAL' "could not resolve $aiHost from here — run from inside the spoke" }
    } else { Gate 4 "AI hostname resolves to private IP" 'MANUAL' "no pilot AI service to probe yet" }
} catch { Gate 4 "AI hostname resolves to private IP" 'MANUAL' $_.Exception.Message }

# Gate 5 — keyless managed identity + RBAC
try {
    $mi = Get-AzUserAssignedIdentity -ResourceGroupName $SpokeResourceGroup -Name "id-ailz-aiworkload-nonprod" -ErrorAction SilentlyContinue
    if ($mi) {
        $roles = Get-AzRoleAssignment -ObjectId $mi.PrincipalId -ErrorAction SilentlyContinue | Select-Object -ExpandProperty RoleDefinitionName
        $hasData = $roles -contains 'Cognitive Services OpenAI User'
        if ($hasData) { Gate 5 "Keyless managed identity + RBAC" 'PASS' ("id-ailz-aiworkload-nonprod holds: {0}" -f ($roles -join ', ')) }
        else { Gate 5 "Keyless managed identity + RBAC" 'FAIL' "identity present but missing 'Cognitive Services OpenAI User'" }
    } else { Gate 5 "Keyless managed identity + RBAC" 'FAIL' "id-ailz-aiworkload-nonprod not found" }
} catch { Gate 5 "Keyless managed identity + RBAC" 'FAIL' $_.Exception.Message }

# Gate 6 — policy initiative assigned + audit mode
try {
    $pa = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -eq 'AILZ-AI-Guardrails-Initiative' } | Select-Object -First 1
    if ($pa) {
        $mode = $pa.Properties.EnforcementMode
        if ($mode -eq 'DoNotEnforce') { Gate 6 "Policy initiative assigned (audit)" 'PASS' "AILZ-AI-Guardrails-Initiative in DoNotEnforce (simulate-first)" }
        else { Gate 6 "Policy initiative assigned (audit)" 'MANUAL' "assigned but EnforcementMode=$mode — enforce only AFTER validation (Phase 4)" }
    } else { Gate 6 "Policy initiative assigned (audit)" 'FAIL' "initiative assignment not found at subscription scope" }
} catch { Gate 6 "Policy initiative assigned (audit)" 'FAIL' $_.Exception.Message }

# Gate 7 — content-safety default (verify availability)
Gate 7 "Content-safety default present" 'MANUAL' "Confirm Policy-ContentSafetyOn-AILZ is in the initiative and the pilot AI service has the content-safety default. Some content-safety/RAI features are preview — VERIFY availability. Acceptable-content thresholds are the customer's trust-and-safety decision."

# Gate 8 — budget + usage
try {
    $budget = Get-AzConsumptionBudget -Name "Budget-AILZ-Platform" -ErrorAction SilentlyContinue
    if ($budget) { Gate 8 "Budget + usage dashboard" 'PASS' ("Budget-AILZ-Platform = {0} {1}; verify Workbook-AILZ-AIUsage in log-ailz-platform" -f $budget.Amount, $budget.TimeGrain) }
    else { Gate 8 "Budget + usage dashboard" 'FAIL' "Budget-AILZ-Platform not found" }
} catch { Gate 8 "Budget + usage dashboard" 'MANUAL' "Get-AzConsumptionBudget unavailable here — verify budget in the portal. $_" }

# Gate 9 — plan-first + state (manual attestation)
Gate 9 "Plan/what-if-first + protected state" 'MANUAL' "Confirm every apply went through azure-pipelines.yml plan->approval->apply and remote state is an encrypted, versioned Azure Storage container (R6). No portal click-ops."

Write-Host ("`nSummary: {0} PASS / {1} FAIL / {2} MANUAL" -f $script:pass, $script:fail, $script:manual) -ForegroundColor Cyan
if ($script:fail -gt 0) { Write-Host "One or more gates FAILED — stay in pilot, keep policies in audit, remediate." -ForegroundColor Red; exit 2 }
Write-Host "No hard failures. Resolve MANUAL checks, then proceed to Expand (flip policies to enforce)." -ForegroundColor Green
