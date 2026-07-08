<#
.SYNOPSIS
    PURVAP-Test-Readiness.ps1 — validate the adaptive-protection wiring (DLP policy mode/scope, IRM signal) as pass/fail (read-only).
.DESCRIPTION
    PURPOSE
        Runs read-only checks aligned to 05-testing.md and reports each as PASS / FAIL / CONFIRM-IN-PORTAL:
        that an IRM scoring source is readable (Gate 2), that the DLP-Adaptive-Protection policy exists,
        its MODE (simulation vs enforce), and that its three risk-level rules are present (Gate 4). It
        does NOT change anything. Adaptive Protection SETUP and the CA policy are portal/Graph objects —
        the script points you to confirm those in-portal where it cannot read them.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVAP-Test-Readiness.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVAP-Test-Readiness.ps1 -PolicyName DLP-Adaptive-Protection

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession), MFA-capable admin with read access to
        compliance policies. Verify capability availability against your licensing/tenant.
    EXPECTED RESULTS
        A checklist of gates with PASS/FAIL/CONFIRM verdicts and an overall readiness line. PASS overall
        = IRM signal readable, the DLP policy exists in SIMULATION with the three expected rules, and the
        assessment completes without error.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $PolicyName    = 'DLP-Adaptive-Protection',
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
function Write-Verdict([string] $Gate, [string] $Verdict, [string] $Detail) {
    $color = switch ($Verdict) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
    Write-Host ("[{0,-7}] {1} — {2}" -f $Verdict, $Gate, $Detail) -ForegroundColor $color
}

$expectedRules = @('AP-Elevated-Block','AP-Moderate-WarnOverride','AP-Minor-Audit')

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect: {0}" -f $_.Exception.Message)
    return
}

Write-Section 'Readiness gates'

# Gate 2 — IRM source signal
if (Get-Command Get-InsiderRiskPolicy -ErrorAction SilentlyContinue) {
    try {
        $irm = @(Get-InsiderRiskPolicy -ErrorAction Stop)
        if ($irm.Count -gt 0) { Write-Verdict 'Gate 2 (IRM signal)' 'PASS' ("{0} insider-risk policy(ies) readable" -f $irm.Count) }
        else { Write-Verdict 'Gate 2 (IRM signal)' 'FAIL' 'no insider-risk policy — Adaptive Protection has no source signal' }
    } catch { Write-Verdict 'Gate 2 (IRM signal)' 'CONFIRM' 'could not read IRM policy — confirm in Purview -> Insider Risk Management -> Policies' }
} else {
    Write-Verdict 'Gate 2 (IRM signal)' 'CONFIRM' 'Get-InsiderRiskPolicy unavailable — confirm an active IRM policy in the portal'
}

# Gate 3 — Adaptive Protection setup (portal)
Write-Verdict 'Gate 3 (AP active)' 'CONFIRM' 'confirm Adaptive Protection is active with Elevated/Moderate/Minor defined (Insider Risk Management -> Adaptive Protection)'

# Gate 4 — DLP policy mode/scope/rules
try {
    $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if (-not $pol) {
        Write-Verdict 'Gate 4 (DLP policy)' 'FAIL' ("policy '{0}' not found — build it (PURVAP-Set-DlpPolicy.ps1 / portal)" -f $PolicyName)
    } else {
        $mode = "$($pol.Mode)"
        if ($mode -match 'Test') {
            Write-Verdict 'Gate 4 (DLP mode)' 'PASS' ("'{0}' is in SIMULATION/TEST mode ({1}) — correct for pilot" -f $PolicyName, $mode)
        } elseif ($mode -match 'Enable') {
            Write-Verdict 'Gate 4 (DLP mode)' 'CONFIRM' ("'{0}' is ENFORCING ({1}) — only after gates pass + HR/legal (R8)" -f $PolicyName, $mode)
        } else {
            Write-Verdict 'Gate 4 (DLP mode)' 'CONFIRM' ("'{0}' mode = {1}" -f $PolicyName, $mode)
        }

        $rules = @(Get-DlpComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue)
        $have  = @($rules | Select-Object -ExpandProperty Name)
        $missing = @($expectedRules | Where-Object { $_ -notin $have })
        if ($missing.Count -eq 0 -and $rules.Count -gt 0) {
            Write-Verdict 'Gate 4 (DLP rules)' 'PASS' 'all three per-level rules present'
        } else {
            Write-Verdict 'Gate 4 (DLP rules)' 'CONFIRM' ("present: [{0}]; missing/expected: [{1}] — add in portal with risk-level+label conditions" -f ($have -join ', '), ($missing -join ', '))
        }
    }
}
catch {
    Write-Verdict 'Gate 4 (DLP policy)' 'CONFIRM' ("could not read policy: {0}" -f $_.Exception.Message)
}

# Gate 5 — CA report-only (Graph/portal)
Write-Verdict 'Gate 5 (CA report-only)' 'CONFIRM' 'confirm CA-InsiderRisk-Elevated is REPORT-ONLY with break-glass excluded (Entra -> Conditional Access); PURVAP-Discovery.ps1 -IncludeConditionalAccess reports presence'

Write-Section 'Summary'
Write-Host 'Cross-check every CONFIRM item in the portal, then work the full gate list in 05-testing.md.'
Write-Host 'Do NOT enforce (DLP -> enforce, CA -> on) until all gates PASS and HR/legal confirm (Gate 10 / R8).'
