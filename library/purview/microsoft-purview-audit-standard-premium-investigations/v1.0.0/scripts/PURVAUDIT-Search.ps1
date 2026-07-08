<#
.SYNOPSIS
    PURVAUDIT-Search.ps1 — paged unified audit log search / investigation helper (read-only).
.DESCRIPTION
    PURPOSE
        Runs Search-UnifiedAuditLog for an investigation by operation(s), record type, user(s), and
        time window, paging with ReturnLargeSet so results are NOT silently truncated. Read-only — it
        never changes tenant state. Use it directly or as the engine behind the investigation runbooks
        (mailbox compromise, data exfiltration, privilege escalation).
    HOW TO RUN
        # Which messages did an attacker read, and did they set forwarding? (Premium: MailItemsAccessed)
        powershell -File .\PURVAUDIT-Search.ps1 -Operations MailItemsAccessed,New-InboxRule,Set-InboxRule `
            -UserIds victim@contoso.com -Start (Get-Date).AddDays(-7) -End (Get-Date) -CsvPath .\out.csv
        Requires ExchangeOnlineManagement (Connect-ExchangeOnline) and the View-Only Audit Logs / Audit
        Logs role. Interactive modern-auth sign-in; no secrets in code.
    EXPECTED RESULTS
        A table (and optional CSV) of matching audit records with the paged total count. If zero, the
        script distinguishes "no events" from likely causes (latency, licensing for high-value events,
        mailbox bypass) so absence is not mistaken for an all-clear.
.NOTES
    Purview category — Audit. Read-only. Search-UnifiedAuditLog has result/throttling limits — keep
    windows short; the script pages ReturnLargeSet. High-value operations (MailItemsAccessed, Send,
    SearchQueryInitiated*) require Audit Premium per user. Timestamps are UTC.
#>
[CmdletBinding()]
param(
    [string[]]$Operations,                          # e.g. MailItemsAccessed, Send, New-InboxRule, FileDownloaded, "Add member to role."
    [string]$RecordType,                            # optional, e.g. ExchangeItem, AzureActiveDirectoryStsLogon, SharePointFileOperation
    [string[]]$UserIds,                             # optional scope by user
    [datetime]$Start = (Get-Date).AddDays(-7),
    [datetime]$End   = (Get-Date),
    [string]$FreeText,                              # optional free-text filter
    [int]$ResultSizePerPage = 5000,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
Connect-ExchangeOnline @cp

$common = @{ StartDate = $Start; EndDate = $End; ResultSize = $ResultSizePerPage; SessionCommand = 'ReturnLargeSet' }
if ($Operations) { $common['Operations'] = $Operations }
if ($RecordType) { $common['RecordType'] = $RecordType }
if ($UserIds)    { $common['UserIds']    = $UserIds }
if ($FreeText)   { $common['FreeText']   = $FreeText }

$sessionId = "PURVAUDIT-{0:yyyyMMddHHmmss}" -f (Get-Date)
Write-Host ("Searching {0:u} .. {1:u} (UTC-based) ..." -f $Start, $End) -ForegroundColor Cyan

$all = New-Object System.Collections.Generic.List[object]
do {
    $page = Search-UnifiedAuditLog @common -SessionId $sessionId
    if ($page) { $page | ForEach-Object { $all.Add($_) } }
    $got = if ($page) { @($page).Count } else { 0 }
    Write-Host ("  page: {0} record(s), running total {1}" -f $got, $all.Count)
} while ($got -gt 0)

Write-Host ("`nTotal records: {0}" -f $all.Count) -ForegroundColor Green

if ($all.Count -eq 0) {
    Write-Host "No matching audit records. Before concluding 'nothing happened', check:" -ForegroundColor Yellow
    Write-Host "  - ingestion latency (recent activity may not be searchable yet)"
    Write-Host "  - high-value ops (MailItemsAccessed/Send/SearchQueryInitiated*) require Audit Premium ASSIGNED to that user"
    Write-Host "  - mailbox audit bypass may be suppressing that user's events (run PURVAUDIT-Discovery.ps1)"
    Write-Host "  - the time window / operation names — audit timestamps are UTC"
    return
}

# Expand common fields for readability
$rows = $all | ForEach-Object {
    $d = $null; try { $d = $_.AuditData | ConvertFrom-Json } catch {}
    [pscustomobject]@{
        CreationDateUTC = $_.CreationDate
        UserIds         = $_.UserIds
        Operation       = $_.Operations
        RecordType      = $_.RecordType
        ClientIP        = $d.ClientIP
        Workload        = $d.Workload
        ResultStatus    = $d.ResultStatus
        Detail          = if ($d.ObjectId) { $d.ObjectId } elseif ($d.Subject) { $d.Subject } else { '' }
    }
}
$rows | Sort-Object CreationDateUTC | Format-Table -AutoSize | Out-String | Write-Host
if ($CsvPath) { $rows | Sort-Object CreationDateUTC | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported to $CsvPath" -ForegroundColor Green }
