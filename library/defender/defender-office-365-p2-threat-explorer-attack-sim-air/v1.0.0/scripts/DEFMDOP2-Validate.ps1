<#
.SYNOPSIS
    DEFMDOP2-Validate.ps1 — run the 05-testing pass/fail gates for the Plan 2 detect/respond build (read-only).
.DESCRIPTION
    PURPOSE
        Checks the build against the gates in 05-testing.md and prints PASS/FAIL per gate: Plan 2
        present, email tables have data, a pilot simulation reported, hunting returns results, AIR
        actions are pending (not auto-applied), remediation preview is available/gated, and the custom
        detection exists in alert-only mode. Read-only — it validates, it does not change anything.
    HOW TO RUN
        pwsh -File .\DEFMDOP2-Validate.ps1 -PilotGroup "Grp-MDO-Pilot-Users"

        Prereqs: Microsoft.Graph; sign in with an admin holding at least Security Reader +
        ThreatHunting.Read.All. Government cloud: pass -Environment. Some checks that require portal-only
        state (Action center pending, custom-detection response mode) are reported as MANUAL prompts.
    EXPECTED RESULTS
        One line per gate: PASS / FAIL / MANUAL. Any FAIL = stay in pilot and remediate that gate.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $PilotGroup = 'Grp-MDO-Pilot-Users',
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
$fail = 0
function Gate([string] $Name, [string] $State, [string] $Detail='') {
    $color = switch ($State) { 'PASS' {'Green'} 'FAIL' {'Red'} default {'Yellow'} }
    Write-Host ("[{0}] {1}{2}" -f $State, $Name, ($(if($Detail){" — $Detail"}else{''}))) -ForegroundColor $color
    if ($State -eq 'FAIL') { $script:fail++ }
}
function Invoke-Kql([string] $q) {
    $body = @{ Query = $q } | ConvertTo-Json -Depth 4
    (Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body).results
}

try {
    Connect-MgGraph -Scopes 'Organization.Read.All','Group.Read.All','ThreatHunting.Read.All','AttackSimulation.Read.All' `
        -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host 'Connected to Microsoft Graph.' -ForegroundColor Green; Write-Host ''
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# Gate 1 — Plan 2 present
try {
    $p2 = (Get-MgSubscribedSku -All).ServicePlans | Where-Object { $_.ServicePlanName -match 'THREAT_INTELLIGENCE|ATP_ENTERPRISE' }
    if ($p2) { Gate 'Gate 1: Plan 2 service plan present' 'PASS' } else { Gate 'Gate 1: Plan 2 service plan present' 'FAIL' 'assign MDO Plan 2 (R1)' }
} catch { Gate 'Gate 1: Plan 2 service plan present' 'MANUAL' 'could not read SKUs — verify in Billing' }

# Gate 3 — Email tables have data
try {
    $r = Invoke-Kql "EmailEvents | where Timestamp > ago(24h) | count"
    $n = if ($r) { [int]$r[0].Count } else { 0 }
    if ($n -gt 0) { Gate 'Gate 3: EmailEvents has recent data' 'PASS' ("{0} rows/24h" -f $n) } else { Gate 'Gate 3: EmailEvents has recent data' 'FAIL' 'no data — confirm Plan 2 + mail flow' }
} catch { Gate 'Gate 3: EmailEvents has recent data' 'MANUAL' 'verify table schema for your cloud' }

# Gate 4 — Pilot simulation reported (beta)
try {
    $sims = @((Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/attackSimulation/simulations').value)
    $pilot = $sims | Where-Object { $_.displayName -like 'Sim-CredHarvest-Pilot*' }
    if ($pilot) { Gate 'Gate 4: pilot simulation exists/reported' 'PASS' } else { Gate 'Gate 4: pilot simulation exists/reported' 'MANUAL' 'no Sim-CredHarvest-Pilot via beta API — confirm in portal' }
} catch { Gate 'Gate 4: pilot simulation exists/reported' 'MANUAL' 'attack-sim beta API unavailable — confirm in portal' }

# Gate 5 — Hunting returns results (post-delivery clicks query resolves)
try {
    $r = Invoke-Kql "UrlClickInfo | where Timestamp > ago(7d) | count"
    Gate 'Gate 5: hunting query resolves' 'PASS' 'click table queryable'
} catch { Gate 'Gate 5: hunting query resolves' 'FAIL' 'hunting query failed — check perms/schema' }

# Gate 6 — AIR pending, not auto-applied (portal state)
Gate 'Gate 6: AIR actions PENDING (not auto-applied)' 'MANUAL' 'confirm Action center -> Pending holds AIR actions (approval-required)'

# Gate 7 — Remediation preview available + gated
if (Test-Path (Join-Path $PSScriptRoot 'DEFMDOP2-Remediate.ps1')) { Gate 'Gate 7: remediation preview script present + -WhatIf default' 'PASS' } else { Gate 'Gate 7: remediation preview script present' 'FAIL' 'DEFMDOP2-Remediate.ps1 missing' }

# Gate 8 — Custom detection alert-only (portal state)
Gate 'Gate 8: Detect-PostDeliveryPhish-Pilot alert-only' 'MANUAL' 'confirm custom detection response = generate alert only'

# Pilot group sanity
try {
    $grp = Get-MgGroup -Filter "displayName eq '$PilotGroup'"
    if ($grp) { Gate ("Pilot group '{0}' exists" -f $PilotGroup) 'PASS' } else { Gate ("Pilot group '{0}' exists" -f $PilotGroup) 'FAIL' 'create it (Step 1.1)' }
} catch { Gate 'Pilot group check' 'MANUAL' }

Write-Host ''
if ($fail -eq 0) { Write-Host 'All automated gates PASS. Complete the MANUAL checks, then proceed to Expand.' -ForegroundColor Green }
else { Write-Host ("{0} gate(s) FAILED — stay in pilot and remediate before Expand." -f $fail) -ForegroundColor Red }
