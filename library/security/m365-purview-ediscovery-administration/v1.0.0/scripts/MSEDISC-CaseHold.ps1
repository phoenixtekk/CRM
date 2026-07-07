<#
.SYNOPSIS
    MSEDISC-CaseHold.ps1 — create the case and a named case hold (dry-run by default).
.DESCRIPTION
    Configures eDiscovery (Standard) preservation for a matter: ensures the case exists, then creates
    a case-hold policy over the custodian mailboxes/sites and a (optionally query-based) hold rule.
    SAFE BY DEFAULT: previews the New-ComplianceCase / New-CaseHoldPolicy / New-CaseHoldRule it WOULD
    run and makes no change unless -Apply is passed. It NEVER removes a hold — releasing preservation
    is a legal decision (see Implementation Guide rollback).
.EXAMPLE
    .\MSEDISC-CaseHold.ps1 -Matter "Matter-A" -Stage "Pilot" `
        -ExchangeLocation "custodian@contoso.com" -SharePointLocation "https://contoso.sharepoint.com/sites/ProjectFalcon"   # dry-run
    .\MSEDISC-CaseHold.ps1 -Matter "Matter-A" -Stage "Pilot" -ExchangeLocation "custodian@contoso.com" -Apply               # commit
    (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect with Connect-IPPSSession)
.NOTES
    Expected results: the case + hold policy/rule that would be (or were) created, named to the matter.
    White-label — Security Solutions. Default is a dry run. Uses New-ComplianceCase / New-CaseHoldPolicy /
    New-CaseHoldRule. Legal owns the hold determination — do not place a live hold without sign-off.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$Matter,
    [string]$Stage = 'Pilot',
    [string[]]$ExchangeLocation   = @(),
    [string[]]$SharePointLocation = @(),
    [string]$HoldQuery,                       # optional KQL to scope the hold; omit = hold everything in-scope
    [switch]$Apply
)
$WhatIf = -not $Apply
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'APPLY'})
$caseName = "eDiscovery Case – $Matter – $Stage"
$policyName = "Hold Policy – $Matter – $Stage"
$ruleName   = "Hold Rule – $Matter – $Stage"

if (-not $ExchangeLocation -and -not $SharePointLocation) {
    Write-Host "  Provide at least one -ExchangeLocation or -SharePointLocation to preserve." -ForegroundColor Red
    return
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== Case + hold configuration [{0}] ===" -f $mode) -ForegroundColor Cyan
Write-Host ("  Case        : {0}" -f $caseName)
Write-Host ("  Hold policy : {0}" -f $policyName)
Write-Host ("  Hold rule   : {0}" -f $ruleName)
Write-Host ("  Exchange    : {0}" -f ($ExchangeLocation -join ', '))
Write-Host ("  SharePoint  : {0}" -f ($SharePointLocation -join ', '))
if ($HoldQuery) { Write-Host ("  Hold KQL    : {0}" -f $HoldQuery) }

$case = Get-ComplianceCase -Identity $caseName -ErrorAction SilentlyContinue

if ($WhatIf) {
    Write-Host "`n  WOULD run:" -ForegroundColor Yellow
    if (-not $case) { Write-Host ("    New-ComplianceCase -Name '{0}' -CaseType eDiscovery" -f $caseName) }
    else            { Write-Host ("    (case '{0}' already exists)" -f $caseName) }
    Write-Host ("    New-CaseHoldPolicy -Name '{0}' -Case '{1}' -ExchangeLocation {2} -SharePointLocation {3} -Enabled `$true" -f `
        $policyName, $caseName, ($ExchangeLocation -join ','), ($SharePointLocation -join ','))
    $ruleArgs = if ($HoldQuery) { "-ContentMatchQuery '$HoldQuery'" } else { "(no query — preserve all in-scope)" }
    Write-Host ("    New-CaseHoldRule -Name '{0}' -Policy '{1}' {2}" -f $ruleName, $policyName, $ruleArgs)
    Write-Host "`nPreview only. Re-run with -Apply after legal sign-off to place the hold." -ForegroundColor Cyan
} else {
    if (-not $case) {
        New-ComplianceCase -Name $caseName -CaseType eDiscovery | Out-Null
        Write-Host ("  Created case '{0}'." -f $caseName) -ForegroundColor Green
    } else { Write-Host ("  Case '{0}' already exists — reusing." -f $caseName) -ForegroundColor Green }

    $policyParams = @{ Name = $policyName; Case = $caseName; Enabled = $true }
    if ($ExchangeLocation)   { $policyParams.ExchangeLocation   = $ExchangeLocation }
    if ($SharePointLocation) { $policyParams.SharePointLocation = $SharePointLocation }
    New-CaseHoldPolicy @policyParams | Out-Null
    Write-Host ("  Created hold policy '{0}'." -f $policyName) -ForegroundColor Green

    $ruleParams = @{ Name = $ruleName; Policy = $policyName }
    if ($HoldQuery) { $ruleParams.ContentMatchQuery = $HoldQuery }
    New-CaseHoldRule @ruleParams | Out-Null
    Write-Host ("  Created hold rule '{0}' — preservation active. Verify with MSEDISC-Report.ps1." -f $ruleName) -ForegroundColor Green
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
