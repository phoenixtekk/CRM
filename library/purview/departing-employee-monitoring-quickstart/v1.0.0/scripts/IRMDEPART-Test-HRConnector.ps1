<#
.SYNOPSIS
    IRMDEPART-Test-HRConnector.ps1 — check the departing-user TRIGGER and indicator readiness (read-only).
.DESCRIPTION
    PURPOSE
        A readiness checker for the prerequisites that make the "Data theft by departing users" policy
        actually fire. It confirms unified audit-log ingestion is on (IRM signals depend on the audit
        pipeline), reports the HR data connector's presence/freshness where the tenant exposes it (the
        departing-user TRIGGER), and lists — as guided portal checks — device onboarding (for device
        indicators) and the Office/Device indicator families. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IRMDEPART-Test-HRConnector.ps1

        Connects to Security & Compliance PowerShell (Connect-IPPSSession) / Exchange Online for the
        readable checks. Several signals (device onboarding, HR-connector uploads, indicator toggles) are
        portal-managed and are reported here as explicit portal checks with the exact path. Verify
        capability availability against your licensing/tenant.
    EXPECTED RESULTS
        A checklist with PASS / GAP / CHECK-IN-PORTAL per item. PASS overall = audit ingestion on, the HR
        connector shows recent uploads (or you deliberately use the Entra account-deletion trigger), and
        the portal checks confirmed. GAP = a readable prerequisite is missing (named); fix it before
        relying on departing-user detection.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/',
    [int]    $ConnectorFreshDays = 7
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

$gaps = @()

try {
    if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) {
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

Write-Section 'HR connector — the departing-user trigger (where readable)'
$connFound = $false
if (Get-Command Get-DataConnector -ErrorAction SilentlyContinue) {
    try {
        $connectors = @(Get-DataConnector -ErrorAction Stop)
        $hr = @($connectors | Where-Object { "$($_.Type)$($_.Name)" -match 'HR|Human' })
        if ($hr.Count -gt 0) {
            $connFound = $true
            foreach ($c in $hr) {
                $last = $c.LastUpdatedTime
                $fresh = $false
                if ($last) { try { $fresh = ([datetime]$last -gt (Get-Date).AddDays(-$ConnectorFreshDays)) } catch {} }
                if ($fresh) {
                    Write-Host ("PASS  HR connector '{0}' — last update {1} (within {2} days)." -f $c.Name, $last, $ConnectorFreshDays) -ForegroundColor Green
                } else {
                    Write-Host ("GAP   HR connector '{0}' — last update {1} looks STALE (older than {2} days). Re-run the upload." -f $c.Name, $last, $ConnectorFreshDays) -ForegroundColor Yellow
                    $gaps += 'Refresh HR connector upload'
                }
            }
        } else {
            Write-Host 'CHECK No HR-type data connector returned via cmdlet — confirm in the portal (below), or use the Entra account-deletion trigger deliberately.' -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning ("Could not read data connectors via cmdlet: {0}. Confirm in the portal." -f $_.Exception.Message)
    }
}
if (-not $connFound) {
    Write-Host 'CHECK HR connector : Settings -> Data connectors — the Microsoft 365 HR connector must show a'
    Write-Host '                     recent SUCCESSFUL upload (resignation/termination dates). This is the'
    Write-Host '                     departing-user trigger. Alternative: Entra account deletion (coarser).'
}

Write-Section 'Portal-managed readiness checks (confirm each in the Purview portal)'
Write-Host 'CHECK Indicators ON     : Settings -> Policy indicators — enable Office (SharePoint/OneDrive'
Write-Host '                          download, external share, email to external/personal) and Device'
Write-Host '                          (USB copy, personal-cloud copy, print) families.'
Write-Host 'CHECK Device onboarding : Settings -> Device onboarding — devices must be onboarded for device'
Write-Host '                          indicators (USB/print/personal-cloud) to fire on a leavers laptop.'
Write-Host 'CHECK Cumulative/seq.   : (recommended) enable cumulative exfiltration / sequence detection to'
Write-Host '                          catch a slow leak of many files over days.'

Write-Section 'Readiness result'
if ($gaps.Count -gt 0) {
    Write-Host ('GAPS (readable): {0}' -f ($gaps -join '; ')) -ForegroundColor Yellow
    Write-Host 'Close the gaps above and confirm the portal-managed checks, then re-run the testing gates (05-testing.md, Gate 3).'
} else {
    Write-Host 'PASS (readable checks) — confirm the portal-managed checks above, then proceed to the testing gates.' -ForegroundColor Green
}
