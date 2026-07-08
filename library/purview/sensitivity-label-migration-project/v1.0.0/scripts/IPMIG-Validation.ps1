<#
.SYNOPSIS
    IPMIG-Validation.ps1 — report a reclassification policy's simulation mode/progress and what it would reclassify (read-only).
.DESCRIPTION
    PURPOSE
        Validation counterpart to IPMIG-Set-Migration.ps1. For a named reclassification auto-labeling policy
        (or all "Reclassify Sim -*" policies) it reports the current mode (simulation vs enforced), the
        distribution/deployment status, the target label it applies, and the detection SIT its rule
        references — so you can confirm before enforcement that the policy is still in SIMULATION, scoped
        correctly, and applying the mapped label. Read-only: it makes no changes and labels no content.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPMIG-Validation.ps1 -SimReport -PolicyName "Reclassify Sim - Confidential - Locations"
        powershell -ExecutionPolicy Bypass -File .\IPMIG-Validation.ps1 -SimReport      # all reclassification policies
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Role: Information Protection reader/admin.
        The detailed simulated match SET (per item) is shown in the Purview portal Auto-labeling > Simulation
        tab — this tool reports mode/status/config and points you there; it does not read item bodies.
    EXPECTED RESULTS
        Per policy: Mode (Test* = simulation PASS before enforcement), status, target label, rule SIT. If a
        policy shows Mode=Enable it is ENFORCING (reclassifying) — expected only after precision sign-off.
.NOTES
    Purview — Sensitivity Label Migration. Read-only. Whether precision is acceptable and whether to enforce
    are data-owner/records decisions — this tool reports state, it does not make the determination.
#>
[CmdletBinding()]
param(
    [switch]$SimReport,
    [string]$PolicyName,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "  $m" -ForegroundColor White }
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-IPPSSession -ShowBanner:$false }
}

Write-Host "=== Reclassification simulation report (read-only) ===" -ForegroundColor Cyan

try {
    if ($PolicyName) { $policies = @(Get-AutoSensitivityLabelPolicy -Identity $PolicyName -ErrorAction Stop) }
    else { $policies = @(Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Where-Object { $_.Name -like 'Reclassify Sim -*' }) }
} catch { Warn "Could not read auto-labeling policies (verify licensing/role, typically E5): $($_.Exception.Message)"; return }

if (-not $policies -or $policies.Count -eq 0) { Warn "No reclassification policies found (name pattern 'Reclassify Sim -*'). Create them with IPMIG-Set-Migration.ps1."; return }

foreach ($p in $policies) {
    Write-Host ("`n-- {0} --" -f $p.Name) -ForegroundColor Cyan
    $mode = "$($p.Mode)"
    if ($mode -like 'Test*') { Ok ("Mode: {0} (SIMULATION — nothing is labeled)" -f $mode) }
    elseif ($mode -eq 'Enable') { Warn ("Mode: {0} (ENFORCING — reclassifying content; expected only after precision sign-off)" -f $mode) }
    else { Info ("Mode: {0}" -f $mode) }

    foreach ($prop in 'DistributionStatus','DeploymentStatus','Comment','ApplySensitivityLabel','LabelDisplayName') {
        if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { Info ("{0}: {1}" -f $prop, $p.$prop) }
    }
    if ($p.SharePointLocation) { Info ("SharePoint scope: {0}" -f (($p.SharePointLocation | ForEach-Object { $_.DisplayName ?? $_ }) -join ', ')) }
    if ($p.OneDriveLocation)   { Info ("OneDrive scope: {0}"   -f (($p.OneDriveLocation   | ForEach-Object { $_.DisplayName ?? $_ }) -join ', ')) }

    # Rule detail: which detection SIT drives the labeling
    try {
        $rules = @(Get-AutoSensitivityLabelRule -Policy $p.Name -ErrorAction Stop)
        foreach ($r in $rules) {
            $sit = ''
            try { $sit = ($r.ContentContainsSensitiveInformation.Name -join '; ') } catch {}
            Info ("Rule '{0}': detects SIT [{1}]" -f $r.Name, $sit)
        }
    } catch { Info "Rule detail unavailable — check in the portal." }
}

Write-Host "`nThe per-item simulated match set (for false-positive review with the data owner) is in the Purview portal:" -ForegroundColor DarkGray
Write-Host "  Information Protection > Auto-labeling > [policy] > Simulation. Sample matches for false positives before enforcing." -ForegroundColor DarkGray
Write-Host "Enforce ONLY after the data owner signs off precision (Step 4/5 gate)." -ForegroundColor DarkGray
