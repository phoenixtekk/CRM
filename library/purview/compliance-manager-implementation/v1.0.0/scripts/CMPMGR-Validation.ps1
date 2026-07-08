<#
.SYNOPSIS
    CMPMGR-Validation.ps1 — read-only technical-evidence collector behind Compliance Manager improvement actions.
.DESCRIPTION
    PURPOSE
        Collects the underlying technical signals that back automatable Compliance Manager improvement
        actions, so you can confirm the score reflects reality and produce evidence. Reports whether:
        unified audit logging is enabled; DLP, retention, and sensitivity-label policies exist; and (via
        Graph) whether Conditional Access policies / an MFA posture are in place. Read-only — makes no
        changes. It does NOT read the Compliance Manager score itself (portal-managed, no public API);
        it validates the tenant state those actions depend on.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Validation.ps1 -CsvPath C:\Temp\CM-Evidence.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for CA/MFA, Microsoft.Graph
        (Connect-MgGraph, scope Policy.Read.All). Sign in with a read-capable compliance admin.
    EXPECTED RESULTS
        A pass/absent line per signal (audit, DLP, retention, labels, Conditional Access), a note of which
        automatable actions each supports, and an optional CSV evidence snapshot. "Absent" means the
        control is not in place — the related improvement action should NOT be marked implemented.
.NOTES
    Purview — Microsoft Purview Compliance Manager Implementation. Read-only. No credentials are stored.
    Enabling any of these controls is a separate, high-impact change owned by that feature's solution and
    piloted in simulation/test first — this tool only observes. Verify availability against your tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

$evidence = @()
function Add-Evidence($signal, $state, $detail, $actionHint) {
    $script:evidence += [pscustomobject]@{ Signal = $signal; State = $state; Detail = $detail; SupportsAction = $actionHint }
    $color = if ($state -eq 'Present') { 'Green' } elseif ($state -eq 'Absent') { 'Yellow' } else { 'DarkYellow' }
    Write-Host ("  [{0,-8}] {1} — {2}" -f $state, $signal, $detail) -ForegroundColor $color
}

# --- Connect (Security & Compliance PowerShell) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement module...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
} catch {
    Write-Error "Connect-IPPSSession failed: $($_.Exception.Message). Confirm licensing and your admin role."
    return
}

Write-Host '=== CM Evidence - technical signals behind improvement actions ===' -ForegroundColor Cyan

# --- Unified audit logging ---
try {
    $adminAudit = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($adminAudit.UnifiedAuditLogIngestionEnabled) {
        Add-Evidence 'Unified audit log' 'Present' 'UnifiedAuditLogIngestionEnabled = True' 'Enable auditing / audit-related actions'
    } else {
        Add-Evidence 'Unified audit log' 'Absent' 'UnifiedAuditLogIngestionEnabled = False' 'Enable auditing / audit-related actions'
    }
} catch {
    Add-Evidence 'Unified audit log' 'Unknown' ("Could not read: {0}" -f $_.Exception.Message) 'Enable auditing / audit-related actions'
}

# --- DLP policies ---
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    if ($dlp.Count -gt 0) { Add-Evidence 'DLP policies' 'Present' ("{0} policy(ies)" -f $dlp.Count) 'Data-loss-prevention actions' }
    else                  { Add-Evidence 'DLP policies' 'Absent' 'No DLP policies found' 'Data-loss-prevention actions' }
} catch {
    Add-Evidence 'DLP policies' 'Unknown' ("Could not read: {0}" -f $_.Exception.Message) 'Data-loss-prevention actions'
}

# --- Retention policies ---
try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    if ($ret.Count -gt 0) { Add-Evidence 'Retention policies' 'Present' ("{0} policy(ies)" -f $ret.Count) 'Data-lifecycle / retention actions' }
    else                  { Add-Evidence 'Retention policies' 'Absent' 'No retention policies found' 'Data-lifecycle / retention actions' }
} catch {
    Add-Evidence 'Retention policies' 'Unknown' ("Could not read: {0}" -f $_.Exception.Message) 'Data-lifecycle / retention actions'
}

# --- Sensitivity labels ---
try {
    $labels = @(Get-Label -ErrorAction Stop)
    if ($labels.Count -gt 0) { Add-Evidence 'Sensitivity labels' 'Present' ("{0} label(s)" -f $labels.Count) 'Information-protection / labeling actions' }
    else                     { Add-Evidence 'Sensitivity labels' 'Absent' 'No sensitivity labels found' 'Information-protection / labeling actions' }
} catch {
    Add-Evidence 'Sensitivity labels' 'Unknown' ("Could not read: {0}" -f $_.Exception.Message) 'Information-protection / labeling actions'
}

# --- Conditional Access / MFA (Graph) ---
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Policy.Read.All' -NoWelcome -ErrorAction Stop
        $ca = @((Invoke-MgGraphRequest -Method GET -Uri 'v1.0/identity/conditionalAccess/policies' -ErrorAction Stop).value)
        $enabled = @($ca | Where-Object { $_.state -eq 'enabled' })
        if ($enabled.Count -gt 0) { Add-Evidence 'Conditional Access' 'Present' ("{0} enabled policy(ies)" -f $enabled.Count) 'Access-control / MFA actions' }
        elseif ($ca.Count -gt 0)  { Add-Evidence 'Conditional Access' 'Absent' ("{0} policy(ies) but none enabled" -f $ca.Count) 'Access-control / MFA actions' }
        else                      { Add-Evidence 'Conditional Access' 'Absent' 'No Conditional Access policies' 'Access-control / MFA actions' }
    } catch {
        Add-Evidence 'Conditional Access' 'Unknown' ("Could not read via Graph: {0}" -f $_.Exception.Message) 'Access-control / MFA actions'
    }
} else {
    Add-Evidence 'Conditional Access' 'Unknown' 'Microsoft.Graph not installed — Install-Module Microsoft.Graph to check' 'Access-control / MFA actions'
}

# --- Optional CSV ---
if ($CsvPath) {
    try {
        $evidence | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host ("`nEvidence snapshot written to {0}" -f $CsvPath) -ForegroundColor Green
    } catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}

$absent = @($evidence | Where-Object { $_.State -eq 'Absent' })
Write-Host ''
if ($absent.Count -gt 0) {
    Write-Host ("[REVIEW] {0} control(s) absent — do NOT mark the related improvement actions implemented until the control is in place (piloted in simulation/test first):" -f $absent.Count) -ForegroundColor Yellow
    $absent | ForEach-Object { Write-Host ("    - {0} ({1})" -f $_.Signal, $_.SupportsAction) -ForegroundColor Yellow }
} else {
    Write-Host '[OK] All checked controls are present. Attach these findings as evidence for the corresponding actions in the portal.' -ForegroundColor Green
}
Write-Host ''
Write-Host 'Validation complete (read-only). The authoritative test status and score live in the Purview portal (Compliance Manager).' -ForegroundColor Cyan
