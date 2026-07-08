<#
.SYNOPSIS
    DLPCODE-Discover.ps1 — Inventory DLP policies, rules, channel coverage/mode, and available sensitive
    info types (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current DLP state for code/IP protection: every DLP policy and rule, which channels each
        covers (Exchange / SharePoint / OneDrive / Teams / Endpoint), each policy's mode (test/enforce), and
        a sample of available sensitive information types. Reminds you to confirm the Source Code classifier
        and Endpoint DLP onboarding in the portal (not readable here). Read-only — makes no change.
    HOW TO RUN
        .\DLPCODE-Discover.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A policy/rule inventory with channels and mode, plus available sensitive info types — captured into
        'Source-Code DLP - Map'. Makes no configuration change.
.NOTES
    Purview — Source-Code & IP Protection DLP. Read-only discovery. Verify your licensing/tenant: Endpoint
    DLP + Source Code classifier require E5; property names vary by module version.
#>
[CmdletBinding()]
param()

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== Source-Code & IP Protection DLP — discovery (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-DlpCompliancePolicy')) {
    Write-Host "Get-DlpCompliancePolicy not available. Run Connect-IPPSSession first." -ForegroundColor Yellow; return
}

$policies = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
Write-Host ("`nDLP policies ({0}):" -f $policies.Count) -ForegroundColor Green

$chanProps = @{
    'Exchange'   = 'ExchangeLocation'
    'SharePoint' = 'SharePointLocation'
    'OneDrive'   = 'OneDriveLocation'
    'Teams'      = 'TeamsLocation'
    'Endpoint'   = 'EndpointDlpLocation'
}
foreach ($p in $policies) {
    $covered = foreach ($k in $chanProps.Keys) {
        $prop = $chanProps[$k]
        if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { $k }
    }
    Write-Host ("`n  Policy: {0} | Mode: {1} | Channels: {2}" -f $p.Name, $p.Mode, $(if($covered){($covered -join ', ')}else{'none/other'})) -ForegroundColor White
    $rules = @(Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue)
    foreach ($r in $rules) { Write-Host ("    Rule: {0} | Disabled: {1}" -f $r.Name, $r.Disabled) -ForegroundColor DarkGray }
}

if (Test-Command 'Get-DlpSensitiveInformationType') {
    $sits = @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue)
    Write-Host ("`nAvailable sensitive information types ({0} total). Sample:" -f $sits.Count) -ForegroundColor Green
    $sits | Select-Object -First 20 Name, Publisher | Format-Table -AutoSize
    Write-Host "  (Author custom IP types/keyword dictionaries for code-names + IP markings as designed.)" -ForegroundColor DarkGray
}

Write-Host "`nConfirm in the Purview portal (not readable here):" -ForegroundColor Cyan
Write-Host "  [ ] Source Code TRAINABLE CLASSIFIER available (Data classification -> Trainable classifiers)" -ForegroundColor DarkGray
Write-Host "  [ ] Endpoint DLP device ONBOARDING + egress-activity settings (Settings -> Endpoint DLP)" -ForegroundColor DarkGray
Write-Host "`nRecord policies, channels, mode, classifier + endpoint state in 'Source-Code DLP - Map'." -ForegroundColor DarkGray
