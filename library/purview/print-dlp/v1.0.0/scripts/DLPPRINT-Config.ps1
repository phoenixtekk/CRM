<#
.SYNOPSIS
    DLPPRINT-Config.ps1 — create/preview the Devices-only Print DLP policy + rule in SIMULATION, or set pilot-ring scope (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Builds the Endpoint DLP Print restriction this solution relies on: a DLP policy scoped to the
        Devices location (all other locations off), in SIMULATION mode, with a rule that triggers on the
        chosen sensitive-information type(s) and sets the Print endpoint restriction to Audit. With
        -SetScope it sets the pilot-ring include scope on an existing policy. SAFE BY DEFAULT: previews
        with -WhatIf; only writes with -Commit; and it NEVER leaves a policy in enforce (mode stays a
        Test* simulation mode). Idempotent by name.
    HOW TO RUN
        Preview (default):   powershell -ExecutionPolicy Bypass -File .\DLPPRINT-Config.ps1 -PolicyName 'DLP - Endpoint Print - Simulation' -SensitiveTypes 'Credit Card Number' -WhatIf
        Create in sim:       ... -SensitiveTypes 'Credit Card Number' -MinCount 1 -Confidence High -Commit
        Set pilot scope:     ... -SetScope -IncludeGroup 'DLP Pilot Ring - Stage1' -Commit
        Requires ExchangeOnlineManagement + a Compliance/DLP admin (Connect-IPPSSession).
    EXPECTED RESULTS
        With -WhatIf: prints the New-DlpCompliancePolicy / New-DlpComplianceRule (or Set-*) it WOULD run.
        With -Commit: the simulation policy + Print rule exist (created if missing), or the include scope
        is set. Printer-group differentiation and exact restriction names evolve — build the rule once in
        the portal and confirm names with DLPPRINT-Discovery.ps1 before relying on -Commit. The enforced
        action per data category is a compliance/legal determination, deferred.
.NOTES
    Purview category — Print DLP (Endpoint DLP). Default -WhatIf; simulation-only (never enforce). No secrets.
    Verify current Endpoint DLP restriction syntax / printer-group config against Microsoft guidance before -Commit.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$PolicyName        = 'DLP - Endpoint Print - Simulation',
    [string]$RuleName          = 'DLP - Endpoint Print - Rule',
    [string[]]$SensitiveTypes  = @('Credit Card Number'),
    [int]$MinCount             = 1,
    [ValidateSet('Low','Medium','High')]
    [string]$Confidence        = 'High',
    [switch]$SetScope,
    [string]$IncludeGroup,
    [switch]$Commit
)

# Safe by default: -WhatIf unless -Commit is passed.
$WhatIfPreference = -not $Commit

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Connecting to Security & Compliance PowerShell..." -ForegroundColor Cyan
    Connect-IPPSSession -ErrorAction Stop | Out-Null
}
if (-not $Commit) { Write-Host "(preview mode — re-run with -Commit to make changes)" -ForegroundColor Yellow }

# Map confidence label to min confidence value used by ContentContainsSensitiveInformation
$minConf = switch ($Confidence) { 'Low' { 65 } 'Medium' { 75 } 'High' { 85 } }

$existingPolicy = $null
try { $existingPolicy = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue } catch {}

# ---------- Mode A: set pilot-ring scope on an existing policy ----------
if ($SetScope) {
    if (-not $IncludeGroup) { throw "Provide -IncludeGroup (e.g. 'DLP Pilot Ring - Stage1') with -SetScope." }
    if (-not $existingPolicy) { throw "Policy '$PolicyName' not found — create it first (run without -SetScope)." }
    Write-Host ("`n-- Set include scope on '{0}' -> group '{1}' --" -f $PolicyName, $IncludeGroup) -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess($PolicyName, "Set EndpointDlpLocation include to '$IncludeGroup'")) {
        Set-DlpCompliancePolicy -Identity $PolicyName -AddEndpointDlpLocation $IncludeGroup -ErrorAction Stop
        Write-Host "  scope updated." -ForegroundColor Green
    }
    return
}

# ---------- Mode B: create the simulation policy + Print rule ----------
Write-Host "`n-- Policy (Devices-only, SIMULATION) --" -ForegroundColor Cyan
if ($existingPolicy) {
    $mode = "$($existingPolicy.Mode)"
    Write-Host ("  OK   : policy '{0}' already exists (mode {1})." -f $PolicyName, $mode) -ForegroundColor Green
    if ($mode -notlike 'Test*') {
        Write-Host ("  NOTE : policy is not in a simulation mode ({0}). This helper will NOT enforce; change mode deliberately in the portal per Phase 4." -f $mode) -ForegroundColor Yellow
    }
} elseif ($PSCmdlet.ShouldProcess($PolicyName, "Create Devices-only DLP policy in simulation (TestWithoutNotifications)")) {
    New-DlpCompliancePolicy -Name $PolicyName `
        -Comment 'Print DLP — endpoint print restriction (simulation-first).' `
        -EndpointDlpLocation 'All' `
        -Mode 'TestWithoutNotifications' -ErrorAction Stop | Out-Null
    Write-Host ("  created policy '{0}' in SIMULATION (TestWithoutNotifications)." -f $PolicyName) -ForegroundColor Green
}

Write-Host "`n-- Rule (Print restriction = Audit) --" -ForegroundColor Cyan
$existingRule = $null
try { $existingRule = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue } catch {}

# Build the sensitive-information condition
$sitCondition = @()
foreach ($t in $SensitiveTypes) {
    $sitCondition += @{ Name = $t; minCount = $MinCount; confidencelevel = $Confidence }
}
# Endpoint Print restriction (Audit). Printer-group differentiation is configured in the portal;
# confirm exact restriction names with DLPPRINT-Discovery.ps1 before relying on -Commit.
$printRestriction = @( @{ Setting = 'Print'; Value = 'Audit' } )

if ($existingRule) {
    Write-Host ("  OK   : rule '{0}' already exists — review it with DLPPRINT-Validation.ps1." -f $RuleName) -ForegroundColor Green
} elseif ($PSCmdlet.ShouldProcess($RuleName, "Create Print-restriction rule (Audit) on '$PolicyName'")) {
    New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
        -ContentContainsSensitiveInformation $sitCondition `
        -EndpointDlpRestrictions $printRestriction `
        -ErrorAction Stop | Out-Null
    Write-Host ("  created rule '{0}' (SITs: {1}; Print=Audit)." -f $RuleName, ($SensitiveTypes -join ', ')) -ForegroundColor Green
}

Write-Host "`nNext: let it run in simulation for the agreed dwell time, then DLPPRINT-Report.ps1 to measure false positives (Phase 3)." -ForegroundColor Cyan
