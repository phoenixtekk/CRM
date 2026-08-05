<#
.SYNOPSIS
    APPASMT-Maturity-Evidence.ps1 — aggregate the evidence into a scored data pack (READ-ONLY).
.DESCRIPTION
    PURPOSE
        The aggregator for the "APPASMT - Maturity Model (9 Dimensions x 5 Levels)". It reads the four
        prior evidence files (estate, assignment, install-health, unmanaged) from the Evidence Pack,
        adds a few direct signals of its own (app-control / WDAC / AppLocker configuration profiles,
        co-management / SCCM workload signals, app configuration & protection policies), and emits a
        single scored data pack: for each of the nine dimensions a SUGGESTED level (1-5) with the exact
        signal behind it. The suggested level is a starting point for the human assessor's APPASMT -
        Scoring Sheet, never the final word. READ-ONLY: Graph .Read.All scopes only; no tenant writes.
    HOW TO RUN
        # Run the four collectors first so the Evidence Pack is populated, then:
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All","DeviceManagementApps.Read.All","DeviceManagementRBAC.Read.All"
        #   GCC High: add -Environment USGov
        powershell -ExecutionPolicy Bypass -File .\APPASMT-Maturity-Evidence.ps1 -EvidenceDir .\APPASMT-EvidencePack
    EXPECTED RESULTS
        Console scorecard (9 dimensions, suggested level, signal) plus:
          APPASMT-EvidencePack.json   (the machine-readable scored pack for the Scoring Sheet)
          APPASMT-Suggested-Scores.csv
.NOTES
    Intune Solutions — application management assessment. READ-ONLY (aggregation/scoring; no tenant writes).
    Suggested levels are deterministic and transparent; the assessor confirms against the evidence tables
    in the Implementation Guide. Government: -Environment USGov (GCC High) / USGovDoD (DoD); verify GCC High
    parity where uncertain.
#>
[CmdletBinding()]
param([string]$EvidenceDir = ".\APPASMT-EvidencePack")

$ctx = Get-MgContext -ErrorAction SilentlyContinue
if (-not $ctx) { throw "Not connected. Run Connect-MgGraph with read-only scopes first (see .NOTES)." }
Write-Host ("Connected as {0} | Environment: {1}" -f $ctx.Account, $ctx.Environment) -ForegroundColor Cyan

function Read-Json($file) {
    $path = Join-Path $EvidenceDir $file
    if (Test-Path $path) { return (Get-Content $path -Raw | ConvertFrom-Json) }
    Write-Warning "Missing $file — dimensions relying on it will score 'Insufficient Evidence'."
    return $null
}
$estate    = Read-Json 'APPASMT-Estate-Summary.json'
$assign    = Read-Json 'APPASMT-Assignment-Summary.json'
$install   = Read-Json 'APPASMT-InstallHealth-Summary.json'
$unmanaged = Read-Json 'APPASMT-Unmanaged-Summary.json'

# Direct signals gathered here.
function Count-Uri([string]$uri) { try { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; return @($r.value).Count } catch { return -1 } }
# App-control (WDAC/AppLocker) via Application Control / endpoint security config policies (best-effort signal).
$appControlSignal = Count-Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=templateReference/templateFamily eq 'endpointSecurityApplicationControl'&`$top=5"
# App protection & configuration policies.
$appProtection = Count-Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/managedAppPolicies?`$top=50"
# Co-management / SCCM signal: devices with a management authority hinting co-management.
$coMgmt = Count-Uri "https://graph.microsoft.com/beta/deviceManagement/comanagedDevices?`$top=5"

function New-Score($key,$domain,$level,$why) { [pscustomobject]@{ Key=$key; Dimension=$domain; SuggestedLevel=$level; Signal=$why } }
function IE($key,$domain,$why) { New-Score $key $domain 'IE' ("Insufficient Evidence — $why") }

$scores = New-Object System.Collections.Generic.List[object]

# D1 Governance & Ownership — orphaned assignments + sprawl are the machine signal; ownership is interview-led.
if ($assign) {
    $orph = [int]$assign.orphanedAssignments; $spr = [int]$assign.assignmentSprawl
    if ($orph -gt 0 -or $spr -gt 5) { $scores.Add((New-Score 'D1' 'Governance & Ownership' 2 "orphaned=$orph, sprawl=$spr — no maintained ownership; confirm intake/register in interview")) }
    else { $scores.Add((New-Score 'D1' 'Governance & Ownership' 3 "orphaned=$orph, sprawl=$spr — clean; confirm written intake/owner register exists (artifact)")) }
} else { $scores.Add((IE 'D1' 'Governance & Ownership' 'assignment summary missing')) }

# D2 Packaging Standards — requires the written standard ARTIFACT; machine can only hint via name entropy.
$scores.Add((New-Score 'D2' 'Packaging Standards' 'IE' "Requires the written packaging-standard artifact (Step 3). Estate has $([int]$estate.totalApps) apps across $([int]$estate.distinctPublishers) publishers — set level from the artifact, not this script."))

# D3 Deployment & Rings — All-Devices/Users assignments are the ring-absence signal.
if ($assign) {
    $ad = [int]$assign.allDevicesOrUsers
    if ($ad -gt 0) { $scores.Add((New-Score 'D3' 'Deployment & Rings' 1 "$ad app assignment(s) target All Devices/Users — no ring discipline; confirm no defined rings")) }
    else { $scores.Add((New-Score 'D3' 'Deployment & Rings' 3 "no All-Devices/Users assignments — confirm defined ring groups + gates (artifact/interview) for L3+")) }
} else { $scores.Add((IE 'D3' 'Deployment & Rings' 'assignment summary missing')) }

# D4 Patching & Version Currency — version drift is the machine signal.
if ($install) {
    $drift = [int]$install.titlesWithVersionDrift
    if ($drift -gt 3) { $scores.Add((New-Score 'D4' 'Patching & Version Currency' 1 "$drift title(s) run multiple live versions — high drift; confirm no cadence")) }
    elseif ($drift -gt 0) { $scores.Add((New-Score 'D4' 'Patching & Version Currency' 2 "$drift title(s) with drift — partial currency; confirm cadence policy")) }
    else { $scores.Add((New-Score 'D4' 'Patching & Version Currency' 3 "no version drift detected — confirm written cadence + supersedence for L3+")) }
} else { $scores.Add((IE 'D4' 'Patching & Version Currency' 'install-health summary missing')) }

# D5 Security & Application Control — WDAC/AppLocker profile presence + unmanaged spread.
$um = if ($unmanaged) { [int]$unmanaged.unmanagedWideSpread } else { -1 }
if ($appControlSignal -lt 0) { $scores.Add((IE 'D5' 'Security & Application Control' 'could not read app-control policies (verify your licensing/tenant)')) }
elseif ($appControlSignal -eq 0) { $scores.Add((New-Score 'D5' 'Security & Application Control' 1 "no WDAC/AppLocker app-control policy found; unmanaged-on-many=$um — no execution control")) }
else { $scores.Add((New-Score 'D5' 'Security & Application Control' 3 "$appControlSignal app-control policy(ies) present; unmanaged-on-many=$um — confirm scope/enforce for L4+")) }

# D6 Lifecycle & Retirement — assigned-but-no-installs + no-assignment apps signal dead-app accumulation.
if ($estate) {
    $noAsg = [int]$estate.noAssignmentCount
    if ($noAsg -gt 5) { $scores.Add((New-Score 'D6' 'Lifecycle & Retirement' 1 "$noAsg apps with no assignment linger in the catalog — no retirement; confirm process absent")) }
    else { $scores.Add((New-Score 'D6' 'Lifecycle & Retirement' 2 "$noAsg unassigned apps — confirm written review/retirement process for L3+")) }
} else { $scores.Add((IE 'D6' 'Lifecycle & Retirement' 'estate summary missing')) }

# D7 Monitoring & Reporting — high-failure apps signal unwatched installs; reporting maturity is interview-led.
if ($install) {
    $hf = [int]$install.highFailureApps
    $scores.Add((New-Score 'D7' 'Monitoring & Reporting' 2 "$hf app(s) at >=10% install failure — confirm whether any regular install/estate report is produced & read (interview) for L3+"))
} else { $scores.Add((IE 'D7' 'Monitoring & Reporting' 'install-health summary missing')) }

# D8 Support Model — no tenant signal; entirely interview/artifact-driven.
$scores.Add((New-Score 'D8' 'Support Model' 'IE' "No tenant signal. Set from the ticket-routing map + runbooks (artifact) and service-desk interview (Step 4)."))

# D9 Tooling & Migration Debt — co-management + unmanaged/detected footprint.
if ($coMgmt -lt 0 -and -not $unmanaged) { $scores.Add((IE 'D9' 'Tooling & Migration Debt' 'co-management + unmanaged signals unavailable')) }
else {
    $cm = if ($coMgmt -lt 0) { 0 } else { $coMgmt }
    $ut = if ($unmanaged) { [int]$unmanaged.unmanagedTitles } else { 0 }
    if ($cm -gt 0 -or $ut -gt 20) { $scores.Add((New-Score 'D9' 'Tooling & Migration Debt' 2 "co-managed devices present=$($cm -gt 0), unmanaged titles=$ut — migration debt remains; confirm plan")) }
    else { $scores.Add((New-Score 'D9' 'Tooling & Migration Debt' 3 "low co-mgmt/unmanaged footprint — confirm Intune-native majority + inventory of remnants for L3+")) }
}

Write-Host "`n=== APPASMT Suggested Scores (APPASMT - Maturity Model, 9 Dimensions x 5 Levels) ===" -ForegroundColor Cyan
$scores | Format-Table Key, @{n='Suggested';e={ if ($_.SuggestedLevel -eq 'IE') { 'Insuff.Ev.' } else { "L$($_.SuggestedLevel)" } }}, Dimension, Signal -Wrap -AutoSize

$numeric = $scores | Where-Object { $_.SuggestedLevel -ne 'IE' }
if ($numeric) {
    $avg = [Math]::Round((($numeric | Measure-Object SuggestedLevel -Average).Average), 2)
    Write-Host ("`nSuggested overall maturity band (scored dimensions only): {0} / 5" -f $avg) -ForegroundColor Green
}
$ieCount = ($scores | Where-Object { $_.SuggestedLevel -eq 'IE' }).Count
Write-Host ("Dimensions needing human evidence (interview/artifact): {0}" -f $ieCount) -ForegroundColor Yellow

$pack = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    environment  = $ctx.Environment
    model        = 'APPASMT - Maturity Model (9 Dimensions x 5 Levels)'
    signals      = [ordered]@{ appControlPolicies=$appControlSignal; appProtectionPolicies=$appProtection; coManagedDeviceSignal=$coMgmt }
    scores       = $scores
}
$pack   | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $EvidenceDir 'APPASMT-EvidencePack.json') -Encoding UTF8
$scores | Export-Csv (Join-Path $EvidenceDir 'APPASMT-Suggested-Scores.csv') -NoTypeInformation -Encoding UTF8
Write-Host ("`nWrote APPASMT-EvidencePack.json and APPASMT-Suggested-Scores.csv to {0}" -f $EvidenceDir) -ForegroundColor Green
Write-Host "Read-only complete. Confirm every suggested level against the evidence tables before it enters the APPASMT - Scoring Sheet." -ForegroundColor Green
