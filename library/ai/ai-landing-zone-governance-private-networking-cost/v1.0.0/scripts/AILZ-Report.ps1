<#
.SYNOPSIS
    AILZ-Report.ps1 — posture + cost snapshot for the AI landing zone (read-only).
.DESCRIPTION
    PURPOSE
        Produces a governance-facing snapshot: private-endpoint coverage across AI services / Key
        Vault, which guardrails the AILZ-AI-Guardrails-Initiative is enforcing and its current
        compliance (what WOULD be denied once enforced), budget status vs actual spend, and current AI
        spend by service. Read-only: Get/List + policy-state + cost queries only.

    HOW TO RUN
        Connect-AzAccount
        ./AILZ-Report.ps1 -SubscriptionId "<pilot-subscription-id>"

    EXPECTED RESULTS
        Printed report sections. Use it to review with cloud governance / FinOps BEFORE enforcing the
        guardrails and expanding to the management-group scope.
.NOTES
    White-label. Read-only. No changes are made. Cost/compliance data may lag; VERIFY current pricing
    and policy-definition availability for your cloud (Commercial vs GCC/GCC-High).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'
function Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Set-AzContext -Subscription $SubscriptionId | Out-Null
Write-Host "AI Landing Zone posture + cost report — subscription $SubscriptionId  ($(Get-Date -Format s))"

Section "Private-endpoint coverage (AI services + Key Vault should be Disabled/private)"
try {
    Get-AzCognitiveServicesAccount -ErrorAction SilentlyContinue | ForEach-Object {
        $pna = $_.Properties.PublicNetworkAccess
        $flag = if ($pna -eq 'Disabled') { 'private' } else { 'PUBLIC ' }
        Write-Host ("  [{0}] AI  {1} ({2}) kind={3} publicNetworkAccess={4}" -f $flag, $_.AccountName, $_.ResourceGroupName, $_.Kind, $pna)
    }
    Get-AzKeyVault -ErrorAction SilentlyContinue | Where-Object { $_.VaultName -like 'kv-ailz-*' } | ForEach-Object {
        $kvd = Get-AzKeyVault -VaultName $_.VaultName
        $flag = if ($kvd.PublicNetworkAccess -eq 'Disabled') { 'private' } else { 'PUBLIC ' }
        Write-Host ("  [{0}] KV  {1} ({2}) publicNetworkAccess={3}" -f $flag, $kvd.VaultName, $kvd.ResourceGroupName, $kvd.PublicNetworkAccess)
    }
    $peps = Get-AzPrivateEndpoint -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'pep-ailz-*' }
    Write-Host ("  Private endpoints (pep-ailz-*): {0}" -f (@($peps).Count))
    $peps | ForEach-Object { Write-Host ("    - {0} ({1})" -f $_.Name, $_.ResourceGroupName) }
} catch { Write-Host "  Could not enumerate services: $_" -ForegroundColor Yellow }

Section "Guardrail initiative + compliance (what would be DENIED once enforced)"
try {
    $pa = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -eq 'AILZ-AI-Guardrails-Initiative' } | Select-Object -First 1
    if ($pa) {
        Write-Host ("  Assignment: {0}  EnforcementMode={1}" -f $pa.Name, $pa.Properties.EnforcementMode)
        if ($pa.Properties.EnforcementMode -eq 'DoNotEnforce') { Write-Host "  (audit mode — reporting only; nothing is blocked yet)" }
        try {
            $states = Get-AzPolicyState -SubscriptionId $SubscriptionId -Filter "PolicyAssignmentName eq 'AILZ-AI-Guardrails-Initiative'" -ErrorAction SilentlyContinue
            $nonCompliant = @($states | Where-Object { $_.ComplianceState -eq 'NonCompliant' })
            Write-Host ("  Non-compliant resources (would be blocked once enforced): {0}" -f $nonCompliant.Count)
            $nonCompliant | Group-Object PolicyDefinitionReferenceId | ForEach-Object {
                $refId = if ($_.Name) { $_.Name } else { 'definition' }
                Write-Host ("    - {0}: {1}" -f $refId, $_.Count)
            }
        } catch { Write-Host "  Policy-state query unavailable (evaluation may lag): $_" -ForegroundColor Yellow }
    } else { Write-Host "  AILZ-AI-Guardrails-Initiative not assigned at this scope." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read policy: $_" -ForegroundColor Yellow }

Section "Budget status vs actual spend"
try {
    $budget = Get-AzConsumptionBudget -Name "Budget-AILZ-Platform" -ErrorAction SilentlyContinue
    if ($budget) {
        Write-Host ("  Budget-AILZ-Platform: amount={0} grain={1} currentSpend={2}" -f $budget.Amount, $budget.TimeGrain, $budget.CurrentSpend.Amount)
        if ($budget.Notification) { Write-Host ("  Alert thresholds: {0}" -f (($budget.Notification.Keys) -join ', ')) }
    } else { Write-Host "  Budget-AILZ-Platform not found." -ForegroundColor Yellow }
} catch { Write-Host "  Budget query unavailable here — check in the portal. $_" -ForegroundColor Yellow }

Section "AI spend by service (month-to-date, if Consumption API available)"
try {
    $start = (Get-Date -Day 1).ToString('yyyy-MM-dd')
    $usage = Get-AzConsumptionUsageDetail -StartDate $start -EndDate (Get-Date).ToString('yyyy-MM-dd') -ErrorAction SilentlyContinue |
             Where-Object { $_.InstanceName -like '*ailz*' -or $_.ConsumedService -like '*CognitiveServices*' }
    if ($usage) {
        $usage | Group-Object ConsumedService | Sort-Object { ($_.Group | Measure-Object PretaxCost -Sum).Sum } -Descending |
            ForEach-Object { Write-Host ("  {0,-32} {1:C}" -f $_.Name, (($_.Group | Measure-Object PretaxCost -Sum).Sum)) }
    } else { Write-Host "  No matching usage rows yet (new zone, or Consumption API not available for this offer)." }
} catch { Write-Host "  Consumption query unavailable: $_" -ForegroundColor Yellow }
Write-Host "  VERIFY current AI pricing for your cloud — pricing changes. Spend thresholds are the customer's FinOps decision."

Section "Report complete"
Write-Host "Review with governance/FinOps. Do NOT enforce guardrails or expand until 05-testing gates pass (AILZ-Validate.ps1)."
