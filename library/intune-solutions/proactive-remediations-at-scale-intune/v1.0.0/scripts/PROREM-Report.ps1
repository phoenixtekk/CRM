<#
.SYNOPSIS
    PROREM-Report.ps1 — export the detection/remediation success-fail trend to CSV.

.DESCRIPTION
    PURPOSE
        For each Proactive Remediation package (or one named package), exports its run-status roll-up
        — devices with issue detected, devices remediated, detection failures, and remediation
        failures — to a CSV so you have evidence of the trend over time and per package. A downward
        "with issue" count across successive exports is proof the practice is working. Read-only.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\PROREM-Report.ps1
        .\PROREM-Report.ps1 -PackageName 'PROREM – Service Health – w32time – Pilot'
        .\PROREM-Report.ps1 -CsvPath C:\Temp\prorem-trend.csv

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All

    EXPECTED RESULTS
        A CSV (one row per package) with detection/remediation counts and a printed summary. Run it on
        a schedule and compare exports to see the trend. (deviceHealthScripts runSummary is a BETA
        endpoint — verify against current Microsoft documentation; column names may change.)

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PackageName,
    [string]$CsvPath = "$PSScriptRoot\prorem-trend-$(Get-Date -Format yyyyMMdd-HHmm).csv"
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function GraphGet($uri) {
    $items = @()
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $items += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    return $items
}

$base = 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts'
try { $scripts = GraphGet "$base`?`$select=id,displayName" }
catch { Write-Host 'Could not read deviceHealthScripts (beta). Confirm entitlement (R1) and the current Graph endpoint.' -ForegroundColor Yellow; return }

if ($PackageName) { $scripts = $scripts | Where-Object { $_.displayName -eq $PackageName } }
if (-not $scripts) { Write-Host 'No matching Proactive Remediation packages.' -ForegroundColor Yellow; return }

$stamp = (Get-Date).ToString('s')
$rows = foreach ($s in $scripts) {
    $sum = $null; try { $sum = Invoke-MgGraphRequest -Method GET -Uri "$base/$($s.id)/runSummary" } catch {}
    [pscustomobject]@{
        Timestamp             = $stamp
        Package               = $s.displayName
        NoIssue               = $sum.noIssueDetectedDeviceCount
        IssueDetected         = $sum.issueDetectedDeviceCount
        Remediated            = $sum.issueRemediatedDeviceCount
        RemediationFailed     = $sum.remediationScriptErrorDeviceCount
        DetectionFailed       = $sum.detectionScriptErrorDeviceCount
        IssueNotRemediated    = $sum.issueReoccurredDeviceCount
    }
}

$rows | Export-Csv -NoTypeInformation -Path $CsvPath
Write-Host "CSV written: $CsvPath" -ForegroundColor Cyan
Write-Host ''
$rows | Format-Table Package, NoIssue, IssueDetected, Remediated, RemediationFailed, DetectionFailed -AutoSize
Write-Host ''
Write-Host 'Compare successive exports: a falling IssueDetected count = the remediation practice is working.' -ForegroundColor Green
Write-Host 'A rising IssueNotRemediated / recurring count = a fix that is not holding (possible loop) — investigate before widening.' -ForegroundColor Yellow
