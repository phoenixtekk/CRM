<#
.SYNOPSIS
    GRAPHSUB-Report.ps1 — inventory Microsoft Graph change-notification subscriptions to console + CSV.
    Read-only.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Event-Driven Mail Processing with Microsoft Graph Change
        Notifications" solution. Produces a subscription inventory — resource, changeType,
        expirationDateTime, computed expiry state (OK / EXPIRING / EXPIRED), time-to-expiry, and the
        notificationUrl host (host only, not the full secret-bearing URL) — to the console and a
        timestamped CSV. Useful for a periodic coverage/expiry review across all monitored mailboxes.
    HOW TO RUN
        pwsh -File .\GRAPHSUB-Report.ps1
        pwsh -File .\GRAPHSUB-Report.ps1 -OutputPath 'C:\Reports' -ExpiringWithinHours 24
    GRAPH SCOPES (delegated, for interactive reporting)
        Subscription.Read.All
        (Connect-MgGraph -Scopes 'Subscription.Read.All')
    EXPECTED RESULTS
        A table and a CSV (GRAPHSUB-Subscriptions-<timestamp>.csv) of every visible subscription with
        its expiry state — the artefact you keep to prove coverage and catch a subscription drifting
        toward expiry. NOTE: only subscriptions owned by the authenticating identity are visible;
        the MI's own subscriptions may require authenticating as the MI — verify with Microsoft.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reports the notificationUrl HOST only (the full URL can carry a secret token). Verify Graph
    specifics against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = '.',
    [int]$ExpiringWithinHours = 24,
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes 'Subscription.Read.All' | Out-Null
}

Write-Host "`n=== Event-Driven Mail Processing — subscription inventory ===" -ForegroundColor Cyan

$now = (Get-Date).ToUniversalTime()
$rows = @()
try {
    $subs = Get-MgSubscription -All -ErrorAction Stop
    foreach ($s in $subs) {
        $exp   = [datetime]$s.ExpirationDateTime
        $state = if ($exp -lt $now) { 'EXPIRED' }
                 elseif ($exp -lt $now.AddHours($ExpiringWithinHours)) { 'EXPIRING' }
                 else { 'OK' }
        $urlHost = try { ([uri]$s.NotificationUrl).Host } catch { '(unparsable)' }
        $rows += [pscustomobject]@{
            Resource           = $s.Resource
            ChangeType         = $s.ChangeType
            ExpirationDateTime = $exp.ToString('u')
            State              = $state
            HoursToExpiry      = [math]::Round(($exp - $now).TotalHours, 1)
            NotificationHost   = $urlHost
            SubscriptionId     = $s.Id
        }
    }
} catch {
    Write-Host ("Could not read subscriptions: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($rows.Count -gt 0) {
    $rows | Sort-Object HoursToExpiry | Format-Table Resource, ChangeType, State, HoursToExpiry, ExpirationDateTime, NotificationHost -AutoSize | Out-String | Write-Host
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
    $csv = Join-Path $OutputPath ("GRAPHSUB-Subscriptions-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
    Write-Host ("CSV written: {0}" -f $csv) -ForegroundColor Green
    $expired  = ($rows | Where-Object State -eq 'EXPIRED').Count
    $expiring = ($rows | Where-Object State -eq 'EXPIRING').Count
    if ($expired)  { Write-Host ("WARNING: {0} EXPIRED subscription(s) — coverage gap; run GRAPHSUB-Renew.ps1." -f $expired) -ForegroundColor Red }
    if ($expiring) { Write-Host ("NOTE: {0} subscription(s) expiring within {1}h — renew soon." -f $expiring, $ExpiringWithinHours) -ForegroundColor Yellow }
} else {
    Write-Host "No subscriptions visible to this identity (the MI's may not appear here — verify)." -ForegroundColor Yellow
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
