<#
.SYNOPSIS
    MDEONB-Report.ps1 — coverage + ASR-audit + TVM exposure report for Defender for Endpoint,
    with baseline drift.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Onboarding Accelerator — Microsoft Defender for Endpoint"
        solution. Summarizes what ASR rules WOULD block (from audit events), the top software
        vulnerabilities (TVM exposure), and — with -SaveBaseline — records an exposure baseline so
        later runs show drift. Also reminds you to keep the pilot AIR automation approval-gated.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEONB-Report.ps1 -Section All -SaveBaseline
        -Section accepts: ASR | Exposure | All (default All).
        Uses Microsoft.Graph.Authentication + Graph Security advanced hunting.
    EXPECTED RESULTS
        An ASR audit summary (what block WOULD stop — review before promoting), the top TVM
        vulnerabilities, and drift versus the saved baseline. A downward exposure trend = healthy.
.NOTES
    White-label. Read-only. Use the ASR audit summary to add exclusions BEFORE moving to block.
    AIR automation must remain approval-gated until the SOC decides otherwise.
#>
[CmdletBinding()]
param(
    [ValidateSet('ASR','Exposure','All')] [string]$Section = 'All',
    [switch]$SaveBaseline,
    [string]$BaselinePath = ".\MDEONB-exposure-baseline.json"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Endpoint — coverage & exposure report ($Section) ===" -ForegroundColor Cyan
$vulnCount = $null

if ($Section -in 'ASR','All') {
    Write-Host "`n-- ASR audit summary (what BLOCK would stop — review before promoting) --" -ForegroundColor Cyan
    $kql = @"
DeviceEvents
| where Timestamp > ago(7d)
| where ActionType startswith 'Asr' and ActionType endswith 'Audited'
| summarize Count=count() by ActionType, FileName=tostring(FolderPath)
| order by Count desc
| take 30
"@
    try {
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json'
        if ($r.results) { $r.results | ForEach-Object { Write-Host ("   {0}  x{1}  {2}" -f $_.ActionType, $_.Count, $_.FileName) } }
        else { Write-Host "   No ASR audit events (rules in audit yet? allow warm-up)." -ForegroundColor Yellow }
    } catch { Write-Host ("   ASR hunt unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Add exclusions for legitimate hits, THEN promote to block (MDEONB-PromoteASR.ps1)." -ForegroundColor DarkGray
}

if ($Section -in 'Exposure','All') {
    Write-Host "`n-- TVM exposure — top software vulnerabilities --" -ForegroundColor Cyan
    $kql = @"
DeviceTvmSoftwareVulnerabilities
| summarize Devices=dcount(DeviceId) by CveId, SoftwareName, VulnerabilitySeverityLevel
| order by Devices desc
| take 25
"@
    try {
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json'
        if ($r.results) { $vulnCount = $r.results.Count; $r.results | ForEach-Object { Write-Host ("   [{0}] {1} — {2} device(s) — {3}" -f $_.VulnerabilitySeverityLevel, $_.CveId, $_.Devices, $_.SoftwareName) } }
        else { Write-Host "   No TVM rows yet — allow warm-up." -ForegroundColor Yellow; $vulnCount = 0 }
    } catch { Write-Host ("   TVM hunt unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "`n-- Automated response --" -ForegroundColor Cyan
Write-Host "   Confirm the pilot device group AIR automation level = 'Semi - require approval' (approval-gated)." -ForegroundColor DarkGray

$now = [ordered]@{ Timestamp = (Get-Date).ToString('s'); TopVulnCount = $vulnCount }
if ($SaveBaseline) { $now | ConvertTo-Json | Set-Content -Path $BaselinePath -Encoding UTF8; Write-Host ("`nExposure baseline saved: {0}" -f $BaselinePath) -ForegroundColor Green }
elseif (Test-Path $BaselinePath) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    if ($null -ne $vulnCount -and $null -ne $base.TopVulnCount) { Write-Host ("`nTop-vuln drift vs baseline ({0}): {1}" -f $base.Timestamp, ($vulnCount - $base.TopVulnCount)) -ForegroundColor Cyan }
} else { Write-Host "`n(no baseline yet — run with -SaveBaseline to create one)" -ForegroundColor DarkGray }
Write-Host "Report complete (read-only)." -ForegroundColor Green
