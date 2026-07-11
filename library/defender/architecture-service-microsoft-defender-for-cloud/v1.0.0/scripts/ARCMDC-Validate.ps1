<#
.SYNOPSIS
    ARCMDC-Validate.ps1 — confirm the architecture: plans enabled at scope, inheritance working,
    providers registered, governance rule present, and continuous export configured.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Architecture Service — Microsoft Defender for Cloud" solution.
        Checks the pass/fail gates from the Testing Guide across the pilot scope and a sample child
        subscription (inheritance), reports PASS/WARN per check with an overall verdict. Makes no
        changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Validate.ps1 -SubscriptionId '<pilot child sub>'
        Requires Az.Accounts, Az.Security, Az.Resources with Security Reader (or higher) at scope.
    EXPECTED RESULTS
        A PASS/WARN line per check and an overall verdict — the gate for expanding beyond the pilot
        scope (Implementation Step 7).
.NOTES
    White-label. Read-only. MG-scope inheritance is confirmed by reading a child subscription's
    effective plan tiers.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

$pass = 0; $warn = 0
function Check($name, $ok, $detail) {
    if ($ok) { Write-Host ("   [PASS] {0} — {1}" -f $name, $detail) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("   [WARN] {0} — {1}" -f $name, $detail) -ForegroundColor Yellow; $script:warn++ }
}

Write-Host "`n=== ARCMDC validation (read-only) ===" -ForegroundColor Cyan
Write-Host ("Sample subscription (inheritance check): {0}" -f $SubscriptionId)

# 1. Plans enabled / inherited on the sample child subscription.
try {
    $pricings = Get-AzSecurityPricing -ErrorAction Stop
    $standard = @($pricings | Where-Object { $_.PricingTier -eq 'Standard' })
    $cspm = $pricings | Where-Object { $_.Name -eq 'CloudPosture' } | Select-Object -First 1
    Check 'Defender CSPM enabled/inherited' ($cspm -and $cspm.PricingTier -eq 'Standard') ($(if ($cspm) { "CloudPosture = $($cspm.PricingTier)" } else { 'CloudPosture plan not found' }))
    Check 'At least one workload plan on' ($standard.Count -gt 0) ("$($standard.Count) standard plan(s): " + (($standard.Name) -join ', '))
} catch { Check 'Plans readable' $false ("could not read plans: " + $_.Exception.Message) }

# 2. Provider registered.
try {
    $prov = (Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction Stop | Select-Object -First 1).RegistrationState
    Check 'Microsoft.Security registered' ($prov -eq 'Registered') ("state: $prov")
} catch { Check 'Microsoft.Security registered' $false ("could not read provider: " + $_.Exception.Message) }

# 3. Governance rule present (Defender for Cloud governance rules API).
try {
    $gov = Invoke-AzRestMethod -Path ("/subscriptions/{0}/providers/Microsoft.Security/governanceRules?api-version=2022-01-01-preview" -f $SubscriptionId) -Method GET -ErrorAction SilentlyContinue
    $hasGov = $false
    if ($gov -and $gov.Content) { $obj = $gov.Content | ConvertFrom-Json; $hasGov = ($obj.value -and $obj.value.Count -gt 0) }
    Check 'Governance rule present' $hasGov ($(if ($hasGov) { 'at least one governance rule' } else { 'none found — create MDC Governance - Platform MG - Prod' }))
} catch { Check 'Governance rule present' $false 'governance API not available in this context' }

# 4. Continuous export configured.
try {
    $exp = Invoke-AzRestMethod -Path ("/subscriptions/{0}/providers/Microsoft.Security/automations?api-version=2019-01-01-preview" -f $SubscriptionId) -Method GET -ErrorAction SilentlyContinue
    $hasExp = $false
    if ($exp -and $exp.Content) { $obj = $exp.Content | ConvertFrom-Json; $hasExp = ($obj.value -and $obj.value.Count -gt 0) }
    Check 'Continuous export configured' $hasExp ($(if ($hasExp) { 'at least one export automation' } else { 'none — configure MDC Continuous Export - Platform MG - Prod' }))
} catch { Check 'Continuous export configured' $false 'automations API not available in this context' }

Write-Host "`n-- Confirm manually (portal) --" -ForegroundColor Cyan
Write-Host "   Plans set at the MANAGEMENT-GROUP node (not per-subscription) so children inherit"
Write-Host "   RBAC least-privilege per the design record; SIEM ingestion path receiving export data"

Write-Host ""
if ($warn -eq 0) { Write-Host ("VERDICT: PASS — {0} checks passed. Safe to proceed per the Testing Guide exit gate." -f $pass) -ForegroundColor Green }
else { Write-Host ("VERDICT: {0} PASS / {1} WARN — resolve WARN items before expanding (Implementation Step 7)." -f $pass, $warn) -ForegroundColor Yellow }
