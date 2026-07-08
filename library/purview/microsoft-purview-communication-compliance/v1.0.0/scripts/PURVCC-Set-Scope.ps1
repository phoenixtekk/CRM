<#
.SYNOPSIS
    PURVCC-Set-Scope.ps1 — scope/config helper to adjust a Communication Compliance policy's supervised users, reviewers, and conditions (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Adjusts an existing Communication Compliance policy/rule during tuning or expansion: change
        the supervised (in-scope) population, the excluded/privacy group, the reviewers, the
        classifiers/conditions, or the sampling percentage. Safe by default: with no switch it runs
        -WhatIf and only DESCRIBES the change; supply -Commit to apply, after HR/legal sign-off.
        Use it to tighten scope (privacy), tune noise, or promote a tuned pilot toward broad scope.
    HOW TO RUN
        # Dry-run (default) — narrow the scope and lower sampling during tuning:
        powershell -ExecutionPolicy Bypass -File .\PURVCC-Set-Scope.ps1 `
            -PolicyName 'Comms Policy - Pilot - Simulation' `
            -SupervisedGroup 'Comms In-Scope - Pilot' -ExcludedGroup 'Comms Excluded - Privacy' `
            -SamplingPercentage 50
        # Apply (after sign-off):
        ... same parameters ... -Commit
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession.
    EXPECTED RESULTS
        Dry-run prints the current vs proposed scope/reviewers/conditions. With -Commit, the policy
        and rule are updated. Verify with PURVCC-Report.ps1.
.NOTES
    Purview — Microsoft Purview Communication Compliance. -WhatIf by default; -Commit required. No
    credentials stored. Keep scope minimized and pilot-first; outcomes deferred to HR/legal.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$SupervisedGroup,
    [string]$ExcludedGroup,
    [string[]]$Reviewers,
    [string[]]$Classifiers,
    [Nullable[int]]$SamplingPercentage,
    [switch]$Commit
)

$whatIf = -not $Commit
$mode = if ($whatIf) { 'WHATIF (dry-run)' } else { 'COMMIT' }
Write-Host ("=== PURVCC-Set-Scope : {0} ===" -f $mode) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

# --- Load current policy + rule ---
$policy = Get-SupervisoryReviewPolicyV2 -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $policy) { Write-Error "Policy '$PolicyName' not found. Create it first with PURVCC-Configuration.ps1."; return }
$rule = Get-SupervisoryReviewRule -Policy $PolicyName -ErrorAction SilentlyContinue | Select-Object -First 1

Write-Host 'Current:' -ForegroundColor DarkGray
Write-Host ("    Reviewers  : {0}" -f (@($policy.Reviewers) -join ', '))
if ($rule) {
    Write-Host ("    Supervised : {0}" -f (@($rule.SupervisedGroups) -join ', '))
    Write-Host ("    Excluded   : {0}" -f ((@($rule.ExcludedGroups) -join ', ') -replace '^$','(none)'))
    Write-Host ("    Classifiers: {0}" -f ((@($rule.Classifiers) -join ', ') -replace '^$','(none)'))
    Write-Host ("    Sampling   : {0}" -f $rule.SamplingRate)
}

# --- Build the proposed change sets ---
$policyChanges = @{}
if ($PSBoundParameters.ContainsKey('Reviewers')) { $policyChanges['Reviewers'] = $Reviewers }

$ruleChanges = @{}
if ($PSBoundParameters.ContainsKey('SupervisedGroup'))   { $ruleChanges['SupervisedGroups'] = $SupervisedGroup }
if ($PSBoundParameters.ContainsKey('ExcludedGroup'))     { $ruleChanges['ExcludedGroups']   = $ExcludedGroup }
if ($PSBoundParameters.ContainsKey('Classifiers'))       { $ruleChanges['Classifiers']      = $Classifiers }
if ($PSBoundParameters.ContainsKey('SamplingPercentage') -and $null -ne $SamplingPercentage) { $ruleChanges['SamplingRate'] = $SamplingPercentage }

if ($policyChanges.Count -eq 0 -and $ruleChanges.Count -eq 0) {
    Write-Host "`nNo changes specified. Provide at least one of -SupervisedGroup / -ExcludedGroup / -Reviewers / -Classifiers / -SamplingPercentage." -ForegroundColor Yellow
    return
}

Write-Host "`nProposed:" -ForegroundColor Yellow
$policyChanges.GetEnumerator() | ForEach-Object { Write-Host ("    policy.{0} -> {1}" -f $_.Key, (@($_.Value) -join ', ')) }
$ruleChanges.GetEnumerator()   | ForEach-Object { Write-Host ("    rule.{0} -> {1}"   -f $_.Key, (@($_.Value) -join ', ')) }

if ($whatIf) {
    Write-Host "`nPLANNED ACTIONS (nothing is being changed):" -ForegroundColor Yellow
    if ($policyChanges.Count) { Write-Host ("  Set-SupervisoryReviewPolicyV2 -Identity '{0}' {1}" -f $PolicyName, (($policyChanges.Keys | ForEach-Object { "-$_ ..." }) -join ' ')) }
    if ($ruleChanges.Count -and $rule) { Write-Host ("  Set-SupervisoryReviewRule -Identity '{0}' {1}" -f $rule.Name, (($ruleChanges.Keys | ForEach-Object { "-$_ ..." }) -join ' ')) }
    Write-Host "`nRe-run with -Commit (after HR/legal sign-off) to apply. Re-validate with the Testing Guide after any change." -ForegroundColor Yellow
    return
}

# --- COMMIT ---
try {
    if ($policyChanges.Count) {
        Set-SupervisoryReviewPolicyV2 -Identity $PolicyName @policyChanges -ErrorAction Stop
        Write-Host '  Policy updated.' -ForegroundColor Green
    }
    if ($ruleChanges.Count) {
        if (-not $rule) { Write-Warning '  No rule found to update.'; }
        else { Set-SupervisoryReviewRule -Identity $rule.Name @ruleChanges -ErrorAction Stop; Write-Host '  Rule updated.' -ForegroundColor Green }
    }
    Write-Host 'Scope/config change applied. Re-validate with the Testing Guide before expanding.' -ForegroundColor Cyan
} catch {
    Write-Error "Commit failed: $($_.Exception.Message)."
}
