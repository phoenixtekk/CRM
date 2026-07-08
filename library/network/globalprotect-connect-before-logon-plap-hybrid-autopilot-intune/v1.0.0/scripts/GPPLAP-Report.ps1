<#
.SYNOPSIS
    GPPLAP-Report.ps1 — GlobalProtect Connect Before Logon (PLAP) install coverage report across the Autopilot fleet.
.DESCRIPTION
    PURPOSE
        Read-only fleet coverage report for the GlobalProtect Connect Before Logon (PLAP) Autopilot
        deployment. For the single Win32 app 'GlobalProtect – Connect Before Logon (PLAP) – Win32' (and the
        two-app alternative, if used) and the optional SCEP certificate profile, pulls Intune
        install/apply status counts (installed, failed, pending, not applicable) and prints a coverage
        summary plus an optional CSV. Use it to prove pilot coverage and to watch drift during expansion.
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPPLAP-Report.ps1
        Optional: -CsvPath .\gpplap-coverage.csv to export per-object rows.
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementApps.Read.All
            DeviceManagementConfiguration.Read.All
            DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table per app/profile with Installed/Succeeded, Failed, Pending, NotApplicable counts and a
        coverage percentage, plus an overall coverage figure. Target: pilot 100%; expansion >= your
        threshold (e.g. 95%). Rows with Failed>0 flag where to run GPPLAP-Collect-Logs.ps1 on the device.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. GlobalProtect portal/gateway and app internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $CsvPath = ''
)

$ErrorActionPreference = 'Stop'

$ExpectedApps = @(
    'GlobalProtect – Connect Before Logon (PLAP) – Win32',
    'GlobalProtect – VPN Client – Win32',
    'GlobalProtect – PLAP Registration – Win32'
)
$ExpectedProfiles = @(
    'GlobalProtect – PLAP – Device Cert (SCEP) – Windows'
)

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementApps.Read.All',
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

Write-Host "`n=== GlobalProtect PLAP — Autopilot Fleet Coverage Report ===" -ForegroundColor Cyan
$rows = @()

# --- Apps: use per-app install summary ---------------------------------------
$allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
foreach ($name in $ExpectedApps) {
    $app = $allApps | Where-Object { $_.displayName -eq $name }
    if (-not $app) {
        $note = if ($name -eq $ExpectedApps[0]) { 'n/a (missing)' } else { 'n/a (two-app alt/missing)' }
        $rows += [pscustomobject]@{ Type='App'; Object=$name; Installed=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct=$note }
        continue
    }
    try {
        $s = Invoke-MgGraphRequest -Method GET -Uri "$base/deviceAppManagement/mobileApps/$($app[0].id)/installSummary"
        $inst = [int]$s.installedDeviceCount
        $fail = [int]$s.failedDeviceCount
        $pend = [int]$s.pendingInstallDeviceCount
        $na   = [int]$s.notApplicableDeviceCount
        $den  = $inst + $fail + $pend
        $pct  = if ($den -gt 0) { [math]::Round(($inst / $den) * 100, 1) } else { 0 }
        $rows += [pscustomobject]@{ Type='App'; Object=$name; Installed=$inst; Failed=$fail; Pending=$pend; NotApplicable=$na; CoveragePct="$pct%" }
    } catch {
        $rows += [pscustomobject]@{ Type='App'; Object=$name; Installed=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct='n/a (no summary)' }
    }
}

# --- Profiles: use per-profile device status summary -------------------------
$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
foreach ($name in $ExpectedProfiles) {
    $prof = $allConfigs | Where-Object { $_.displayName -eq $name }
    if (-not $prof) {
        $rows += [pscustomobject]@{ Type='Profile'; Object=$name; Installed=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct='n/a (optional/missing)' }
        continue
    }
    try {
        $s = Invoke-MgGraphRequest -Method GET -Uri "$base/deviceManagement/deviceConfigurations/$($prof[0].id)/deviceStatusOverview"
        $ok   = [int]$s.successCount
        $fail = [int]$s.errorCount + [int]$s.conflictCount
        $pend = [int]$s.pendingCount
        $na   = [int]$s.notApplicableCount
        $den  = $ok + $fail + $pend
        $pct  = if ($den -gt 0) { [math]::Round(($ok / $den) * 100, 1) } else { 0 }
        $rows += [pscustomobject]@{ Type='Profile'; Object=$name; Installed=$ok; Failed=$fail; Pending=$pend; NotApplicable=$na; CoveragePct="$pct%" }
    } catch {
        $rows += [pscustomobject]@{ Type='Profile'; Object=$name; Installed=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct='n/a (no summary)' }
    }
}

$rows | Format-Table -AutoSize -Wrap

# --- Overall coverage --------------------------------------------------------
$totInst = ($rows | Measure-Object Installed -Sum).Sum
$totFail = ($rows | Measure-Object Failed    -Sum).Sum
$totPend = ($rows | Measure-Object Pending   -Sum).Sum
$totDen  = $totInst + $totFail + $totPend
$overall = if ($totDen -gt 0) { [math]::Round(($totInst / $totDen) * 100, 1) } else { 0 }

Write-Host "`n=== Overall ===" -ForegroundColor Cyan
Write-Host ("  Installed/Succeeded : {0}" -f $totInst)
Write-Host ("  Failed              : {0}" -f $totFail) -ForegroundColor $(if($totFail -gt 0){'Yellow'}else{'Green'})
Write-Host ("  Pending             : {0}" -f $totPend)
Write-Host ("  Overall coverage    : {0}%" -f $overall) -ForegroundColor $(if($overall -ge 95){'Green'}elseif($overall -ge 80){'Yellow'}else{'Red'})
if ($totFail -gt 0) {
    Write-Host "  Rows with Failed>0: run GPPLAP-Collect-Logs.ps1 on the failing device(s) and see 06-troubleshooting.md." -ForegroundColor Yellow
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported per-object rows to $CsvPath" -ForegroundColor Green
}
Write-Host "Report complete (read-only). No changes were made." -ForegroundColor Green
