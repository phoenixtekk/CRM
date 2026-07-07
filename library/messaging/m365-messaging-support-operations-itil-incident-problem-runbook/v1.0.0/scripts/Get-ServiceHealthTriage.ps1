<#
.SYNOPSIS
  Service Health / message-trace triage helper (read-only). Lists active Exchange Online service
  issues and advisories so on-call can quickly answer "is it us or Microsoft?"; also serves as the
  scope/health pre-flight via -CheckScope.
.DESCRIPTION
  Reads the Microsoft Graph Service Communications API (service announcement issues + messages) and
  filters to Exchange Online, so the messaging support team can distinguish a Microsoft-side service
  incident from a local misconfiguration before starting local diagnosis. With -CheckScope it reports
  the connected operator's effective posture and module versions (Testing T1 pre-flight). With
  -TraceUser it adds a recent EXO message-trace summary for a single user. Read-only throughout; no
  credentials are stored. Government clouds: connect Graph with the appropriate environment
  (e.g. Connect-MgGraph -Environment USGov / USGovDoD) and verify endpoints for your tenant.
.EXAMPLE
  .\Get-ServiceHealthTriage.ps1
  # Connect-MgGraph -Scopes "ServiceHealth.Read.All" first; lists active Exchange Online issues/advisories.
.EXAMPLE
  .\Get-ServiceHealthTriage.ps1 -CheckScope
  # Pre-flight: report connected Graph/EXO context, scopes, and module versions (read-only).
.EXAMPLE
  .\Get-ServiceHealthTriage.ps1 -TraceUser user@contoso.com -TraceHours 4
  # Also summarize the last 4 hours of message trace for one user (requires Connect-ExchangeOnline).
  # (PowerShell 5.1+/7+, Microsoft.Graph + ExchangeOnlineManagement modules.)
.NOTES
  Expected results: a table of active Exchange Online service issues/advisories (or "No active issues").
  PASS = you can tell service-side from local before deep troubleshooting. No changes are made.
#>

[CmdletBinding()]
param(
    [switch]$CheckScope,
    [switch]$IncludeAdvisories,
    [string]$TraceUser,
    [int]$TraceHours = 4
)

$ErrorActionPreference = 'Stop'

function Write-Section($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }

# --- Scope / health pre-flight -------------------------------------------------
if ($CheckScope) {
    Write-Section 'Scope / health pre-flight (read-only)'

    $graphMod = Get-Module -ListAvailable -Name Microsoft.Graph.ServiceCommunications, Microsoft.Graph |
        Sort-Object Version -Descending | Select-Object -First 1
    $exoMod = Get-Module -ListAvailable -Name ExchangeOnlineManagement |
        Sort-Object Version -Descending | Select-Object -First 1

    Write-Host ("PowerShell version : {0}" -f $PSVersionTable.PSVersion)
    Write-Host ("Microsoft.Graph    : {0}" -f ($(if ($graphMod) { $graphMod.Version } else { 'NOT INSTALLED' })))
    Write-Host ("ExchangeOnlineMgmt : {0}" -f ($(if ($exoMod) { $exoMod.Version } else { 'NOT INSTALLED' })))

    try {
        $ctx = Get-MgContext -ErrorAction Stop
        if ($ctx) {
            Write-Host ("Graph account      : {0}" -f $ctx.Account)
            Write-Host ("Graph environment  : {0}" -f $ctx.Environment)
            Write-Host ("Graph scopes       : {0}" -f ($ctx.Scopes -join ', '))
            if ($ctx.Scopes -notcontains 'ServiceHealth.Read.All') {
                Write-Warning "ServiceHealth.Read.All not present. Reconnect: Connect-MgGraph -Scopes 'ServiceHealth.Read.All'"
            }
        }
    } catch { Write-Warning "Not connected to Microsoft Graph. Run Connect-MgGraph -Scopes 'ServiceHealth.Read.All'." }

    try {
        $exoConn = Get-ConnectionInformation -ErrorAction Stop | Select-Object -First 1
        if ($exoConn) { Write-Host ("EXO account        : {0} ({1})" -f $exoConn.UserPrincipalName, $exoConn.ConnectionUri) }
    } catch { Write-Host "EXO                : not connected (only needed for -TraceUser)." }

    return
}

# --- Service Health ------------------------------------------------------------
Write-Section 'Exchange Online — active service issues'

try { $ctx = Get-MgContext -ErrorAction Stop } catch { $ctx = $null }
if (-not $ctx) {
    Write-Error "Not connected to Microsoft Graph. Run: Connect-MgGraph -Scopes 'ServiceHealth.Read.All' (Government: add -Environment USGov / USGovDoD)."
    return
}

# Get-MgServiceAnnouncementIssue is provided by the Microsoft.Graph.ServiceCommunications module.
$issues = Get-MgServiceAnnouncementIssue -All -ErrorAction Stop |
    Where-Object { $_.Service -like '*Exchange*' -and $_.Status -notin @('serviceRestored','resolved','falsePositive','postIncidentReviewPublished') }

if (-not $issues) {
    Write-Host "No active Exchange Online service issues. Treat as a LOCAL issue and proceed with local diagnosis." -ForegroundColor Green
} else {
    $issues |
        Select-Object Id,
            @{n='Title'; e={ $_.Title }},
            @{n='Classification'; e={ $_.Classification }},
            @{n='Status'; e={ $_.Status }},
            @{n='StartUTC'; e={ $_.StartDateTime }} |
        Sort-Object StartUTC -Descending | Format-Table -AutoSize
    Write-Host "Match a ticket to an issue above -> annotate 'Microsoft-side, MS incident <Id>' and monitor." -ForegroundColor Yellow
}

if ($IncludeAdvisories) {
    Write-Section 'Message center advisories (Exchange)'
    try {
        Get-MgServiceAnnouncementMessage -All -ErrorAction Stop |
            Where-Object { $_.Services -contains 'Exchange Online' } |
            Select-Object Id, Title, @{n='ActUTC'; e={ $_.ActionRequiredByDateTime }}, @{n='LastUpd'; e={ $_.LastModifiedDateTime }} |
            Sort-Object LastUpd -Descending | Select-Object -First 15 | Format-Table -AutoSize
    } catch { Write-Warning "Could not read message center advisories: $($_.Exception.Message)" }
}

# --- Optional single-user message trace ---------------------------------------
if ($TraceUser) {
    Write-Section ("Message trace summary — {0} (last {1}h)" -f $TraceUser, $TraceHours)
    try {
        $null = Get-ConnectionInformation -ErrorAction Stop
    } catch {
        Write-Warning "Not connected to Exchange Online. Run Connect-ExchangeOnline to use -TraceUser."
        return
    }
    $start = (Get-Date).ToUniversalTime().AddHours(-1 * [math]::Abs($TraceHours))
    $end   = (Get-Date).ToUniversalTime()
    try {
        $trace = Get-MessageTrace -SenderAddress $TraceUser -StartDate $start -EndDate $end -ErrorAction Stop
        $trace += Get-MessageTrace -RecipientAddress $TraceUser -StartDate $start -EndDate $end -ErrorAction Stop
        if (-not $trace) {
            Write-Host "No message trace entries for $TraceUser in the window." -ForegroundColor Yellow
        } else {
            $trace | Group-Object Status |
                Select-Object @{n='Status'; e={ $_.Name }}, Count |
                Sort-Object Count -Descending | Format-Table -AutoSize
        }
    } catch { Write-Warning "Message trace failed: $($_.Exception.Message)" }
}
