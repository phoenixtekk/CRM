<#
.SYNOPSIS
    GRAPHSUB-Test-Notification.ps1 — check recent notification/processing evidence and flag a lapsed
    subscription (a coverage gap). Read-only.
.DESCRIPTION
    PURPOSE
        Read-only coverage check for the "Event-Driven Mail Processing with Microsoft Graph Change
        Notifications" solution. Answers "is the webhook actually working right now?" without changing
        anything, by correlating two facts for the target mailbox:
          1. Is there an ACTIVE, non-expired change-notification subscription on the mailbox? (If not,
             new mail is NOT being pushed — a coverage gap.)
          2. Are there recent messages that arrived AFTER a reference time (default: last hour) that
             the event pipeline should have processed? (These are what you reconcile against the
             receiver's run history / dedup store to confirm nothing was missed.)
        It reports a lapsed subscription and lists recent messages as processing evidence; it does not
        create, renew, delete, or send anything.
    HOW TO RUN
        pwsh -File .\GRAPHSUB-Test-Notification.ps1 -Mailbox 'svc-mailevents@contoso.com'
        pwsh -File .\GRAPHSUB-Test-Notification.ps1 -Mailbox 'svc-mailevents@contoso.com' -SinceHours 4
    GRAPH SCOPES (delegated)
        Subscription.Read.All   — check the subscription is alive
        Mail.Read               — read recent messages of the mailbox as processing evidence
                                  (least privilege; verify the current scope name with Microsoft)
        (Connect-MgGraph -Scopes 'Subscription.Read.All','Mail.Read')
    EXPECTED RESULTS
        A clear verdict: subscription ACTIVE or LAPSED (gap), plus a list of recent messages (received
        time, subject, id) to reconcile against what the receiver actually processed. A LAPSED
        subscription with recent messages = events were likely missed → recover via the catch-up read /
        GRAPHSUB-Renew.ps1. This checks for EVIDENCE; it does not itself inject a test event.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reads message metadata only. Verify Graph specifics (supported resources, permission names,
    national-cloud endpoints) against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Mailbox,
    [int]$SinceHours = 1,
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes 'Subscription.Read.All','Mail.Read' | Out-Null
}

$now       = (Get-Date).ToUniversalTime()
$since     = $now.AddHours(-1 * [math]::Abs($SinceHours))
$sinceIso  = $since.ToString('o')

Write-Host "`n=== Event-Driven Mail Processing — notification coverage check ===" -ForegroundColor Cyan
Write-Host ("Mailbox: {0}   Window: since {1:u}" -f $Mailbox, $since)

# 1 — is a subscription alive on the mailbox?
$active = $null
try {
    $subs = Get-MgSubscription -All -ErrorAction Stop |
            Where-Object { $_.Resource -match [regex]::Escape($Mailbox) -and $_.Resource -match 'messages' }
    $active = $subs | Where-Object { [datetime]$_.ExpirationDateTime -gt $now } | Select-Object -First 1
    if ($active) {
        Write-Host ("Subscription: ACTIVE  (id={0}, expires={1:u})" -f $active.Id, [datetime]$active.ExpirationDateTime) -ForegroundColor Green
    } elseif ($subs) {
        Write-Host "Subscription: LAPSED — a subscription exists but is EXPIRED. COVERAGE GAP: new mail is not being pushed." -ForegroundColor Red
    } else {
        Write-Host "Subscription: NONE visible for this mailbox — COVERAGE GAP (or the subscription is owned by the MI and not visible here — verify)." -ForegroundColor Red
    }
} catch {
    Write-Host ("Could not read subscriptions: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 2 — recent messages as processing evidence
Write-Host "`n-- Recent messages (reconcile against the receiver run history / dedup store) --" -ForegroundColor Cyan
try {
    $uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages?`$filter=receivedDateTime ge $sinceIso&`$select=id,subject,receivedDateTime,internetMessageId&`$top=25&`$orderby=receivedDateTime desc"
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
    $msgs = $resp.value
    if ($msgs -and $msgs.Count -gt 0) {
        foreach ($m in $msgs) {
            Write-Host ("   {0:u}  {1,-40}  id={2}" -f [datetime]$m.receivedDateTime, ($m.subject -replace '\s+',' ').PadRight(40).Substring(0,40), $m.id)
        }
        if (-not $active) {
            Write-Host ("`nWARNING: {0} message(s) arrived while the subscription was NOT active — these were likely MISSED by the webhook. Recover with the catch-up read / GRAPHSUB-Renew.ps1." -f $msgs.Count) -ForegroundColor Red
        } else {
            Write-Host ("`n{0} recent message(s) — confirm each id appears in the receiver run history / dedup store." -f $msgs.Count) -ForegroundColor Green
        }
    } else {
        Write-Host "   (no messages in the window — nothing to reconcile)" -ForegroundColor Yellow
    }
} catch {
    Write-Host ("   Could not read messages (permission scoped away or endpoint?): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nCoverage check complete (read-only)." -ForegroundColor Green
