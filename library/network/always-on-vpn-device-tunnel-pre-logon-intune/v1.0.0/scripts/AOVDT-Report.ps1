<#
.SYNOPSIS
    AOVDT-Report.ps1 — Always On VPN device-tunnel + certificate coverage report across the fleet.
.DESCRIPTION
    PURPOSE
        Read-only fleet coverage report for the Windows Always On VPN device-tunnel deployment. For the
        Custom OMA-URI ProfileXML profile and each certificate profile (Trusted Root CA, SCEP machine
        cert), pulls Intune apply-status counts (succeeded, error/conflict, pending, not applicable)
        via deviceStatusOverview and prints a coverage summary plus an optional CSV. Use it to prove
        pilot coverage and to watch drift during expansion. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AOVDT-Report.ps1
        Optional: -CsvPath .\aovdt-coverage.csv to export per-object rows.
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementConfiguration.Read.All
            DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table per profile with Succeeded, Failed, Pending, NotApplicable counts and a coverage
        percentage, plus an overall figure. Target: pilot 100%; expansion >= your threshold (e.g. 95%).
        Rows with Failed>0 flag where to run remediation.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. VPN gateway head-end internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $CsvPath = ''
)

$ErrorActionPreference = 'Stop'

$ExpectedProfiles = @(
    'AOVPN – Device Tunnel – ProfileXML – Windows',
    'AOVPN – Device Tunnel – Trusted Root CA – Windows',
    'AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows'
)

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementManagedDevices.Read.All'
    )
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph as $((Get-MgContext).Account)" -ForegroundColor Green
}

function Invoke-Graph {
    param([string] $Uri)
    $results = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $Uri = $resp.'@odata.nextLink'
    } while ($Uri)
    return $results
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

Write-Host "`n=== Always On VPN Device Tunnel — Fleet Coverage Report ===" -ForegroundColor Cyan
$rows = @()

# --- Profiles: use per-profile device status overview ------------------------
$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
foreach ($name in $ExpectedProfiles) {
    $prof = $allConfigs | Where-Object { $_.displayName -eq $name }
    if (-not $prof) {
        $rows += [pscustomobject]@{ Object=$name; Succeeded=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct='n/a (missing)' }
        continue
    }
    try {
        $s = Invoke-MgGraphRequest -Method GET -Uri "$base/deviceManagement/deviceConfigurations/$($prof.id)/deviceStatusOverview"
        $ok   = [int]$s.successCount
        $fail = [int]$s.errorCount + [int]$s.conflictCount
        $pend = [int]$s.pendingCount
        $na   = [int]$s.notApplicableCount
        $den  = $ok + $fail + $pend
        $pct  = if ($den -gt 0) { [math]::Round(($ok / $den) * 100, 1) } else { 0 }
        $rows += [pscustomobject]@{ Object=$name; Succeeded=$ok; Failed=$fail; Pending=$pend; NotApplicable=$na; CoveragePct="$pct%" }
    } catch {
        $rows += [pscustomobject]@{ Object=$name; Succeeded=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct='n/a (no summary)' }
    }
}

$rows | Format-Table -AutoSize -Wrap

# --- Overall coverage --------------------------------------------------------
$totOk   = ($rows | Measure-Object Succeeded -Sum).Sum
$totFail = ($rows | Measure-Object Failed    -Sum).Sum
$totPend = ($rows | Measure-Object Pending   -Sum).Sum
$totDen  = $totOk + $totFail + $totPend
$overall = if ($totDen -gt 0) { [math]::Round(($totOk / $totDen) * 100, 1) } else { 0 }

Write-Host "`n=== Overall ===" -ForegroundColor Cyan
Write-Host ("  Succeeded        : {0}" -f $totOk)
Write-Host ("  Failed           : {0}" -f $totFail) -ForegroundColor $(if($totFail -gt 0){'Yellow'}else{'Green'})
Write-Host ("  Pending          : {0}" -f $totPend)
Write-Host ("  Overall coverage : {0}%" -f $overall) -ForegroundColor $(if($overall -ge 95){'Green'}elseif($overall -ge 80){'Yellow'}else{'Red'})
if ($totFail -gt 0) {
    Write-Host "  Rows with Failed>0 are candidates for AOVDT-Remediation.ps1." -ForegroundColor Yellow
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported per-object rows to $CsvPath" -ForegroundColor Green
}
Write-Host "Report complete (read-only). No changes were made." -ForegroundColor Green
