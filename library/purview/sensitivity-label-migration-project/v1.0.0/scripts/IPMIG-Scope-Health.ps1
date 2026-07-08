<#
.SYNOPSIS
    IPMIG-Scope-Health.ps1 — mapping-health check: flag unmapped values, missing SITs/labels, or policies enforcing before sign-off (read-only).
.DESCRIPTION
    PURPOSE
        Guardrail check before expansion. Reads the mapping CSV and the live estate and flags: any legacy
        value with NO mapping, any mapping referencing a detection SIT or target label that DOES NOT EXIST,
        and any reclassification policy already ENFORCING (Mode=Enable) — which must not happen before the
        data owner signs off precision. Read-only: makes no changes; it only reports health so you don't
        expand on a broken mapping.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPMIG-Scope-Health.ps1 -MappingCsv .\mapping.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Mapping CSV columns: LegacyValue,
        TargetLabel, SitName (optional Locations). PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        A HEALTHY / issues-found summary. HEALTHY = every in-scope legacy value is mapped, every referenced
        SIT and target label exists, and no reclassification policy is enforcing prematurely. Any issue
        blocks expansion until resolved.
.NOTES
    Purview — Sensitivity Label Migration. Read-only. An unmapped value flagged as an OWNER DECISION is a
    determination for the data owner, not a technical fix — surface it, don't guess a mapping.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MappingCsv,
    [switch]$AllowEnforced,              # suppress the "enforcing before sign-off" flag once sign-off is recorded
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Bad($m){ Write-Host "  [ISSUE] $m" -ForegroundColor Yellow }

if (-not (Test-Path $MappingCsv)) { Write-Error "Mapping CSV not found: $MappingCsv"; return }
$mappings = @(Import-Csv $MappingCsv)
if ($mappings.Count -eq 0) { Write-Error 'Mapping CSV has no rows.'; return }

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-IPPSSession -ShowBanner:$false }
}

$labelNames = @(Get-Label -ErrorAction SilentlyContinue | ForEach-Object { $_.DisplayName; $_.Name })
$sitNames   = @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
$autoPols   = @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)

Write-Host "=== Mapping health check (read-only) ===" -ForegroundColor Cyan
$issues = 0

# 1) Unmapped legacy values
foreach ($m in $mappings) {
    $legacy = "$($m.LegacyValue)".Trim()
    if (-not "$($m.TargetLabel)".Trim()) { Bad "Legacy value '$legacy' has NO target label — resolve as an owner decision (do not guess)."; $issues++ }
}

# 2) Mappings referencing missing SIT / target label
foreach ($m in $mappings) {
    $legacy = "$($m.LegacyValue)".Trim()
    $target = "$($m.TargetLabel)".Trim()
    $sit    = "$($m.SitName)".Trim()
    if ($target -and ($labelNames -notcontains $target)) { Bad "Mapping '$legacy' -> target label '$target' does NOT exist / not found (create & publish it, Requirement 2.2)."; $issues++ }
    if ($sit -and ($sitNames -notcontains $sit)) { Bad "Mapping '$legacy' -> detection SIT '$sit' does NOT exist (author it in the portal, Step 2)."; $issues++ }
    if (-not $sit) { Bad "Mapping '$legacy' has no detection SIT named — Purview cannot detect the legacy marking without one."; $issues++ }
}

# 3) Policies enforcing before sign-off
$enforcing = @($autoPols | Where-Object { $_.Name -like 'Reclassify Sim -*' -and "$($_.Mode)" -eq 'Enable' })
if ($enforcing.Count -gt 0 -and -not $AllowEnforced) {
    foreach ($p in $enforcing) { Bad "Policy '$($p.Name)' is ENFORCING (Mode=Enable) — confirm the data owner signed off precision (Step 4/5). Use -AllowEnforced once sign-off is recorded, or return it to simulation (IPMIG-Set-Migration.ps1 -ReturnToSimulation -Commit)."; $issues++ }
} elseif ($enforcing.Count -gt 0) {
    Ok "$($enforcing.Count) policy(ies) enforcing — sign-off acknowledged (-AllowEnforced)."
}

Write-Host ""
if ($issues -eq 0) { Ok "HEALTHY: every in-scope legacy value is mapped, every referenced SIT/label exists, and no policy is enforcing prematurely." }
else { Bad "$issues issue(s) found — do NOT expand until each is resolved (map the value / publish the label / author the SIT / confirm sign-off)." }
