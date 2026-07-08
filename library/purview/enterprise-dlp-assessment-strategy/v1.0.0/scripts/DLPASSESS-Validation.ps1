<#
.SYNOPSIS
    DLPASSESS-Validation.ps1 — read-only readiness & non-enforcement gate for the DLP assessment.
.DESCRIPTION
    PURPOSE
        Confirms the assessment can run and that it is not accidentally enforcing anything. Checks:
        unified audit logging is ON (movement data depends on it), Content Explorer / the export
        cmdlet is reachable (the data map depends on it), the DLP cmdlets are available (roles), and
        that no DLP policy is in ENFORCE mode unexpectedly. Read-only — makes no changes. Prints a
        PASS/REVIEW verdict per check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPASSESS-Validation.ps1
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
.EXAMPLE
    .\DLPASSESS-Validation.ps1 -ExpectedSimulationPolicy 'DLP Baseline - All Locations - Simulation'
    Also verifies the named monitor-only baseline exists and is in simulation mode.
.NOTES
    Purview — Enterprise DLP Assessment & Strategy. Read-only. EXPECTED RESULTS: a checklist with PASS
    or REVIEW per item. PASS gate for the assessment: audit ON, Content Explorer reachable, roles
    present, and no unintended enforcement.
#>
[CmdletBinding()]
param(
    [string]$ExpectedSimulationPolicy,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host '=== DLP Assessment Readiness & Non-Enforcement Gate (read-only) ===' -ForegroundColor Cyan
$results = @()
function Add-Check($name, $pass, $detail) {
    $script:results += [pscustomobject]@{ Check = $name; Verdict = $(if ($pass) { 'PASS' } else { 'REVIEW' }); Detail = $detail }
    $color = if ($pass) { 'Green' } else { 'Yellow' }
    Write-Host ("[{0}] {1} — {2}" -f $(if ($pass){'PASS'}else{'REVIEW'}), $name, $detail) -ForegroundColor $color
}

# 1. Unified audit logging enabled (movement data depends on it)
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    Add-Check 'Unified audit logging enabled' ([bool]$cfg.UnifiedAuditLogIngestionEnabled) `
        ("UnifiedAuditLogIngestionEnabled = {0}" -f $cfg.UnifiedAuditLogIngestionEnabled)
} catch {
    Add-Check 'Unified audit logging enabled' $false ("Could not read audit config: {0}" -f $_.Exception.Message)
}

# 2. DLP cmdlets available (role signal)
$dlpOk = [bool](Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
Add-Check 'DLP cmdlets available (role)' $dlpOk 'Get-DlpCompliancePolicy present (Compliance/View-Only DLP role).'

# 3. Content Explorer export reachable (data-at-rest map depends on it)
$ceOk = [bool](Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue)
Add-Check 'Content Explorer export reachable' $ceOk `
    $(if ($ceOk) { 'Export-ContentExplorerData present (Content Explorer viewer roles).' } else { 'Missing — confirm Content Explorer viewer roles + licensing (verify your tenant).' })

# 4. No unintended enforcement
try {
    $policies = Get-DlpCompliancePolicy -ErrorAction Stop
    $enforcing = @($policies | Where-Object { $_.Mode -eq 'Enable' })
    Add-Check 'No unintended enforcing DLP policy' ($enforcing.Count -eq 0) `
        $(if ($enforcing.Count -eq 0) { 'No policies in Enable mode.' } else { ("ENFORCING: {0}" -f (($enforcing | ForEach-Object Name) -join ', ')) })
} catch {
    Add-Check 'No unintended enforcing DLP policy' $false ("Could not enumerate policies: {0}" -f $_.Exception.Message)
}

# 5. Expected monitor-only simulation baseline (optional)
if ($ExpectedSimulationPolicy) {
    $p = $policies | Where-Object { $_.Name -eq $ExpectedSimulationPolicy }
    if ($p) {
        Add-Check 'Monitor-only baseline in simulation' ($p.Mode -like 'Test*') ("'{0}' Mode = {1}" -f $ExpectedSimulationPolicy, $p.Mode)
    } else {
        Add-Check 'Monitor-only baseline in simulation' $false ("'{0}' not found (create with DLPASSESS-Baseline.ps1 -Commit)." -f $ExpectedSimulationPolicy)
    }
}

Write-Host '--- Summary ---' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$review = @($results | Where-Object { $_.Verdict -eq 'REVIEW' })
if ($review.Count -eq 0) {
    Write-Host 'READY: all checks pass — proceed with discovery.' -ForegroundColor Green
} else {
    Write-Host ("{0} check(s) need REVIEW before/while assessing — see Requirements 2.1-2.3, 2.5." -f $review.Count) -ForegroundColor Yellow
}
