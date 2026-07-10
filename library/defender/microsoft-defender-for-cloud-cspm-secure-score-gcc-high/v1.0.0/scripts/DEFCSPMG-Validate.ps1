<#
.SYNOPSIS
    DEFCSPMG-Validate.ps1 — confirm Defender CSPM, agentless scanning, provider registration,
    governance, and continuous export are in place. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Microsoft Defender for Cloud — CSPM & Secure Score
        Remediation" solution. For the subscription in context (or a named subscription), checks:
          - Defender CSPM (CloudPosture) plan = Standard/On
          - Agentless scanning enabled in the CSPM plan extensions
          - Microsoft.Security provider registered
          - At least one governance rule present (best-effort via REST)
          - At least one continuous-export automation configured
        Prints a PASS/FAIL line per check. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFCSPMG-Validate.ps1
        powershell -ExecutionPolicy Bypass -File .\DEFCSPMG-Validate.ps1 -SubscriptionId '<sub id>'
        Requires Az.Accounts, Az.Security, Az.Resources.
    EXPECTED RESULTS
        A checklist of PASS/FAIL results confirming the pilot subscription is correctly configured
        before you expand across the estate.
.NOTES
    Government (GCC High) edition: targets the US Gov cloud via Connect-AzAccount -Environment AzureUSGovernment. Plan/feature availability in GCC High/DoD may lag commercial — verify against current Microsoft Government documentation.
    White-label. Read-only.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount -Environment AzureUSGovernment | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$ctx = Get-AzContext
$sub = $ctx.Subscription.Id

function Show-Check([string]$Name, [bool]$Ok, [string]$Detail) {
    $flag = if ($Ok) { 'PASS' } else { 'FAIL' }
    $color = if ($Ok) { 'Green' } else { 'Yellow' }
    Write-Host ("   [{0}] {1,-34} {2}" -f $flag, $Name, $Detail) -ForegroundColor $color
}

Write-Host "`n=== Defender for Cloud — CSPM validation (read-only) ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $sub)
Write-Host ""

# 1. Defender CSPM (CloudPosture) plan
$cspmOk = $false; $cspmDetail = 'not found'
try {
    $cspm = Get-AzSecurityPricing -Name 'CloudPosture' -ErrorAction SilentlyContinue
    if ($cspm) { $cspmOk = ($cspm.PricingTier -eq 'Standard'); $cspmDetail = "tier: $($cspm.PricingTier)" }
} catch { $cspmDetail = $_.Exception.Message }
Show-Check 'Defender CSPM (CloudPosture)' $cspmOk $cspmDetail

# 2. Agentless scanning extension
$aglessOk = $false; $aglessDetail = 'unknown'
try {
    if ($cspm -and $cspm.Extensions) {
        $ag = $cspm.Extensions | Where-Object { $_.Name -match 'AgentlessVmScanning|AgentlessDiscovery' }
        if ($ag) { $aglessOk = ($ag.IsEnabled -eq 'True' -or $ag.IsEnabled -eq $true); $aglessDetail = "extension: $($ag.Name)=$($ag.IsEnabled)" }
        else { $aglessDetail = 'no agentless extension on plan' }
    } else { $aglessDetail = 'plan/extension data not available' }
} catch { $aglessDetail = $_.Exception.Message }
Show-Check 'Agentless scanning' $aglessOk $aglessDetail

# 3. Provider registration
$provOk = $false; $provDetail = 'unknown'
try {
    $prov = Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction Stop | Select-Object -First 1
    $provOk = ($prov.RegistrationState -eq 'Registered'); $provDetail = $prov.RegistrationState
} catch { $provDetail = $_.Exception.Message }
Show-Check 'Microsoft.Security provider' $provOk $provDetail

# 4. Governance rules (best-effort REST)
$govOk = $false; $govDetail = 'none'
try {
    $g = Invoke-AzRestMethod -Path ("/subscriptions/{0}/providers/Microsoft.Security/governanceRules?api-version=2022-01-01-preview" -f $sub) -Method GET -ErrorAction SilentlyContinue
    if ($g -and $g.Content) { $go = $g.Content | ConvertFrom-Json; $govOk = (($go.value | Measure-Object).Count -gt 0); $govDetail = "count: $(($go.value | Measure-Object).Count)" }
} catch { $govDetail = 'governance API not available' }
Show-Check 'Governance rule present' $govOk $govDetail

# 5. Continuous export automations
$expOk = $false; $expDetail = 'none'
try {
    $a = Invoke-AzRestMethod -Path ("/subscriptions/{0}/providers/Microsoft.Security/automations?api-version=2019-01-01-preview" -f $sub) -Method GET -ErrorAction SilentlyContinue
    if ($a -and $a.Content) { $ao = $a.Content | ConvertFrom-Json; $expOk = (($ao.value | Measure-Object).Count -gt 0); $expDetail = "automations: $(($ao.value | Measure-Object).Count)" }
} catch { $expDetail = 'automation API not available' }
Show-Check 'Continuous export configured' $expOk $expDetail

Write-Host "`nValidation complete (read-only). Address any FAIL per the Implementation/Troubleshooting guides." -ForegroundColor Green
