<#
.SYNOPSIS
    DLPSPO-Check-Prereqs.ps1 — Prerequisite/health helper for SharePoint Online DLP (read-only; PASS/GAP).
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to configure DLP: the ExchangeOnlineManagement module and S&C
        PowerShell connection, whether the DLP cmdlets are available, whether sensitive information types
        can be read, and existing DLP policies. Read-only.
    HOW TO RUN
        .\DLPSPO-Check-Prereqs.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/GAP line per signal. GAPs are recorded against the Requirements checklist and remediated
        before configuring. Makes no change.
.NOTES
    Purview — SharePoint Online DLP. Read-only. Verify your licensing/tenant: core DLP is E3; some advanced
    classifiers/conditions require E5/E5 Compliance.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Signal([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("GAP   {0} — {1}" -f $Name, $Detail) -ForegroundColor Yellow }
}

Write-Host "`n=== SharePoint Online DLP — prerequisite/health check (read-only) ===" -ForegroundColor Cyan

$haveMod = [bool](Get-Module -ListAvailable -Name ExchangeOnlineManagement)
Signal 'Module: ExchangeOnlineManagement' $haveMod $(if($haveMod){'installed'}else{'install: Install-Module ExchangeOnlineManagement -Scope CurrentUser'})

Signal 'S&C PowerShell connected' (Test-Command 'Get-DlpCompliancePolicy') $(if(Test-Command 'Get-DlpCompliancePolicy'){'DLP cmdlets available'}else{'run Connect-IPPSSession'})

Signal 'Sensitive info types readable' (Test-Command 'Get-DlpSensitiveInformationType') $(if(Test-Command 'Get-DlpSensitiveInformationType'){'Get-DlpSensitiveInformationType present'}else{'connect S&C PowerShell'})

if (Test-Command 'Get-DlpCompliancePolicy') {
    $pol = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
    Signal 'Existing DLP policies' ($pol.Count -gt 0) ("{0} policy(ies) found" -f $pol.Count)
} else {
    Signal 'Existing DLP policies' $false 'cannot check — connect S&C PowerShell'
}

Write-Host "`nVerify manually (not readable here):" -ForegroundColor Cyan
Write-Host "  [ ] DLP licensing (E3 baseline; E5/E5 Compliance for advanced classifiers/conditions)" -ForegroundColor DarkGray
Write-Host "  [ ] Compliance / DLP Compliance Management role assigned (least privilege)" -ForegroundColor DarkGray
Write-Host "  [ ] Sensitive content + sharing conditions to govern documented and approved" -ForegroundColor DarkGray
Write-Host "  [ ] In-scope SharePoint/OneDrive locations + pilot scope defined" -ForegroundColor DarkGray
Write-Host "  [ ] Plan starts in TEST mode; policy-tip/notification/exception design ready" -ForegroundColor DarkGray
Write-Host "`nRecord every GAP against the Requirements checklist before configuring." -ForegroundColor DarkGray
