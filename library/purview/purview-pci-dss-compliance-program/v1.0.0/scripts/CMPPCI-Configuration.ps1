<#
.SYNOPSIS
    CMPPCI-Configuration.ps1 — create the cardholder-data DLP in SIMULATION and write the action/evidence plan (-WhatIf by default; makes no ENFORCING change).
.DESCRIPTION
    PURPOSE
        Stands up the PCI-DSS Requirement 3 cardholder-data control the safe way: with -Commit it creates
        the DLP policy DLP-PCI-CardholderData in SIMULATION (TestWithNotifications) mode with the rule
        DLP-PCI-CardholderData-Rule matching the built-in "Credit Card Number" sensitive information type
        across the in-scope workloads, and writes the local tracking artifacts PCI Action Plan - Pilot and
        PCI Evidence - Register from an owner-provided action CSV. It NEVER enforces (blocks) — enforcement
        is a separate, gated step in CMPPCI-Set-Scope.ps1 after validation. Defaults to -WhatIf, printing
        exactly what it would create/write.
    HOW TO RUN
        # Dry run (default) — shows the intended DLP policy/rule and plan, changes nothing:
        powershell -ExecutionPolicy Bypass -File .\CMPPCI-Configuration.ps1 -ActionCsv .\pci-actions.csv
        # Apply — creates the DLP policy in SIMULATION and writes the tracking artifacts:
        powershell -ExecutionPolicy Bypass -File .\CMPPCI-Configuration.ps1 -ActionCsv .\pci-actions.csv -Commit

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession) with a role able to create DLP policies
        (e.g. Compliance Administrator). The optional -ActionCsv has columns: Requirement, Action, Owner,
        TargetDate, Status, EvidenceSource. Sensitivity-label authoring and Compliance Manager evidence
        upload are portal actions — this script does not perform them. Verify SIT name and workload
        availability against your tenant.
    EXPECTED RESULTS
        In -WhatIf: a printed plan of the DLP policy/rule (SIMULATION mode) and the parsed action plan;
        nothing created. In -Commit: DLP-PCI-CardholderData exists in TestWithNotifications mode with the
        Credit Card Number rule, and PCI Action Plan - Pilot.csv / PCI Evidence - Register.csv are written
        locally. PASS = the policy is created in a Test* (simulation) mode, never Enable.
.NOTES
    White-label. -WhatIf by default; no enforcing change. Security & Compliance PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [string]   $PolicyName = 'DLP-PCI-CardholderData',
    [string]   $RuleName   = 'DLP-PCI-CardholderData-Rule',
    [string[]] $Workloads  = @('Exchange','SharePoint','OneDriveForBusiness','Teams'),
    [string]   $ActionCsv,
    [string]   $OutputDir  = '.',
    [switch]   $Commit
)

$ErrorActionPreference = 'Stop'
$WhatIf = -not $Commit

function Write-Section([string] $Title) {
    Write-Host ''
    Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan
}

Write-Host ("Mode: {0}" -f ($(if ($WhatIf) { 'DRY-RUN (-WhatIf) — no changes' } else { 'COMMIT — will create DLP in SIMULATION and write artifacts' }))) -ForegroundColor Yellow

try {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession | Out-Null
    }
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    return
}

# ---- 1. Cardholder-data DLP policy in SIMULATION (Req 3) ------------------------------------------
Write-Section 'Cardholder-data DLP policy — SIMULATION mode (PCI-DSS Req 3)'
# TestWithNotifications = simulation: audits and notifies, does NOT block. Enforcement is a later,
# explicit step (CMPPCI-Set-Scope.ps1 -Commit) done only after Testing (05-testing.md) passes.
$simMode = 'TestWithNotifications'

Write-Host ("Policy : {0}" -f $PolicyName)
Write-Host ("Rule   : {0}  (SIT: 'Credit Card Number')" -f $RuleName)
Write-Host ("Mode   : {0}  (SIMULATION — no blocking)" -f $simMode)
Write-Host ("Scope  : {0}" -f ($Workloads -join ', '))

$existing = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $PolicyName })
if ($existing.Count -gt 0) {
    Write-Host ("Policy '{0}' already exists (mode '{1}'). Not recreating; adjust in the portal or with Set-DlpCompliancePolicy." -f $PolicyName, $existing[0].Mode) -ForegroundColor Yellow
}
elseif ($WhatIf) {
    Write-Host 'WHATIF: would run New-DlpCompliancePolicy -Name <PolicyName> -Mode TestWithNotifications with the scoped locations,' -ForegroundColor DarkYellow
    Write-Host '        then New-DlpComplianceRule matching the "Credit Card Number" SIT (report/notify, no block).' -ForegroundColor DarkYellow
}
else {
    try {
        $locParams = @{}
        if ($Workloads -contains 'Exchange')            { $locParams['ExchangeLocation']   = 'All' }
        if ($Workloads -contains 'SharePoint')          { $locParams['SharePointLocation'] = 'All' }
        if ($Workloads -contains 'OneDriveForBusiness') { $locParams['OneDriveLocation']   = 'All' }
        if ($Workloads -contains 'Teams')               { $locParams['TeamsLocation']      = 'All' }

        New-DlpCompliancePolicy -Name $PolicyName -Mode $simMode @locParams -ErrorAction Stop | Out-Null
        Write-Host ("Created policy '{0}' in SIMULATION ({1})." -f $PolicyName, $simMode) -ForegroundColor Green

        $sitConfig = @(@{ Name = 'Credit Card Number'; minCount = 1 })
        New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
            -ContentContainsSensitiveInformation $sitConfig `
            -GenerateIncidentReport SiteAdmin -ErrorAction Stop | Out-Null
        Write-Host ("Created rule '{0}' (Credit Card Number SIT, report/notify only)." -f $RuleName) -ForegroundColor Green
        Write-Host 'Review simulation results in the portal before enforcing (05-testing.md Tests 6-7).' -ForegroundColor Yellow
    }
    catch {
        Write-Error ("DLP creation failed: {0}" -f $_.Exception.Message)
        Write-Host 'Confirm your role can create DLP policies and that the SIT name matches your tenant.'
    }
}

# ---- 2. Action plan / evidence register (Req 12) --------------------------------------------------
Write-Section 'Action plan / evidence register (PCI-DSS Req 12)'
if ($ActionCsv -and (Test-Path $ActionCsv)) {
    try {
        $actions = Import-Csv -Path $ActionCsv
        Write-Host ("Parsed {0} action rows from {1}." -f $actions.Count, $ActionCsv)
        $unassigned = @($actions | Where-Object { -not $_.Owner -or -not $_.EvidenceSource })
        if ($unassigned.Count -gt 0) {
            Write-Host ("WARNING: {0} action(s) missing an Owner or EvidenceSource — complete before validating." -f $unassigned.Count) -ForegroundColor Yellow
        }
        if ($WhatIf) {
            Write-Host 'WHATIF: would write PCI Action Plan - Pilot.csv and PCI Evidence - Register.csv to the output dir.' -ForegroundColor DarkYellow
            $actions | Select-Object -First 5 | Format-Table -AutoSize
        }
        else {
            $planPath = Join-Path $OutputDir 'PCI Action Plan - Pilot.csv'
            $evPath   = Join-Path $OutputDir 'PCI Evidence - Register.csv'
            $actions | Export-Csv -Path $planPath -NoTypeInformation -Encoding UTF8
            $actions | Select-Object Requirement, Action, Owner, EvidenceSource, Status |
                Export-Csv -Path $evPath -NoTypeInformation -Encoding UTF8
            Write-Host ("Wrote '{0}' and '{1}'." -f $planPath, $evPath) -ForegroundColor Green
        }
    }
    catch {
        Write-Error ("Failed to process action CSV: {0}" -f $_.Exception.Message)
    }
}
else {
    Write-Host 'No -ActionCsv provided (or not found). Provide columns: Requirement, Action, Owner, TargetDate, Status, EvidenceSource.'
    Write-Host 'Assignments and evidence upload for Compliance Manager happen in the portal, driven by these artifacts.'
}

Write-Section 'Configuration complete'
Write-Host 'Reminder: the DLP policy is in SIMULATION only. Enforce with CMPPCI-Set-Scope.ps1 AFTER 05-testing.md passes.'
Write-Host 'Sensitivity-label authoring (Label-PCI-CardholderData) and evidence upload are portal actions.'
if ($WhatIf) { Write-Host 'This was a DRY RUN. Re-run with -Commit to apply.' -ForegroundColor Yellow }
