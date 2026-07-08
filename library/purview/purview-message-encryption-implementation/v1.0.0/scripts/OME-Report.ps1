<#
.SYNOPSIS
    OME-Report.ps1 — summarize OME-encrypted mail flow from message trace, by rule/direction/day (read-only).
.DESCRIPTION
    PURPOSE
        Read-only reporting for Purview Message Encryption (OME). Uses message trace
        (Get-MessageTraceV2 / Get-MessageTrace) over a bounded window to produce a defensible rollup of
        mail that was processed by the OME rules — counts by sender/recipient-domain/day — without
        exposing message bodies. Maps to Testing Gate 9 (reporting reconciles with message trace).
        Message trace is authoritative; this is a summarizing convenience.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement; Connect-ExchangeOnline as an Exchange admin.
          .\OME-Report.ps1 -Days 7
          .\OME-Report.ps1 -Days 2 -SenderDomain contoso.com -SaveReport .\OME-Report.csv
    EXPECTED RESULTS
        A per-day / per-recipient-domain rollup of outbound messages in the window for the pilot senders,
        which you reconcile against message trace and (for Advanced external mail) Get-OMEMessageStatus.
.NOTES
    White-label. Read-only (no -Commit path). Exchange Online PowerShell. No credentials in code.
    Message trace does not label "encrypted" directly for every path — reconcile with the rule Audit
    results / Get-OMEMessageStatus. Retention of message trace is tenant-dependent — verify. No cmdlets invented.
#>

[CmdletBinding()]
param(
    [ValidateRange(1,10)]
    [int] $Days = 7,
    [string] $SenderDomain,                 # optional filter, e.g. contoso.com
    [string] $PilotGroup = 'SG-OME-Pilot@contoso.com',
    [string] $SaveReport
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not (Get-Command Get-TransportRule -ErrorAction SilentlyContinue)) {
    Write-Error 'Not connected to Exchange Online. Run Connect-ExchangeOnline with an Exchange admin, then retry.'
    return
}

$start = (Get-Date).AddDays(-1 * $Days)
$end   = Get-Date
Write-Section ("OME mail-flow summary — {0:yyyy-MM-dd} to {1:yyyy-MM-dd}" -f $start, $end)

# Resolve pilot senders so the report stays scoped to the pilot (avoids over-collection).
$senders = @()
try { $senders = @(Get-DistributionGroupMember -Identity $PilotGroup -ErrorAction Stop | Select-Object -ExpandProperty PrimarySmtpAddress) }
catch { Write-Host ("  Note: could not resolve '{0}' — reporting on all outbound in window (verify group)." -f $PilotGroup) -ForegroundColor Yellow }

# Prefer the newer paged cmdlet when present; fall back to Get-MessageTrace.
$trace = @()
try {
    if (Get-Command Get-MessageTraceV2 -ErrorAction SilentlyContinue) {
        $trace = @(Get-MessageTraceV2 -StartDate $start -EndDate $end -ErrorAction Stop)
    } else {
        $trace = @(Get-MessageTrace -StartDate $start -EndDate $end -ErrorAction Stop)
    }
} catch { Write-Warning ("Message trace query failed: {0}" -f $_.Exception.Message); return }

if ($senders.Count -gt 0) { $trace = $trace | Where-Object { $senders -contains $_.SenderAddress } }
if ($SenderDomain)        { $trace = $trace | Where-Object { $_.SenderAddress -match ('@' + [regex]::Escape($SenderDomain) + '$') } }

Write-Host ("Messages in window (scoped): {0}" -f @($trace).Count) -ForegroundColor Green

if (@($trace).Count -eq 0) {
    Write-Host 'No messages matched the scope/window. Widen -Days or check the pilot senders.' -ForegroundColor Yellow
    return
}

# Rollup by day + recipient domain (no bodies, no subjects retained).
$rows = foreach ($m in $trace) {
    $rcptDom = if ($m.RecipientAddress -match '@(.+)$') { $Matches[1] } else { '(unknown)' }
    [pscustomobject]@{
        Day             = ([datetime]$m.Received).ToString('yyyy-MM-dd')
        RecipientDomain = $rcptDom
        Status          = $m.Status
    }
}

Write-Section 'By day'
$rows | Group-Object Day | Sort-Object Name | Select-Object @{n='Day';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Section 'By recipient domain (top 15)'
$rows | Group-Object RecipientDomain | Sort-Object Count -Descending | Select-Object -First 15 @{n='RecipientDomain';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Section 'By delivery status'
$rows | Group-Object Status | Sort-Object Count -Descending | Select-Object @{n='Status';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host ''
Write-Host 'Reconcile this rollup with message trace in the portal and, for Advanced external mail,' -ForegroundColor Cyan
Write-Host 'with Get-OMEMessageStatus. Message trace is authoritative (Gate 9).'

if ($SaveReport) {
    try { $rows | Export-Csv -Path $SaveReport -NoTypeInformation -Encoding UTF8; Write-Host ("Saved: {0}" -f $SaveReport) -ForegroundColor Green }
    catch { Write-Warning ("Could not save report: {0}" -f $_.Exception.Message) }
}
