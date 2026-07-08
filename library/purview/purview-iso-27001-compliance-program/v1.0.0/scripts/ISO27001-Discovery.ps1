<#
.SYNOPSIS
    ISO27001-Discovery.ps1 — read-only Purview posture + ISO 27001 control-coverage baseline.
.DESCRIPTION
    PURPOSE
        Builds the baseline for an ISO 27001-aligned Purview program: whether unified audit logging is
        ON (the logging/monitoring evidence backbone for A.8.15/A.8.16), the existing sensitivity
        labels, DLP policies and their MODE (enforce vs simulation/test vs disabled), and retention
        policies present in the tenant, plus licensing signals (via Graph) that gate the ISO Compliance
        Manager template and advanced controls. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISO27001-Discovery.ps1 -CsvPath .\ISO27001-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement);
        optional Microsoft Graph (Connect-MgGraph) for the licensing signal.
    EXPECTED RESULTS
        A console summary of audit state, labels, DLP policies (Name/Mode), and retention policies, plus
        an optional CSV inventory. PASS signal: unified audit is enabled; high-impact policies you expect
        to be piloting report a simulation/test/disabled mode; anything already enforcing that you did
        not intend is flagged for review. Note: Compliance Manager assessments are portal-only and are
        not enumerated here.
.NOTES
    Purview — ISO 27001 Compliance Program. Read-only baseline. No changes made.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$UserPrincipalName
)

# --- Connect (modern auth / MFA). Reuses an existing session if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName }
    else { Connect-IPPSSession }
}

Write-Host '=== ISO 27001 Purview Posture Baseline (read-only) ===' -ForegroundColor Cyan

# --- Unified audit logging (A.8.15 Logging / A.8.16 Monitoring) ---
Write-Host '--- Unified audit logging (evidence backbone) ---' -ForegroundColor Cyan
$auditOn = $null
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $auditOn = $cfg.UnifiedAuditLogIngestionEnabled
} catch { Write-Host '  Could not read audit config (check role/connection).' -ForegroundColor Yellow }
if ($auditOn -eq $true) {
    Write-Host '  Unified audit logging: ENABLED (A.8.15/8.16 evidence available).' -ForegroundColor Green
} elseif ($auditOn -eq $false) {
    Write-Host '  Unified audit logging: DISABLED — enable it; audit data only accrues once ON.' -ForegroundColor Yellow
}

# --- Sensitivity labels (A.5.12 Classification / A.5.13 Labelling) ---
Write-Host '--- Sensitivity labels ---' -ForegroundColor Cyan
$labels = @()
if (Get-Command Get-Label -ErrorAction SilentlyContinue) {
    $labels = @(Get-Label -ErrorAction SilentlyContinue)
    Write-Host ("  Sensitivity labels defined: {0}" -f $labels.Count)
    if ($labels.Count -gt 0) { $labels | Select-Object DisplayName, Name | Format-Table -AutoSize }
} else {
    Write-Host '  Get-Label unavailable (role/licensing) — verify Information Protection access.' -ForegroundColor Yellow
}

# --- DLP policies and their mode (A.8.12 Data leakage prevention) ---
Write-Host '--- DLP policies (A.8.12) ---' -ForegroundColor Cyan
$dlpRows = @()
$dlp = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
$dlpRows = foreach ($p in $dlp) {
    # Enable = enforcing; Test* = SIMULATION; Disable = off
    [pscustomobject]@{
        Type       = 'DLP'
        Name       = $p.Name
        Mode       = $p.Mode
        Simulation = ($p.Mode -like 'Test*')
        Enforcing  = ($p.Mode -eq 'Enable')
        Enabled    = $p.Enabled
    }
}
if ($dlpRows) { $dlpRows | Sort-Object Name | Format-Table Name, Mode, Simulation, Enforcing -AutoSize }
else { Write-Host '  No DLP policies found.' -ForegroundColor Yellow }

# --- Retention policies (A.8.10 Information deletion / A.5.33 Protection of records) ---
Write-Host '--- Retention policies (A.8.10 / A.5.33) ---' -ForegroundColor Cyan
$retRows = @()
if (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue) {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)
    $retRows = foreach ($r in $ret) {
        [pscustomobject]@{
            Type      = 'Retention'
            Name      = $r.Name
            Mode      = $r.Mode
            Enabled   = $r.Enabled
            Simulation= ($r.Mode -like 'Test*')
            Enforcing = ($r.Enabled -eq $true -and $r.Mode -notlike 'Test*')
        }
    }
    if ($retRows) { $retRows | Sort-Object Name | Format-Table Name, Mode, Enabled -AutoSize }
    else { Write-Host '  No retention policies found.' -ForegroundColor Yellow }
} else {
    Write-Host '  Get-RetentionCompliancePolicy unavailable (role/licensing).' -ForegroundColor Yellow
}

# --- Flag anything enforcing that may need to be piloted first ---
$enforcing = @(@($dlpRows) + @($retRows) | Where-Object { $_.Enforcing })
if ($enforcing.Count -gt 0) {
    Write-Host ("REVIEW: {0} high-impact policy(ies) are ENFORCING — confirm each was piloted in simulation/test:" -f $enforcing.Count) -ForegroundColor Yellow
    $enforcing | ForEach-Object { Write-Host ("   * [{0}] {1}" -f $_.Type, $_.Name) -ForegroundColor Yellow }
} else {
    Write-Host 'No enforcing high-impact policies (all simulation/test/disabled) — expected during pilot build.' -ForegroundColor Green
}

# --- Licensing signal via Graph (gates the ISO template + advanced controls) ---
Write-Host '--- Licensing signal (ISO template + advanced controls) ---' -ForegroundColor Cyan
if (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue) {
    try {
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        $part = ($skus | Select-Object -ExpandProperty SkuPartNumber) -join ', '
        Write-Host ("  Subscribed SKUs: {0}" -f $part)
        Write-Host '  Verify E5 / E5 Compliance (or Compliance Manager Premium Assessment Add-On) for the ISO/IEC 27001 template and advanced DLP/labeling/Audit Premium.' -ForegroundColor Cyan
    } catch { Write-Host '  Could not read SKUs (run Connect-MgGraph -Scopes Organization.Read.All).' -ForegroundColor Yellow }
} else {
    Write-Host '  Microsoft Graph not connected — run Connect-MgGraph -Scopes Organization.Read.All for the licensing signal.' -ForegroundColor Yellow
}

# --- Optional CSV export ---
if ($CsvPath) {
    $all = @()
    $all += [pscustomobject]@{ Type='Audit'; Name='UnifiedAuditLogIngestion'; Mode=$auditOn; Simulation=''; Enforcing=''; Enabled=$auditOn }
    $all += $dlpRows
    $all += $retRows
    $all | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Posture inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — proceed to map Annex A controls and build simulation/test policies.' -ForegroundColor Cyan
