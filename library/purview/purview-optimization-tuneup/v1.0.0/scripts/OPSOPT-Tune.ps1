<#
.SYNOPSIS
    OPSOPT-Tune.ps1 — SAFE tuning of DLP / auto-label / alert policies. Moves to simulation, adjusts thresholds/exceptions, re-enforces, or rolls back. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Applies the designed tuning to REDUCE false positives, always landing a policy in simulation/test
        before enforcing. Supports: -ToSimulation (Set-DlpCompliancePolicy/-AutoSensitivityLabelPolicy
        -Mode Test...), DLP rule tuning (-MinConfidence / -MinCount / -ExceptIfFrom via
        Set-DlpComplianceRule), alert tuning (-Threshold / -Aggregation via Set-ProtectionAlert),
        -Enforce (Mode Enable), and -Rollback. SAFE BY DEFAULT: runs in -WhatIf unless -Commit is given,
        and records the prior value of every setting to rollback-<policy>.json before changing it.
    HOW TO RUN
        PowerShell 5.1+/7+. Connect first: Connect-IPPSSession
        Move a DLP policy to simulation (dry-run, then commit):
          .\OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -ToSimulation -WhatIf
          .\OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -ToSimulation -Commit
        Tune a rule (raise confidence + instance count) and add a justified exception:
          .\OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -Rule "PII - High Volume" -MinConfidence High -MinCount 10 `
             -ExceptIfFrom "finance-ap@contoso.com" -Justification "AP mailbox handles supplier card refs (owner: Finance Controller)" -Commit
        Tune an alert policy / re-enforce / roll back:
          .\OPSOPT-Tune.ps1 -AlertPolicy "Elevated DLP activity" -Threshold 25 -Aggregation SimpleAggregation -Commit
          .\OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -Enforce -Commit
          .\OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -Rollback -Commit
    EXPECTED RESULTS
        -WhatIf: one line per intended change; nothing changes. -Commit: the change is applied after the
        prior value is saved to .\OPSOPT-out\rollback-<policy>.json. -Enforce is a separate, deliberate step.
.NOTES
    Purview — Optimization & Tune-Up. Default mode makes NO changes. Insider-risk policy tuning is
    portal-driven and NOT handled here (see Implementation Step 9). No credentials in code.
#>
[CmdletBinding()]
param(
    [string]$Policy,                 # DLP policy name
    [string]$Rule,                   # DLP rule name (within -Policy)
    [string]$AutoLabelPolicy,        # auto-labeling policy name
    [string]$AlertPolicy,            # alert policy name (Get/Set-ProtectionAlert)

    [switch]$ToSimulation,           # move policy to TestWithoutNotifications
    [switch]$Enforce,                # move policy to Enable (separate, approved step)
    [switch]$Rollback,               # revert to recorded prior values

    [ValidateSet('Low','Medium','High')][string]$MinConfidence,
    [int]$MinCount,
    [string]$ExceptIfFrom,           # add an ExceptIf sender exception (justified)
    [string]$Justification,

    [int]$Threshold,                 # alert policy threshold
    [ValidateSet('None','SimpleAggregation','AnomalousAggregation')][string]$Aggregation,

    [string]$OutputFolder = '.\OPSOPT-out',
    [switch]$Commit                  # absent = -WhatIf (default, no changes)
)

$WhatIf = -not $Commit
$mode = if ($WhatIf) { 'WHATIF (no changes)' } else { 'COMMIT (applying changes)' }
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
Write-Host ("=== OPSOPT Tune [{0}] ===" -f $mode) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

function Save-Rollback([string]$name, [hashtable]$priorValues) {
    $safe = ($name -replace '[^A-Za-z0-9_-]', '_')
    $path = Join-Path $OutputFolder ("rollback-{0}.json" -f $safe)
    # Do NOT overwrite an existing baseline — the first-captured prior value is the true rollback point.
    if (-not (Test-Path $path)) {
        $priorValues | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8
        Write-Host ("  prior values saved -> {0}" -f $path) -ForegroundColor DarkGray
    } else {
        Write-Host ("  rollback baseline already exists -> {0} (kept)" -f $path) -ForegroundColor DarkGray
    }
}
function Get-Rollback([string]$name) {
    $safe = ($name -replace '[^A-Za-z0-9_-]', '_')
    $path = Join-Path $OutputFolder ("rollback-{0}.json" -f $safe)
    if (Test-Path $path) { return (Get-Content $path -Raw | ConvertFrom-Json) }
    return $null
}

# ---------------- DLP policy mode changes ----------------
if ($Policy -and ($ToSimulation -or $Enforce -or $Rollback) -and -not $Rule) {
    $cur = Get-DlpCompliancePolicy -Identity $Policy -ErrorAction Stop
    if ($Rollback) {
        $rb = Get-Rollback $Policy
        if (-not $rb -or -not $rb.Mode) { throw "No rollback baseline (Mode) for '$Policy'." }
        Write-Host ("ROLLBACK DLP '{0}' Mode: {1} -> {2}" -f $Policy, $cur.Mode, $rb.Mode) -ForegroundColor Magenta
        if (-not $WhatIf) { Set-DlpCompliancePolicy -Identity $Policy -Mode $rb.Mode }
    } else {
        $target = if ($Enforce) { 'Enable' } else { 'TestWithoutNotifications' }
        Save-Rollback $Policy @{ Mode = "$($cur.Mode)" }
        Write-Host ("DLP '{0}' Mode: {1} -> {2}" -f $Policy, $cur.Mode, $target) -ForegroundColor $(if ($Enforce) { 'Red' } else { 'Yellow' })
        if (-not $WhatIf) { Set-DlpCompliancePolicy -Identity $Policy -Mode $target }
    }
}

# ---------------- DLP rule tuning (confidence / count / exception) ----------------
if ($Policy -and $Rule -and ($MinConfidence -or $MinCount -or $ExceptIfFrom -or $Rollback)) {
    $r = Get-DlpComplianceRule -Identity $Rule -ErrorAction Stop
    if ($Rollback) {
        $rb = Get-Rollback ("$Policy--$Rule")
        if (-not $rb) { throw "No rollback baseline for rule '$Rule'." }
        Write-Host ("ROLLBACK rule '{0}' to recorded ContentContainsSensitiveInformation" -f $Rule) -ForegroundColor Magenta
        if (-not $WhatIf -and $rb.ContentContainsSensitiveInformation) {
            $prior = $rb.ContentContainsSensitiveInformation | ForEach-Object {
                @{ Name = $_.name; minconfidence = $_.minconfidence; mincount = $_.mincount; maxcount = $_.maxcount }
            }
            Set-DlpComplianceRule -Identity $Rule -ContentContainsSensitiveInformation @($prior)
        }
    } else {
        if (-not $ExceptIfFrom -or $Justification) { } # justification is required alongside an exception
        if ($ExceptIfFrom -and -not $Justification) { throw "An -ExceptIfFrom exception requires -Justification (Requirement 2.8)." }

        # Capture prior SIT settings for rollback.
        $priorSit = @()
        foreach ($s in @($r.ContentContainsSensitiveInformation)) {
            $priorSit += @{ name = $s.name; minconfidence = $s.minconfidence; mincount = $s.mincount; maxcount = $s.maxcount }
        }
        Save-Rollback ("$Policy--$Rule") @{ ContentContainsSensitiveInformation = $priorSit; ExceptIfFrom = @($r.ExceptIfFrom) }

        # Build the tuned SIT array.
        $newSit = foreach ($s in @($r.ContentContainsSensitiveInformation)) {
            $h = @{ name = $s.name }
            $h.minconfidence = if ($MinConfidence) { $MinConfidence } elseif ($s.minconfidence) { $s.minconfidence } else { 'High' }
            $h.mincount      = if ($MinCount)      { $MinCount }      elseif ($s.mincount)      { $s.mincount }      else { 1 }
            if ($s.maxcount) { $h.maxcount = $s.maxcount }
            $h
        }
        Write-Host ("TUNE rule '{0}': confidence>= {1}, mincount>= {2}" -f $Rule, ($MinConfidence -or '<unchanged>'), ($MinCount -or '<unchanged>')) -ForegroundColor Yellow
        if ($ExceptIfFrom) { Write-Host ("  + ExceptIf From '{0}' — {1}" -f $ExceptIfFrom, $Justification) -ForegroundColor Yellow }
        if (-not $WhatIf) {
            if ($newSit) { Set-DlpComplianceRule -Identity $Rule -ContentContainsSensitiveInformation @($newSit) }
            if ($ExceptIfFrom) {
                Set-DlpComplianceRule -Identity $Rule -ExceptIfFrom $ExceptIfFrom
                # Persist the justification alongside the evidence.
                ("{0}`t{1}`t{2}`t{3}" -f (Get-Date -Format o), $Rule, $ExceptIfFrom, $Justification) |
                    Add-Content -Path (Join-Path $OutputFolder 'exception-justifications.tsv')
            }
        }
    }
}

# ---------------- Auto-labeling policy mode ----------------
if ($AutoLabelPolicy -and ($ToSimulation -or $Enforce -or $Rollback)) {
    $a = Get-AutoSensitivityLabelPolicy -Identity $AutoLabelPolicy -ErrorAction Stop
    if ($Rollback) {
        $rb = Get-Rollback $AutoLabelPolicy
        if ($rb -and $rb.Mode -and -not $WhatIf) { Set-AutoSensitivityLabelPolicy -Identity $AutoLabelPolicy -Mode $rb.Mode }
        Write-Host ("ROLLBACK auto-label '{0}' Mode" -f $AutoLabelPolicy) -ForegroundColor Magenta
    } else {
        $target = if ($Enforce) { 'Enable' } else { 'TestWithoutNotifications' }
        Save-Rollback $AutoLabelPolicy @{ Mode = "$($a.Mode)" }
        Write-Host ("Auto-label '{0}' Mode: {1} -> {2}" -f $AutoLabelPolicy, $a.Mode, $target) -ForegroundColor $(if ($Enforce) { 'Red' } else { 'Yellow' })
        if (-not $WhatIf) { Set-AutoSensitivityLabelPolicy -Identity $AutoLabelPolicy -Mode $target }
    }
}

# ---------------- Alert policy threshold / aggregation ----------------
if ($AlertPolicy -and ($Threshold -or $Aggregation -or $Rollback)) {
    $al = Get-ProtectionAlert -Identity $AlertPolicy -ErrorAction Stop
    if ($Rollback) {
        $rb = Get-Rollback $AlertPolicy
        if ($rb -and -not $WhatIf) {
            if ($rb.Threshold)       { Set-ProtectionAlert -Identity $AlertPolicy -Threshold ([int]$rb.Threshold) }
            if ($rb.AggregationType) { Set-ProtectionAlert -Identity $AlertPolicy -AggregationType $rb.AggregationType }
        }
        Write-Host ("ROLLBACK alert '{0}' threshold/aggregation" -f $AlertPolicy) -ForegroundColor Magenta
    } else {
        Save-Rollback $AlertPolicy @{ Threshold = "$($al.Threshold)"; AggregationType = "$($al.AggregationType)" }
        Write-Host ("Alert '{0}': threshold {1} -> {2}, aggregation {3} -> {4}" -f `
            $AlertPolicy, $al.Threshold, ($Threshold -or '<unchanged>'), $al.AggregationType, ($Aggregation -or '<unchanged>')) -ForegroundColor Yellow
        if (-not $WhatIf) {
            if ($Threshold)   { Set-ProtectionAlert -Identity $AlertPolicy -Threshold $Threshold }
            if ($Aggregation) { Set-ProtectionAlert -Identity $AlertPolicy -AggregationType $Aggregation }
        }
    }
}

Write-Host ("=== Tune complete [{0}] ===" -f $mode) -ForegroundColor Cyan
if ($WhatIf) { Write-Host "Re-run with -Commit to apply. Nothing was changed." -ForegroundColor Yellow }
