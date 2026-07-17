<#
.SYNOPSIS
    GRAPHPOLL-Report.ps1 — processing / backlog report for the "Graph Mailbox Polling Workflows in Azure
    Logic Apps (Managed Identity, No Service Account)" solution, with CSV export.
.DESCRIPTION
    PURPOSE
        Read-only reporting. Produces a per-mailbox snapshot: Inbox total / unread count, the count in the
        'Processed' idempotency folder, the newest message receivedDateTime, and the last-processed
        watermark currently stored — so you can see backlog trend and confirm the high-water mark is
        advancing. Exports the same to CSV. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GRAPHPOLL-Report.ps1 `
            -Mailbox 'supportmailbox@contoso.com' `
            -StoredWatermark '2026-07-17T12:00:00Z' `
            -CsvPath .\GRAPHPOLL-report.csv
        Requires the Microsoft.Graph PowerShell SDK (Connect-MgGraph runs if not connected). Pass the
        current -StoredWatermark you read from your watermark store (table 'mailpollingwatermark'), or
        omit it to report counts only. For a national cloud, pass -Environment.
    GRAPH SCOPES (delegated, read-only sign-in)
        Mail.Read (or Mail.ReadBasic.All), Directory.Read.All.
    EXPECTED RESULTS
        A console table + CSV: Inbox total/unread, Processed count, newest receivedDateTime, and the
        stored watermark — the evidence that the poller is keeping up and the watermark is moving forward.
.NOTES
    Azure Solutions — read-only reporting. The repeatable way.
    Reports only; makes no changes to mailboxes, messages, or the watermark. White-label: contoso.com only.
    Backlog thresholds are informational; verify Graph limits against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$Mailbox = 'supportmailbox@contoso.com',
    [string]$StoredWatermark,
    [string]$CsvPath = ".\GRAPHPOLL-report.csv",
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes 'Mail.Read','Directory.Read.All' | Out-Null
}

Write-Host "`n=== Graph Mailbox Polling — processing/backlog report ===" -ForegroundColor Cyan
Write-Host ("Mailbox: {0}" -f $Mailbox)

$inboxTotal = $null; $inboxUnread = $null; $processedCount = $null; $newest = $null

try {
    $inbox = Get-MgUserMailFolder -UserId $Mailbox -MailFolderId 'Inbox' -ErrorAction Stop
    $inboxTotal  = $inbox.TotalItemCount
    $inboxUnread = $inbox.UnreadItemCount
} catch {
    Write-Host ("   Could not read Inbox: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

try {
    $processed = Get-MgUserMailFolder -UserId $Mailbox -All -ErrorAction SilentlyContinue |
                 Where-Object DisplayName -eq 'Processed' | Select-Object -First 1
    if ($processed) { $processedCount = $processed.TotalItemCount }
} catch { }

try {
    # Newest message by receivedDateTime — the value the watermark should be at (or past).
    $top = Get-MgUserMessage -UserId $Mailbox -Top 1 -Sort 'receivedDateTime desc' `
            -Property 'receivedDateTime,subject,id' -ErrorAction Stop
    if ($top) { $newest = $top.ReceivedDateTime }
} catch {
    Write-Host ("   Could not read newest message: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

$row = [pscustomobject]@{
    Mailbox               = $Mailbox
    InboxTotal            = $inboxTotal
    InboxUnread           = $inboxUnread
    ProcessedFolderCount  = $processedCount
    NewestReceivedDateTime= $newest
    StoredWatermark       = $StoredWatermark
    WatermarkCaughtUp     = if ($StoredWatermark -and $newest) {
                                try { [datetime]$StoredWatermark -ge [datetime]$newest } catch { $null }
                            } else { $null }
    ReportUtc             = (Get-Date).ToUniversalTime().ToString('o')
}

$row | Format-List
$row | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nCSV written: {0}" -f $CsvPath) -ForegroundColor Green

if ($StoredWatermark -and $newest) {
    if ($row.WatermarkCaughtUp -eq $false) {
        Write-Host "Watermark is BEHIND the newest message — the poller has backlog to drain (expected between runs)." -ForegroundColor Yellow
    } else {
        Write-Host "Watermark is at/after the newest message — caught up." -ForegroundColor Green
    }
}
Write-Host "Report complete (read-only)." -ForegroundColor Green
