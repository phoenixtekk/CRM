<#
.SYNOPSIS
    DLPASSESS-Report.ps1 — read-only exposure/movement report that ranks sensitive-data categories for the roadmap.
.DESCRIPTION
    PURPOSE
        Builds the data-in-motion half of the map and the exposure ranking that drives the rollout
        roadmap. Reads simulation DLP matches from the unified audit log over a window and aggregates
        them by sensitive information type, workload, volume, and EXTERNAL exposure (shared-externally
        events) — then prints a simple ranked view (prevalence x external exposure) to prioritise which
        categories/locations to enforce first. Read-only — queries Search-UnifiedAuditLog only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPASSESS-Report.ps1 -Days 21 -CsvPath .\DLPASSESS-Movement.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and audit logging enabled (Req 2.3).
.EXAMPLE
    .\DLPASSESS-Report.ps1 -Days 14
    Prints movement + a ranked exposure view for the last 14 days.
.EXAMPLE
    .\DLPASSESS-Report.ps1 -Days 30 -CsvPath .\DLPASSESS-Movement.csv
    Same over 30 days and exports the per-event movement CSV.
.NOTES
    Purview — Enterprise DLP Assessment & Strategy. Read-only reporting from the unified audit log; no
    changes. EXPECTED RESULTS: matches by SIT/workload/exposure and a ranked category list. PASS gate:
    a defensible ranking feeding 'DLP Roadmap - Prioritized - Strategy'. If empty, allow dwell time /
    confirm the simulation baseline is live and audit logging is on.
#>
[CmdletBinding()]
param(
    [int]$Days = 21,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$start = (Get-Date).AddDays(-$Days)
$end   = Get-Date
# DLP record types across the cloud locations the monitor-only baseline covers.
$recordTypes = 'ComplianceDLPExchange','ComplianceDLPSharePoint'

Write-Host ("=== DLP exposure/movement: {0:yyyy-MM-dd} to {1:yyyy-MM-dd} ({2} days, read-only) ===" -f $start, $end, $Days) -ForegroundColor Cyan

$events = @()
foreach ($rt in $recordTypes) {
    $sessionId = "DLPASSESS-$rt-$(Get-Random)"
    do {
        $batch = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt `
                    -SessionId $sessionId -SessionCommand ReturnLargeSet -ResultSize 5000 -ErrorAction SilentlyContinue
        if ($batch) { $events += $batch }
    } while ($batch -and $batch.Count -eq 5000)
}

if (-not $events -or $events.Count -eq 0) {
    Write-Host 'No DLP simulation matches found in the window.' -ForegroundColor Yellow
    Write-Host 'Check: baseline is live and in simulation (DLPASSESS-Discovery), audit logging on (DLPASSESS-Validation), and allow dwell time.' -ForegroundColor Yellow
    return
}

$rows = foreach ($e in $events) {
    $d = $null
    try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    $sit = $null; $action = $null; $external = $false; $policy = $null
    if ($d) {
        if ($d.PolicyDetails) {
            $policy = ($d.PolicyDetails | ForEach-Object { $_.PolicyName }) -join '; '
            $rule = $d.PolicyDetails.Rules | Select-Object -First 1
            if ($rule) {
                $action = ($rule.Actions -join ', ')
                if ($rule.ConditionsMatched -and $rule.ConditionsMatched.SensitiveInformation) {
                    $sit = ($rule.ConditionsMatched.SensitiveInformation | ForEach-Object { $_.SensitiveInformationTypeName }) -join '; '
                }
            }
        }
        # External-exposure signal: SharePoint/OneDrive external sharing or external mail recipients.
        if ($d.SharingType -match 'External' -or $d.TargetDomain) { $external = $true }
        if ($d.Recipients) { if (($d.Recipients -join ',') -notmatch '@contoso\.com') { $external = $true } }
    }
    [pscustomobject]@{
        TimeUtc  = $e.CreationDate
        Workload = $e.RecordType
        User     = $e.UserIds
        Policy   = $policy
        SIT      = $sit
        Action   = $action
        External = $external
    }
}

Write-Host '--- Matches by workload ---' -ForegroundColor Cyan
$rows | Group-Object Workload | Sort-Object Count -Descending |
    Select-Object @{n='Workload';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host '--- Ranked exposure by sensitive information type (prevalence + external exposure) ---' -ForegroundColor Cyan
$ranking = $rows | Where-Object SIT | Group-Object SIT | ForEach-Object {
    $ext = @($_.Group | Where-Object External).Count
    [pscustomobject]@{
        SIT           = $_.Name
        Matches       = $_.Count
        ExternalExp   = $ext
        # Simple, transparent score — weight external exposure 2x. Agree the weighting with stakeholders.
        ExposureScore = $_.Count + (2 * $ext)
    }
} | Sort-Object ExposureScore -Descending
$ranking | Format-Table -AutoSize

Write-Host ("Total DLP simulation match events: {0}" -f $rows.Count) -ForegroundColor Green
Write-Host 'Highest ExposureScore = strongest candidate to enforce first (ratify scope/action with compliance/legal).' -ForegroundColor Cyan

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Per-event movement exported to {0}. Feed the ranking into 'DLP Roadmap - Prioritized - Strategy'." -f $CsvPath) -ForegroundColor Green
} else {
    Write-Host 'Tip: pass -CsvPath to export the per-event movement data for the roadmap.' -ForegroundColor Cyan
}
