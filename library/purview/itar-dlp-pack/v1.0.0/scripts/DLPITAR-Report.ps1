<#
.SYNOPSIS
    DLPITAR-Report.ps1 — read-only ITAR technical-data egress evidence report from the unified audit log (safe: read-only).
.DESCRIPTION
    PURPOSE
        Produces the "ITAR DLP Evidence - Egress - Report" artifact: the DLP rule matches for the ITAR
        technical-data policy over a time window, broken down by workload and recipient/scope so you can
        (a) tune true-positive vs false-positive during the pilot and (b) evidence what the policy detects
        and the admin action once enforcing. Works for policies in SIMULATION and in enforcement —
        simulation matches are logged the same way. Read-only: queries Search-UnifiedAuditLog only and
        changes nothing. (Activity Explorer in the portal and Microsoft Graph security alerts are
        equivalent sources — verify availability against your licensing/tenant.)
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPITAR-Report.ps1 -Days 14 -CsvPath .\ITAR-DLP-Evidence.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and audit logging enabled in the tenant.
    EXAMPLE
        .\DLPITAR-Report.ps1 -Days 14 -CsvPath .\ITAR-DLP-Evidence.csv
        Summarises matches by workload and policy and exports a per-event CSV with a blank Disposition column.
    NOTES
        White-label. Read-only reporting from the unified audit log. No changes made. No credentials in code.
        Expected results: during pilot, classify each row TP/FP and compute FP rate = FP / (TP+FP); when
        enforcing, the report is the evidence you show a reviewer. Verify capability/paths against your tenant.
#>
[CmdletBinding()]
param(
    [int] $Days = 14,
    [string] $PolicyName = 'ITAR Technical-Data Egress - AllWorkloads - Pilot',
    [string] $CsvPath,
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
}

$start = (Get-Date).AddDays(-$Days)
$end   = Get-Date
# DLP record types across the workloads this solution covers (Endpoint included where licensed/onboarded).
$recordTypes = 'ComplianceDLPExchange','ComplianceDLPSharePoint','DLPEndpoint'

Write-Host ("=== ITAR DLP Evidence - Egress - Report: {0:yyyy-MM-dd} to {1:yyyy-MM-dd} ({2} days) ===" -f $start, $end, $Days) -ForegroundColor Cyan

$events = @()
foreach ($rt in $recordTypes) {
    $sessionId = "DLPITAR-$rt-$(Get-Random)"
    do {
        $batch = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt `
                    -SessionId $sessionId -SessionCommand ReturnLargeSet -ResultSize 5000 -ErrorAction SilentlyContinue
        if ($batch) { $events += $batch }
    } while ($batch -and $batch.Count -eq 5000)
}

if (-not $events -or $events.Count -eq 0) {
    Write-Host 'No DLP matches found in the window. If the policy is freshly created, allow dwell time and re-run.' -ForegroundColor Yellow
    return
}

$rows = foreach ($e in $events) {
    $d = $null
    try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    $policy = $null; $rule = $null; $sit = $null; $action = $null; $scope = $null
    if ($d -and $d.PolicyDetails) {
        $policy = ($d.PolicyDetails | ForEach-Object { $_.PolicyName }) -join '; '
        $r = $d.PolicyDetails.Rules | Select-Object -First 1
        if ($r) {
            $rule   = $r.RuleName
            $action = ($r.Actions -join ', ')
            if ($r.ConditionsMatched -and $r.ConditionsMatched.SensitiveInformation) {
                $sit = ($r.ConditionsMatched.SensitiveInformation | ForEach-Object { $_.SensitiveInformationTypeName }) -join '; '
            }
        }
    }
    # Recipient / external-share scope is the ITAR-relevant egress signal for the evidence artifact.
    if ($d) {
        if ($d.Recipients)          { $scope = ($d.Recipients -join '; ') }
        elseif ($d.SharingType)     { $scope = $d.SharingType }
        elseif ($d.TargetUserOrGroupName) { $scope = $d.TargetUserOrGroupName }
    }
    [pscustomobject]@{
        TimeUtc     = $e.CreationDate
        Workload    = $e.RecordType
        User        = $e.UserIds
        Policy      = $policy
        Rule        = $rule
        SIT         = $sit
        EgressScope = $scope
        Action      = $action
        Disposition = ''   # <-- mark TP or FP here during pilot tuning
    }
}

# Optionally focus on the ITAR policy when many DLP policies are logging.
$itarRows = @($rows | Where-Object { -not $_.Policy -or $_.Policy -match [regex]::Escape($PolicyName) })
if ($itarRows.Count -eq 0) { $itarRows = $rows }

Write-Host '--- Matches by workload ---' -ForegroundColor Cyan
$itarRows | Group-Object Workload | Sort-Object Count -Descending |
    Select-Object @{n='Workload';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host '--- Matches by policy ---' -ForegroundColor Cyan
$itarRows | Where-Object Policy | Group-Object Policy | Sort-Object Count -Descending |
    Select-Object @{n='Policy';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host ("Total DLP match events (ITAR-scoped): {0}" -f $itarRows.Count) -ForegroundColor Green

if ($CsvPath) {
    $itarRows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Exported 'ITAR DLP Evidence - Egress - Report' to {0}. During pilot, classify TP/FP; when enforcing, retain as evidence." -f $CsvPath) -ForegroundColor Green
} else {
    Write-Host 'Tip: pass -CsvPath to export the evidence artifact for TP/FP classification and reviewer retention.' -ForegroundColor Cyan
}
