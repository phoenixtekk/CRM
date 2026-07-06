<#
.SYNOPSIS
    RIDCAP-Discovery.ps1 — Report RID-pool consumption, remaining capacity, and RID Master health.
.DESCRIPTION
    PURPOSE
        Reads the domain RID pool from the RID Manager object and decodes it into RIDs
        consumed, pool maximum, RIDs remaining, and percent consumed. Also identifies the
        RID Master FSMO holder so its health can be confirmed. Read-only.
        Run this against your-domain to establish the numbers every projection depends on.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RIDCAP-Discovery.ps1
        Requires the RSAT ActiveDirectory module and domain read access.
        Optional: -AlertThresholdPercent 80 to change the warning gate.
    EXPECTED RESULTS
        A summary of RIDMaster, RIDsConsumed, RIDMaximum, RIDsRemaining, PercentConsumed.
        PASS when PercentConsumed is below the alert threshold (default 80%); FAIL at/above it.
.NOTES
    White-label — the repeatable way. Read-only against Active Directory.
#>

[CmdletBinding()]
param(
    [double]$AlertThresholdPercent = 80
)

Import-Module ActiveDirectory -ErrorAction Stop

$domain    = Get-ADDomain
$ridMaster = $domain.RIDMaster

# The rIDAvailablePool attribute on CN=RID Manager$,CN=System packs two 32-bit halves into
# a 64-bit value: the low 32 bits = next RID to issue (= consumed count), the high 32 bits
# = the pool ceiling (default 1,073,741,823 = 2^30 - 1).
$ridManagerDN = "CN=RID Manager$,CN=System,$($domain.DistinguishedName)"
$ridManager   = Get-ADObject $ridManagerDN -Property rIDAvailablePool -ErrorAction Stop
$pool         = [uint64]$ridManager.rIDAvailablePool

$divisor   = [uint64]([math]::Pow(2, 32))
$consumed  = [uint64]($pool -band ($divisor - 1))   # low 32 bits = next RID / consumed
$maximum   = [uint64]([math]::Floor($pool / $divisor))  # high 32 bits = pool ceiling
$remaining = $maximum - $consumed
$pct       = [math]::Round(($consumed / $maximum) * 100, 4)

$status = if ($pct -ge $AlertThresholdPercent) { "FAIL (>= $AlertThresholdPercent% consumed)" }
          else { "PASS (< $AlertThresholdPercent% consumed)" }

Write-Host ""
Write-Host "=== RIDCAP Discovery — RID pool consumption & RID Master ===" -ForegroundColor Cyan
[pscustomobject]@{
    Domain          = $domain.DNSRoot
    RIDMaster       = $ridMaster
    RIDsConsumed    = $consumed
    RIDMaximum      = $maximum
    RIDsRemaining   = $remaining
    PercentConsumed = "$pct %"
    AlertThreshold  = "$AlertThresholdPercent %"
    Status          = $status
} | Format-List

Write-Host "RID Master health — verify with:" -ForegroundColor Yellow
Write-Host "  dcdiag /test:RidManager /v"
Write-Host "  repadmin /showrepl $ridMaster"
Write-Host ""
Write-Host "Note: RIDs are never reclaimed on delete; consumption is cumulative for the life of the domain."
Write-Host "Extended RID pool (Server 2012+) can raise the ceiling to 2^31 as a one-way safety valve."
Write-Host ""

if ($pct -ge $AlertThresholdPercent) { exit 1 } else { exit 0 }
