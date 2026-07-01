<#
.SYNOPSIS
    NSCLIENT-Validation.ps1 — confirm the Netskope client is installed, running, enrolled, and steering.
.DESCRIPTION
    PURPOSE
        Read-only. Validates device-side client health: the client is installed, its service is
        running, it is enrolled to a tenant, and steering appears active. Use at the pilot gate and
        after each ring expansion.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSCLIENT-Validation.ps1
    EXPECTED RESULTS
        "CLIENT HEALTHY" when installed + service running + enrolled + steering active; otherwise a
        per-check breakdown of what is missing.
.NOTES
    Network Solutions — read-only. Netskope client internals (exact service name, enrollment/steering
    state location) are vendor-version-dependent and DEFERRED to the official Netskope documentation;
    confirm the probes below against your client build. This script does not change client state.
#>
[CmdletBinding()] param()

Write-Host "=== Netskope client validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# Installed (path probe — confirm per Netskope docs)
$pathProbe = @("$env:ProgramFiles\Netskope","${env:ProgramFiles(x86)}\Netskope")
$installed = [bool]($pathProbe | Where-Object { Test-Path $_ })

# Service running (common service-name defaults — confirm per Netskope docs)
$svcNames = @('stagentsvc','nsclientservice','netskope')
$svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $svcNames -contains $_.Name.ToLower() -or $_.DisplayName -match 'Netskope' } | Select-Object -First 1
$running = ($svc -and $svc.Status -eq 'Running')

# Enrolled to tenant — vendor-specific; presence of a Netskope config/registry hive is the heuristic.
# The authoritative enrollment/tenant value location is DEFERRED to Netskope docs.
$cfgProbe = @('HKLM:\SOFTWARE\Netskope','HKLM:\SOFTWARE\WOW6432Node\Netskope')
$enrolled = [bool]($cfgProbe | Where-Object { Test-Path $_ })

# Steering active — DEFERRED: the authoritative steering state is reported by the client itself
# (client UI / logs / vendor cmdlet per Netskope docs). Heuristic only: client installed and running.
$steering = ($installed -and $running)

function Show($label,$ok){ Write-Host ("  {0,-22}: {1}" -f $label, ($(if($ok){'PASS'}else{'FAIL'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'})) }
Show 'Client installed'  $installed
Show 'Service running'   $running
Show 'Enrolled (heuristic)' $enrolled
Show 'Steering active (heuristic)' $steering

Write-Host "  Note: enrolled/steering are heuristics — confirm authoritatively via Netskope client/docs." -ForegroundColor DarkGray

if ($installed -and $running -and $enrolled -and $steering) {
    Write-Host "`nResult: CLIENT HEALTHY" -ForegroundColor Green; exit 0
} else {
    Write-Host "`nResult: NOT HEALTHY — see failed checks; use NSCLIENT-Remediation.ps1 (-WhatIf first)" -ForegroundColor Yellow; exit 1
}
