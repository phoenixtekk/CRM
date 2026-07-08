<#
.SYNOPSIS
    PURVIRM-Test-Readiness.ps1 — check IRM connector / indicator / integration readiness (read-only).
.DESCRIPTION
    PURPOSE
        A readiness checker for the prerequisites that make IRM detections actually fire. It reports
        whether unified audit-log ingestion is on (IRM signals depend on the audit pipeline), whether a
        DLP policy exists to trigger data-leak detection, and — as guided portal checks — device
        onboarding (for device indicators), HR-connector freshness (departing-user trigger), and the
        Defender for Endpoint connection (security-policy-violation trigger). Read-only — it changes
        nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIRM-Test-Readiness.ps1

        Connects to Security & Compliance PowerShell (Connect-IPPSSession) / Exchange Online for the
        readable checks. Some readiness signals (device onboarding, HR/physical connector uploads,
        indicator toggles) are portal-managed and are reported here as explicit portal checks with the
        exact path. Verify capability availability against your licensing/tenant.
    EXPECTED RESULTS
        A checklist with PASS / GAP / CHECK-IN-PORTAL per item. PASS overall = audit ingestion on, a DLP
        trigger policy present (for data leaks), and the portal checks confirmed. GAP = a readable
        prerequisite is missing (named); fix it before relying on the corresponding detection.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

$gaps = @()

try {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected to Security & Compliance PowerShell.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect: {0}" -f $_.Exception.Message)
    return
}

Write-Section 'Unified audit-log ingestion (IRM depends on the audit pipeline)'
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($cfg.UnifiedAuditLogIngestionEnabled) {
        Write-Host 'PASS  Unified audit-log ingestion is ENABLED.' -ForegroundColor Green
    } else {
        Write-Host 'GAP   Unified audit-log ingestion is DISABLED — enable it (Purview -> Audit) before relying on IRM signals.' -ForegroundColor Yellow
        $gaps += 'Enable unified audit-log ingestion'
    }
}
catch {
    Write-Warning ("Could not read audit config: {0}. Verify in Purview -> Audit." -f $_.Exception.Message)
}

Write-Section 'DLP trigger policy (needed for the Data leaks template)'
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    if ($dlp.Count -gt 0) {
        Write-Host ("PASS  {0} DLP policy(ies) present — a high-severity match can trigger IRM data-leak detection." -f $dlp.Count) -ForegroundColor Green
        $dlp | Select-Object Name, Mode, Enabled | Format-Table -AutoSize
    } else {
        Write-Host 'GAP   No DLP policies found — create/point to one to trigger IRM data-leak detection.' -ForegroundColor Yellow
        $gaps += 'Create a DLP trigger policy for data-leak detection'
    }
}
catch {
    Write-Warning ("Could not read DLP policies: {0}" -f $_.Exception.Message)
}

Write-Section 'Portal-managed readiness checks (confirm each in the Purview portal)'
Write-Host 'CHECK Indicators ON      : Settings -> Policy indicators — enable Office, Device, and (for'
Write-Host '                           security-policy violations) Microsoft Defender for Endpoint families.'
Write-Host 'CHECK Device onboarding  : Settings -> Device onboarding — devices must be onboarded for'
Write-Host '                           device indicators (USB/print/personal-cloud) to fire.'
Write-Host 'CHECK HR connector       : Settings -> Data connectors — the HR connector must show recent'
Write-Host '                           successful uploads (departing-user trigger), or use Entra account'
Write-Host '                           deletion as the trigger.'
Write-Host 'CHECK Defender for Endpt : the MDE connection must be enabled (indicator + trigger source for'
Write-Host '                           IRM-SecurityPolicyViolations).'
Write-Host 'CHECK Physical badging    : (optional) Settings -> Data connectors — only if you need physical'
Write-Host '                           access correlation.'

Write-Section 'Readiness result'
if ($gaps.Count -gt 0) {
    Write-Host ('GAPS (readable): {0}' -f ($gaps -join '; ')) -ForegroundColor Yellow
    Write-Host 'Close the gaps above and confirm the portal-managed checks, then re-run the testing gates (05-testing.md).'
} else {
    Write-Host 'PASS (readable checks) — confirm the portal-managed checks above, then proceed to the testing gates.' -ForegroundColor Green
}
