<#
.SYNOPSIS
    MDCFULL-Validate.ps1 — read-only validation across the Defender for Cloud lifecycle
    (plans/inheritance, providers, Servers MDE/agents, continuous export, response workflow, and the PoC).
.DESCRIPTION
    PURPOSE
        Read-only pass/fail validation for the "Microsoft Defender for Cloud" (complete) solution. Confirms
        the state the Testing Guide checks, without changing anything:
          -Plan All       : every in-scope workload plan is On on the pilot subscription.
          -Plan Servers   : Defender for Servers MDE integration + monitoring agent coverage.
          -Plan Export    : continuous export configured (data path to the workspace/SIEM).
          -Plan Workflow  : the response workflow exists and is notify-only.
          -Plan Inherit   : plans set at MG scope + a child subscription inherits; providers registered.
          -PoC            : PoC observations — recommendation, Secure Score, alerts, regulatory compliance.
        With no -Plan/-PoC it runs the readiness set (providers, Secure Score present, a plan on, ARG).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Validate.ps1 -SubscriptionId '<pilot sub id>'
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Validate.ps1 -Plan All -SubscriptionId '<id>'
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Validate.ps1 -PoC -SubscriptionId '<id>'
        Requires Az.Accounts, Az.Security, Az.Resources (+ Az.ResourceGraph for hunting). Security Reader.
    EXPECTED RESULTS
        A checklist of PASS/REVIEW lines for the requested area. Read-only — makes no changes.
.NOTES
    White-label. Read-only. Plan/pricing facts are indicative — verify current pricing/availability.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [ValidateSet('All','Servers','Export','Workflow','Inherit')]
    [string]$Plan,
    [switch]$PoC,
    [string]$PilotManagementGroupId
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop; Import-Module Az.Security -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

function Result([string]$label, [bool]$ok, [string]$note) {
    $tag = if ($ok) { 'PASS  ' } else { 'REVIEW' }
    Write-Host ("   [{0}] {1}{2}" -f $tag, $label, $(if ($note) { " — $note" } else { '' })) -ForegroundColor $(if ($ok) { 'Green' } else { 'Yellow' })
}

Write-Host "`n=== Defender for Cloud — validation (read-only) ===" -ForegroundColor Cyan
$pricings = @()
try { $pricings = Get-AzSecurityPricing -ErrorAction Stop } catch { Write-Host ("   Could not read pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
$onPlans = @($pricings | Where-Object { $_.PricingTier -eq 'Standard' } | ForEach-Object { $_.Name })

# --- Readiness (default) ---
if (-not $Plan -and -not $PoC) {
    Write-Host "`n-- Readiness --" -ForegroundColor Cyan
    $rp = Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction SilentlyContinue | Select-Object -First 1
    Result 'Microsoft.Security registered' ($rp -and $rp.RegistrationState -eq 'Registered') $(if ($rp) { $rp.RegistrationState } else { 'NotFound' })
    Result 'At least one Defender plan On' ($onPlans.Count -gt 0) ("on: " + (($onPlans -join ', ')))
    $score = $null; try { $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
    Result 'Secure Score data present' ($null -ne $score) $(if ($score) { "score object returned" } else { "allow assessment warm-up" })
    $arg = $null; try { Import-Module Az.ResourceGraph -ErrorAction SilentlyContinue; $arg = Search-AzGraph -Query "securityresources | take 1" -ErrorAction SilentlyContinue } catch {}
    Result 'Azure Resource Graph reachable' ($null -ne $arg) 'needed for the labs / hunting pack'
}

# --- Plan validations ---
if ($Plan -eq 'All') {
    Write-Host "`n-- Workload plans On (pilot subscription) --" -ForegroundColor Cyan
    foreach ($want in 'VirtualMachines','Containers','SqlServers','StorageAccounts','KeyVaults','AppServices','Arm') {
        $p = $pricings | Where-Object { $_.Name -eq $want } | Select-Object -First 1
        Result ("plan {0}" -f $want) ($p -and $p.PricingTier -eq 'Standard') $(if ($p) { $p.PricingTier } else { 'not present' })
    }
}
if ($Plan -eq 'Servers') {
    Write-Host "`n-- Defender for Servers (MDE + agent) --" -ForegroundColor Cyan
    $srv = $pricings | Where-Object { $_.Name -eq 'VirtualMachines' } | Select-Object -First 1
    Result 'Defender for Servers On' ($srv -and $srv.PricingTier -eq 'Standard') $(if ($srv) { $srv.PricingTier } else { 'off' })
    Write-Host "   Confirm MDE integration + monitoring agent auto-provisioning in Environment settings -> Servers -> Settings (Arc for non-Azure)." -ForegroundColor DarkGray
    Write-Host "   Verify current agent/extension requirements in your tenant." -ForegroundColor DarkGray
}
if ($Plan -eq 'Export') {
    Write-Host "`n-- Continuous export --" -ForegroundColor Cyan
    Write-Host "   Confirm Environment settings -> Continuous export ('MDC Continuous Export - Platform MG - Prod') targets the central workspace" -ForegroundColor DarkGray
    Write-Host "   and exports Security alerts + recommendations + Secure Score, and that the SecurityAlert table receives data and reaches the SIEM." -ForegroundColor DarkGray
    Result 'Continuous export (manual confirm)' $false 'verify in portal / query the workspace SecurityAlert table'
}
if ($Plan -eq 'Workflow') {
    Write-Host "`n-- Response workflow (notify-only) --" -ForegroundColor Cyan
    Write-Host "   Confirm 'MDC Workload Response - Tenant - Prod' triggers on high-severity alerts and ONLY notifies/creates a ticket (no auto-remediation)." -ForegroundColor DarkGray
    Result 'Workflow notify-only (manual confirm)' $false 'Defender for Cloud -> Workflow automation'
}
if ($Plan -eq 'Inherit') {
    Write-Host "`n-- MG inheritance --" -ForegroundColor Cyan
    Write-Host "   Confirm plans set at the pilot MG ('MDC Scope - Pilot MG - Pilot') and a child subscription shows the INHERITED plan state." -ForegroundColor DarkGray
    $rp = Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction SilentlyContinue | Select-Object -First 1
    Result 'Microsoft.Security registered (this sub)' ($rp -and $rp.RegistrationState -eq 'Registered') $(if ($rp) { $rp.RegistrationState } else { 'NotFound' })
}

# --- PoC validation ---
if ($PoC) {
    Write-Host "`n-- PoC observations (read-only) --" -ForegroundColor Cyan
    $score = $null; try { $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
    Result 'Secure Score present' ($null -ne $score) $(if ($score) { 'returned' } else { 'allow warm-up' })
    $alerts = @(); try { $alerts = Get-AzSecurityAlert -ErrorAction SilentlyContinue } catch {}
    Result 'Security alert(s) fired (sample/EICAR)' ($alerts.Count -gt 0) ("count: " + $alerts.Count)
    $assess = @(); try { $assess = Get-AzSecurityAssessment -ErrorAction SilentlyContinue } catch {}
    Result 'Recommendation/assessment data present' ($assess.Count -gt 0) ("count: " + $assess.Count)
    Write-Host "   Confirm Regulatory compliance shows control status for the pilot subscription (portal)." -ForegroundColor DarkGray
    Write-Host "   After teardown: expect the workload plan Off (Free) and the test resource gone." -ForegroundColor DarkGray
}

Write-Host "`nValidation complete (read-only). Map REVIEW lines to the Troubleshooting guide." -ForegroundColor Green
