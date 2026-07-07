<#
.SYNOPSIS
  Mailbox / mail-flow health-check for common tickets (read-only). Returns the key facts L2 needs to
  diagnose a "user can't send/receive" ticket from one place.
.DESCRIPTION
  For a given mailbox, gathers mailbox type and primary SMTP, forwarding settings, litigation/retention
  hold state, quota/usage, and a recent message-trace status summary for that user. Read-only - it runs
  Get-* cmdlets only and changes nothing. Requires Connect-ExchangeOnline with an account that can read
  the mailbox (per the tier's least-privilege role). Government clouds: connect EXO with the correct
  -ConnectionUri / -ExchangeEnvironmentName and verify for your tenant.
.EXAMPLE
  .\Test-MailboxMailFlowHealth.ps1 -Identity user@contoso.com
  # Connect-ExchangeOnline first. Prints mailbox + mail-flow health for the user (read-only).
.EXAMPLE
  .\Test-MailboxMailFlowHealth.ps1 -Identity user@contoso.com -TraceHours 8
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module.)
.NOTES
  Expected results: a health block (type, SMTP, forwarding, holds, quota) + a message-trace status
  count. PASS = L2 can diagnose the common ticket without hunting across multiple portals.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Identity,

    [int]$TraceHours = 8
)

$ErrorActionPreference = 'Stop'
function Write-Section($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }

try { $null = Get-ConnectionInformation -ErrorAction Stop }
catch { Write-Error "Not connected to Exchange Online. Run Connect-ExchangeOnline first."; return }

Write-Section "Mailbox — $Identity"
try {
    $mbx = Get-Mailbox -Identity $Identity -ErrorAction Stop
} catch {
    Write-Error "Mailbox '$Identity' not found or not readable with the current account: $($_.Exception.Message)"
    return
}

[pscustomobject]@{
    DisplayName            = $mbx.DisplayName
    PrimarySmtpAddress     = $mbx.PrimarySmtpAddress
    RecipientTypeDetails   = $mbx.RecipientTypeDetails
    ForwardingSmtpAddress  = $mbx.ForwardingSmtpAddress
    ForwardingAddress      = $mbx.ForwardingAddress
    DeliverToMailboxAndFwd = $mbx.DeliverToMailboxAndForward
    LitigationHoldEnabled  = $mbx.LitigationHoldEnabled
    RetentionHoldEnabled   = $mbx.RetentionHoldEnabled
    ArchiveStatus          = $mbx.ArchiveStatus
    HiddenFromGAL          = $mbx.HiddenFromAddressListsEnabled
} | Format-List

Write-Section 'Quota / usage'
try {
    Get-MailboxStatistics -Identity $Identity -ErrorAction Stop |
        Select-Object DisplayName, TotalItemSize, ItemCount, LastLogonTime | Format-List
} catch { Write-Warning "Could not read mailbox statistics: $($_.Exception.Message)" }

Write-Section 'Junk / quarantine hint'
Write-Host "If the ticket is 'missing inbound mail', also check quarantine (Get-QuarantineMessage) and the anti-phish/anti-spam policy that applies to this recipient (L3 if a policy change is required)." -ForegroundColor DarkGray

Write-Section ("Message trace summary (last {0}h)" -f $TraceHours)
$start = (Get-Date).ToUniversalTime().AddHours(-1 * [math]::Abs($TraceHours))
$end   = (Get-Date).ToUniversalTime()
try {
    $trace = @()
    $trace += Get-MessageTrace -SenderAddress $mbx.PrimarySmtpAddress -StartDate $start -EndDate $end -ErrorAction Stop
    $trace += Get-MessageTrace -RecipientAddress $mbx.PrimarySmtpAddress -StartDate $start -EndDate $end -ErrorAction Stop
    if (-not $trace) {
        Write-Host "No message trace entries in the window (note: recent-hours trace only; use Start-HistoricalSearch for older)." -ForegroundColor Yellow
    } else {
        $trace | Group-Object Status |
            Select-Object @{n='Status'; e={ $_.Name }}, Count |
            Sort-Object Count -Descending | Format-Table -AutoSize
        Write-Host "Non-'Delivered' statuses (Failed, FilteredAsSpam, Pending) point to where to look next." -ForegroundColor DarkGray
    }
} catch { Write-Warning "Message trace failed: $($_.Exception.Message)" }

Write-Host "`nRead-only health check complete. No changes were made." -ForegroundColor Green
