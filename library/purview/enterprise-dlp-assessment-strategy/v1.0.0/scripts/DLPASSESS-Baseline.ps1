<#
.SYNOPSIS
    DLPASSESS-Baseline.ps1 — create/remove the ONE monitor-only DLP policy in SIMULATION (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Stands up (or removes) a single, broad DLP policy in SIMULATION mode whose only job is to
        MEASURE how sensitive data moves — it takes no enforcement action and shows no policy tips.
        This populates real match data (by SIT, location, volume) for the exposure ranking. It is
        -WhatIf BY DEFAULT: nothing is created until you pass -Commit, and it will NEVER create an
        enforcing policy — the mode is hard-coded to TestWithoutNotifications (simulation).
    HOW TO RUN
        Preview (no change):  powershell -File .\DLPASSESS-Baseline.ps1 -WhatIf
        Create (simulation):  powershell -File .\DLPASSESS-Baseline.ps1 -Commit
        Remove (clean up):    powershell -File .\DLPASSESS-Baseline.ps1 -Remove -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and a Compliance/Compliance
        Data Administrator role to create the policy.
.EXAMPLE
    .\DLPASSESS-Baseline.ps1 -WhatIf
    Shows the policy/rule that would be created — makes no change.
.EXAMPLE
    .\DLPASSESS-Baseline.ps1 -SensitiveTypes 'Credit Card Number','U.S. Social Security Number (SSN)' -Commit
    Creates the simulation baseline covering the named SITs across Exchange/SPO/OneDrive/Teams.
.NOTES
    Purview — Enterprise DLP Assessment & Strategy. WRITE gated behind -Commit; mode is always
    SIMULATION. EXPECTED RESULTS: with -Commit, one policy 'DLP Baseline - All Locations - Simulation'
    in Mode=TestWithoutNotifications. PASS signal: DLPASSESS-Discovery.ps1 reports it as a Test* mode.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$PolicyName = 'DLP Baseline - All Locations - Simulation',
    [string]$RuleName   = 'Monitor All SITs - All Locations - Simulation',
    [string[]]$SensitiveTypes = @('Credit Card Number','U.S. Social Security Number (SSN)'),
    [int]$MinCount = 1,
    [switch]$Remove,
    [switch]$Commit,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# -Commit turns ShouldProcess on; without it we run in -WhatIf (preview only).
if (-not $Commit) { $WhatIfPreference = $true }

$existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

# ---------------- Remove path ----------------
if ($Remove) {
    if (-not $existing) { Write-Host ("Policy '{0}' not found — nothing to remove." -f $PolicyName) -ForegroundColor Yellow; return }
    if ($PSCmdlet.ShouldProcess($PolicyName, 'Remove monitor-only simulation DLP policy')) {
        Remove-DlpCompliancePolicy -Identity $PolicyName -Confirm:$false
        Write-Host ("Removed '{0}' — clean, zero user impact (it was simulation-only)." -f $PolicyName) -ForegroundColor Green
    } else {
        Write-Host ("[WhatIf] Would remove '{0}'. Pass -Remove -Commit to apply." -f $PolicyName) -ForegroundColor Cyan
    }
    return
}

# ---------------- Create path (SIMULATION ONLY) ----------------
Write-Host '=== Monitor-only SIMULATION baseline (measures movement; enforces nothing) ===' -ForegroundColor Cyan
Write-Host ("Policy: {0}" -f $PolicyName)
Write-Host ("Rule:   {0}" -f $RuleName)
Write-Host ("SITs:   {0}" -f ($SensitiveTypes -join ', '))
Write-Host  "Mode:   TestWithoutNotifications (SIMULATION — no enforcement, no tips)" -ForegroundColor Cyan

if ($existing) {
    Write-Host ("Policy '{0}' already exists (Mode = {1})." -f $PolicyName, $existing.Mode) -ForegroundColor Yellow
    if ($existing.Mode -eq 'Enable') {
        Write-Host 'WARNING: existing policy is ENFORCING. This tool will NOT modify it to avoid changing enforcement. Review manually.' -ForegroundColor Red
    }
    return
}

if ($PSCmdlet.ShouldProcess($PolicyName, 'Create monitor-only DLP policy in SIMULATION mode')) {
    # Create the policy in simulation across the four cloud locations. Mode is fixed to simulation.
    New-DlpCompliancePolicy -Name $PolicyName `
        -Comment 'Assessment monitor-only baseline. SIMULATION only — measures movement, enforces nothing.' `
        -Mode 'TestWithoutNotifications' `
        -ExchangeLocation All -SharePointLocation All -OneDriveLocation All -TeamsLocation All -ErrorAction Stop | Out-Null

    # Build the sensitive-information-type condition (any of the named SITs at the min instance count).
    $sitCondition = @( foreach ($t in $SensitiveTypes) { @{ Name = $t; minCount = $MinCount } } )

    New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
        -ContentContainsSensitiveInformation $sitCondition `
        -Comment 'Audit-only detection for assessment. No BlockAccess / no notifications.' -ErrorAction Stop | Out-Null

    $check = Get-DlpCompliancePolicy -Identity $PolicyName
    Write-Host ("Created '{0}' in Mode = {1}." -f $PolicyName, $check.Mode) -ForegroundColor Green
    if ($check.Mode -notlike 'Test*') {
        Write-Host 'ERROR: policy is not in simulation mode — set it back to simulation immediately.' -ForegroundColor Red
    } else {
        Write-Host 'Simulation baseline live — let it dwell (Req 2.6), then run DLPASSESS-Report.ps1.' -ForegroundColor Cyan
    }
} else {
    Write-Host '[WhatIf] Would create the simulation policy + rule above. Pass -Commit to apply.' -ForegroundColor Cyan
    Write-Host 'No change made (safe-by-default).' -ForegroundColor Green
}
