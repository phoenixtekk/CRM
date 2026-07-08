<#
.SYNOPSIS
    DLCSPO-Discover.ps1 — Inventory SharePoint/OneDrive retention policies, rules, and adaptive scopes (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current retention state: every retention policy and rule, whether each covers SharePoint
        and/or OneDrive, the retention period and action (retain / retain-then-delete / delete-only) of each
        rule, and any adaptive scopes. Read-only — makes no change.
    HOW TO RUN
        .\DLCSPO-Discover.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A policy/rule inventory with locations, periods, and actions, plus any adaptive scopes — captured
        into 'Lifecycle Schedule - Map'. Makes no configuration change.
.NOTES
    Purview — SharePoint & OneDrive Lifecycle Policies. Read-only discovery. Verify your licensing/tenant:
    adaptive scopes require E5/E5 Compliance; some property names vary by module version.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== SharePoint & OneDrive Lifecycle — discovery (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-RetentionCompliancePolicy')) {
    Write-Host "Get-RetentionCompliancePolicy not available. Run Connect-IPPSSession first." -ForegroundColor Yellow; return
}

$policies = @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)
Write-Host ("`nRetention policies ({0}):" -f $policies.Count) -ForegroundColor Green

foreach ($p in $policies) {
    $spo = $false; $od = $false
    foreach ($prop in 'SharePointLocation','SharePointLocationException') { if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { $spo = $true } }
    foreach ($prop in 'OneDriveLocation','OneDriveLocationException')     { if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { $od  = $true } }
    $loc = @(); if ($spo) { $loc += 'SharePoint' }; if ($od) { $loc += 'OneDrive' }
    Write-Host ("`n  Policy: {0}   [Enabled: {1}]   Covers: {2}" -f $p.Name, $p.Enabled, $(if($loc){$loc -join ', '}else{'other/none'})) -ForegroundColor White

    $rules = @(Get-RetentionComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue)
    foreach ($r in $rules) {
        $action = if ($r.RetentionComplianceAction) { $r.RetentionComplianceAction } else { 'Retain/Delete (see rule)' }
        Write-Host ("    Rule: {0} | Period: {1} | Action: {2} | ExpireBy: {3}" -f `
            $r.Name, $r.RetentionDuration, $action, $r.ExpirationDateOption) -ForegroundColor DarkGray
    }
}

# Adaptive scopes (E5)
if (Test-Command 'Get-AdaptiveScope') {
    $scopes = @(Get-AdaptiveScope -ErrorAction SilentlyContinue)
    Write-Host ("`nAdaptive scopes ({0}):" -f $scopes.Count) -ForegroundColor Green
    $scopes | Select-Object Name, LocationType | Format-Table -AutoSize
} else {
    Write-Host "`nAdaptive scopes: Get-AdaptiveScope not available (E5/E5 Compliance, or older module) — use static scopes." -ForegroundColor DarkGray
}

Write-Host "`nRecord policies, covered locations, periods, actions, and scopes in 'Lifecycle Schedule - Map'." -ForegroundColor DarkGray
