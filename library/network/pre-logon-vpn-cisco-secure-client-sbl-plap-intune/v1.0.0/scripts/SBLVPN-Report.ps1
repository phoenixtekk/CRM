<#
.SYNOPSIS
    SBLVPN-Report.ps1 — Pre-Logon VPN (Cisco Secure Client SBL/PLAP) coverage report across the fleet.
.DESCRIPTION
    PURPOSE
        Read-only fleet coverage report for the Cisco Secure Client Start Before Logon (SBL/PLAP)
        deployment. For the Win32 app and each configuration profile (the Windows VPN profile, the
        Trusted Root CA profile, and the SCEP device-certificate profile), pulls Intune install/apply
        status counts (installed, failed, pending, not applicable) and prints a coverage summary plus
        an optional CSV. Use it to prove pilot coverage, to watch drift during expansion, and to catch
        an expiring/failed device certificate before it silently breaks pre-logon. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SBLVPN-Report.ps1
        Optional: -CsvPath .\sblvpn-coverage.csv to export per-object rows.
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementApps.Read.All
            DeviceManagementConfiguration.Read.All
            DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table per app/profile with Installed/Succeeded, Failed, Pending, NotApplicable counts and a
        coverage percentage, plus an overall coverage figure. Target: pilot 100%; expansion >= your
        threshold (e.g. 95%). Rows with Failed>0 flag where to run remediation.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco-specific internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $CsvPath = ''
)

$ErrorActionPreference = 'Stop'

$ExpectedApps = @(
    'Cisco Secure Client – Pre-Logon (SBL) – Win32'
)
$ExpectedProfiles = @(
    'Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows',
    'Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows',
    'Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows'
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

Write-Host "`n=== Pre-Logon VPN (Cisco SBL/PLAP) — Fleet Coverage Report ===" -ForegroundColor Cyan
$rows = @()

# --- App: use per-app install summary ----------------------------------------
$allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
foreach ($name in $ExpectedApps) {
    $app = $allApps | Where-Object { $_.displayName -eq $name }
    if (-not $app) {
        $rows += [pscustomobject]@{ Type='App'; Object=$name; Installed=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct='n/a (missing)' }
        continue
    }
    try {
        $s = Invoke-MgGraphRequest -Method GET -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/installSummary"
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
        $note = if ($name -like '*Profile – Windows') { 'n/a (optional/missing)' } else { 'n/a (missing)' }
        $rows += [pscustomobject]@{ Type='Profile'; Object=$name; Installed=0; Failed=0; Pending=0; NotApplicable=0; CoveragePct=$note }
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
    Write-Host "  Rows with Failed>0 are candidates for SBLVPN-Remediation.ps1." -ForegroundColor Yellow
}
Write-Host "  Tip: watch the SCEP device-cert row — an expiring/failed cert silently breaks pre-logon." -ForegroundColor DarkGray

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported per-object rows to $CsvPath" -ForegroundColor Green
}
Write-Host "Report complete (read-only). No changes were made." -ForegroundColor Green
