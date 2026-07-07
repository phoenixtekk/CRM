<#
.SYNOPSIS
  Read-only reporting: quarantine review, Tenant Allow/Block List review (incl. stale/expiring
  allows), and a false-positive / spoof-intelligence oriented summary from message data.
.DESCRIPTION
  Connects with Exchange Online PowerShell (EXO V3) and produces the review report for the
  quarantine owner: quarantined messages by verdict for a lookback window, the full Tenant
  Allow/Block List with expiration flags, and a summary of spoof-related verdicts to support
  deliberate allow decisions. Makes NO changes. Optionally exports CSV.
.EXAMPLE
  .\Get-QuarantineAndAllowBlockReport.ps1 -Days 7 -OutputFolder .\hygiene-reports
  # Read-only. Connect first with Connect-ExchangeOnline.
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module)
.NOTES
  Expected results: on-screen tables plus optional CSVs - quarantine by verdict, TABL entries with
  "EXPIRES SOON" flags, and a spoof-verdict summary. Nothing is modified.
#>
[CmdletBinding()]
param(
    [ValidateRange(1,30)][int]$Days = 7,
    [string]$OutputFolder,
    [int]$ExpiringWithinDays = 14
)

try { Get-OrganizationConfig -ErrorAction Stop | Out-Null }
catch { throw "Not connected. Run Connect-ExchangeOnline first." }

if ($OutputFolder -and -not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$start = (Get-Date).AddDays(-$Days)
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Save-Csv($data, [string]$name) {
    if ($OutputFolder -and $data) { $data | Export-Csv -Path (Join-Path $OutputFolder "$name-$stamp.csv") -NoTypeInformation -Encoding UTF8 }
}

# 1. Quarantine review (last N days) grouped by verdict
Write-Host "== Quarantine review (last $Days days) ==" -ForegroundColor Cyan
try {
    $q = Get-QuarantineMessage -StartReceivedDate $start -EndReceivedDate (Get-Date) -PageSize 1000 -ErrorAction Stop
    if ($q) {
        $q | Group-Object Type | Sort-Object Count -Descending |
            Select-Object @{n='Verdict';e={$_.Name}}, Count | Format-Table -AutoSize
        Save-Csv ($q | Select-Object ReceivedTime, SenderAddress, RecipientAddress, Subject, Type, Expires) "quarantine"
        Write-Host ("  Total quarantined: {0}. Review for false positives before release." -f @($q).Count)
    } else { Write-Host "  No quarantined messages in window." -ForegroundColor DarkGray }
} catch { Write-Warning "  Get-QuarantineMessage failed: $($_.Exception.Message)" }

# 2. Tenant Allow/Block List review with expiration flags
Write-Host "`n== Tenant Allow/Block List review ==" -ForegroundColor Cyan
$soon = (Get-Date).AddDays($ExpiringWithinDays)
$allTabl = New-Object System.Collections.Generic.List[object]
foreach ($lt in 'Sender','Url','FileHash') {
    try {
        $items = Get-TenantAllowBlockListItems -ListType $lt -ErrorAction Stop
        foreach ($i in $items) {
            $expFlag = ''
            if ($i.ExpirationDate -and $i.ExpirationDate -ne [datetime]::MaxValue -and $i.ExpirationDate -le $soon) { $expFlag = 'EXPIRES SOON' }
            elseif (-not $i.ExpirationDate -or $i.ExpirationDate -eq [datetime]::MaxValue) { if ($i.Action -eq 'Allow') { $expFlag = 'NO EXPIRY (review)' } }
            $allTabl.Add([pscustomobject]@{ ListType=$lt; Value=$i.Value; Action=$i.Action; Expires=$i.ExpirationDate; Flag=$expFlag })
        }
    } catch { Write-Warning "  TABL $lt unavailable: $($_.Exception.Message)" }
}
if ($allTabl.Count) { $allTabl | Format-Table -AutoSize; Save-Csv $allTabl "tabl-review" }
else { Write-Host "  No TABL entries." -ForegroundColor DarkGray }

# 3. Spoof / false-positive oriented message summary (message trace, best-effort)
Write-Host "`n== Spoof / verdict summary (message trace, last $Days days) ==" -ForegroundColor Cyan
try {
    $trace = Get-MessageTrace -StartDate $start -EndDate (Get-Date) -ErrorAction Stop
    if ($trace) {
        $trace | Group-Object Status | Sort-Object Count -Descending |
            Select-Object @{n='Status';e={$_.Name}}, Count | Format-Table -AutoSize
        Write-Host "  Review 'FilteredAsSpam' / failed items against sender legitimacy; allow via TABL, not filter downgrade."
    } else { Write-Host "  No message-trace data in window." -ForegroundColor DarkGray }
} catch { Write-Warning "  Get-MessageTrace note: $($_.Exception.Message) (trace covers ~10 days; use historical search for older)." }

Write-Host "`nReport complete (read-only)." -ForegroundColor Cyan
