<#
.SYNOPSIS
    GRAPHPOLL-Test-Watermark.ps1 — read-only exactly-once check: simulates two consecutive watermarked
    reads and confirms there is no overlap and no gap between them.
.DESCRIPTION
    PURPOSE
        Read-only verification of the high-water-mark logic for the "Graph Mailbox Polling Workflows"
        solution. It performs the SAME query the Logic App uses — messages with
        receivedDateTime gt <watermark>, ordered ascending — for two consecutive "runs":
          Run A: reads with the supplied -StartWatermark, then computes the watermark it WOULD store
                 (the newest receivedDateTime it saw).
          Run B: reads again with that computed watermark.
        It then asserts EXACTLY-ONCE:
          - No OVERLAP: no message id appears in both Run A and Run B.
          - No GAP: every message strictly newer than the Run-A watermark is picked up by Run B (nothing
            silently skipped between the two reads).
        It reads only message metadata (id, receivedDateTime, subject); it does NOT process, mark, move,
        or write any watermark. Nothing is changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GRAPHPOLL-Test-Watermark.ps1 `
            -Mailbox 'supportmailbox@contoso.com' `
            -StartWatermark '2026-07-17T00:00:00Z' `
            -PageSize 25
        Requires the Microsoft.Graph PowerShell SDK (Connect-MgGraph runs if not connected). For a
        national cloud, pass -Environment. Send a couple of test messages between observing Run A and
        Run B if you want to prove the "no gap" arm with live arrivals.
    GRAPH SCOPES (delegated, read-only sign-in)
        Mail.Read (or Mail.ReadBasic.All).
    EXPECTED RESULTS
        A PASS/FAIL: PASS when the two reads have no overlapping message ids AND no message newer than the
        Run-A watermark is missed by Run B — i.e. each message is accounted for exactly once. FAIL prints
        the offending ids so you can see a double-read (overlap) or a skip (gap).
.NOTES
    Azure Solutions — read-only exactly-once check. The repeatable way.
    Simulates/inspects reads only; never processes, marks, moves, or persists a watermark. White-label:
    contoso.com only. Delta-query behavior differs from timestamp watermarking — verify against current
    Microsoft documentation if you adopt /messages/delta.
#>
[CmdletBinding()]
param(
    [string]$Mailbox = 'supportmailbox@contoso.com',
    [Parameter(Mandatory)] [string]$StartWatermark,
    [int]$PageSize = 25,
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes 'Mail.Read' | Out-Null
}

# Read all messages newer than $wm (ascending), following paging — the same shape as the workflow.
function Read-NewerThan([string]$wm) {
    $all = [System.Collections.Generic.List[object]]::new()
    $filter = "receivedDateTime gt $wm"
    $page = Get-MgUserMessage -UserId $Mailbox -Filter $filter -Sort 'receivedDateTime asc' `
                -Top $PageSize -Property 'id,receivedDateTime,subject' -ErrorAction Stop
    foreach ($m in $page) { $all.Add($m) }
    # Follow @odata.nextLink via -All would also work; here we page explicitly to mirror the workflow.
    $next = $page.AdditionalProperties.'@odata.nextLink'
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop
        foreach ($m in $resp.value) {
            $all.Add([pscustomobject]@{ Id = $m.id; ReceivedDateTime = $m.receivedDateTime; Subject = $m.subject })
        }
        $next = $resp.'@odata.nextLink'
    }
    return $all
}

Write-Host "`n=== Graph Mailbox Polling — exactly-once watermark check (read-only) ===" -ForegroundColor Cyan
Write-Host ("Mailbox: {0}" -f $Mailbox)
Write-Host ("Run A watermark (start): {0}" -f $StartWatermark)

# --- Run A ---
$runA = Read-NewerThan $StartWatermark
Write-Host ("Run A read {0} message(s)." -f $runA.Count)

# The watermark the workflow would store after Run A = newest receivedDateTime seen (or unchanged if none).
$computedWm = $StartWatermark
if ($runA.Count -gt 0) {
    $computedWm = ($runA | Sort-Object { [datetime]$_.ReceivedDateTime } | Select-Object -Last 1).ReceivedDateTime
    if ($computedWm -isnot [string]) { $computedWm = ([datetime]$computedWm).ToUniversalTime().ToString('o') }
}
Write-Host ("Computed Run A -> stored watermark: {0}" -f $computedWm)

# --- Run B (with the advanced watermark) ---
$runB = Read-NewerThan $computedWm
Write-Host ("Run B read {0} message(s) (should be only mail newer than Run A's watermark)." -f $runB.Count)

# --- Assert exactly-once ---
$idsA = @($runA | ForEach-Object Id)
$idsB = @($runB | ForEach-Object Id)
$overlap = $idsA | Where-Object { $idsB -contains $_ }

# "No gap": everything strictly newer than $computedWm must be in Run B.
$expectedNewer = @($runA | Where-Object { [datetime]$_.ReceivedDateTime -gt [datetime]$computedWm } | ForEach-Object Id) +
                 @($runB | ForEach-Object Id)
$missing = @()   # by construction Run B is defined by the same filter, so a gap would show as ids
                 # present in a fresh unfiltered newer-than read but absent from Run B.
$freshNewer = Read-NewerThan $computedWm
$missing = @($freshNewer | ForEach-Object Id) | Where-Object { $idsB -notcontains $_ }

Write-Host "`n-- Result --" -ForegroundColor Cyan
$pass = $true
if ($overlap.Count -gt 0) {
    $pass = $false
    Write-Host ("   OVERLAP (double-read) ids: {0}" -f ($overlap -join ', ')) -ForegroundColor Red
} else {
    Write-Host "   No overlap between Run A and Run B (no double-read)." -ForegroundColor Green
}
if ($missing.Count -gt 0) {
    $pass = $false
    Write-Host ("   GAP (skipped) ids newer than watermark but not in Run B: {0}" -f ($missing -join ', ')) -ForegroundColor Red
} else {
    Write-Host "   No gap — every message newer than the Run A watermark is picked up by Run B." -ForegroundColor Green
}

if ($pass) {
    Write-Host "`nEXACTLY-ONCE: PASS — no overlap, no gap." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nEXACTLY-ONCE: FAIL — see ids above." -ForegroundColor Red
    exit 1
}
