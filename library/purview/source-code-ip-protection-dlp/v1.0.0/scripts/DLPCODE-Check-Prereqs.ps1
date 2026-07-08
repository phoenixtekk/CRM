<#
.SYNOPSIS
    DLPCODE-Check-Prereqs.ps1 — Prerequisite/health helper for source-code/IP DLP (read-only; PASS/GAP).
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to configure code/IP DLP: the ExchangeOnlineManagement module and
        S&C PowerShell connection, whether the DLP cmdlets and sensitive info types are available, and
        existing DLP policies. Prints the manual checks (Source Code classifier, Endpoint DLP onboarding).
        Read-only.
    HOW TO RUN
        .\DLPCODE-Check-Prereqs.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/GAP line per signal plus a manual checklist. GAPs are recorded against the Requirements
        checklist and remediated before configuring. Makes no change.
.NOTES
    Purview — Source-Code & IP Protection DLP. Read-only. Verify your licensing/tenant: core DLP is E3;
    Endpoint DLP + Source Code classifier require E5/E5 Compliance.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Signal([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("GAP   {0} — {1}" -f $Name, $Detail) -ForegroundColor Yellow }
}

Write-Host "`n=== Source-Code & IP Protection DLP — prerequisite/health check (read-only) ===" -ForegroundColor Cyan

$haveMod = [bool](Get-Module -ListAvailable -Name ExchangeOnlineManagement)
Signal 'Module: ExchangeOnlineManagement' $haveMod $(if($haveMod){'installed'}else{'install: Install-Module ExchangeOnlineManagement -Scope CurrentUser'})

Signal 'S&C PowerShell connected' (Test-Command 'Get-DlpCompliancePolicy') $(if(Test-Command 'Get-DlpCompliancePolicy'){'DLP cmdlets available'}else{'run Connect-IPPSSession'})
Signal 'Sensitive info types readable' (Test-Command 'Get-DlpSensitiveInformationType') $(if(Test-Command 'Get-DlpSensitiveInformationType'){'present'}else{'connect S&C PowerShell'})

if (Test-Command 'Get-DlpCompliancePolicy') {
    $pol = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
    Signal 'Existing DLP policies' ($pol.Count -gt 0) ("{0} policy(ies) found" -f $pol.Count)
} else {
    Signal 'Existing DLP policies' $false 'cannot check — connect S&C PowerShell'
}

Write-Host "`nVerify manually (not readable here):" -ForegroundColor Cyan
Write-Host "  [ ] DLP licensing (E3 baseline; E5/E5 Compliance for Endpoint DLP + Source Code classifier)" -ForegroundColor DarkGray
Write-Host "  [ ] Compliance / DLP Compliance Management role assigned (least privilege)" -ForegroundColor DarkGray
Write-Host "  [ ] Source Code TRAINABLE CLASSIFIER available (Data classification -> Trainable classifiers)" -ForegroundColor DarkGray
Write-Host "  [ ] Endpoint DLP device ONBOARDING + egress-activity settings in place for pilot devices" -ForegroundColor DarkGray
Write-Host "  [ ] Custom IP types/keyword dictionaries designed; channels + pilot ring agreed; plan starts TEST mode" -ForegroundColor DarkGray
Write-Host "`nRecord every GAP against the Requirements checklist before configuring." -ForegroundColor DarkGray
