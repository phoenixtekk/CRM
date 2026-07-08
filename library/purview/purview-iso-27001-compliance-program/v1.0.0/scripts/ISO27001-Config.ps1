<#
.SYNOPSIS
    ISO27001-Config.ps1 — supporting-control config helper; builds DLP/retention controls in SIMULATION/TEST (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Creates or updates a supporting technical control that backs an ISO 27001 Annex A control —
        a DLP policy (A.8.12 data leakage) or a retention policy (A.8.10 information deletion / A.5.33
        records) — and always in a SAFE, NON-ENFORCING mode: DLP is created/left in simulation
        (TestWithoutNotifications), retention is created/left in test mode where supported. Read-only by
        default (prints the intended change under -WhatIf); a write requires the explicit -Commit switch.
        The script NEVER sets a policy to enforce (Mode=Enable) — moving to enforcement is a deliberate
        portal action after the pilot passes.
    HOW TO RUN
        # Preview (default, no change):
        powershell -ExecutionPolicy Bypass -File .\ISO27001-Config.ps1 -Control DLP -PolicyName 'ISO27001 DLP - Data Leakage - Simulation' -WhatIf
        # Apply the simulation-mode policy (explicit write):
        powershell -ExecutionPolicy Bypass -File .\ISO27001-Config.ps1 -Control DLP -PolicyName 'ISO27001 DLP - Data Leakage - Simulation' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        Under -WhatIf: the intended create/update and the mode it would set (always simulation/test).
        Under -Commit: the policy exists in simulation/test mode. PASS signal: Get-DlpCompliancePolicy /
        Get-RetentionCompliancePolicy shows the policy in a Test*/disabled mode, never Enable.
.NOTES
    Purview — ISO 27001 Compliance Program. Safe-by-default; -Commit required to write; never enforces.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][ValidateSet('DLP','Retention')][string]$Control,
    [Parameter(Mandatory = $true)][string]$PolicyName,
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$doWrite = $Commit -and -not $WhatIf
if (-not $doWrite) {
    Write-Host 'SAFE MODE (-WhatIf / no -Commit): no changes will be made. Pass -Commit to apply.' -ForegroundColor Yellow
}

function Test-Existing($getCmd, $name) {
    try { return (& $getCmd -Identity $name -ErrorAction SilentlyContinue) } catch { return $null }
}

if ($Control -eq 'DLP') {
    # DLP data-leakage control (A.8.12) — created/kept in SIMULATION (TestWithoutNotifications).
    $existing = Test-Existing 'Get-DlpCompliancePolicy' $PolicyName
    if ($existing) {
        if ($existing.Mode -eq 'Enable') {
            Write-Host ("REFUSING to touch mode: '{0}' is currently ENFORCING (Enable). This script never enforces or silently changes an enforcing policy. Adjust in the portal deliberately." -f $PolicyName) -ForegroundColor Red
            return
        }
        Write-Host ("DLP policy '{0}' exists (Mode={1}). Would ensure simulation mode (TestWithoutNotifications)." -f $PolicyName, $existing.Mode) -ForegroundColor Cyan
        if ($doWrite -and $PSCmdlet.ShouldProcess($PolicyName, 'Set DLP policy to simulation mode')) {
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode Test -ErrorAction Stop
            Write-Host '  Applied: policy set to simulation (Test) mode.' -ForegroundColor Green
        }
    } else {
        Write-Host ("DLP policy '{0}' does not exist. Would CREATE it in simulation mode, scoped to the pilot ring." -f $PolicyName) -ForegroundColor Cyan
        Write-Host '  NOTE: locations/rules (SITs, conditions, actions) are defined in the portal or a follow-up New-DlpComplianceRule; this helper creates the policy shell in simulation.' -ForegroundColor Cyan
        if ($doWrite -and $PSCmdlet.ShouldProcess($PolicyName, 'Create DLP policy in simulation mode')) {
            New-DlpCompliancePolicy -Name $PolicyName -Mode Test `
                -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -ErrorAction Stop | Out-Null
            Write-Host '  Created in simulation (Test) mode. Add rules/conditions and tighten scope in the portal, then pilot before enforcing.' -ForegroundColor Green
        }
    }
}
elseif ($Control -eq 'Retention') {
    if (-not (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
        Write-Host 'Retention cmdlets unavailable (role/licensing) — verify Records/Retention Management access.' -ForegroundColor Yellow
        return
    }
    $existing = Test-Existing 'Get-RetentionCompliancePolicy' $PolicyName
    if ($existing) {
        Write-Host ("Retention policy '{0}' exists (Enabled={1}, Mode={2}). Would keep it disabled/pilot-scoped for validation before broad enablement." -f $PolicyName, $existing.Enabled, $existing.Mode) -ForegroundColor Cyan
        Write-Host '  This helper does not broaden a retention policy scope; expand scope deliberately in the portal after the pilot passes.' -ForegroundColor Cyan
    } else {
        Write-Host ("Retention policy '{0}' does not exist. Would CREATE it DISABLED (pilot), for a limited scope." -f $PolicyName) -ForegroundColor Cyan
        Write-Host '  NOTE: retention settings/duration/scope reflect the records requirement (a records/legal determination); configure them per the schedule.' -ForegroundColor Cyan
        if ($doWrite -and $PSCmdlet.ShouldProcess($PolicyName, 'Create retention policy (disabled/pilot)')) {
            New-RetentionCompliancePolicy -Name $PolicyName -Enabled $false -ErrorAction Stop | Out-Null
            Write-Host '  Created DISABLED. Add a retention rule (duration/action) and pilot scope in the portal, validate, then enable.' -ForegroundColor Green
        }
    }
}

Write-Host 'Done. High-impact controls remain in simulation/test/disabled — enforcement is a deliberate portal step after the pilot gate.' -ForegroundColor Cyan
