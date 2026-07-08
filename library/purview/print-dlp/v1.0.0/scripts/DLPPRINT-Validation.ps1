<#
.SYNOPSIS
    DLPPRINT-Validation.ps1 — validate the Print DLP policy shape: Devices-only, Print restriction, mode, scope (read-only).
.DESCRIPTION
    PURPOSE
        Validates that the Print DLP policy is built correctly: scoped to the Devices/Endpoint location
        only, its rule sets the Print endpoint restriction, the policy is in the expected mode
        (simulation vs enforce), and the include/exclude scope matches the intended identities (e.g. the
        pilot ring). Prints PASS/FAIL per check. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPPRINT-Validation.ps1 -PolicyName 'DLP - Endpoint Print - Simulation'
        Expect simulation:  ... -ExpectMode Simulation
        Expect ring:        ... -ExpectMode Enforce -ExpectScope 'DLP Pilot Ring - Stage1'
        Requires ExchangeOnlineManagement + a Compliance/DLP reviewer role (Connect-IPPSSession).
    EXPECTED RESULTS
        A PASS/FAIL line per check (policy exists, Devices-only, Print restriction present, mode as
        expected, scope as expected) and an overall result. Any FAIL points at the fix in the
        Implementation / Troubleshooting guides. Nothing is modified.
.NOTES
    Purview category — Print DLP (Endpoint DLP). Read-only. Printer-group syntax / restriction names evolve —
    verify against current Microsoft guidance / your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$PolicyName,
    [ValidateSet('Simulation','Enforce','Any')]
    [string]$ExpectMode = 'Any',
    [string]$ExpectScope
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Connecting to Security & Compliance PowerShell..." -ForegroundColor Cyan
    Connect-IPPSSession -ErrorAction Stop | Out-Null
}

$fails = 0
function Assert($label, [bool]$ok, $detail) {
    if ($ok) { Write-Host ("  PASS  {0} {1}" -f $label, $detail) -ForegroundColor Green }
    else     { Write-Host ("  FAIL  {0} {1}" -f $label, $detail) -ForegroundColor Red; $script:fails++ }
}

Write-Host ("`n=== Validate Print DLP policy '{0}' ===" -f $PolicyName) -ForegroundColor Cyan

$p = $null
try { $p = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction Stop } catch {}
Assert 'Policy exists' ([bool]$p) $PolicyName
if (-not $p) { Write-Host "`nOverall: FAIL (policy not found)." -ForegroundColor Red; return }

# Devices-only
$hasDevices = ($p.EndpointDlpLocation -and @($p.EndpointDlpLocation).Count -gt 0)
$otherLocs = @()
foreach ($prop in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation') {
    if ($p.$prop -and @($p.$prop).Count -gt 0) { $otherLocs += $prop }
}
Assert 'Scopes Devices location' $hasDevices ''
Assert 'Devices-only (no other locations)' ($otherLocs.Count -eq 0) ($(if ($otherLocs) { "extra: $($otherLocs -join ', ')" } else { '' }))

# Print restriction on a rule
$rules = @(); try { $rules = Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue } catch {}
$printSet = $false; $printValue = ''
foreach ($r in $rules) {
    foreach ($item in @($r.EndpointDlpRestrictions)) {
        if ("$($item.Setting)" -match 'Print' -and "$($item.Value)" -and "$($item.Value)" -ne 'Ignore') {
            $printSet = $true; $printValue = "$($item.Value)"; break
        }
    }
    if ($printSet) { break }
}
Assert 'Print restriction present' $printSet ($(if ($printSet) { "(action: $printValue)" } else { '' }))

# Mode
$mode = "$($p.Mode)"
$isSim = $mode -like 'Test*'
switch ($ExpectMode) {
    'Simulation' { Assert 'Mode = simulation' $isSim "($mode)" }
    'Enforce'    { Assert 'Mode = enforce'   ($mode -eq 'Enable') "($mode)" }
    default      { Write-Host ("  INFO  Mode: {0}" -f $mode) -ForegroundColor Gray }
}

# Scope
if ($ExpectScope) {
    $scopeText = (@($p.EndpointDlpLocation) | ForEach-Object { "$_" }) -join '; '
    Assert 'Include scope matches expected' ($scopeText -match [regex]::Escape($ExpectScope)) "(scope: $scopeText)"
}

Write-Host ""
if ($fails -eq 0) { Write-Host "Overall: PASS — policy shape is correct." -ForegroundColor Green }
else { Write-Host ("Overall: FAIL — {0} check(s) failed; see the Implementation/Troubleshooting guides." -f $fails) -ForegroundColor Red }
