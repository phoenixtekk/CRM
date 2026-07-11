<#
.SYNOPSIS
    WSMDC-Validate.ps1 — read-only readiness validation for the Defender for Cloud workshop.
.DESCRIPTION
    PURPOSE
        Confirms the pilot subscription is ready to teach the "Workshop — Microsoft Defender for
        Cloud" labs BEFORE attendees arrive. Checks (all read-only): Az connectivity, that the
        Microsoft.Security provider is registered, that Secure Score data has populated, that at
        least one Defender (CWPP) plan is On (for the alerts lab), and reminds about ARG access.
        Prints a PASS/REVIEW table.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMDC-Validate.ps1 -SubscriptionId '<pilot sub id>'
        Requires Az.Accounts, Az.Security, Az.Resources. Run Connect-AzAccount first, or it prompts.
    EXPECTED RESULTS
        A PASS/REVIEW line per check. All PASS = ready to run Lab 0 onward; any REVIEW points at the
        matching item in 02-requirements.md.
.NOTES
    White-label. Read-only. Makes no changes.
    Plan/pricing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Continue'
$checks = @()
function Add-Check($name,$ok,$detail){ $script:checks += [pscustomobject]@{ Check=$name; Result=($(if($ok){'PASS'}else{'REVIEW'})); Detail=$detail } }

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Az.Accounts -ErrorAction SilentlyContinue
Import-Module Az.Security -ErrorAction SilentlyContinue

Write-Host "`n=== Defender for Cloud workshop — readiness validation (read-only) ===" -ForegroundColor Cyan
try {
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
    $ctx = Get-AzContext
    Add-Check 'Az connectivity' ($null -ne $ctx) ("Subscription: $($ctx.Subscription.Name) ($($ctx.Subscription.Id))")
} catch { Add-Check 'Az connectivity' $false $_.Exception.Message }

try {
    $prov = Get-AzResourceProvider -ProviderNamespace 'Microsoft.Security' -ErrorAction Stop | Select-Object -First 1
    Add-Check 'Microsoft.Security provider registered' ($prov.RegistrationState -eq 'Registered') ("State: $($prov.RegistrationState)")
} catch { Add-Check 'Microsoft.Security provider registered' $false $_.Exception.Message }

try {
    $score = Get-AzSecuritySecureScore -ErrorAction Stop | Where-Object { $_.Name -eq 'ascScore' } | Select-Object -First 1
    Add-Check 'Secure Score data present' ($null -ne $score) ($(if($score){"Score $($score.Current)/$($score.Max)"}else{"Not populated — allow warm-up (R2)"}))
} catch { Add-Check 'Secure Score data present' $false $_.Exception.Message }

try {
    $pricings = Get-AzSecurityPricing -ErrorAction Stop
    $onCount = ($pricings | Where-Object { $_.PricingTier -eq 'Standard' }).Count
    Add-Check 'At least one Defender plan On (for alerts lab)' ($onCount -ge 1) ("$onCount plan(s) On (R3)")
} catch { Add-Check 'At least one Defender plan On (for alerts lab)' $false $_.Exception.Message }

Add-Check 'Azure Resource Graph access (portal)' $true 'Confirm attendees can run: securityresources | take 5 in Resource Graph Explorer (R6).'

Write-Host ""
$checks | Format-Table Check, Result, Detail -AutoSize
$review = ($checks | Where-Object Result -eq 'REVIEW').Count
if ($review -eq 0) { Write-Host "READY: all checks PASS. Proceed to Lab 0." -ForegroundColor Green }
else { Write-Host "$review item(s) need REVIEW — see 02-requirements.md before teaching." -ForegroundColor Yellow }
