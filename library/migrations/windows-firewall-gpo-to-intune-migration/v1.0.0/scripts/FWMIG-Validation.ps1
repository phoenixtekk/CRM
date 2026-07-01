<#
.SYNOPSIS
    FWMIG-Validation.ps1 - Post-migration firewall rule-parity check (READ-ONLY).

.DESCRIPTION
    PURPOSE
        Confirms a migrated device's EFFECTIVE Windows Defender Firewall state matches the captured
        GPO inventory (the parity baseline from FWMIG-Discovery.ps1), and that GPO is no longer
        contributing rules (single authority). Reports per-profile default parity, per-rule parity
        (present / missing / mismatched / stray), and any still-applying GPO firewall rules.
        This script is READ-ONLY - it makes no changes.

    HOW TO RUN
        Run on a migrated device (in the current ring) in an elevated PowerShell session, pointing at
        the baseline JSON produced by FWMIG-Discovery.ps1 before cutover:
            .\FWMIG-Validation.ps1 -BaselinePath C:\Temp\FWMIG\FWMIG-Inventory-PC01-...json
        Uses the built-in NetSecurity module.

    EXPECTED RESULTS
        - PASS when: profile defaults match the baseline, every baseline rule is present and matching,
          and no GPO-sourced firewall rules still apply (single authority = Intune/MDM).
        - FAIL (non-zero exit) listing: mismatched profile defaults, MISSING/MISMATCH rules, and any
          GPO rules still in effect (indicates double management / unfinished cutover).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $BaselinePath
)

if (-not (Test-Path $BaselinePath)) { Write-Error "Baseline not found: $BaselinePath"; return }
Import-Module NetSecurity -ErrorAction Stop

$baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
$failures = New-Object System.Collections.Generic.List[string]

Write-Host "FWMIG Validation on $env:COMPUTERNAME against baseline $(Split-Path $BaselinePath -Leaf)" -ForegroundColor Cyan

# --- Profile default parity ---
$liveProfiles = Get-NetFirewallProfile -PolicyStore ActiveStore
foreach ($bp in $baseline.Profiles) {
    $lp = $liveProfiles | Where-Object Name -eq $bp.Profile
    if (-not $lp) { $failures.Add("Profile $($bp.Profile) not found live"); continue }
    if ("$($lp.Enabled)"               -ne "$($bp.Enabled)")               { $failures.Add("$($bp.Profile): Enabled $($lp.Enabled) != baseline $($bp.Enabled)") }
    if ("$($lp.DefaultInboundAction)"  -ne "$($bp.DefaultInboundAction)")  { $failures.Add("$($bp.Profile): DefaultInboundAction $($lp.DefaultInboundAction) != $($bp.DefaultInboundAction)") }
    if ("$($lp.DefaultOutboundAction)" -ne "$($bp.DefaultOutboundAction)") { $failures.Add("$($bp.Profile): DefaultOutboundAction $($lp.DefaultOutboundAction) != $($bp.DefaultOutboundAction)") }
}

# --- Rule parity (effective active store vs baseline ActiveStore rules) ---
$baseRules = $baseline.Rules | Where-Object Source -eq 'ActiveStore'
$liveRules = Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction SilentlyContinue

function Get-RuleKey { param($r) "$($r.DisplayName)|$($r.Direction)|$($r.Action)" }

$liveIndex = @{}
foreach ($lr in $liveRules) {
    $port = $lr | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
    $liveIndex[(Get-RuleKey $lr)] = [pscustomobject]@{
        Protocol  = "$($port.Protocol)"
        LocalPort = ($port.LocalPort -join ',')
    }
}

foreach ($br in $baseRules) {
    $key = Get-RuleKey $br
    if (-not $liveIndex.ContainsKey($key)) {
        $failures.Add("MISSING rule: $($br.DisplayName) [$($br.Direction)/$($br.Action)]")
        continue
    }
    $live = $liveIndex[$key]
    if ($br.Protocol  -and "$($live.Protocol)"  -ne "$($br.Protocol)")  { $failures.Add("MISMATCH protocol on '$($br.DisplayName)': $($live.Protocol) != $($br.Protocol)") }
    if ($br.LocalPort -and "$($live.LocalPort)" -ne "$($br.LocalPort)") { $failures.Add("MISMATCH local port on '$($br.DisplayName)': $($live.LocalPort) != $($br.LocalPort)") }
}

# --- Single-authority check: any GPO-sourced firewall rules still applying? ---
$gpoStillApplying = Get-NetFirewallRule -PolicyStore RSOP -ErrorAction SilentlyContinue
if (@($gpoStillApplying).Count -gt 0) {
    $failures.Add("DOUBLE MANAGEMENT: $(@($gpoStillApplying).Count) GPO-sourced firewall rule(s) still apply - device not fully out of GPO scope")
}

if ($failures.Count -eq 0) {
    Write-Host "PASS - effective firewall state matches the GPO baseline; single authority (Intune/MDM)." -ForegroundColor Green
    exit 0
} else {
    Write-Host "FAIL - $($failures.Count) parity issue(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}
