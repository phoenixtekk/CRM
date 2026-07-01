<#
.SYNOPSIS
    GPOPROG-Validation.ps1 — per-phase coexistence/conflict validation on a device.
.DESCRIPTION
    PURPOSE
        Confirms a transition phase is safe to advance. On a device in the phase's scope it: reads
        the MDMWinsOverGP (ControlPolicyConflict) precedence state; lists the applied MDM
        PolicyManager values Intune is enforcing; and (when -PreviousSnapshot is supplied) compares
        against a prior run to detect FLIP/LOOP signatures (a setting whose value changed between
        cycles = the loop signature this program guards against). Writes a snapshot for the next run.
        Read-only against the device.
    HOW TO RUN
        On a phase-scope device (elevated). First run captures a baseline snapshot:
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Validation.ps1 -Phase "Core OS"
        After a policy cycle, compare to detect loops:
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Validation.ps1 -Phase "Core OS" -PreviousSnapshot .\GPOPROG-Validation-CoreOS.json
    EXPECTED RESULTS
        MDMWinsOverGP state (enabled = pass), the count of applied MDM settings, and — with a
        previous snapshot — a list of any settings that CHANGED value between cycles (loop signature).
        Zero changed settings + precedence enabled = the phase coexistence check passes.
.NOTES
    Workplace Marketplace — Migrations. Read-only.
#>
[CmdletBinding()]
param(
    [string] $Phase = "Core OS",
    [string] $PreviousSnapshot,
    [string] $OutputPath = "."
)

Write-Host "`n=== Phase coexistence/conflict validation — '$Phase' ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# 1) Precedence: MDM wins over GP
$cpc = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict' -ErrorAction SilentlyContinue
$mdmWins = $cpc.MDMWinsOverGP
if ($mdmWins -eq 1) { Write-Host "MDMWinsOverGP : ENABLED (pass)." -ForegroundColor Green }
else { Write-Host "MDMWinsOverGP : NOT enabled (FAIL) — assign 'Coexistence Policy - MDM Wins Over GP - All Migrated' to this phase scope." -ForegroundColor Yellow }

# 2) Applied MDM PolicyManager values (what Intune is enforcing)
$pmRoot = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device'
$applied = @{}
if (Test-Path $pmRoot) {
    foreach ($area in Get-ChildItem $pmRoot -ErrorAction SilentlyContinue) {
        $props = Get-ItemProperty $area.PSPath -ErrorAction SilentlyContinue
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -notmatch '^PS') { $applied["$($area.PSChildName)\$($p.Name)"] = "$($p.Value)" }
        }
    }
}
Write-Host ("Applied MDM settings: {0} values under PolicyManager." -f $applied.Count) -ForegroundColor Green

# 3) Loop/flip detection vs. a previous snapshot
$loopFindings = @()
if ($PreviousSnapshot -and (Test-Path $PreviousSnapshot)) {
    Write-Host ("`nComparing against previous snapshot: {0}" -f $PreviousSnapshot) -ForegroundColor Cyan
    try {
        $prevObj = Get-Content $PreviousSnapshot -Raw | ConvertFrom-Json
        $prev = @{}
        foreach ($p in $prevObj.Applied.PSObject.Properties) { $prev[$p.Name] = "$($p.Value)" }
        foreach ($k in $applied.Keys) {
            if ($prev.ContainsKey($k) -and $prev[$k] -ne $applied[$k]) {
                $loopFindings += [pscustomobject]@{ Setting = $k; Previous = $prev[$k]; Current = $applied[$k] }
            }
        }
        if ($loopFindings.Count) {
            Write-Host ("LOOP SIGNATURE: {0} setting(s) CHANGED value between cycles (FAIL) — a GPO/Intune precedence fight is likely:" -f $loopFindings.Count) -ForegroundColor Yellow
            $loopFindings | Format-Table -AutoSize
            Write-Host "Resolve with GPOPROG-Remediation.ps1 and scope the legacy GPO away for these areas." -ForegroundColor Gray
        } else {
            Write-Host "No value changes between cycles — no loop signature (pass)." -ForegroundColor Green
        }
    } catch {
        Write-Host "Could not read previous snapshot: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNo -PreviousSnapshot supplied — captured a baseline; re-run after a policy cycle to detect loops." -ForegroundColor Gray
}

# 4) Write snapshot for the next run
$safePhase = ($Phase -replace '[^A-Za-z0-9]', '')
$snap = Join-Path $OutputPath ("GPOPROG-Validation-{0}.json" -f $safePhase)
[pscustomobject]@{
    Phase         = $Phase
    Computer      = $env:COMPUTERNAME
    Timestamp     = (Get-Date).ToString('o')
    MDMWinsOverGP = $mdmWins
    Applied       = ([pscustomobject]$applied)
} | ConvertTo-Json -Depth 5 | Set-Content -Path $snap -Encoding UTF8
Write-Host ("`nSnapshot saved: {0}" -f $snap) -ForegroundColor Green

# 5) Phase verdict
$pass = ($mdmWins -eq 1) -and ($loopFindings.Count -eq 0)
Write-Host ("`nPhase '{0}' coexistence check: {1}" -f $Phase, $(if ($pass) { 'PASS' } else { 'NEEDS WORK' })) -ForegroundColor $(if ($pass) { 'Green' } else { 'Yellow' })
