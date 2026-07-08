<#
.SYNOPSIS
    DLPMac-Report.ps1 — export Endpoint DLP activity (Activity Explorer) for the macOS fleet as the evidence trail (read-only).
.DESCRIPTION
    PURPOSE
        Pulls Endpoint DLP events from Activity Explorer via Export-ActivityExplorerData so you can see
        exactly what the macOS DLP policy is catching in simulation (audited egress) and, after
        enforcement, what it is blocking/overriding — by activity, application, and matched rule. This
        is the audit evidence that the control exists and works. Read-only — makes no changes.
    HOW TO RUN
        Last 7 days:  powershell -ExecutionPolicy Bypass -File .\DLPMac-Report.ps1
        Wider window: ... -Days 30 -OutputCsv .\macos-dlp-activity.csv
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement; connects via Connect-IPPSSession
        (Activity Explorer export requires the appropriate compliance role). No credentials in script.
    EXPECTED RESULTS
        A summary of Endpoint DLP activities for the period (grouped by activity type and, where
        available, platform), and — with -OutputCsv — a CSV of the raw events for the audit file. Empty
        results usually mean no matching activity yet, macOS not onboarded, or the policy not in scope.
.NOTES
    Purview category — macOS Endpoint DLP. Read-only. Export-ActivityExplorerData paging/filters evolve —
    verify field names against current Microsoft guidance if a filter returns nothing.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$OutputCsv,
    [int]$PageSize = 5000
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

$start = (Get-Date).AddDays(-1 * [math]::Abs($Days)).ToString('yyyy-MM-ddTHH:mm:ss')
$end   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')

Write-Host ("`n=== Endpoint DLP activity {0} .. {1} ===" -f $start, $end) -ForegroundColor Cyan
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch {
    Write-Host ("Could not connect: {0}" -f $_.Exception.Message) -ForegroundColor Red; return
}

$events = @()
try {
    # Filter to Endpoint DLP workload. Field/filter names can evolve — Filter1 targets the workload.
    $events = Export-ActivityExplorerData -StartTime $start -EndTime $end `
                -Filter1 'Workload,EndpointDLP' -OutputFormat Json -PageSize $PageSize -ErrorAction Stop
} catch {
    Write-Host ("  First filter failed ({0}); retrying without the workload filter (will include all Activity Explorer data)." -f $_.Exception.Message) -ForegroundColor DarkGray
    try {
        $events = Export-ActivityExplorerData -StartTime $start -EndTime $end -OutputFormat Json -PageSize $PageSize -ErrorAction Stop
    } catch {
        Write-Host ("  FAIL : Export-ActivityExplorerData error: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "         Verify your role includes Activity Explorer export, and confirm current filter field names in Microsoft guidance." -ForegroundColor DarkGray
        try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
        return
    }
}

# Normalise (Export-ActivityExplorerData JSON rows vary by tenant; be defensive about field names).
$rows = @()
foreach ($e in $events) {
    $obj = if ($e -is [string]) { try { $e | ConvertFrom-Json } catch { $null } } else { $e }
    if ($null -eq $obj) { continue }
    $rows += [pscustomobject]@{
        Happened  = $obj.Happened
        Activity  = $obj.Activity
        App       = ($obj.ApplicationName, $obj.App, $obj.TargetApp | Where-Object { $_ } | Select-Object -First 1)
        Platform  = ($obj.Platform, $obj.DeviceOS | Where-Object { $_ } | Select-Object -First 1)
        Policy    = ($obj.PolicyName, $obj.Policy | Where-Object { $_ } | Select-Object -First 1)
        Rule      = ($obj.RuleName, $obj.Rule | Where-Object { $_ } | Select-Object -First 1)
        User      = ($obj.User, $obj.UserId | Where-Object { $_ } | Select-Object -First 1)
    }
}

if ($rows.Count -eq 0) {
    Write-Host "  No Endpoint DLP activity returned for the period." -ForegroundColor Yellow
    Write-Host "  Check: Macs onboarded? policy Devices-scoped? test activity actually driven? (See Troubleshooting.)" -ForegroundColor DarkGray
} else {
    Write-Host ("  {0} Endpoint DLP event(s) in window." -f $rows.Count) -ForegroundColor Green
    Write-Host "`n-- By activity --" -ForegroundColor Cyan
    $rows | Group-Object Activity | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("    {0,-30} {1}" -f $_.Name, $_.Count)
    }
    $mac = $rows | Where-Object { "$($_.Platform)" -match 'mac|osx|darwin' }
    if ($mac) { Write-Host ("`n  macOS-attributed events : {0}" -f $mac.Count) -ForegroundColor Green }
    else { Write-Host "`n  (No events explicitly tagged macOS — platform field may be absent; verify device platform in Activity Explorer.)" -ForegroundColor DarkGray }

    if ($OutputCsv) {
        try { $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host ("`n  Wrote CSV evidence file: {0}" -f $OutputCsv) -ForegroundColor Green }
        catch { Write-Host ("  Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    }
}

try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
