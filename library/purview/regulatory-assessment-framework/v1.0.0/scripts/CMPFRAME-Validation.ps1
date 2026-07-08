<#
.SYNOPSIS
    CMPFRAME-Validation.ps1 — read-only technical-evidence check behind the automatable shared controls.
.DESCRIPTION
    PURPOSE
        Collects the technical evidence behind the shared controls a Regulatory Assessment Framework
        maps across regulations, so you can confirm which shared controls Compliance Manager can
        auto-test and which need manual evidence — and cross-check that auto-tested actions reflect the
        real state (no false pass). Checks common cross-regulation signals: unified audit logging
        enabled, DLP policy presence, retention/label policy presence, and Conditional Access / MFA
        presence (Graph). Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Validation.ps1 -CsvPath C:\Temp\RAF-Signals.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession) for audit/DLP/retention/label signals,
        and Microsoft.Graph (Connect-MgGraph) for Conditional Access/MFA. Sign in with a read-capable
        compliance/security admin. Availability of each signal is plan-dependent — verify.
    EXPECTED RESULTS
        A per-signal PASS / ABSENT report (the technical evidence behind the shared controls). PASS
        means the underlying control exists and can back an auto-tested action; ABSENT means the mapped
        regulations are not yet satisfied by that control — implement it (piloted in simulation/test)
        or plan manual evidence. Optional CSV.
.NOTES
    Purview — Regulatory Assessment Framework. Read-only. No credentials are stored. Signal availability
    is plan-dependent and the portal evolves — verify against your own licensing and tenant. Presence of
    a policy is not adequacy: whether the evidence satisfies a regulation is a compliance/legal decision.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

$results = @()
function Add-Signal($name, $state, $detail) {
    $script:results += [pscustomobject]@{ Signal = $name; State = $state; Detail = $detail }
    $color = if ($state -eq 'PASS') { 'Green' } elseif ($state -eq 'ABSENT') { 'Yellow' } else { 'DarkYellow' }
    Write-Host ("  [{0}] {1} — {2}" -f $state, $name, $detail) -ForegroundColor $color
}

# --- Security & Compliance PowerShell signals ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement module...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

Write-Host '=== Shared-control technical evidence (read-only) ===' -ForegroundColor Cyan

$ippsOk = $false
try {
    Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
    $ippsOk = $true
} catch {
    Write-Host ("  Could not connect Security & Compliance PowerShell: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
}

if ($ippsOk) {
    # Unified audit logging (a control that maps across nearly every regulation)
    try {
        $ec = Get-AdminAuditLogConfig -ErrorAction Stop
        if ($ec.UnifiedAuditLogIngestionEnabled) { Add-Signal 'Unified audit logging' 'PASS' 'UnifiedAuditLogIngestionEnabled = True' }
        else { Add-Signal 'Unified audit logging' 'ABSENT' 'UnifiedAuditLogIngestionEnabled = False — enable it (its own change control)' }
    } catch { Add-Signal 'Unified audit logging' 'UNKNOWN' $_.Exception.Message }

    # DLP policies
    try {
        $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
        if ($dlp.Count -gt 0) { Add-Signal 'DLP policy presence' 'PASS' ("{0} DLP policy(ies) present" -f $dlp.Count) }
        else { Add-Signal 'DLP policy presence' 'ABSENT' 'No DLP policy — implement (pilot in simulation/test first)' }
    } catch { Add-Signal 'DLP policy presence' 'UNKNOWN' $_.Exception.Message }

    # Retention / records policies
    try {
        $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
        if ($ret.Count -gt 0) { Add-Signal 'Retention policy presence' 'PASS' ("{0} retention policy(ies) present" -f $ret.Count) }
        else { Add-Signal 'Retention policy presence' 'ABSENT' 'No retention policy — implement per records schedule' }
    } catch { Add-Signal 'Retention policy presence' 'UNKNOWN' $_.Exception.Message }

    # Sensitivity labels (encryption/classification control)
    try {
        $lab = @(Get-Label -ErrorAction Stop)
        if ($lab.Count -gt 0) { Add-Signal 'Sensitivity labels' 'PASS' ("{0} sensitivity label(s) published/available" -f $lab.Count) }
        else { Add-Signal 'Sensitivity labels' 'ABSENT' 'No sensitivity labels — implement classification/encryption control' }
    } catch { Add-Signal 'Sensitivity labels' 'UNKNOWN' $_.Exception.Message }
}

# --- Graph signals: Conditional Access / MFA (access control mapped across regulations) ---
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome -ErrorAction Stop
        $ca = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -ErrorAction Stop
        $enabled = @($ca.value | Where-Object { $_.state -eq 'enabled' })
        if ($enabled.Count -gt 0) { Add-Signal 'Conditional Access / MFA' 'PASS' ("{0} enabled Conditional Access policy(ies)" -f $enabled.Count) }
        else { Add-Signal 'Conditional Access / MFA' 'ABSENT' 'No enabled Conditional Access policy — implement access control' }
    } catch {
        Add-Signal 'Conditional Access / MFA' 'UNKNOWN' $_.Exception.Message
    }
} else {
    Write-Host '  Microsoft.Graph not installed — skipping Conditional Access/MFA read. Install-Module Microsoft.Graph to enable.' -ForegroundColor DarkYellow
}

# --- Summary ---
$pass   = @($results | Where-Object { $_.State -eq 'PASS' }).Count
$absent = @($results | Where-Object { $_.State -eq 'ABSENT' }).Count
Write-Host ''
Write-Host ("Shared-control evidence: {0} PASS, {1} ABSENT, {2} total signal(s)." -f $pass, $absent, $results.Count) -ForegroundColor Cyan
Write-Host 'A PASS control can back auto-tested actions across every regulation it maps to; an ABSENT control leaves those regulations unsatisfied until implemented (piloted in simulation/test) or manually evidenced.' -ForegroundColor DarkGray

if ($CsvPath) {
    try { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nSignals written to {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}
