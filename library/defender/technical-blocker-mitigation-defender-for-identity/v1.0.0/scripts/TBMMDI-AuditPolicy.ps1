<#
.SYNOPSIS
    TBMMDI-AuditPolicy.ps1 — read-only, on-DC check of the advanced audit policy and NNR readiness a
    Defender for Identity sensor depends on.
.DESCRIPTION
    PURPOSE
        Run ON an affected domain controller from 'MDI Blocker Triage - Affected Sensors - Diagnose'.
        Event-collection and network-traffic blockers are only confirmable on the DC. This script reads
        (read-only) the advanced audit policy subcategory states MDI needs and probes NNR-relevant local
        readiness, then reports which are missing. It makes NO changes to audit policy, accounts, or
        network config.
    HOW TO RUN
        Run locally on the DC in an elevated PowerShell (read rights are enough):
        powershell -ExecutionPolicy Bypass -File .\TBMMDI-AuditPolicy.ps1
    EXPECTED RESULTS
        A table of the required audit subcategories with Enabled/Disabled state and an NNR readiness
        summary, written to MDI-auditpolicy-<hostname>.json. Disabled subcategories point at the
        event-collection fix; NNR gaps point at the network-traffic fix.
.NOTES
    White-label. Read-only — uses 'auditpol /get' and read-only probes only; changes nothing.
    The exact required subcategories and NNR ports EVOLVE — verify the current MDI requirements and
    treat this as a readiness indicator, not an authority.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDI-auditpolicy-$env:COMPUTERNAME.json"
)

Write-Host "`n=== TBMMDI — DC audit policy + NNR readiness (read-only) ===" -ForegroundColor Cyan
Write-Host ("DC: {0}" -f $env:COMPUTERNAME)

# Advanced audit subcategories MDI commonly relies on (verify current list).
$required = @(
    'Security Group Management',
    'Distribution Group Management',
    'Computer Account Management',
    'User Account Management',
    'Directory Service Access',
    'Directory Service Changes',
    'Credential Validation',
    'Kerberos Authentication Service',
    'Kerberos Service Ticket Operations'
)

$auditResults = @()
try {
    $raw = & auditpol /get /category:* 2>$null
    foreach ($sub in $required) {
        $line = $raw | Where-Object { $_ -match [regex]::Escape($sub) } | Select-Object -First 1
        $state = 'UNKNOWN'
        if ($line) {
            if ($line -match 'Success and Failure') { $state = 'Success+Failure' }
            elseif ($line -match 'Success')        { $state = 'Success' }
            elseif ($line -match 'Failure')         { $state = 'Failure' }
            elseif ($line -match 'No Auditing')     { $state = 'No Auditing' }
        }
        $ok = $state -match 'Success'
        $color = if ($ok) { 'Green' } else { 'Yellow' }
        Write-Host ("   {0,-38} {1}" -f $sub, $state) -ForegroundColor $color
        $auditResults += [ordered]@{ Subcategory=$sub; State=$state; MeetsMinimum=$ok }
    }
} catch { Write-Host ("   Could not read audit policy (run elevated on the DC): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- NNR readiness (informational, read-only) ---
Write-Host "`n-- NNR readiness (informational) --" -ForegroundColor Cyan
$nnrPorts = @(
    @{ Name='NetBIOS';        Port=137;   Proto='UDP' },
    @{ Name='RPC (Endpoint)'; Port=135;   Proto='TCP' },
    @{ Name='NetBIOS Session';Port=139;   Proto='TCP' },
    @{ Name='RDP (NNR)';      Port=3389;  Proto='TCP' }
)
Write-Host "   MDI uses NNR (reverse-lookup of IP->device) from the DC to endpoints. The sensor performs" -ForegroundColor DarkGray
Write-Host "   these lookups against clients; confirm these ports are reachable client-side. VERIFY the" -ForegroundColor DarkGray
Write-Host "   current NNR method/ports for your MDI version — the sensor UI reports NNR warnings directly." -ForegroundColor DarkGray
$nnrPorts | ForEach-Object { Write-Host ("     {0,-16} {1}/{2}" -f $_.Name, $_.Proto, $_.Port) }

$missing = @($auditResults | Where-Object { -not $_.MeetsMinimum }).Count
Write-Host ("`nAudit readiness: {0} required subcategory(ies) below minimum." -f $missing) -ForegroundColor ($(if ($missing -eq 0) { 'Green' } else { 'Yellow' }))
if ($missing -gt 0) { Write-Host "Fix: enable the advanced audit subcategories per current MDI guidance (event-collection fix)." -ForegroundColor Yellow }

[ordered]@{ Timestamp=(Get-Date).ToString('s'); DC=$env:COMPUTERNAME; AuditSubcategories=$auditResults; NNRPortsToVerify=$nnrPorts; MissingCount=$missing } |
    ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Readiness snapshot: {0}" -f $OutputPath) -ForegroundColor Green
