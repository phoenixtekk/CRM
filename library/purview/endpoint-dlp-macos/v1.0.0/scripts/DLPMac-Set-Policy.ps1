<#
.SYNOPSIS
    DLPMac-Set-Policy.ps1 — create the Devices-scoped DLP policy in TestWithoutNotifications (simulation) + an Audit egress rule (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates the two objects this solution relies on, SAFELY: (1) a DLP compliance policy scoped to
        the DEVICES (Endpoint) location in TestWithoutNotifications (silent simulation / Audit) — it is
        NEVER created in Enable/Block; and (2) a DLP compliance rule ('macOS Egress - Sensitive Content')
        whose macOS egress channels (cloud upload, USB removable media, network share, clipboard, print,
        restricted apps) are set to AUDIT. Idempotent: skips objects that already exist by name. Default
        -WhatIf previews the cmdlets; pass -Commit to create (still test-mode only). Enforcement (Block /
        Enable) is a deliberate, separate Set-DlpCompliancePolicy step per the Implementation Guide.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\DLPMac-Set-Policy.ps1
        Create (test mode): ... -Commit -SensitiveInformationType 'Credit Card Number'
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement; connects via Connect-IPPSSession
        (interactive modern auth). No credentials are stored in this script.
    EXPECTED RESULTS
        The policy 'Endpoint DLP - macOS - Pilot' exists in Mode=TestWithoutNotifications and the rule
        'macOS Egress - Sensitive Content' exists with Audit endpoint restrictions. Validate with
        DLPMac-Validation.ps1; drive test activity and review DLPMac-Report.ps1 before enforcing.
.NOTES
    Purview category — macOS Endpoint DLP. Default -WhatIf; -Commit creates in TEST mode only, never Enable.
    macOS channel support is version-dependent — verify current support before enforcing.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$PolicyName   = 'Endpoint DLP - macOS - Pilot',
    [string]$RuleName     = 'macOS Egress - Sensitive Content',
    [string]$SensitiveInformationType = 'Credit Card Number',   # replace with the agreed SIT(s)
    [string]$RestrictedAppGroup       = 'macOS - Restricted Apps',
    [switch]$Commit
)

# Default to preview unless -Commit is supplied.
$WhatIfPreference = -not $Commit

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement module not found — installing for current user..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

Write-Host "=== Create macOS Endpoint DLP policy (simulation/Audit) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "(preview mode — re-run with -Commit to create the objects in TEST mode)" -ForegroundColor Yellow }
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch {
    Write-Host ("Could not connect: {0}" -f $_.Exception.Message) -ForegroundColor Red; return
}

# ---------- 1) DLP policy scoped to Devices, in TestWithoutNotifications ----------
Write-Host "`n-- DLP policy (Devices / simulation) --" -ForegroundColor Cyan
$existingPolicy = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($existingPolicy) {
    Write-Host ("  OK   : policy '{0}' already exists (Mode: {1})." -f $PolicyName, $existingPolicy.Mode) -ForegroundColor Green
    if ("$($existingPolicy.Mode)" -eq 'Enable') {
        Write-Host "  WARN : this policy is ENFORCING. This script will not change its mode — advance/rollback deliberately with Set-DlpCompliancePolicy." -ForegroundColor Yellow
    }
} elseif ($PSCmdlet.ShouldProcess($PolicyName, "Create DLP policy (EndpointDlpLocation All, Mode TestWithoutNotifications)")) {
    try {
        New-DlpCompliancePolicy -Name $PolicyName `
            -EndpointDlpLocation All `
            -Mode TestWithoutNotifications `
            -Comment 'macOS Endpoint DLP pilot — created in silent simulation (Audit). Do not enforce without sign-off.' -ErrorAction Stop | Out-Null
        Write-Host ("  DONE : created '{0}' in TestWithoutNotifications (simulation)." -f $PolicyName) -ForegroundColor Green
    } catch {
        Write-Host ("  FAIL : could not create policy: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host ("  WOULD: New-DlpCompliancePolicy -Name '{0}' -EndpointDlpLocation All -Mode TestWithoutNotifications" -f $PolicyName) -ForegroundColor Cyan
}

# ---------- 2) DLP rule with Audit endpoint restrictions ----------
Write-Host "`n-- DLP rule (macOS egress, all Audit) --" -ForegroundColor Cyan
# Endpoint restrictions as Setting/Value pairs. Value=Audit for the pilot (never Block here).
# Only include channels supported on your macOS version — verify current support.
$restrictions = @(
    @{ Setting = 'CloudEgress';    Value = 'Audit' }   # upload to cloud service / unallowed browser
    @{ Setting = 'RemovableMedia'; Value = 'Audit' }   # copy to USB removable media
    @{ Setting = 'NetworkShare';   Value = 'Audit' }   # copy to a network share
    @{ Setting = 'CopyPaste';      Value = 'Audit' }   # copy to clipboard
    @{ Setting = 'Print';          Value = 'Audit' }   # print
    @{ Setting = 'UnallowedApps';  Value = 'Audit' }   # access by restricted apps
)
$existingRule = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue
if ($existingRule) {
    Write-Host ("  OK   : rule '{0}' already exists (policy: {1})." -f $RuleName, $existingRule.ParentPolicyName) -ForegroundColor Green
} elseif ($PSCmdlet.ShouldProcess($RuleName, "Create DLP rule with Audit endpoint restrictions")) {
    try {
        New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
            -ContentContainsSensitiveInformation @{ Name = $SensitiveInformationType } `
            -EndpointDlpRestrictions $restrictions `
            -Comment 'macOS egress channels at Audit for pilot simulation.' -ErrorAction Stop | Out-Null
        Write-Host ("  DONE : created rule '{0}' with {1} Audit egress restriction(s)." -f $RuleName, $restrictions.Count) -ForegroundColor Green
        Write-Host ("  NEXT : ensure the restricted-app group '{0}' exists in Endpoint DLP settings for the UnallowedApps control." -f $RestrictedAppGroup) -ForegroundColor DarkGray
    } catch {
        Write-Host ("  FAIL : could not create rule: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "         Endpoint restriction Setting/Value names and macOS support evolve — verify against current Microsoft guidance, or build the rule in the portal (Implementation Step 6)." -ForegroundColor DarkGray
    }
} else {
    Write-Host ("  WOULD: New-DlpComplianceRule -Name '{0}' -Policy '{1}' with Audit egress: {2}" -f $RuleName, $PolicyName, (($restrictions | ForEach-Object { $_.Setting }) -join ', ')) -ForegroundColor Cyan
}

Write-Host "`nEnforcement is deliberate: after validating in simulation, advance with" -ForegroundColor DarkGray
Write-Host "  Set-DlpCompliancePolicy -Identity '$PolicyName' -Mode TestWithNotifications   (then Enable)" -ForegroundColor DarkGray
Write-Host "Rollback any time with: Set-DlpCompliancePolicy -Identity '$PolicyName' -Mode TestWithoutNotifications" -ForegroundColor DarkGray
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
