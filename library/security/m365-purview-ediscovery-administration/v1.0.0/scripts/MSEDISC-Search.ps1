<#
.SYNOPSIS
    MSEDISC-Search.ps1 — build and run a scoped Content Search (dry-run by default).
.DESCRIPTION
    Creates a named Content Search inside a case, with a KQL/condition query and the in-scope
    locations, then starts it. SAFE BY DEFAULT: previews the exact New-ComplianceSearch /
    Start-ComplianceSearch it WOULD run and makes no change unless -Apply is passed. Iterate the KQL
    and re-run with -Apply; the search NAME stays stable so the matter is traceable.
.EXAMPLE
    .\MSEDISC-Search.ps1 -Matter "Matter-A" -Stage "Pilot" `
        -ContentMatchQuery '(subject:"Project Falcon") AND (received>=2024-01-01 AND received<=2024-12-31)' `
        -ExchangeLocation All -SharePointLocation All            # dry-run (preview only)
    .\MSEDISC-Search.ps1 -Matter "Matter-A" -Stage "Pilot" -ContentMatchQuery '...' -Apply   # create + start
    (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect with Connect-IPPSSession)
.NOTES
    Expected results: the planned/created search name and, after -Apply, its start confirmation.
    White-label — Security Solutions. Default is a dry run. Uses New-/Start-/Get-ComplianceSearch.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$Matter,
    [string]$Stage = 'Pilot',
    [Parameter(Mandatory)][string]$ContentMatchQuery,
    [string[]]$ExchangeLocation   = @('All'),
    [string[]]$SharePointLocation = @('All'),
    [string]$Case,
    [switch]$Apply
)
$WhatIf = -not $Apply
$mode = $(if($WhatIf){'WHATIF (preview only)'}else{'APPLY'})
$searchName = "Content Search – $Matter-Keywords – $Stage"
if (-not $Case) { $Case = "eDiscovery Case – $Matter – $Stage" }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== Content Search build [{0}] ===" -f $mode) -ForegroundColor Cyan
Write-Host ("  Case   : {0}" -f $Case)
Write-Host ("  Search : {0}" -f $searchName)
Write-Host ("  KQL    : {0}" -f $ContentMatchQuery)
Write-Host ("  Exchange locations   : {0}" -f ($ExchangeLocation -join ', '))
Write-Host ("  SharePoint locations : {0}" -f ($SharePointLocation -join ', '))
Write-Host "  NOTE: Teams messages are collected via mailboxes (Exchange); Teams files via SharePoint/OneDrive." -ForegroundColor DarkGray

$existing = Get-ComplianceSearch -Identity $searchName -ErrorAction SilentlyContinue

if ($WhatIf) {
    Write-Host "`n  WOULD run:" -ForegroundColor Yellow
    if (-not $existing) {
        Write-Host ("    New-ComplianceSearch -Name '{0}' -Case '{1}' -ExchangeLocation {2} -SharePointLocation {3} -ContentMatchQuery '{4}'" -f `
            $searchName, $Case, ($ExchangeLocation -join ','), ($SharePointLocation -join ','), $ContentMatchQuery)
    } else {
        Write-Host ("    Set-ComplianceSearch -Identity '{0}' -ContentMatchQuery '{1}'  (search already exists)" -f $searchName, $ContentMatchQuery)
    }
    Write-Host ("    Start-ComplianceSearch -Identity '{0}'" -f $searchName)
    Write-Host "`nPreview only. Re-run with -Apply to create and start the search." -ForegroundColor Cyan
} else {
    if (-not $existing) {
        New-ComplianceSearch -Name $searchName -Case $Case `
            -ExchangeLocation $ExchangeLocation -SharePointLocation $SharePointLocation `
            -ContentMatchQuery $ContentMatchQuery | Out-Null
        Write-Host ("  Created search '{0}'." -f $searchName) -ForegroundColor Green
    } else {
        Set-ComplianceSearch -Identity $searchName -ContentMatchQuery $ContentMatchQuery | Out-Null
        Write-Host ("  Updated query on existing search '{0}'." -f $searchName) -ForegroundColor Green
    }
    Start-ComplianceSearch -Identity $searchName
    Write-Host ("  Started '{0}'. Use MSEDISC-Report.ps1 to read statistics; New-ComplianceSearchAction -Preview to sample." -f $searchName) -ForegroundColor Green
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
