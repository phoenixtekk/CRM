<#
.SYNOPSIS
    MSEDISC-Scope.ps1 — eDiscovery scope/config helper: compliance boundary + named-object check (dry-run by default).
.DESCRIPTION
    Two jobs, both safe by default. (1) Reports existing compliance security filters and, with -Apply,
    creates a boundary filter (New-ComplianceSecurityFilter) so a scoped eDiscovery team can only
    search a defined population. (2) Validates that a matter's named objects (case, search, hold
    policy/rule) exist and are consistent. The boundary POLICY (who may search whom) is a legal/HR
    determination — this script only implements the decision you give it.
.EXAMPLE
    .\MSEDISC-Scope.ps1 -Validate -Matter "Matter-A" -Stage "Pilot"                       # check named objects (read-only)
    .\MSEDISC-Scope.ps1 -FilterName "Boundary – Region-EU – Prod" -Users "euediscovery@contoso.com" `
        -RecipientFilter "CountryOrRegion -eq 'DE'"                                        # dry-run the boundary filter
    .\MSEDISC-Scope.ps1 -FilterName "Boundary – Region-EU – Prod" -Users "euediscovery@contoso.com" `
        -RecipientFilter "CountryOrRegion -eq 'DE'" -Apply                                 # create the filter
    (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect with Connect-IPPSSession)
.NOTES
    Expected results: existing filters listed; planned/created filter; and a PASS/FAIL per named object.
    White-label — Security Solutions. Default is read-only / dry run. Uses Get-/New-ComplianceSecurityFilter,
    Get-ComplianceCase / Get-ComplianceSearch / Get-CaseHoldPolicy.
#>
[CmdletBinding()] param(
    [switch]$Validate,
    [string]$Matter,
    [string]$Stage = 'Pilot',
    [string]$FilterName,
    [string[]]$Users,
    [string]$RecipientFilter,        # membership predicate for the boundary, e.g. "CountryOrRegion -eq 'DE'"
    [switch]$Apply
)
$WhatIf = -not $Apply

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== eDiscovery scope / config helper ===" -ForegroundColor Cyan

# --- Job 1: compliance security filters (boundary) ---
Write-Host "`n--- Existing compliance security filters (boundaries) ---" -ForegroundColor Cyan
$filters = Get-ComplianceSecurityFilter -ErrorAction SilentlyContinue
if ($filters) { $filters | Select-Object FilterName, Users, Action | Format-Table -AutoSize }
else { Write-Host "  No compliance security filters configured." -ForegroundColor Yellow }

if ($FilterName -and $Users -and $RecipientFilter) {
    Write-Host ("`n  Boundary requested: {0}" -f $FilterName) -ForegroundColor Cyan
    if ($WhatIf) {
        Write-Host "  WOULD run:" -ForegroundColor Yellow
        Write-Host ("    New-ComplianceSecurityFilter -FilterName '{0}' -Users {1} -Filters `"Mailbox_{2}`" -Action All" -f `
            $FilterName, ($Users -join ','), $RecipientFilter)
        Write-Host "  (Recipient/Mailbox/SiteContent filter syntax is version-dependent — verify in your tenant.)" -ForegroundColor DarkGray
        Write-Host "  Preview only. Re-run with -Apply to create the boundary." -ForegroundColor Cyan
    } else {
        New-ComplianceSecurityFilter -FilterName $FilterName -Users $Users `
            -Filters "Mailbox_$RecipientFilter" -Action All | Out-Null
        Write-Host ("  Created boundary filter '{0}'." -f $FilterName) -ForegroundColor Green
    }
} elseif ($FilterName) {
    Write-Host "  To create a boundary provide -FilterName, -Users, and -RecipientFilter." -ForegroundColor Yellow
}

# --- Job 2: validate the matter's named objects ---
if ($Validate) {
    if (-not $Matter) { Write-Host "`n  -Validate requires -Matter." -ForegroundColor Red; }
    else {
        $caseName   = "eDiscovery Case – $Matter – $Stage"
        $searchName = "Content Search – $Matter-Keywords – $Stage"
        $policyName = "Hold Policy – $Matter – $Stage"
        $ruleName   = "Hold Rule – $Matter – $Stage"
        Write-Host ("`n--- Named-object check for '{0}' ({1}) ---" -f $Matter, $Stage) -ForegroundColor Cyan
        function Test-Object($label, $exists) {
            if ($exists) { Write-Host ("  PASS  {0}" -f $label) -ForegroundColor Green }
            else         { Write-Host ("  FAIL  {0} (missing)" -f $label) -ForegroundColor Red }
        }
        Test-Object $caseName   ([bool](Get-ComplianceCase   -Identity $caseName   -ErrorAction SilentlyContinue))
        Test-Object $searchName ([bool](Get-ComplianceSearch -Identity $searchName -ErrorAction SilentlyContinue))
        $pol = Get-CaseHoldPolicy -Identity $policyName -ErrorAction SilentlyContinue
        Test-Object $policyName  ([bool]$pol)
        if ($pol) { Test-Object $ruleName ([bool](Get-CaseHoldRule -Policy $policyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $ruleName })) }
    }
}

Write-Host "`nScope helper complete." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
