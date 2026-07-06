<#
.SYNOPSIS
    GWCONSOL-Validation.ps1 — Read-only target-state conformance validation for consolidation waves.
.DESCRIPTION
    PURPOSE
        Validates the target-state conformance and readiness prerequisites a consolidation wave depends
        on, using Microsoft Graph, and emits PASS/FAIL per check for the readiness gate (Testing Group
        0) and the per-wave decommission gates. Checks cover: the identity tenant reachable, the
        presence and correct naming of the per-wave scope groups, that each wave's pilot group is
        populated, and the residual legacy-licence footprint (the lower the assigned count on
        consolidation-candidate SKUs, the closer to target-state conformance). It is strictly read-only
        — it asserts state, it does not change it. Google Workspace/Gemini target-side state is verified
        in the Google Admin console per Google documentation; Gemini preview capabilities are verified
        in your tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCONSOL-Validation.ps1
        Add -Wave to scope: Baseline, Collab, AI, Identity, Decommission (or All). Required Graph scopes
        (read-only): Organization.Read.All, Group.Read.All, Directory.Read.All. Sign in with a
        read-only / global-reader account. Install once: Install-Module Microsoft.Graph -Scope CurrentUser
    EXPECTED RESULTS
        A console list of checks, each marked [PASS] or [FAIL], and a final summary line with the
        pass/fail count. A non-zero exit code if any check FAILS (useful for gate automation). No tenant
        changes are made.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [ValidateSet('Baseline','Collab','AI','Identity','Decommission','All')]
    [string]$Wave = 'All',
    [string]$GroupNamePrefix = "Consolidation Wave Scope"
)

$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0

function Test-Check {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host ("[PASS] {0}" -f $Name) -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host ("[FAIL] {0} :: {1}" -f $Name, $Detail) -ForegroundColor Red
        $script:fail++
    }
}

# Wave -> the scope name its groups use.
$waveScopes = @('Baseline','Collab','AI','Identity','Decommission')
$scopesToCheck = if ($Wave -eq 'All') { $waveScopes } else { @($Wave) }

# Consolidation-candidate SKU hints (legacy collaboration + AI estate).
$legacyHints = 'EXCHANGE','TEAMS','SHAREPOINT','ONEDRIVE','COPILOT'

Write-Host "=== Consolidation target-state conformance validation (read-only) ===" -ForegroundColor Cyan
Write-Host ("Wave: {0}" -f $Wave) -ForegroundColor Cyan

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes @(
    "Organization.Read.All",
    "Group.Read.All",
    "Directory.Read.All"
) -NoWelcome

# --- Identity control plane present ---
$org = $null
try { $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1 } catch {}
Test-Check -Name "Identity tenant reachable" -Condition ([bool]$org) `
           -Detail "Could not read organization - confirm Entra access (R3)"

# --- Per-wave scope groups exist (Pilot + Broad), correctly named ---
$allGroups = @()
try { $allGroups = Get-MgGroup -Filter "startswith(displayName,'$GroupNamePrefix')" -All -ErrorAction Stop } catch {}

foreach ($scope in $scopesToCheck) {
    foreach ($stage in @('Pilot','Broad')) {
        $expected = "$GroupNamePrefix - $scope - $stage"
        $exists = [bool]($allGroups | Where-Object { $_.DisplayName -eq $expected })
        Test-Check -Name "Scope group present: $expected" -Condition $exists `
                   -Detail "Create with GWCONSOL-Set-ScopeTargeting.ps1 (R7)"
    }
}

# --- Pilot group has members (a pilot needs a population) ---
foreach ($scope in $scopesToCheck) {
    $pilotName = "$GroupNamePrefix - $scope - Pilot"
    $pilot = $allGroups | Where-Object { $_.DisplayName -eq $pilotName } | Select-Object -First 1
    if ($pilot) {
        $members = (Get-MgGroupMember -GroupId $pilot.Id -All -ErrorAction SilentlyContinue).Count
        Test-Check -Name "Pilot group populated: $pilotName" -Condition ($members -gt 0) `
                   -Detail "Pilot group has no members - add pilot users (R7)"
    }
}

# --- Target-state conformance signal: residual legacy-licence footprint ---
try {
    $skus = Get-MgSubscribedSku -All -ErrorAction Stop
    $legacyAssigned = 0
    foreach ($s in $skus) {
        foreach ($h in $legacyHints) {
            if ($s.SkuPartNumber -match $h) { $legacyAssigned += [int]$s.ConsumedUnits; break }
        }
    }
    # This is an informational conformance signal, not a hard fail: report the residual footprint.
    Test-Check -Name "Legacy-licence footprint readable (conformance signal)" -Condition ($skus.Count -gt 0) `
               -Detail "Could not read SKUs - confirm Directory.Read.All (R4)"
    Write-Host ("       Residual assigned licences on consolidation-candidate SKUs: {0} (target trends to 0)" -f $legacyAssigned) -ForegroundColor DarkCyan
} catch {
    Test-Check -Name "Legacy-licence footprint readable (conformance signal)" -Condition $false `
               -Detail "Could not read subscribed SKUs - confirm Directory.Read.All: $($_.Exception.Message)"
}

Disconnect-MgGraph | Out-Null

Write-Host ("`n=== Validation summary [{0}] - PASS: {1}  FAIL: {2} ===" -f $Wave, $pass, $fail) -ForegroundColor Cyan
Write-Host "Reminder: Google Workspace/Gemini target-state (and any preview capability) is verified in the Google Admin console / your tenant per Google docs." -ForegroundColor Yellow
if ($fail -gt 0) { exit 1 } else { exit 0 }
