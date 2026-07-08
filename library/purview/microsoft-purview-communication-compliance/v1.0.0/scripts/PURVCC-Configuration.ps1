<#
.SYNOPSIS
    PURVCC-Configuration.ps1 — policy + classifier/condition config helper for a PILOT Communication Compliance policy (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Composes a pilot Communication Compliance policy and rule (SupervisoryReview policy/rule)
        scoped to the approved pilot population, with the chosen reviewers, trainable classifiers,
        sensitive information types / keywords, and a sampling percentage. Safe by default: with no
        switch it runs -WhatIf and only DESCRIBES what it would create. Supply -Commit to apply —
        only after HR/legal sign-off. Build narrow and treat the first run as simulation/test.
    HOW TO RUN
        # Dry-run (default) — shows the planned policy/rule without changing anything:
        powershell -ExecutionPolicy Bypass -File .\PURVCC-Configuration.ps1 `
            -PolicyName 'Comms Policy - Pilot - Simulation' `
            -SupervisedGroup 'Comms In-Scope - Pilot' -ExcludedGroup 'Comms Excluded - Privacy' `
            -Reviewers 'analyst1@contoso.com','analyst2@contoso.com' `
            -Classifiers 'Threat','Harassment','Discrimination','Profanity' -SamplingPercentage 100
        # Apply (after sign-off):
        ... same parameters ... -Commit
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession.
    EXPECTED RESULTS
        Dry-run prints the exact New-SupervisoryReviewPolicyV2 / New-SupervisoryReviewRule it would
        run. With -Commit, the pilot policy and rule are created and echoed back. Verify with
        PURVCC-Report.ps1.
.NOTES
    Purview — Microsoft Purview Communication Compliance. -WhatIf by default; -Commit required to
    change the tenant. No credentials stored. Classifier availability is plan/tenant-dependent —
    verify each classifier exists in your tenant (Data classification -> Classifiers). Outcomes are
    deferred to HR/legal.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName = 'Comms Policy - Pilot - Simulation',
    [Parameter(Mandatory)][string]$SupervisedGroup,          # e.g. 'Comms In-Scope - Pilot'
    [string]$ExcludedGroup = 'Comms Excluded - Privacy',
    [Parameter(Mandatory)][string[]]$Reviewers,              # UPNs from the Analysts role group
    [string[]]$Classifiers = @('Threat','Harassment','Discrimination','Profanity'),
    [string[]]$SensitiveInfoTypes = @(),                     # e.g. 'Credit Card Number'
    [int]$SamplingPercentage = 100,
    [switch]$Commit
)

$whatIf = -not $Commit
$mode = if ($whatIf) { 'WHATIF (dry-run)' } else { 'COMMIT' }
Write-Host ("=== PURVCC-Configuration : {0} ===" -f $mode) -ForegroundColor Cyan
Write-Host ("Policy           : {0}" -f $PolicyName)
Write-Host ("Supervised group : {0}" -f $SupervisedGroup)
Write-Host ("Excluded group   : {0}" -f $ExcludedGroup)
Write-Host ("Reviewers        : {0}" -f ($Reviewers -join ', '))
Write-Host ("Classifiers      : {0}" -f ($Classifiers -join ', '))
Write-Host ("Sensitive types  : {0}" -f (($SensitiveInfoTypes -join ', ') -replace '^$','(none)'))
Write-Host ("Sampling %       : {0}" -f $SamplingPercentage)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

# --- Guard: policy must not already exist ---
$existing = Get-SupervisoryReviewPolicyV2 -Identity $PolicyName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Warning "Policy '$PolicyName' already exists. Use PURVCC-Set-Scope.ps1 to adjust it, or choose a new name."
    return
}

Write-Host ''
if ($whatIf) {
    Write-Host 'PLANNED ACTIONS (nothing is being changed):' -ForegroundColor Yellow
    Write-Host ("  New-SupervisoryReviewPolicyV2 -Name '{0}' -Reviewers {1}" -f `
        $PolicyName, ($Reviewers | ForEach-Object { "'$_'" }) -join ',')
    Write-Host ("  New-SupervisoryReviewRule -Name '{0}-rule' -Policy '{0}' \\" -f $PolicyName)
    Write-Host ("      -SupervisedGroups '{0}' -ExcludedGroups '{1}' \\" -f $SupervisedGroup, $ExcludedGroup)
    Write-Host ("      -Classifiers @({0}) -SamplingRate {1}" -f (($Classifiers | ForEach-Object { "'$_'" }) -join ','), $SamplingPercentage)
    if ($SensitiveInfoTypes.Count -gt 0) {
        Write-Host ("      -ContentContainsSensitiveInformation @({0})" -f (($SensitiveInfoTypes | ForEach-Object { "'$_'" }) -join ','))
    }
    Write-Host ''
    Write-Host 'Re-run with -Commit (after HR/legal sign-off) to create the pilot policy in simulation.' -ForegroundColor Yellow
    return
}

# --- COMMIT ---
try {
    Write-Host 'Creating pilot policy...' -ForegroundColor Green
    $policy = New-SupervisoryReviewPolicyV2 -Name $PolicyName -Reviewers $Reviewers -ErrorAction Stop
    Write-Host ("  Created policy: {0}" -f $policy.Name) -ForegroundColor Green

    $ruleParams = @{
        Name             = "$PolicyName-rule"
        Policy           = $PolicyName
        SupervisedGroups = $SupervisedGroup
        SamplingRate     = $SamplingPercentage
        ErrorAction      = 'Stop'
    }
    if ($ExcludedGroup)          { $ruleParams['ExcludedGroups'] = $ExcludedGroup }
    if ($Classifiers.Count)      { $ruleParams['Classifiers']    = $Classifiers }
    if ($SensitiveInfoTypes.Count) { $ruleParams['ContentContainsSensitiveInformation'] = $SensitiveInfoTypes }

    $rule = New-SupervisoryReviewRule @ruleParams
    Write-Host ("  Created rule: {0}" -f $rule.Name) -ForegroundColor Green
    Write-Host 'Pilot policy created. Validate detection + reviewer workflow with the Testing Guide before expanding.' -ForegroundColor Cyan
} catch {
    Write-Error "Commit failed: $($_.Exception.Message). Confirm classifier/SIT names exist in your tenant and your role permits policy creation."
}
