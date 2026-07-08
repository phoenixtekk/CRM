<#
.SYNOPSIS
    PURVAP-Set-DlpPolicy.ps1 — plan (and optionally scaffold, in SIMULATION) the adaptive-protection DLP policy (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Validates prerequisites and prints the exact intended plan for the DLP-Adaptive-Protection
        policy and its three risk-level rules (AP-Elevated-Block / AP-Moderate-WarnOverride /
        AP-Minor-Audit), then — only with -Commit — SCAFFOLDS the policy shell in SIMULATION mode
        (TestWithoutNotifications) using documented DLP cmdlets. It DEFAULTS TO -WhatIf (preview only)
        and creates nothing until you re-run with -Commit -WhatIf:$false. IMPORTANT: the
        adaptive-protection RISK-LEVEL CONDITION and pilot-group scoping are added in the PORTAL where
        PowerShell does not expose them — the scaffold creates a safe simulation-mode shell and tells
        you exactly what to finish in the portal. It never enforces and never blocks.
    HOW TO RUN
        Preview the plan (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\PURVAP-Set-DlpPolicy.ps1
        Scaffold the simulation-mode policy shell (still no enforcement):
          powershell -ExecutionPolicy Bypass -File .\PURVAP-Set-DlpPolicy.ps1 -Commit -WhatIf:$false

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession) and a Compliance Administrator / DLP
        Compliance Management admin (MFA-capable). Verify the risk-level condition is available in your
        tenant (E5 / E5 Compliance; Adaptive Protection enabled). No credentials in code.
    EXPECTED RESULTS
        In preview: the intended policy/rule plan and the portal steps to finish, with no change. With
        -Commit -WhatIf:$false: DLP-Adaptive-Protection is created in SIMULATION mode
        (TestWithoutNotifications) and the script prints the remaining portal steps (add risk-level +
        label conditions, scope to SG-AP-Pilot). PASS = plan prints / shell created without error.
.NOTES
    White-label. Change tool — defaults to -WhatIf; -Commit only scaffolds a SIMULATION-mode shell.
    Security & Compliance PowerShell. No credentials in code. The risk-level condition is added in the portal.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]   $PolicyName     = 'DLP-Adaptive-Protection',
    [string]   $PilotGroup     = 'SG-AP-Pilot',
    [string[]] $SensitivityLabels = @('Confidential','Highly Confidential'),
    [switch]   $Commit,
    [string]   $ConnectionUri  = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# The intended rule plan (portal completes the risk-level + label conditions and pilot scoping).
$rulePlan = @(
    [pscustomobject]@{ Rule = 'AP-Elevated-Block';        RiskLevel = 'Elevated'; Action = 'Block (with policy tip)' },
    [pscustomobject]@{ Rule = 'AP-Moderate-WarnOverride'; RiskLevel = 'Moderate'; Action = 'Block with override / warn' },
    [pscustomobject]@{ Rule = 'AP-Minor-Audit';           RiskLevel = 'Minor';    Action = 'Audit only (allow + record)' }
)

Write-Section 'Intended plan for DLP-Adaptive-Protection'
Write-Host ("Policy   : {0}  (mode: SIMULATION / TestWithoutNotifications first)" -f $PolicyName)
Write-Host ("Scope    : {0}  (pilot only — widen later via PURVAP-Set-Scope.ps1)" -f $PilotGroup)
Write-Host ("Labels   : {0}  (each rule combines risk level AND a sensitivity-label/SIT condition)" -f ($SensitivityLabels -join ', '))
$rulePlan | Format-Table -AutoSize
Write-Host 'Each rule = [ adaptive-protection risk level = <level> ]  AND  [ content has label/SIT ]  ->  <action>.'

if ($WhatIfPreference) { Write-Host ''; Write-Host 'MODE: PREVIEW (-WhatIf) — nothing will be created.' -ForegroundColor Yellow }
else                   { Write-Host ''; Write-Host 'MODE: APPLY — a SIMULATION-mode policy shell may be created (no enforcement).' -ForegroundColor Red }

if (-not $Commit) {
    Write-Host ''
    Write-Host 'No -Commit supplied: plan-only. Re-run with -Commit -WhatIf:$false to scaffold the'
    Write-Host 'simulation-mode shell, or build the whole policy in the portal (recommended if the'
    Write-Host 'risk-level condition is portal-only in your tenant).'
    Write-Host ''
    Write-Host 'Portal path: purview.microsoft.com -> Data Loss Prevention -> Policies -> Create policy.'
    return
}

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command New-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect: {0}" -f $_.Exception.Message)
    return
}

Write-Section 'Scaffolding the simulation-mode policy shell'
$existing = $null
try { $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue } catch {}
if ($existing) {
    Write-Host ("Policy '{0}' already exists (Mode: {1}). Not modifying it." -f $PolicyName, $existing.Mode) -ForegroundColor Yellow
} else {
    if ($PSCmdlet.ShouldProcess($PolicyName, 'Create DLP policy in SIMULATION mode (TestWithoutNotifications)')) {
        try {
            # Documented parameters only. TestWithoutNotifications = simulation (no user-facing action).
            New-DlpCompliancePolicy -Name $PolicyName -Mode 'TestWithoutNotifications' `
                -Comment 'Adaptive Protection pilot — simulation only. Finish risk-level + label conditions and SG-AP-Pilot scoping in the portal.' `
                -ExchangeLocation 'All' -ErrorAction Stop | Out-Null
            Write-Host ("Created '{0}' in SIMULATION mode (TestWithoutNotifications)." -f $PolicyName) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Could not create the policy shell: {0}" -f $_.Exception.Message)
            Write-Host 'Create it in the portal instead (Data Loss Prevention -> Policies).'
            return
        }
    } else {
        Write-Host ("WOULD create '{0}' in SIMULATION mode." -f $PolicyName) -ForegroundColor Yellow
    }
}

Write-Section 'Finish in the portal (PowerShell does not expose the risk-level condition)'
Write-Host '1. Scope the policy to SG-AP-Pilot and the workloads you need (Exchange/SharePoint/OneDrive/Teams/Devices).'
Write-Host '2. Add the three rules AP-Elevated-Block / AP-Moderate-WarnOverride / AP-Minor-Audit; for each,'
Write-Host '   set the condition "a user''s risk level for adaptive protection is <Elevated/Moderate/Minor>"'
Write-Host '   AND a sensitivity-label/SIT condition, then the mapped action (block / warn+override / audit).'
Write-Host '3. Keep the policy in SIMULATION/TEST; validate with PURVAP-Test-Readiness.ps1 and 05-testing.md.'
Write-Host '4. Only move to ENFORCE after every gate passes and HR/legal confirm (R8).'
Write-Host 'Verify the risk-level condition is available in your tenant (Adaptive Protection enabled; E5/E5 Compliance).'
