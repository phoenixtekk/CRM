<#
.SYNOPSIS
    AZSEC-Discovery.ps1 — inventory Azure Policy assignments, RBAC (incl. standing Owner), and
    Microsoft Defender for Cloud posture across a management-group / subscription scope.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Azure Security Baseline & Governance" solution. For the scope
        in context (or a named subscription / management group), lists the Azure Policy assignments
        and their effect, the RBAC role assignments — flagging standing Owner — and the Defender for
        Cloud pricing/plan status and secure score. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Discovery.ps1 -SubscriptionId '<sub id>'
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Discovery.ps1 -ManagementGroupId '<mg id>'
        Requires the Az PowerShell modules (Az.Accounts, Az.Resources, Az.PolicyInsights, Az.Security).
        Run Connect-AzAccount first, or the script will prompt.
    EXPECTED RESULTS
        A per-scope snapshot: policy assignments with effect, RBAC assignments with standing Owner
        highlighted, and Defender for Cloud plan status plus current secure score — a single
        readiness picture before you assign guardrails and tighten access.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    Reports on configuration/identifiers only; makes no changes to policy, RBAC, or Defender.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ManagementGroupId
)

foreach ($m in 'Az.Accounts','Az.Resources','Az.PolicyInsights','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Install-Module Az -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
Import-Module Az.PolicyInsights -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

# Resolve the scope string for policy/RBAC queries.
if ($ManagementGroupId) {
    $scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
} else {
    $ctx   = Get-AzContext
    $scope = "/subscriptions/$($ctx.Subscription.Id)"
}

Write-Host "`n=== Azure Security Baseline & Governance — discovery ===" -ForegroundColor Cyan
Write-Host ("Scope: {0}" -f $scope)

# --- Policy assignments ---
Write-Host "`n-- Policy assignments --" -ForegroundColor Cyan
try {
    $assignments = Get-AzPolicyAssignment -Scope $scope -ErrorAction Stop
    if ($assignments) {
        foreach ($a in $assignments) {
            $name   = $a.Name
            $effect = $a.Properties.Parameters.effect.value
            if (-not $effect) { $effect = '(per-policy / not overridden)' }
            Write-Host ("   {0,-48} effect: {1}" -f $name, $effect)
        }
    } else { Write-Host "   (none at this scope)" -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- RBAC assignments (flag standing Owner) ---
Write-Host "`n-- RBAC role assignments --" -ForegroundColor Cyan
try {
    $ra = Get-AzRoleAssignment -Scope $scope -ErrorAction Stop
    if ($ra) {
        foreach ($r in $ra) {
            $isOwner = $r.RoleDefinitionName -eq 'Owner'
            $line = ("   {0,-30} {1}  ({2})" -f $r.RoleDefinitionName, $r.DisplayName, $r.ObjectType)
            if ($isOwner) { Write-Host ($line + "  <-- standing Owner (review)") -ForegroundColor Yellow }
            else { Write-Host $line }
        }
    } else { Write-Host "   (none at this scope)" -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read role assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Defender for Cloud posture (subscription-level) ---
if (-not $ManagementGroupId) {
    Write-Host "`n-- Microsoft Defender for Cloud --" -ForegroundColor Cyan
    try {
        $pricings = Get-AzSecurityPricing -ErrorAction Stop
        foreach ($p in $pricings) {
            $color = if ($p.PricingTier -eq 'Standard') { 'Green' } else { 'Yellow' }
            Write-Host ("   Plan {0,-28} tier: {1}" -f $p.Name, $p.PricingTier) -ForegroundColor $color
        }
    } catch { Write-Host ("   Could not read Defender plans: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    try {
        $scores = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue
        if ($scores) {
            foreach ($s in $scores) {
                Write-Host ("   Secure score '{0}': {1}% ({2}/{3})" -f $s.DisplayName, [math]::Round($s.Percentage * 100), $s.CurrentScore, $s.MaxScore)
            }
        } else { Write-Host "   Secure score not available (allow time after enabling Defender)." -ForegroundColor Yellow }
    } catch { Write-Host ("   Could not read secure score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
