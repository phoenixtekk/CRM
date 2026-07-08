<#
.SYNOPSIS
    IRMASSESS-Discovery.ps1 — read-only Insider Risk Management readiness posture: roles/separation, audit-log, licensing signal (safe: read-only).
.DESCRIPTION
    PURPOSE
        Builds the IRM readiness baseline from the signals that ARE scriptable: the Insider Risk Management
        role groups and their membership (flagging role-SEPARATION conflicts and super-group over-membership),
        the unified-audit-log ingestion state (the correlation substrate), and a LICENSING signal derived
        from subscribed-SKU service plans (Microsoft Graph). Insider Risk Management is largely
        PORTAL-CONFIGURED with a limited PowerShell/Graph surface, so this script also prints a PORTAL
        CHECKLIST for the parts it cannot script (Analytics scan, connector health, pseudonymization/
        anonymization toggle, and policy/priority-user configuration) — flagged "verify in the Purview
        portal / verify your licensing/tenant". Read-only — makes no changes and touches no individual.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IRMASSESS-Discovery.ps1 -CsvPath .\IRMASSESS-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement) for
        role groups + audit config; optional Microsoft Graph (Connect-MgGraph) for the licensing signal.
.EXAMPLE
    .\IRMASSESS-Discovery.ps1 -CsvPath .\IRMASSESS-Posture.csv
    Prints the IRM role groups (member counts + separation conflicts), audit-log state, licensing signal, and
    a portal checklist; exports the role-group inventory CSV.
.NOTES
    Purview — Insider Risk Readiness Assessment. Read-only. No changes, no de-anonymization, no individual data.
    Expected results: PASS = four IRM roles separated across distinct owners, audit log enabled, licensing
    signal present. Anything else is flagged for review or for portal verification.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$UserPrincipalName
)

# --- Connect Security & Compliance PowerShell (role groups + audit). Reuses an existing session if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName }
    else { Connect-IPPSSession }
}

Write-Host '=== Insider Risk Management — Readiness Posture (read-only) ===' -ForegroundColor Cyan
Write-Host 'Note: IRM is largely portal-configured; this reports the scriptable signals + a portal checklist.' -ForegroundColor DarkCyan

# --- IRM role groups + membership + separation analysis ---
Write-Host '--- IRM role groups & separation ---' -ForegroundColor Cyan
# The built-in Insider Risk Management role groups (names per Microsoft public docs).
$irmRoleNames = @(
    'Insider Risk Management',              # super-group: grants everything — hold to a minimum
    'Insider Risk Management Admins',
    'Insider Risk Management Analysts',
    'Insider Risk Management Investigators',
    'Insider Risk Management Auditors'
)
$allRoleGroups = Get-RoleGroup -ErrorAction SilentlyContinue
$irmGroups = @($allRoleGroups | Where-Object { $_.Name -like 'Insider Risk*' })

$rows = @()
$memberIndex = @{}   # member -> list of IRM roles they hold (for conflict detection)
foreach ($name in $irmRoleNames) {
    $g = $irmGroups | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $g) {
        Write-Host ("  {0}: NOT PRESENT (verify in the Purview portal — role groups can vary by tenant/version)" -f $name) -ForegroundColor Yellow
        $rows += [pscustomobject]@{ RoleGroup = $name; Present = $false; MemberCount = 0 }
        continue
    }
    $members = @()
    try { $members = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) } catch {}
    foreach ($m in $members) {
        if (-not $memberIndex.ContainsKey($m)) { $memberIndex[$m] = @() }
        $memberIndex[$m] += $name
    }
    Write-Host ("  {0}: {1} member(s)" -f $name, $members.Count)
    $rows += [pscustomobject]@{ RoleGroup = $name; Present = $true; MemberCount = $members.Count }
}

# Conflict detection: same identity holding conflicting duties, or holding the super-group.
$conflicts = @()
foreach ($m in $memberIndex.Keys) {
    $held = $memberIndex[$m]
    $distinct = $held | Sort-Object -Unique
    # Super-group membership is always worth calling out.
    if ($distinct -contains 'Insider Risk Management') {
        $conflicts += ("{0} holds the ALL-POWERFUL 'Insider Risk Management' super-group ({1})" -f $m, ($distinct -join ', '))
    }
    # Analyst + Investigator (or +Admin) in one identity breaks separation of duties.
    $conflictPairs = @(
        @('Insider Risk Management Analysts','Insider Risk Management Investigators'),
        @('Insider Risk Management Admins','Insider Risk Management Investigators'),
        @('Insider Risk Management Admins','Insider Risk Management Analysts'),
        @('Insider Risk Management Auditors','Insider Risk Management Investigators')
    )
    foreach ($pair in $conflictPairs) {
        if (($distinct -contains $pair[0]) -and ($distinct -contains $pair[1])) {
            $conflicts += ("{0} holds conflicting roles: {1} + {2}" -f $m, $pair[0], $pair[1])
        }
    }
}
if ($conflicts.Count -gt 0) {
    Write-Host 'SEPARATION REVIEW — conflicts found:' -ForegroundColor Yellow
    $conflicts | Sort-Object -Unique | ForEach-Object { Write-Host "   * $_" -ForegroundColor Yellow }
} else {
    Write-Host 'Role separation: no conflicting membership detected across IRM roles.' -ForegroundColor Green
}

# --- Unified audit log (correlation substrate) ---
Write-Host '--- Unified audit log ---' -ForegroundColor Cyan
$auditOn = $null
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction SilentlyContinue
    $auditOn = [bool]$cfg.UnifiedAuditLogIngestionEnabled
} catch {}
if ($auditOn -eq $true) {
    Write-Host '  Unified audit log ingestion: ENABLED (PASS — IRM has a correlation substrate).' -ForegroundColor Green
} elseif ($auditOn -eq $false) {
    Write-Host '  Unified audit log ingestion: DISABLED (FAIL — enable before relying on IRM signal).' -ForegroundColor Yellow
} else {
    Write-Host '  Could not read audit config (check role/connection) — verify in the Purview portal.' -ForegroundColor Yellow
}

# --- Licensing signal (optional, via Microsoft Graph) ---
Write-Host '--- Licensing signal (verify your licensing/tenant) ---' -ForegroundColor Cyan
if (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue) {
    try {
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        $irmPlans = @()
        foreach ($sku in $skus) {
            foreach ($sp in $sku.ServicePlans) {
                if ($sp.ServicePlanName -match 'INSIDER|RISK') { $irmPlans += $sp.ServicePlanName }
            }
        }
        $irmPlans = $irmPlans | Sort-Object -Unique
        if ($irmPlans.Count -gt 0) {
            Write-Host ("  Insider-risk service plan signal present: {0}" -f ($irmPlans -join ', ')) -ForegroundColor Green
        } else {
            Write-Host '  No insider-risk service plan matched in subscribed SKUs — VERIFY your licensing/tenant in the admin center.' -ForegroundColor Yellow
        }
    } catch {
        Write-Host '  Could not query subscribed SKUs — verify licensing in the M365 admin center.' -ForegroundColor Yellow
    }
} else {
    Write-Host '  Microsoft Graph not connected. Run: Connect-MgGraph -Scopes Organization.Read.All  (then re-run) — or verify licensing in the admin center.' -ForegroundColor DarkCyan
}

# --- Portal checklist (the parts IRM does not expose to PowerShell) ---
Write-Host '--- Portal checklist (IRM is portal-configured — verify each in the Purview portal) ---' -ForegroundColor Cyan
@(
    'Privacy: anonymization ("Show anonymized versions of usernames") is ON  -> Settings > Privacy',
    'Indicators: only the MINIMUM required indicators enabled                -> Settings > Policy indicators',
    'Connectors: HR / Entra / DLP / Defender for Endpoint present & HEALTHY   -> Data Connectors / Settings',
    'Analytics: run the tenant scan (aggregated, anonymized, NO policy) first -> Insider Risk Management > Analytics',
    'Scope: priority-user group + readiness policy DISABLED/MINIMAL           -> Settings > Priority user groups / Policies'
) | ForEach-Object { Write-Host "   [ ] $_" -ForegroundColor DarkCyan }

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Role-group inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — set privacy-by-design, then separate roles (Implementation Phases 1-2).' -ForegroundColor Cyan
