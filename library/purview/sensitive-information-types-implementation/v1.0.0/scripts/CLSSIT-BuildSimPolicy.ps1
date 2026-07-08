<#
.SYNOPSIS
    CLSSIT-BuildSimPolicy.ps1 — builds a DLP measurement policy referencing the selected SIT(s) in SIMULATION mode (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates a DLP compliance policy (and a matching content rule) that references your selected
        built-in sensitive information type(s) at a chosen confidence level and instance count, in
        SIMULATION mode, so you can MEASURE how the SIT behaves against real production content with zero
        user impact. This is measurement scaffolding, not enforcement. Safe by default: with -WhatIf it
        only reports the intended change; it applies nothing unless -Commit is passed, and it NEVER
        creates or leaves a policy in enforce (Enable) mode — simulation only.
    HOW TO RUN
        # Preview a simulation measurement policy for the built-in Credit Card SIT:
        powershell -File .\CLSSIT-BuildSimPolicy.ps1 -PolicyName 'SIT Measure - Payment Card - Simulation' `
            -SensitiveTypes 'Credit Card Number' -MinCount 10 -Confidence High -WhatIf
        # Actually create it (still simulation mode):
        powershell -File .\CLSSIT-BuildSimPolicy.ps1 -PolicyName 'SIT Measure - Payment Card - Simulation' `
            -SensitiveTypes 'Credit Card Number' -MinCount 10 -Confidence High -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        -WhatIf: prints the New-DlpCompliancePolicy / New-DlpComplianceRule calls it WOULD run, Mode=Test*.
        -Commit: creates the policy in simulation + the rule, then prints the resulting Mode (a Test* value
        = PASS). Let it dwell, then measure with CLSSIT-Report.ps1. Verify with CLSSIT-Discovery.ps1.
.NOTES
    Purview — Sensitive Information Types Implementation. Writes gated behind -Commit; simulation-only (never Enable). No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string[]]$SensitiveTypes = @('Credit Card Number'),
    [int]$MinCount = 10,
    [ValidateSet('Low','Medium','High')][string]$Confidence = 'High',
    # Simulation flavour: with or without showing policy tips to users during the test.
    [ValidateSet('TestWithNotifications','TestWithoutNotifications')][string]$SimulationMode = 'TestWithoutNotifications',
    # Locations to measure across. Broad by default so the sample is representative.
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams')]
    [string[]]$Locations = @('Exchange','SharePoint','OneDrive','Teams'),
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# Map confidence name -> minimum confidence level used by the content rule (Low/Med/High ~= 65/75/85).
$confMap = @{ Low = 65; Medium = 75; High = 85 }
$minConfidence = $confMap[$Confidence]

# Build the location parameter splat (scoped to "All"; narrow with CLSSIT-Set-Scope.ps1).
$locParams = @{}
foreach ($l in $Locations) {
    switch ($l) {
        'Exchange'   { $locParams['ExchangeLocation']   = 'All' }
        'SharePoint' { $locParams['SharePointLocation'] = 'All' }
        'OneDrive'   { $locParams['OneDriveLocation']   = 'All' }
        'Teams'      { $locParams['TeamsLocation']      = 'All' }
    }
}

# Build the sensitive-information-type condition for the rule.
$sitConditions = foreach ($t in $SensitiveTypes) {
    @{ Name = $t; minCount = $MinCount; minconfidence = $minConfidence }
}

Write-Host ("=== SIT measurement policy '{0}' — SIMULATION ({1}) ===" -f $PolicyName, $SimulationMode) -ForegroundColor Cyan
Write-Host ("Locations : {0}" -f ($Locations -join ', '))
Write-Host ("SITs      : {0} (minCount={1}, minConfidence={2}/{3})" -f ($SensitiveTypes -join ', '), $MinCount, $minConfidence, $Confidence)

$existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    if ($existing) {
        Write-Host ("Set-DlpComplianceRule for policy '{0}' (already exists, Mode={1})" -f $PolicyName, $existing.Mode)
    } else {
        Write-Host ("New-DlpCompliancePolicy -Name '{0}' -Mode {1} {2}" -f $PolicyName, $SimulationMode, (($locParams.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join ' '))
        Write-Host ("New-DlpComplianceRule -Name '{0} - Rule' -Policy '{0}' -ContentContainsSensitiveInformation <{1}> (minCount={2}, minConfidence={3})" -f $PolicyName, ($SensitiveTypes -join '; '), $MinCount, $minConfidence)
    }
    Write-Host 'Re-run with -Commit to apply (policy will be created in SIMULATION, never enforce).' -ForegroundColor Yellow
    return
}

# --- Commit path (simulation only) ---
if (-not $existing) {
    New-DlpCompliancePolicy -Name $PolicyName -Mode $SimulationMode @locParams -ErrorAction Stop | Out-Null
    Write-Host ("Created policy '{0}' in {1}." -f $PolicyName, $SimulationMode) -ForegroundColor Green
} else {
    if ($existing.Mode -eq 'Enable') {
        Write-Host ("SAFETY: policy '{0}' is currently ENFORCING; this helper will not modify an enforcing policy. Adjust in the portal under change control." -f $PolicyName) -ForegroundColor Red
        return
    }
    Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimulationMode @locParams -ErrorAction Stop
    Write-Host ("Updated policy '{0}' (kept in {1})." -f $PolicyName, $SimulationMode) -ForegroundColor Green
}

$ruleName = "$PolicyName - Rule"
if (-not (Get-DlpComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue)) {
    New-DlpComplianceRule -Name $ruleName -Policy $PolicyName `
        -ContentContainsSensitiveInformation $sitConditions -ErrorAction Stop | Out-Null
    Write-Host ("Created rule '{0}'." -f $ruleName) -ForegroundColor Green
} else {
    Set-DlpComplianceRule -Identity $ruleName -ContentContainsSensitiveInformation $sitConditions -ErrorAction Stop
    Write-Host ("Updated rule '{0}'." -f $ruleName) -ForegroundColor Green
}

$after = Get-DlpCompliancePolicy -Identity $PolicyName
if ($after.Mode -like 'Test*') {
    Write-Host ("PASS: '{0}' is in SIMULATION (Mode={1}). Let it dwell, then measure with CLSSIT-Report.ps1." -f $PolicyName, $after.Mode) -ForegroundColor Green
} else {
    Write-Host ("WARNING: unexpected Mode '{0}' — verify in the portal." -f $after.Mode) -ForegroundColor Yellow
}
