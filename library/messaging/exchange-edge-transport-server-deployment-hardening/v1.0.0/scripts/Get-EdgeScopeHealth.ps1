<#
.SYNOPSIS
  Scope/health helper — consolidated read-only Edge health: EdgeSync, connectors, queues, cert expiry.
.DESCRIPTION
  One-shot, read-only health summary that ties the Edge deployment together for ongoing monitoring and
  re-validation after each CU: Edge Subscription + EdgeSync status, Send/Receive connector scope, the
  SMTP certificate expiry (Cert - Edge SMTP - Prod), and transport queue depth. Prints a PASS/WARN
  scorecard mapped to the solution's gates. Changes nothing. Run in the Exchange Management Shell
  (internal server for EdgeSync/connectors; Edge for cert/queues) — it uses whatever cmdlets are
  present in the current shell.
.EXAMPLE
  .\Get-EdgeScopeHealth.ps1 -CertExpiryWarnDays 30
  # Read-only scorecard; warn if the SMTP certificate expires within 30 days.
  (Exchange Management Shell. Run the EdgeSync/connector part on the internal server, cert/queue part on the Edge.)
.NOTES
  Expected results: a scorecard — EdgeSync Normal (Gate B), connectors scoped, SMTP cert valid/not
  near expiry, queues healthy. WARN items are the monitoring signals to act on. Re-run after every CU.
#>
[CmdletBinding()]
param(
    [int]$CertExpiryWarnDays = 30,
    [int]$QueueWarnCount = 500
)

$score = New-Object System.Collections.Generic.List[object]
function Add-Score([string]$Area, [string]$Status, [string]$Detail) {
    $score.Add([pscustomobject]@{ Area = $Area; Status = $Status; Detail = $Detail })
}

Write-Host "Edge scope/health scorecard — read-only`n" -ForegroundColor Cyan

# --- EdgeSync (Gate B) ---
if (Get-Command Test-EdgeSynchronization -ErrorAction SilentlyContinue) {
    try {
        $sync = Test-EdgeSynchronization -ErrorAction Stop
        $state = ($sync | Select-Object -First 1).SyncStatus
        Add-Score 'EdgeSync (Gate B)' ($(if ("$state" -match 'Normal') { 'PASS' } else { 'WARN' })) "SyncStatus: $state"
    } catch { Add-Score 'EdgeSync (Gate B)' 'WARN' $_.Exception.Message }
} else { Add-Score 'EdgeSync (Gate B)' 'INFO' 'Run on the internal Exchange server for EdgeSync status.' }

if (Get-Command Get-EdgeSubscription -ErrorAction SilentlyContinue) {
    try {
        $subs = Get-EdgeSubscription -ErrorAction Stop
        Add-Score 'Edge Subscription' ($(if ($subs) { 'PASS' } else { 'WARN' })) (($subs | ForEach-Object Name) -join ', ')
    } catch { Add-Score 'Edge Subscription' 'WARN' $_.Exception.Message }
}

# --- Connector scope ---
if (Get-Command Get-SendConnector -ErrorAction SilentlyContinue) {
    try {
        $send = Get-SendConnector -ErrorAction Stop
        $inet = $send | Where-Object { $_.AddressSpaces -match '\*' -or $_.Name -match 'EdgeSync' }
        Add-Score 'Send connectors' 'INFO' ("{0} total; internet/EdgeSync connector present: {1}" -f $send.Count, [bool]$inet)
    } catch { Add-Score 'Send connectors' 'WARN' $_.Exception.Message }
}
if (Get-Command Get-ReceiveConnector -ErrorAction SilentlyContinue) {
    try {
        $recv = Get-ReceiveConnector -ErrorAction Stop
        $anonExt = $recv | Where-Object { "$($_.PermissionGroups)" -match 'AnonymousUsers' }
        Add-Score 'Receive connectors' ($(if ($anonExt) { 'WARN' } else { 'PASS' })) (
            $(if ($anonExt) { "Anonymous permission group present — confirm it CANNOT relay to external (see Test-OpenRelay.ps1)." }
              else { "No anonymous-relay risk flagged; verify with Test-OpenRelay.ps1 (Gate C)." }))
    } catch { Add-Score 'Receive connectors' 'WARN' $_.Exception.Message }
}

# --- SMTP certificate expiry (Cert - Edge SMTP - Prod) ---
if (Get-Command Get-ExchangeCertificate -ErrorAction SilentlyContinue) {
    try {
        $certs = Get-ExchangeCertificate -ErrorAction Stop | Where-Object { "$($_.Services)" -match 'SMTP' }
        if (-not $certs) {
            Add-Score 'SMTP certificate' 'WARN' 'No certificate enabled for SMTP — TLS will fail.'
        } else {
            foreach ($c in $certs) {
                $days = [int]([datetime]$c.NotAfter - (Get-Date)).TotalDays
                $st = if ($days -lt 0) { 'WARN' } elseif ($days -le $CertExpiryWarnDays) { 'WARN' } else { 'PASS' }
                Add-Score 'SMTP certificate' $st ("Subject '$($c.Subject)' expires in $days day(s) (NotAfter $($c.NotAfter)).")
            }
        }
    } catch { Add-Score 'SMTP certificate' 'INFO' $_.Exception.Message }
} else { Add-Score 'SMTP certificate' 'INFO' 'Run on the Edge server to check the SMTP certificate.' }

# --- Queues ---
if (Get-Command Get-Queue -ErrorAction SilentlyContinue) {
    try {
        $q = Get-Queue -ErrorAction Stop | Where-Object { $_.Identity -notmatch 'Shadow' }
        $depth = ($q | Measure-Object MessageCount -Sum).Sum
        Add-Score 'Transport queues' ($(if ($depth -gt $QueueWarnCount) { 'WARN' } else { 'PASS' })) "Total queued messages: $depth"
    } catch { Add-Score 'Transport queues' 'INFO' $_.Exception.Message }
} else { Add-Score 'Transport queues' 'INFO' 'Run on/against the Edge for queue depth.' }

$score | Format-Table -AutoSize
$warn = ($score | Where-Object Status -eq 'WARN').Count
Write-Host ("`nScorecard: {0} WARN item(s). Healthy Edge = EdgeSync Normal (Gate B), no anon external relay (Gate C via Test-OpenRelay.ps1), SMTP cert valid, queues draining." -f $warn) -ForegroundColor Yellow
Write-Host 'Re-run after every Exchange CU — TLS/agent defaults are version/CU-dependent; verify for your version.' -ForegroundColor DarkGray
