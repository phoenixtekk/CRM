<#
.SYNOPSIS
    DLPSPO-Discover.ps1 — Inventory DLP policies, rules, coverage/mode, and available sensitive info types (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current DLP state: every DLP policy and rule, whether each covers SharePoint and/or
        OneDrive, each policy's mode (test/enforce), and a sample of the available sensitive information
        types to match on. Read-only — makes no change.
    HOW TO RUN
        .\DLPSPO-Discover.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A policy/rule inventory with locations and mode, plus available sensitive info types — captured into
        'DLP Scope - Map'. Makes no configuration change.
.NOTES
    Purview — SharePoint Online DLP. Read-only discovery. Verify your licensing/tenant: some info
    types/conditions require E5; property names vary by module version.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== SharePoint Online DLP — discovery (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-DlpCompliancePolicy')) {
    Write-Host "Get-DlpCompliancePolicy not available. Run Connect-IPPSSession first." -ForegroundColor Yellow; return
}

$policies = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
Write-Host ("`nDLP policies ({0}):" -f $policies.Count) -ForegroundColor Green

foreach ($p in $policies) {
    $spo = ($p.PSObject.Properties.Name -contains 'SharePointLocation' -and $p.SharePointLocation)
    $od  = ($p.PSObject.Properties.Name -contains 'OneDriveLocation'   -and $p.OneDriveLocation)
    $loc = @(); if ($spo) { $loc += 'SharePoint' }; if ($od) { $loc += 'OneDrive' }
    Write-Host ("`n  Policy: {0} | Mode: {1} | Covers: {2}" -f $p.Name, $p.Mode, $(if($loc){$loc -join ', '}else{'other/none'})) -ForegroundColor White
    $rules = @(Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue)
    foreach ($r in $rules) {
        Write-Host ("    Rule: {0} | Disabled: {1}" -f $r.Name, $r.Disabled) -ForegroundColor DarkGray
    }
}

# Available sensitive information types (sample)
if (Test-Command 'Get-DlpSensitiveInformationType') {
    $sits = @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue)
    Write-Host ("`nAvailable sensitive information types ({0} total). Sample:" -f $sits.Count) -ForegroundColor Green
    $sits | Select-Object -First 25 Name, Publisher | Format-Table -AutoSize
    Write-Host "  (Use exact Name values in the -SensitiveTypes parameter of DLPSPO-Set-DlpPolicy.ps1.)" -ForegroundColor DarkGray
} else {
    Write-Host "`nGet-DlpSensitiveInformationType not available — connect S&C PowerShell." -ForegroundColor DarkGray
}

Write-Host "`nRecord policies, coverage, mode, and chosen info types in 'DLP Scope - Map'." -ForegroundColor DarkGray
