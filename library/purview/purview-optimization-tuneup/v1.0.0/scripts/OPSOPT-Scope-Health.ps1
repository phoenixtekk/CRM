<#
.SYNOPSIS
    OPSOPT-Scope-Health.ps1 — snapshot the prior values of policies to be tuned (rollback baseline) and flag drift. Read-only except for writing baseline files.
.DESCRIPTION
    PURPOSE
        Two jobs, neither of which changes a live policy: (1) capture the CURRENT value of every setting
        you intend to tune (DLP policy mode + rule confidence/instance counts, auto-label mode, alert
        threshold/aggregation) into .\OPSOPT-out\rollback-<policy>.json so a rollback baseline exists
        BEFORE any change (Implementation Step 4); (2) drift-check the change set — a policy re-enforced
        without pilot, a policy left in simulation too long, a reverted threshold, and whether the pilot
        group Purview Tuning - Pilot is populated (Step 13). It only reads tenant policy and writes local
        baseline/report files.
    HOW TO RUN
        PowerShell 5.1+/7+. Connect first: Connect-IPPSSession
          .\OPSOPT-Scope-Health.ps1 -Policies "PII - Exchange DLP" -AlertPolicies "Elevated DLP activity" -OutputFolder .\OPSOPT-out
          .\OPSOPT-Scope-Health.ps1 -OutputFolder .\OPSOPT-out          # drift-check all policies, no baseline capture
    EXPECTED RESULTS
        rollback-<policy>.json exists for each named policy (prior mode/confidence/threshold), and a
        drift summary flags any policy enforcing that was never piloted, simulation left on beyond the
        agreed window, or the pilot group empty.
.NOTES
    Purview — Optimization & Tune-Up. Does not change any live policy. Baseline files are never overwritten
    (first-captured value is the true rollback point). Insider-risk tuning is portal-driven, not here. No
    credentials in code. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [string[]]$Policies,                 # DLP policies to baseline (with their rules)
    [string[]]$AutoLabelPolicies,        # auto-labeling policies to baseline
    [string[]]$AlertPolicies,            # alert policies to baseline
    [string]$PilotGroup = 'Purview Tuning - Pilot',
    [int]$MaxSimulationDays = 30,        # flag a policy left in simulation longer than this (drift)
    [string]$OutputFolder = '.\OPSOPT-out'
)

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
Write-Host '=== OPSOPT Scope-Health — baseline capture + drift check (no live changes) ===' -ForegroundColor Cyan

function Save-Baseline([string]$name, [hashtable]$priorValues) {
    $safe = ($name -replace '[^A-Za-z0-9_-]', '_')
    $path = Join-Path $OutputFolder ("rollback-{0}.json" -f $safe)
    if (-not (Test-Path $path)) {
        $priorValues | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8
        Write-Host ("  baseline saved -> {0}" -f $path) -ForegroundColor DarkGray
    } else {
        Write-Host ("  baseline already exists -> {0} (kept)" -f $path) -ForegroundColor DarkGray
    }
}

$drift = [System.Collections.Generic.List[object]]::new()
function Flag([string]$Policy,[string]$Issue){ $drift.Add([pscustomobject]@{ Policy = $Policy; Issue = $Issue }) }

# --- Baseline + drift for DLP policies --------------------------------------------------------------
$allDlp = @()
try { $allDlp = @(Get-DlpCompliancePolicy -ErrorAction Stop) } catch { Write-Warning "Could not read DLP policies: $($_.Exception.Message)" }

foreach ($p in $allDlp) {
    $isTarget = (-not $Policies) -or ($Policies -contains $p.Name)
    if ($Policies -and $isTarget) {
        # Capture mode + each rule's SIT settings
        Save-Baseline $p.Name @{ Mode = "$($p.Mode)" }
        try {
            $rules = @(Get-DlpComplianceRule -Policy $p.Name -ErrorAction Stop)
            foreach ($r in $rules) {
                $priorSit = @()
                foreach ($s in @($r.ContentContainsSensitiveInformation)) {
                    $priorSit += @{ name = $s.name; minconfidence = $s.minconfidence; mincount = $s.mincount; maxcount = $s.maxcount }
                }
                Save-Baseline ("$($p.Name)--$($r.Name)") @{ ContentContainsSensitiveInformation = $priorSit; ExceptIfFrom = @($r.ExceptIfFrom) }
            }
        } catch { Write-Warning "Could not read rules for '$($p.Name)': $($_.Exception.Message)" }
    }
    # Drift: enforcing but no rollback baseline (i.e. never went through the tuning pipeline that would record one)
    $safe = ($p.Name -replace '[^A-Za-z0-9_-]', '_')
    $rb   = Join-Path $OutputFolder ("rollback-{0}.json" -f $safe)
    if ("$($p.Mode)" -like 'Test*') {
        if (Test-Path $rb) {
            $age = (Get-Date) - (Get-Item $rb).LastWriteTime
            if ($age.TotalDays -gt $MaxSimulationDays) { Flag $p.Name ("In simulation for {0:N0} days (> {1}) — validate and re-enforce or roll back." -f $age.TotalDays, $MaxSimulationDays) }
        }
    }
    if ("$($p.Mode)" -eq 'Enable' -and -not (Test-Path $rb)) {
        Flag $p.Name 'Enforcing with no rollback baseline recorded — was it tuned/piloted through the pipeline?'
    }
}

# --- Baseline auto-label + alert policies -----------------------------------------------------------
foreach ($a in @($AutoLabelPolicies)) {
    if (-not $a) { continue }
    try { $x = Get-AutoSensitivityLabelPolicy -Identity $a -ErrorAction Stop; Save-Baseline $a @{ Mode = "$($x.Mode)" } }
    catch { Write-Warning "Could not read auto-label policy '$a': $($_.Exception.Message)" }
}
foreach ($al in @($AlertPolicies)) {
    if (-not $al) { continue }
    try { $x = Get-ProtectionAlert -Identity $al -ErrorAction Stop; Save-Baseline $al @{ Threshold = "$($x.Threshold)"; AggregationType = "$($x.AggregationType)" } }
    catch { Write-Warning "Could not read alert policy '$al': $($_.Exception.Message)" }
}

# --- Pilot group check ------------------------------------------------------------------------------
Write-Host ("--- Pilot scope: {0} ---" -f $PilotGroup) -ForegroundColor Cyan
$members = @()
try { $members = @(Get-DistributionGroupMember -Identity $PilotGroup -ErrorAction Stop) } catch {
    try { $members = @(Get-UnifiedGroupLinks -Identity $PilotGroup -LinkType Members -ErrorAction Stop) } catch { Write-Host "  Could not read pilot group (verify name/type)." -ForegroundColor Yellow }
}
if ($members.Count -gt 0) { Write-Host ("  Pilot members: {0}" -f $members.Count) -ForegroundColor Green }
else { Flag $PilotGroup 'Pilot group empty — populate before piloting (Requirement 2.6).' }

# --- Drift summary ----------------------------------------------------------------------------------
Write-Host '--- Drift / health summary ---' -ForegroundColor Cyan
if ($drift.Count -gt 0) {
    $drift | Format-Table Policy, Issue -AutoSize | Out-String | Write-Host
    $drift | Export-Csv (Join-Path $OutputFolder 'scope-health-drift.csv') -NoTypeInformation -Encoding UTF8
    Write-Host ("{0} drift item(s) — review before re-enforcing." -f $drift.Count) -ForegroundColor Yellow
} else {
    Write-Host 'No drift detected in the checked scope.' -ForegroundColor Green
}
Write-Host '=== Scope-Health complete (no live policy changed) ===' -ForegroundColor Cyan
