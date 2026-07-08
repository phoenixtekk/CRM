<#
.SYNOPSIS
    DLPOD-Config.ps1 — OneDrive DLP policy config/remediation helper; creates/updates a policy in SIMULATION mode (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates a new DLP compliance policy (and a matching content rule for one or more sensitive
        information types) scoped to the ONEDRIVE location in SIMULATION mode, or updates an existing
        policy's rule. With -ExternalShareOnly the rule additionally requires the content to be shared
        with people OUTSIDE the organization (AccessScope NotInOrganization) — the high-severity
        over-share case. Safe by default: with -WhatIf it only reports the intended change; it applies
        nothing unless -Commit is passed, and it NEVER creates or leaves a policy in enforce (Enable)
        mode — simulation only. Enforcement is a deliberate, separate portal/change-control step.
    HOW TO RUN
        # Preview an at-rest OneDrive simulation policy for the built-in Credit Card SIT:
        powershell -File .\DLPOD-Config.ps1 -PolicyName 'DLP - OneDrive Sensitive - Simulation' `
            -SensitiveTypes 'Credit Card Number' -MinCount 10 -Confidence High -WhatIf
        # Preview the external-share variant (fires when shared outside the org):
        powershell -File .\DLPOD-Config.ps1 -PolicyName 'DLP - OneDrive External Share - Simulation' `
            -SensitiveTypes 'Credit Card Number' -MinCount 1 -Confidence High -ExternalShareOnly -WhatIf
        # Actually create it (still simulation mode):
        powershell -File .\DLPOD-Config.ps1 -PolicyName 'DLP - OneDrive Sensitive - Simulation' `
            -SensitiveTypes 'Credit Card Number' -MinCount 10 -Confidence High -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        -WhatIf: prints the New-DlpCompliancePolicy / New-DlpComplianceRule calls it WOULD run, with
        Mode=TestWithNotifications and OneDriveLocation=All. -Commit: creates the policy in simulation and
        the rule, then prints the resulting Mode (a Test* value = PASS). Verify with DLPOD-Discovery.ps1.
.NOTES
    Purview — OneDrive for Business DLP. Writes gated behind -Commit; simulation-only (never Enable). No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string[]]$SensitiveTypes = @('Credit Card Number'),
    [int]$MinCount = 10,
    [ValidateSet('Low','Medium','High')][string]$Confidence = 'High',
    # When set, the rule also requires the content to be shared OUTSIDE the org (the over-share case).
    [switch]$ExternalShareOnly,
    # Simulation flavour: with or without showing policy tips to users during the test.
    [ValidateSet('TestWithNotifications','TestWithoutNotifications')][string]$SimulationMode = 'TestWithNotifications',
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

# Map confidence name -> minimum confidence level used by the content rule.
$confMap = @{ Low = 65; Medium = 75; High = 85 }
$minConfidence = $confMap[$Confidence]

# OneDrive-only scope (narrow to a pilot ring later with DLPOD-Scope.ps1).
$locParams = @{ OneDriveLocation = 'All' }

# Build the sensitive-information-type condition for the rule.
$sitConditions = foreach ($t in $SensitiveTypes) {
    @{ Name = $t; minCount = $MinCount; minconfidence = $minConfidence }
}

Write-Host ("=== OneDrive DLP policy '{0}' — SIMULATION ({1}) ===" -f $PolicyName, $SimulationMode) -ForegroundColor Cyan
Write-Host  'Location  : OneDrive accounts (All)'
Write-Host ("SITs      : {0} (minCount={1}, minConfidence={2})" -f ($SensitiveTypes -join ', '), $MinCount, $minConfidence)
if ($ExternalShareOnly) { Write-Host 'Condition : + shared with people OUTSIDE the organization (AccessScope=NotInOrganization)' -ForegroundColor DarkCyan }

$existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    if ($existing) {
        Write-Host ("Set-DlpComplianceRule for policy '{0}' (already exists, Mode={1})" -f $PolicyName, $existing.Mode)
    } else {
        Write-Host ("New-DlpCompliancePolicy -Name '{0}' -Mode {1} -OneDriveLocation All" -f $PolicyName, $SimulationMode)
        $ruleLine = ("New-DlpComplianceRule -Name '{0} - Rule' -Policy '{0}' -ContentContainsSensitiveInformation <{1}>" -f $PolicyName, ($SensitiveTypes -join '; '))
        if ($ExternalShareOnly) { $ruleLine += ' -AccessScope NotInOrganization' }
        Write-Host $ruleLine
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
$ruleParams = @{ ContentContainsSensitiveInformation = $sitConditions }
if ($ExternalShareOnly) { $ruleParams['AccessScope'] = 'NotInOrganization' }

if (-not (Get-DlpComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue)) {
    New-DlpComplianceRule -Name $ruleName -Policy $PolicyName @ruleParams -ErrorAction Stop | Out-Null
    Write-Host ("Created rule '{0}'." -f $ruleName) -ForegroundColor Green
} else {
    Set-DlpComplianceRule -Identity $ruleName @ruleParams -ErrorAction Stop
    Write-Host ("Updated rule '{0}'." -f $ruleName) -ForegroundColor Green
}

$after = Get-DlpCompliancePolicy -Identity $PolicyName
if ($after.Mode -like 'Test*') {
    Write-Host ("PASS: '{0}' is in SIMULATION (Mode={1}). Let it dwell, then measure with DLPOD-Report.ps1." -f $PolicyName, $after.Mode) -ForegroundColor Green
} else {
    Write-Host ("WARNING: unexpected Mode '{0}' — verify in the portal." -f $after.Mode) -ForegroundColor Yellow
}
