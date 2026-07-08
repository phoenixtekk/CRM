<#
.SYNOPSIS
    DLPPRINT-Report.ps1 — export endpoint Print DLP activity (matches, overrides, printers) over N days for FP/alert review (read-only).
.DESCRIPTION
    PURPOSE
        Pulls endpoint DLP Print activity from the unified audit log over the last N days so you can
        measure the simulation/enforcement result: how many prints matched, which sensitive-information
        types/labels fired, which printers were involved, and how many were overridden. Use it to
        classify true vs false positives during tuning (Implementation Phase 3) and to watch drift in
        operations (Phase 5). Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPPRINT-Report.ps1 -Days 14 -CsvPath .\DLPPRINT-Activity.csv
        Requires ExchangeOnlineManagement + audit-log read (Connect-IPPSSession / Connect-ExchangeOnline).
        Unified audit log must be enabled in the tenant.
    EXPECTED RESULTS
        A console summary (total print-DLP events, unique users, unique printers, override count) and an
        optional CSV of the raw events for classification. If nothing returns, confirm the policy has run
        long enough and the audit log is enabled. No changes are made.
.NOTES
    Purview category — Print DLP (Endpoint DLP). Read-only. Audit schema evolves — verify field names against
    current Microsoft guidance / your tenant.
#>
[CmdletBinding()]
param(
    [int]$Days       = 14,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    Write-Host "Connecting to Security & Compliance PowerShell..." -ForegroundColor Cyan
    Connect-IPPSSession -ErrorAction Stop | Out-Null
}

$start = (Get-Date).AddDays(-1 * [math]::Abs($Days))
$end   = Get-Date
Write-Host ("`n=== Endpoint Print DLP activity, last {0} day(s) ===" -f $Days) -ForegroundColor Cyan

# Endpoint DLP events surface under the DLPEndpoint record type; filter to print operations.
$raw = @()
try {
    $raw = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType 'DLPEndpoint' -ResultSize 5000 -ErrorAction Stop
} catch {
    Write-Host "Unable to query the audit log — confirm it is enabled and you have audit-read rights." -ForegroundColor Yellow
    return
}

$events = @()
foreach ($e in $raw) {
    $d = $null; try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    if (-not $d) { continue }
    $op = "$($d.Operation)$($d.EndpointMetaData.EnforcementMode)$($d.Verb)$($d.Application)"
    # Keep events that reference a print activity.
    $isPrint = ($op -match 'Print') -or ("$($d.EndpointMetaData.Application)" -match 'print') -or ("$($d.PolicyDetails.Rules.Actions)" -match 'Print')
    if (-not $isPrint) { continue }
    $events += [pscustomobject]@{
        TimeUtc     = $e.CreationDate
        User        = $d.UserId
        Device      = $d.EndpointMetaData.DeviceName
        Printer     = $d.EndpointMetaData.PrinterName
        PrinterType = $d.EndpointMetaData.PrintType
        Action      = $d.EndpointMetaData.EnforcementMode
        Overridden  = $d.EndpointMetaData.Justification
        Policy      = ($d.PolicyDetails.PolicyName -join '; ')
        SIT         = ($d.PolicyDetails.Rules.ConditionsMatched.SensitiveInformation.SensitiveInformationTypeName -join '; ')
        FileName    = $d.ObjectId
    }
}

$total     = @($events).Count
$users     = @($events | Select-Object -ExpandProperty User -Unique).Count
$printers  = @($events | Where-Object { $_.Printer } | Select-Object -ExpandProperty Printer -Unique).Count
$overrides = @($events | Where-Object { $_.Overridden }).Count

Write-Host "`n-- Summary --" -ForegroundColor Cyan
Write-Host ("Print DLP events : {0}" -f $total) -ForegroundColor $(if ($total -gt 0) { 'Green' } else { 'Gray' })
Write-Host ("Unique users     : {0}" -f $users)
Write-Host ("Unique printers  : {0}" -f $printers)
Write-Host ("Overrides        : {0}" -f $overrides) -ForegroundColor $(if ($overrides -gt 0) { 'Yellow' } else { 'Gray' })
if ($total -eq 0) {
    Write-Host "No print-DLP events — confirm the policy has run through some printing and the audit log is enabled." -ForegroundColor Yellow
}

if ($CsvPath -and $total -gt 0) {
    $events | Sort-Object TimeUtc | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} event(s) to {1} — classify each true/false positive for tuning (Phase 3)." -f $total, $CsvPath) -ForegroundColor Cyan
}
