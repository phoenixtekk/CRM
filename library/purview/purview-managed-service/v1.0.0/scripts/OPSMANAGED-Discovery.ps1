<#
.SYNOPSIS
    OPSMANAGED-Discovery.ps1 — capture the Purview estate + operational signals as the monitoring baseline (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell (and Exchange Online for the unified-audit-log status)
        and inventories the estate the managed service operates: DLP policies with their Mode, sensitivity
        labels + label policies, retention/lifecycle policies + retention labels, unified-audit-log status,
        insider-risk policy PRESENCE + privacy posture (posture only), and compliance role groups. This is
        `Managed Service – Monitoring Baseline` — the reference the service watches for drift. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Discovery.ps1 -CsvPath .\opsmanaged-baseline.csv
        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline), MFA-capable read
        admin. Verify capability availability against your licensing/tenant.
    EXPECTED RESULTS
        A read-only baseline: DLP (Name/Mode/Enabled), label + label-policy counts, retention + labels,
        unified-audit-log ON/OFF, IRM presence/posture note, role-group membership. Save it as the baseline
        the daily monitoring sweep compares against.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
#>
[CmdletBinding()]
param(
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
$baseline = New-Object System.Collections.Generic.List[object]
function Add-Row($Area, $Name, $State) { $baseline.Add([pscustomobject]@{ Area = $Area; Name = $Name; State = $State }) }

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession | Out-Null }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); return }

Write-Section 'DLP policies (with Mode)'
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    if ($dlp.Count -eq 0) { Write-Host 'No DLP policies found.' -ForegroundColor Yellow }
    else { $dlp | Select-Object Name, Mode, Enabled, Workload | Format-Table -AutoSize
           foreach ($p in $dlp) { Add-Row 'DLP' $p.Name ("Mode={0}; Enabled={1}" -f $p.Mode, $p.Enabled) } }
}
catch { Write-Warning ("DLP unreadable: {0}" -f $_.Exception.Message) }

Write-Section 'Sensitivity labels & label policies'
try {
    $labels = @(Get-Label -ErrorAction Stop); $lp = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
    Write-Host ("Labels: {0}   Label policies: {1}" -f $labels.Count, $lp.Count)
    Add-Row 'Labels' 'Sensitivity labels' ("count={0}" -f $labels.Count)
    Add-Row 'Labels' 'Label policies' ("count={0}" -f $lp.Count)
}
catch { Write-Warning ("Labels unreadable: {0}" -f $_.Exception.Message) }

Write-Section 'Retention / data-lifecycle'
try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop); $rl = @(Get-ComplianceTag -ErrorAction SilentlyContinue)
    Write-Host ("Retention policies: {0}   Retention labels: {1}" -f $ret.Count, $rl.Count)
    $ret | Select-Object Name, Enabled, Mode | Format-Table -AutoSize
    foreach ($p in $ret) { Add-Row 'Retention' $p.Name ("Enabled={0}; Mode={1}" -f $p.Enabled, $p.Mode) }
    Write-Host 'NOTE: retention SCHEDULE correctness is a records/legal determination — defer.' -ForegroundColor DarkYellow
}
catch { Write-Warning ("Retention unreadable: {0}" -f $_.Exception.Message) }

Write-Section 'Unified audit log status'
try {
    if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
    $ual = (Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
    Write-Host ("Unified audit log: {0}" -f ($(if($ual){'ON'}else{'OFF'}))) -ForegroundColor $(if($ual){'Green'}else{'Red'})
    Add-Row 'Audit' 'Unified audit log' ($(if($ual){'ON'}else{'OFF (High-severity — the estate is un-evidenced)'}))
}
catch { Write-Warning ("Audit-log status unreadable: {0} — verify Exchange Online access." -f $_.Exception.Message) }

Write-Section 'Insider Risk presence + privacy posture (posture only)'
if (Get-Command Get-InsiderRiskPolicy -ErrorAction SilentlyContinue) {
    try { $irm = @(Get-InsiderRiskPolicy -ErrorAction Stop); Write-Host ("Insider-risk policies present: {0} (presence only)." -f $irm.Count); Add-Row 'IRM' 'Insider-risk policies' ("presence={0}" -f $irm.Count) }
    catch { Write-Host 'Insider-risk not readable via cmdlet — confirm PRESENCE + privacy posture in the portal.' }
} else {
    Write-Host 'Get-InsiderRiskPolicy not available (IRM largely portal-managed). Confirm presence + privacy posture in the portal — posture ONLY, never case contents.'
}

Write-Section 'Compliance role groups'
try {
    $rg = @(Get-RoleGroup -ErrorAction Stop)
    foreach ($g in $rg) { $m = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue); Add-Row 'Roles' $g.Name ("members={0}" -f $m.Count) }
    Write-Host ("Role groups: {0}" -f $rg.Count)
}
catch { Write-Warning ("Role groups unreadable: {0}" -f $_.Exception.Message) }

Write-Section 'Baseline complete'
if ($CsvPath) { $baseline | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Baseline written to {0}" -f $CsvPath) -ForegroundColor Green }
Write-Host 'Save this as `Managed Service – Monitoring Baseline`. Next: OPSMANAGED-Monitor.ps1 (daily sweep).'
