<#
.SYNOPSIS
  Scope/diagnostic helper: runs a message trace, pulls trace detail, and parses message headers to show
  the hop path, connectors, SCL/spam verdict, and SPF/DKIM/DMARC results. Read-only.
.DESCRIPTION
  Supports the layered mail-flow diagnostic (trace -> headers -> queues). Given a sender/recipient and a
  time window it runs Get-MessageTraceV2 (or Get-MessageTrace) and, for a chosen message, retrieves the
  per-hop detail. If a raw header block is provided (-HeaderFile), it parses the Received: chain and the
  Authentication-Results / Received-SPF / X-*-Antispam headers to summarize path, connector, SCL, and
  auth outcomes. On-prem queue/SMTP-log inspection (the third layer) is done on the hybrid transport
  server with Get-Queue and is out of this cloud helper's scope - the notes below say where to look.
.EXAMPLE
  .\Get-MailFlowTraceHelper.ps1 -SenderAddress pilot-tx@contoso.com -HoursBack 6
  .\Get-MailFlowTraceHelper.ps1 -HeaderFile .\message-headers.txt   # parse a saved header block
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: a trace table and, for a selected/most-recent message, its per-hop detail; when a
  header file is given, a parsed summary of the Received chain, SCL, and SPF/DKIM/DMARC results. Points
  to on-prem Get-Queue for legs cloud trace cannot see.
#>

[CmdletBinding()]
param(
    [string]$SenderAddress,
    [string]$RecipientAddress,
    [int]$HoursBack = 6,
    [string]$MessageId,        # optional: pull detail for a specific message
    [string]$HeaderFile,       # optional: parse a saved raw-header block
    [string]$AdminUpn
)

$ErrorActionPreference = 'Stop'

function Confirm-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement."
    }
    try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
    catch {
        if ($AdminUpn) { Connect-ExchangeOnline -UserPrincipalName $AdminUpn -ShowBanner:$false }
        else { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

# --- Header parsing (works offline; no connection needed) --------------------
function Parse-MessageHeaders {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Header file not found: $Path" }
    $raw = Get-Content -Path $Path -Raw

    Write-Host "`n== Parsed message headers ==" -ForegroundColor Cyan

    # Received: chain (bottom-up = actual path). Each 'Received:' begins a hop.
    $received = [regex]::Matches($raw, '(?im)^Received:\s(.*?)(?=^\S|\Z)', 'Singleline') |
        ForEach-Object { ($_.Groups[1].Value -replace '\s+', ' ').Trim() }
    Write-Host "Received hops (top = most recent):" -ForegroundColor Green
    $i = 0
    foreach ($h in $received) { Write-Host ("  [{0}] {1}" -f $i++, ($h.Substring(0, [Math]::Min(160, $h.Length)))) }
    if ($received.Count -ge 25) {
        Write-Host "  [WARN] $($received.Count) Received hops - unusually long path; check for a routing loop." -ForegroundColor Yellow
    }

    function Show-Header([string]$label, [string]$pattern) {
        $m = [regex]::Match($raw, $pattern, 'IgnoreCase, Singleline')
        if ($m.Success) { Write-Host ("{0}: {1}" -f $label, ($m.Groups[1].Value -replace '\s+',' ').Trim()) -ForegroundColor Green }
        else { Write-Host ("{0}: (not present)" -f $label) -ForegroundColor DarkYellow }
    }
    Write-Host "`nAuthentication & hygiene:" -ForegroundColor Green
    Show-Header 'Authentication-Results' '(?im)^Authentication-Results:\s(.*?)(?=^\S)'
    Show-Header 'Received-SPF'           '(?im)^Received-SPF:\s(.*?)(?=^\S)'
    Show-Header 'X-Forefront-Antispam'   '(?im)^X-Forefront-Antispam-Report:\s(.*?)(?=^\S)'
    Show-Header 'X-MS-Exchange-Org-SCL'  '(?im)^X-MS-Exchange-Organization-SCL:\s(.*?)(?=^\S)'

    # SPF/DKIM/DMARC quick verdicts out of Authentication-Results
    $ar = [regex]::Match($raw, '(?im)^Authentication-Results:\s(.*?)(?=^\S)', 'Singleline')
    if ($ar.Success) {
        foreach ($mech in 'spf','dkim','dmarc') {
            $v = [regex]::Match($ar.Groups[1].Value, "$mech=(\w+)", 'IgnoreCase')
            if ($v.Success) { Write-Host ("  {0} = {1}" -f $mech.ToUpper(), $v.Groups[1].Value) }
        }
    }
}

if ($HeaderFile) {
    Parse-MessageHeaders -Path $HeaderFile
    Write-Host "`n(Third layer) For on-prem legs cloud trace can't see, on the hybrid transport server run:" -ForegroundColor DarkCyan
    Write-Host "    Get-Queue ; Get-Message -Queue <q> ; and review protocol/connectivity logs (Get-TransportService | fl *LogPath*)." -ForegroundColor DarkCyan
    return
}

# --- Message trace (needs connection) ---------------------------------------
Confirm-ExoConnected
$tp = @{ StartDate = (Get-Date).AddHours(-1 * $HoursBack); EndDate = (Get-Date) }
if ($SenderAddress)    { $tp['SenderAddress']    = $SenderAddress }
if ($RecipientAddress) { $tp['RecipientAddress'] = $RecipientAddress }
if ($MessageId)        { $tp['MessageId']        = $MessageId }

$useV2 = [bool](Get-Command Get-MessageTraceV2 -ErrorAction SilentlyContinue)
$trace = if ($useV2) { Get-MessageTraceV2 @tp } else { Get-MessageTrace @tp }

if (-not $trace) {
    Write-Host "No trace rows in the last $HoursBack h for the given filter. Widen -HoursBack or use historical search (Start-HistoricalSearch) for older mail." -ForegroundColor Yellow
    return
}

Write-Host "`n== Message trace (last $HoursBack h) ==" -ForegroundColor Cyan
$trace | Select-Object Received, SenderAddress, RecipientAddress, Subject, Status | Format-Table -AutoSize

# Per-hop detail for the most recent (or specified) message
$target = $trace | Sort-Object Received -Descending | Select-Object -First 1
Write-Host "`nPulling per-hop detail for MessageId $($target.MessageId) ..." -ForegroundColor Cyan
try {
    $detailCmd = if (Get-Command Get-MessageTraceDetailV2 -ErrorAction SilentlyContinue) { 'Get-MessageTraceDetailV2' } else { 'Get-MessageTraceDetail' }
    & $detailCmd -MessageTraceId $target.MessageTraceId -RecipientAddress $target.RecipientAddress -ErrorAction Stop |
        Select-Object Date, Event, Action, Detail | Format-Table -AutoSize
} catch {
    Write-Host "Trace detail unavailable: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

Write-Host "`nNext: export the message headers and re-run with -HeaderFile to parse the Received chain / SCL / auth results." -ForegroundColor DarkCyan
Write-Host "For on-prem legs, inspect Get-Queue and protocol logs on the hybrid transport server." -ForegroundColor DarkCyan
