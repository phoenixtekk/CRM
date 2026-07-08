<#
.SYNOPSIS
    AUDSIEM-Reconcile.ps1 — Count SOURCE audit records for a window to compare against SIEM ingestion (read-only).
.DESCRIPTION
    PURPOSE
        Produces the SOURCE-OF-TRUTH audit record count for a time window, broken down by workload/record type,
        using Search-UnifiedAuditLog (Exchange Online). You compare this to your SIEM's ingested count for the
        SAME aligned window to detect SILENT PARTIAL LOSS (a stopped subscription, expired webhook, un-collected
        blobs, or a connector filter). Read-only — makes NO changes. This is the reconciliation gate that turns
        "the feed is configured" into "the feed is trusted."
    HOW TO RUN
        # Source counts by record type for the last 24h (all workloads):
        powershell -File .\AUDSIEM-Reconcile.ps1 -Hours 24
        # Narrow to the content type you piloted (maps to record types for that workload):
        .\AUDSIEM-Reconcile.ps1 -ContentType Audit.AzureActiveDirectory -Hours 24
        Requires ExchangeOnlineManagement (Connect-ExchangeOnline) and the View-Only Audit Logs / Audit Logs
        role (Purview Audit Reader). PowerShell 5.1+/7+.
    EXPECTED RESULTS
        Prints total source records and a per-record-type breakdown for the window. Compare to the SIEM's count
        for the same window within an agreed, latency-aware tolerance. A material shortfall in the SIEM = silent
        loss to investigate. Match within tolerance = the pipeline is lossless for that window.
.NOTES
    Purview category — Audit → SIEM integration. Read-only; no writes; NO secrets in code. Search-UnifiedAuditLog
    has result/throttle limits — keep windows short and page with -SessionCommand ReturnLargeSet. Feed latency
    means the newest minutes may not yet be in the SIEM; align the window to allow for it. The newer Graph Audit
    Log Query API (/security/auditLog/queries) is an alternative source — verify its availability in your tenant.
#>
[CmdletBinding()]
param(
    [ValidateSet('Audit.AzureActiveDirectory','Audit.Exchange','Audit.SharePoint','Audit.General','DLP.All')]
    [string]$ContentType,
    [ValidateRange(1,168)][int]$Hours = 24,
    [int]$ResultSize = 5000
)

$ErrorActionPreference = 'Stop'
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }

# Map a Management Activity API content type to the unified-audit RecordType filter(s) for the same workload.
$ctMap = @{
    'Audit.AzureActiveDirectory' = @('AzureActiveDirectory','AzureActiveDirectoryStsLogon','AzureActiveDirectoryAccountLogon')
    'Audit.Exchange'             = @('ExchangeAdmin','ExchangeItem','ExchangeItemGroup','ExchangeItemAggregated')
    'Audit.SharePoint'           = @('SharePoint','SharePointFileOperation','SharePointSharingOperation','OneDrive')
    'Audit.General'              = @()   # broad; General spans many record types — leave unfiltered
    'DLP.All'                    = @('DLPEndpoint','ComplianceDLPExchange','ComplianceDLPSharePoint')
}

try {
    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) { Import-Module ExchangeOnlineManagement -ErrorAction Stop }
    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        Say "Connecting to Exchange Online (modern auth)..." 'DarkGray'
        Connect-ExchangeOnline -ShowBanner:$false | Out-Null
    }
} catch {
    Say ("Could not connect to Exchange Online: {0}" -f $_.Exception.Message) 'Red'
    Say "Install ExchangeOnlineManagement and sign in with an audit-read admin (Audit Reader / View-Only Audit Logs)." 'Yellow'
    return
}

$end = [DateTime]::UtcNow
$start = $end.AddHours(-$Hours)
$recordTypes = if ($ContentType) { $ctMap[$ContentType] } else { @() }

Say ("=== AUDSIEM Reconcile — SOURCE audit counts (UTC {0} .. {1}) ===" -f $start.ToString('u'),$end.ToString('u')) 'Cyan'
if ($ContentType) { Say ("Content type: {0}  ->  record types: {1}" -f $ContentType, ($(if($recordTypes){$recordTypes -join ', '}else{'(unfiltered / broad)'}))) 'DarkGray' }

# Paged search using ReturnLargeSet; keep the window short to stay within limits.
$all = New-Object System.Collections.Generic.List[object]
$sessionId = "AUDSIEM-Reconcile-$([guid]::NewGuid().ToString('N').Substring(0,8))"
do {
    $params = @{
        StartDate     = $start
        EndDate       = $end
        SessionId     = $sessionId
        SessionCommand= 'ReturnLargeSet'
        ResultSize    = $ResultSize
    }
    if ($recordTypes -and $recordTypes.Count -gt 0) { $params['RecordType'] = $recordTypes }
    $batch = Search-UnifiedAuditLog @params
    if ($batch) { foreach ($r in $batch) { $all.Add($r) } }
} while ($batch -and $batch.Count -eq $ResultSize)

$total = $all.Count
Say ("`nSOURCE total records in window: {0}" -f $total) $(if($total -gt 0){'Green'}else{'Yellow'})
if ($total -gt 0) {
    Say "Breakdown by RecordType:" 'Cyan'
    $all | Group-Object RecordType | Sort-Object Count -Descending |
        Select-Object @{n='RecordType';e={$_.Name}}, Count |
        Format-Table -AutoSize | Out-String | Write-Host
}

Say "-------------------------------------------------------------------" 'DarkGray'
Say "RECONCILE: compare the SOURCE total above to your SIEM's ingested count for the SAME window." 'Cyan'
Say " - Match within tolerance (allowing feed latency on the newest minutes) => pipeline is lossless for this window." 'Green'
Say " - SIEM materially LOWER => silent partial loss: check subscription status, webhook expiry, collector uptime, connector filters." 'Yellow'
Say "Record this as the 'Audit Pipeline - Coverage - Report'. Read-only reconciliation complete; no changes made." 'Cyan'
