<#
.SYNOPSIS
    DLPPRINT-Discovery.ps1 — Print DLP posture assessment: policies, modes, Devices location, Print restriction, SIT coverage (read-only).
.DESCRIPTION
    PURPOSE
        Assesses the tenant's readiness for an Endpoint DLP Print restriction. Reports existing DLP
        policies and their mode (simulation vs enforce), which policies scope the Devices/Endpoint
        location, whether any rule already configures the Print endpoint restriction, and the built-in
        vs custom sensitive-information-type inventory. Read-only against Security & Compliance
        PowerShell — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPPRINT-Discovery.ps1 -CsvPath .\DLPPRINT-Posture.csv
        Requires the ExchangeOnlineManagement module and a Compliance/DLP admin. Connect first with
        Connect-IPPSSession (the script connects if no session is present).
    EXPECTED RESULTS
        A per-policy list with mode, whether it scopes Devices, and whether its rules set the Print
        restriction; a count of built-in vs custom SITs; and (optional) a CSV export. Nothing is
        modified. Regulatory/records/legal determinations are deferred to the relevant governance functions.
.NOTES
    Purview category — Print DLP (Endpoint DLP). Read-only. Endpoint Print behaviour is OS-/tenant-dependent
    (Windows most complete; macOS varies) — verify against current Microsoft guidance / your tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Connecting to Security & Compliance PowerShell..." -ForegroundColor Cyan
    Connect-IPPSSession -ErrorAction Stop | Out-Null
}

Write-Host "`n=== Print DLP posture (read-only) ===" -ForegroundColor Cyan

$rows = @()
$policies = @()
try { $policies = Get-DlpCompliancePolicy -ErrorAction Stop } catch {
    Write-Host "Unable to read DLP policies — confirm your DLP role and S&C PowerShell session." -ForegroundColor Yellow
}

Write-Host ("`n-- DLP policies ({0}) --" -f $policies.Count) -ForegroundColor Cyan
foreach ($p in $policies) {
    $rules = @()
    try { $rules = Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue } catch {}

    # Devices/Endpoint location scoped?
    $scopesDevices = $false
    if ($p.EndpointDlpLocation -and @($p.EndpointDlpLocation).Count -gt 0) { $scopesDevices = $true }

    # Any rule that sets the Print endpoint restriction (non-Ignore)?
    $printRule = $null
    foreach ($r in $rules) {
        $restr = $r.EndpointDlpRestrictions
        if ($restr) {
            foreach ($item in @($restr)) {
                $setting = "$($item.Setting)"; $value = "$($item.Value)"
                if ($setting -match 'Print' -and $value -and $value -ne 'Ignore') { $printRule = $r; break }
            }
        }
        if ($printRule) { break }
    }

    $mode = "$($p.Mode)"
    $modeLabel = switch -Wildcard ($mode) {
        'Test*'   { 'SIMULATION' }
        'Enable'  { 'ENFORCE' }
        'Disable' { 'DISABLED' }
        default   { $mode }
    }
    $col = if ($modeLabel -eq 'ENFORCE') { 'Yellow' } else { 'Green' }
    Write-Host ("Policy : {0}" -f $p.Name) -ForegroundColor $col
    Write-Host ("  mode           : {0} ({1})" -f $modeLabel, $mode)
    Write-Host ("  scopes Devices : {0}" -f $scopesDevices)
    Write-Host ("  Print rule set : {0}" -f ([bool]$printRule)) -ForegroundColor $(if ($printRule) { 'Green' } else { 'Gray' })
    if ($printRule) { Write-Host ("    via rule     : {0}" -f $printRule.Name) }

    $rows += [pscustomobject]@{
        Policy        = $p.Name
        Mode          = $mode
        ModeLabel     = $modeLabel
        ScopesDevices = $scopesDevices
        PrintRuleSet  = [bool]$printRule
        PrintRuleName = $printRule.Name
        RuleCount     = @($rules).Count
    }
}

# SIT inventory (built-in vs custom)
Write-Host "`n-- Sensitive information types --" -ForegroundColor Cyan
try {
    $sits = Get-DlpSensitiveInformationType -ErrorAction Stop
    $custom  = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' }).Count
    $builtin = @($sits).Count - $custom
    Write-Host ("Built-in SITs   : {0}" -f $builtin) -ForegroundColor Green
    Write-Host ("Custom SITs     : {0}" -f $custom) -ForegroundColor Green
} catch {
    Write-Host "SIT inventory   : unable to read (Get-DlpSensitiveInformationType)." -ForegroundColor Yellow
}

# Summary
$devicePolicies = @($rows | Where-Object { $_.ScopesDevices }).Count
$printPolicies  = @($rows | Where-Object { $_.PrintRuleSet }).Count
Write-Host "`n-- Summary --" -ForegroundColor Cyan
Write-Host ("Policies total          : {0}" -f $rows.Count)
Write-Host ("Scoping Devices location: {0}" -f $devicePolicies)
Write-Host ("With a Print restriction: {0}" -f $printPolicies) -ForegroundColor $(if ($printPolicies -gt 0) { 'Green' } else { 'Gray' })
if ($printPolicies -eq 0) {
    Write-Host "No Print restriction found — build 'DLP - Endpoint Print - Simulation' per the Implementation Guide (Phase 2)." -ForegroundColor Yellow
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported posture to {0}" -f $CsvPath) -ForegroundColor Cyan
}
