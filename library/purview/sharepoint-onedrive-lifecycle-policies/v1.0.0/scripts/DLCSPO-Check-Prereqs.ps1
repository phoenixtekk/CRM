<#
.SYNOPSIS
    DLCSPO-Check-Prereqs.ps1 — Prerequisite/health helper for SharePoint/OneDrive retention (read-only; PASS/GAP).
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to configure retention: the ExchangeOnlineManagement module and
        S&C PowerShell connection, whether the retention cmdlets and adaptive-scope cmdlets are available
        (a licensing signal), and existing retention policies. Read-only.
    HOW TO RUN
        .\DLCSPO-Check-Prereqs.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/GAP line per signal. GAPs are recorded against the Requirements checklist and remediated
        before configuring. Makes no change.
.NOTES
    Purview — SharePoint & OneDrive Lifecycle Policies. Read-only. Verify your licensing/tenant: basic
    retention is E3; adaptive scopes generally require E5/E5 Compliance.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Signal([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("GAP   {0} — {1}" -f $Name, $Detail) -ForegroundColor Yellow }
}

Write-Host "`n=== SharePoint & OneDrive Lifecycle — prerequisite/health check (read-only) ===" -ForegroundColor Cyan

$haveMod = [bool](Get-Module -ListAvailable -Name ExchangeOnlineManagement)
Signal 'Module: ExchangeOnlineManagement' $haveMod $(if($haveMod){'installed'}else{'install: Install-Module ExchangeOnlineManagement -Scope CurrentUser'})

Signal 'S&C PowerShell connected' (Test-Command 'Get-RetentionCompliancePolicy') $(if(Test-Command 'Get-RetentionCompliancePolicy'){'retention cmdlets available'}else{'run Connect-IPPSSession'})

Signal 'Adaptive scopes available (E5 signal)' (Test-Command 'Get-AdaptiveScope') $(if(Test-Command 'Get-AdaptiveScope'){'Get-AdaptiveScope present'}else{'not present — use static scopes (or verify E5/E5 Compliance)'})

if (Test-Command 'Get-RetentionCompliancePolicy') {
    $pol = @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)
    Signal 'Existing retention policies' ($pol.Count -gt 0) ("{0} policy(ies) found" -f $pol.Count)
} else {
    Signal 'Existing retention policies' $false 'cannot check — connect S&C PowerShell'
}

Write-Host "`nVerify manually (not readable here):" -ForegroundColor Cyan
Write-Host "  [ ] Retention licensing (E3 baseline; E5/E5 Compliance for adaptive scopes)" -ForegroundColor DarkGray
Write-Host "  [ ] Records Management / Compliance Administrator role assigned (least privilege)" -ForegroundColor DarkGray
Write-Host "  [ ] Retention schedule translated to rules; keep/delete determinations approved" -ForegroundColor DarkGray
Write-Host "  [ ] In-scope SharePoint/OneDrive locations enumerated; scope method chosen" -ForegroundColor DarkGray
Write-Host "  [ ] Pilot scope defined; plan starts RETAIN-ONLY; Preservation Hold Library understood" -ForegroundColor DarkGray
Write-Host "`nRecord every GAP against the Requirements checklist before configuring." -ForegroundColor DarkGray
