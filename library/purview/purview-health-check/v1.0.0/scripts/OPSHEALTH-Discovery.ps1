<#
.SYNOPSIS
    OPSHEALTH-Discovery.ps1 — inventory the Microsoft Purview estate (DLP, labels, retention, audit, IRM presence, roles) for the health check (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell (and Exchange Online for the unified-audit-log
        status) and inventories the Microsoft Purview estate so the HEALTH CHECK can score it. It reports
        DLP policies with their Mode, sensitivity labels and label policies, retention/data-lifecycle
        policies and retention labels, the unified-audit-log status, insider-risk policy PRESENCE and
        privacy posture (posture only — never case contents), and compliance role groups. Read-only — it
        changes nothing. This is the raw material the scoring in 03-implementation.md works from.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-Discovery.ps1 -CsvPath .\opshealth-inventory.csv

        Prereqs: ExchangeOnlineManagement module (Connect-IPPSSession + Connect-ExchangeOnline) and an
        MFA-capable admin with at least read access to compliance policies. Some objects (e.g. insider
        risk) are largely portal-managed and may have no read surface in your tenant — the script says so.
        Verify capability availability against your licensing/tenant (many advanced capabilities need
        Microsoft 365 E5 / E5 Compliance; some are in preview).
    EXPECTED RESULTS
        A read-only inventory: DLP policies (Name/Mode/Enabled), label + label-policy counts, retention
        policies + retention labels, unified-audit-log ON/OFF, IRM presence/posture note, and role-group
        membership. PASS = the inventory completes and every in-scope surface is readable; an unreadable
        surface is a READ-ACCESS finding, not a drift Gap.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/',
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($Surface, $Detail) { $findings.Add([pscustomobject]@{ Surface = $Surface; Detail = $Detail }) }

# --- Connect: Security & Compliance PowerShell ------------------------------------------------------
try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    Write-Host 'Install ExchangeOnlineManagement and sign in with an MFA-capable admin, then retry.'
    return
}

# --- DLP policies (with Mode) -----------------------------------------------------------------------
Write-Section 'DLP policies (Policy health domain P)'
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    if ($dlp.Count -eq 0) {
        Write-Host 'No DLP policies found. If DLP is intended (see the capability baseline), this is a Gap.' -ForegroundColor Yellow
    } else {
        $dlp | Select-Object Name, Mode, Enabled, Workload | Format-Table -AutoSize
        # "Stuck in test" heuristic: any Test* mode is At Risk if it is not a fresh pilot.
        $inTest = @($dlp | Where-Object { $_.Mode -like 'Test*' })
        foreach ($p in $inTest) { Add-Finding 'DLP' ("Policy '{0}' is in {1} (simulation/test) — At Risk if past pilot." -f $p.Name, $p.Mode) }
        $disabled = @($dlp | Where-Object { $_.Enabled -eq $false -or $_.Mode -eq 'Disable' })
        foreach ($p in $disabled) { Add-Finding 'DLP' ("Policy '{0}' is disabled — Gap if intended to be enforcing." -f $p.Name) }
    }
}
catch { Write-Warning ("Could not read DLP policies: {0}" -f $_.Exception.Message); Add-Finding 'DLP' 'Unreadable — read-access finding (not a drift Gap).' }

# --- Sensitivity labels + label policies ------------------------------------------------------------
Write-Section 'Sensitivity labels & label policies (Policy health / Coverage)'
try {
    $labels = @(Get-Label -ErrorAction Stop)
    $labelPolicies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
    Write-Host ("Sensitivity labels: {0}   Label policies: {1}" -f $labels.Count, $labelPolicies.Count)
    $labels | Select-Object DisplayName, Disabled | Format-Table -AutoSize
    # Orphaned labels: published by no policy (heuristic — a label in zero policies is unpublished).
    if ($labelPolicies.Count -eq 0 -and $labels.Count -gt 0) {
        Add-Finding 'Labels' 'Labels exist but no label policy publishes them — labels are orphaned (At Risk/Gap).'
    }
}
catch { Write-Warning ("Could not read sensitivity labels: {0}" -f $_.Exception.Message); Add-Finding 'Labels' 'Unreadable — read-access finding.' }

# --- Retention / data-lifecycle ---------------------------------------------------------------------
Write-Section 'Retention / data-lifecycle policies & retention labels (Policy health / Coverage)'
try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    $retLabels = @(Get-ComplianceTag -ErrorAction SilentlyContinue)
    Write-Host ("Retention policies: {0}   Retention labels: {1}" -f $ret.Count, $retLabels.Count)
    $ret | Select-Object Name, Enabled, Mode, Workload | Format-Table -AutoSize
    $retDisabled = @($ret | Where-Object { $_.Enabled -eq $false })
    foreach ($p in $retDisabled) { Add-Finding 'Retention' ("Retention policy '{0}' is disabled — Gap if intended." -f $p.Name) }
    Write-Host 'NOTE: whether a retention SCHEDULE/records file plan is correct is a records/legal determination — defer.' -ForegroundColor DarkYellow
}
catch { Write-Warning ("Could not read retention policies: {0}" -f $_.Exception.Message); Add-Finding 'Retention' 'Unreadable — read-access finding.' }

# --- Unified audit log status (Exchange Online) -----------------------------------------------------
Write-Section 'Unified audit log status (Policy health — foundational)'
try {
    if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) {
        Connect-ExchangeOnline -ShowBanner:$false | Out-Null
    }
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $ual = $cfg.UnifiedAuditLogIngestionEnabled
    if ($ual) {
        Write-Host 'Unified audit log: ON (Healthy).' -ForegroundColor Green
    } else {
        Write-Host 'Unified audit log: OFF — HIGH-severity Gap. This is the one fix OPSHEALTH-Remediate.ps1 can commit.' -ForegroundColor Red
        Add-Finding 'Audit' 'Unified audit log is OFF — High-severity Gap (re-enable via OPSHEALTH-Remediate.ps1 -EnableUnifiedAuditLog -Commit).'
    }
}
catch {
    Write-Warning ("Could not read unified audit log status: {0}" -f $_.Exception.Message)
    Write-Host 'Connect-ExchangeOnline and confirm Get-AdminAuditLogConfig read access. Verify in tenant.'
    Add-Finding 'Audit' 'Unified audit log status unreadable — confirm Exchange Online read access.'
}

# --- Insider risk PRESENCE + privacy posture (posture only) -----------------------------------------
Write-Section 'Insider Risk presence + privacy posture (posture only — HR/privacy-sensitive)'
if (Get-Command Get-InsiderRiskPolicy -ErrorAction SilentlyContinue) {
    try {
        $irm = @(Get-InsiderRiskPolicy -ErrorAction Stop)
        Write-Host ("Insider-risk policies present: {0} (presence only — no case contents reported)." -f $irm.Count)
    }
    catch { Write-Host 'Insider-risk policies not readable via cmdlet — confirm PRESENCE + privacy posture in the portal.' }
} else {
    Write-Host 'Get-InsiderRiskPolicy not available (IRM is largely portal-managed). Confirm in the portal:'
    Write-Host '  purview.microsoft.com -> Insider Risk Management -> Settings -> Privacy (anonymization ON) and role separation.'
    Write-Host '  Report POSTURE only — never case contents or any person''s identity.'
}

# --- Compliance role groups -------------------------------------------------------------------------
Write-Section 'Compliance role groups (Roles domain R — least privilege)'
try {
    $rg = @(Get-RoleGroup -ErrorAction Stop)
    Write-Host ("Role groups: {0}" -f $rg.Count)
    foreach ($g in $rg) {
        $members = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue)
        if ($members.Count -eq 0) { Add-Finding 'Roles' ("Role group '{0}' is EMPTY — At Risk/Gap if critical." -f $g.Name) }
        elseif ($members.Count -eq 1) { Add-Finding 'Roles' ("Role group '{0}' has a SINGLE member (SPOF) — At Risk." -f $g.Name) }
    }
    Write-Host 'Global Admin sprawl is reviewed via Graph in OPSHEALTH-ScopeCheck.ps1.'
}
catch { Write-Warning ("Could not read role groups: {0}" -f $_.Exception.Message); Add-Finding 'Roles' 'Role groups unreadable — read-access finding.' }

# --- Summary ----------------------------------------------------------------------------------------
Write-Section 'Inventory complete'
if ($findings.Count -gt 0) {
    Write-Host ("Preliminary findings for scoring ({0}):" -f $findings.Count) -ForegroundColor Yellow
    $findings | Format-Table -AutoSize
    if ($CsvPath) { $findings | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Findings written to {0}" -f $CsvPath) -ForegroundColor Green }
} else {
    Write-Host 'No preliminary findings from the inventory heuristics — score against your intended baseline (R4).' -ForegroundColor Green
}
Write-Host 'Next: OPSHEALTH-ScopeCheck.ps1 (coverage + role review), then score P/C/R and build the register.'
