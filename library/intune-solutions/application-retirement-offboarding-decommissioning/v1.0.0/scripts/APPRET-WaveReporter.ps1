<#
.SYNOPSIS
    APPRET-WaveReporter.ps1 — retirement-wave status, planning, and straggler classification.
.DESCRIPTION
    PURPOSE
        The operational reporter for a running uninstall campaign. Three actions:
          -Action Status      : per-device uninstall/detection status for the app, summarised and
                                (optionally) exported — the wave gate check. (read-only)
          -Action Plan        : split an install-base CSV (from APPRET-Discovery) into balanced wave
                                lists, spread across departments/OU, so waves are representative.
                                (read-only; writes CSVs only if -OutFolder is given)
          -Action Stragglers  : classify devices that have NOT uninstalled — Offline/NeverCheckedIn,
                                StillRequired (an install intent still wins), or UninstallFailed
                                (escalate to Win32 uninstall failure remediation). (read-only)
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPRET-WaveReporter.ps1 -AppName "LegacyTrack Client" -Action Status
        powershell -ExecutionPolicy Bypass -File .\APPRET-WaveReporter.ps1 -Action Plan -InstallBaseCsv .\install-base.csv -Waves 3 -OutFolder .\waves
        powershell -ExecutionPolicy Bypass -File .\APPRET-WaveReporter.ps1 -AppName "LegacyTrack Client" -Action Stragglers -StaleDays 14
        US Gov: add  -Environment USGov  or  -Environment USGovDoD
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        Status: Installed/Uninstalled/Failed counts + optional CSV. Plan: N wave CSVs. Stragglers: a
        classified table with each device's disposition for the evidence pack.
.NOTES
    Intune Solutions — read-only reporting/planning. Execution stage of an application retirement.
#>
[CmdletBinding()]
param(
    [ValidateSet('Status','Plan','Stragglers')][string]$Action = 'Status',
    [string]$AppName,
    [string]$CsvPath,
    [string]$InstallBaseCsv,
    [int]$Waves = 3,
    [int]$StaleDays = 14,
    [string]$OutFolder,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

# ---- Plan is offline CSV math; no Graph needed ----
if ($Action -eq 'Plan') {
    if (-not (Test-Path $InstallBaseCsv)) { Write-Host "InstallBaseCsv not found: $InstallBaseCsv" -ForegroundColor Red; return }
    $rows = Import-Csv $InstallBaseCsv
    # round-robin by a grouping key (User domain / department if present) to balance waves
    $key = ($rows[0].PSObject.Properties.Name | Where-Object { $_ -in 'Department','User','Ou' } | Select-Object -First 1)
    $sorted = if ($key) { $rows | Sort-Object $key } else { $rows }
    $buckets = @{}; 1..$Waves | ForEach-Object { $buckets[$_] = @() }
    for ($i=0; $i -lt $sorted.Count; $i++) { $w = ($i % $Waves) + 1; $buckets[$w] += $sorted[$i] }
    foreach ($w in 1..$Waves) {
        Write-Host ("Wave {0}: {1} devices" -f $w, $buckets[$w].Count) -ForegroundColor Cyan
        if ($OutFolder) {
            if (-not (Test-Path $OutFolder)) { New-Item -ItemType Directory -Path $OutFolder | Out-Null }
            $p = Join-Path $OutFolder ("wave-$w.csv"); $buckets[$w] | Export-Csv $p -NoTypeInformation -Encoding UTF8
            Write-Host "  -> $p" -ForegroundColor Green
        }
    }
    return
}

if (-not $AppName) { Write-Host "-AppName is required for Status/Stragglers." -ForegroundColor Red; return }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All' -Environment $Environment -NoWelcome

$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$app = ($apps | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1)
if (-not $app) { Write-Host "No app named '$AppName' found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
$id = $app.id

$dev = @(); $duri = "/v1.0/deviceAppManagement/mobileApps/$id/deviceStatuses"
do { $dr = Invoke-MgGraphRequest -Method GET -Uri $duri; $dev += $dr.value; $duri = $dr.'@odata.nextLink' } while ($duri)

if ($Action -eq 'Status') {
    $g = $dev | Group-Object installState | Sort-Object Name
    Write-Host ("=== {0} — uninstall status ===" -f $app.displayName) -ForegroundColor Cyan
    foreach ($x in $g) { Write-Host ("    {0,-16} {1}" -f $x.Name, $x.Count) }
    $installed = ($dev | Where-Object { $_.installState -in 'installed' }).Count
    $total = $dev.Count
    if ($total) { Write-Host ("    Removed so far: {0}%  (still installed: {1})" -f [math]::Round((($total-$installed)/$total)*100,1), $installed) -ForegroundColor Green }
    if ($CsvPath) { $dev | Select-Object deviceName,userName,installState,installStateDetail,lastSyncDateTime | Export-Csv $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Saved $CsvPath" -ForegroundColor Green }
}
elseif ($Action -eq 'Stragglers') {
    $cut = (Get-Date).AddDays(-$StaleDays)
    $rows = foreach ($d in ($dev | Where-Object { $_.installState -notin 'notInstalled','uninstalled','unknown' -or $_.installState -eq 'failed' })) {
        $last = try { [datetime]$d.lastSyncDateTime } catch { $null }
        $class =
            if ($d.installState -eq 'failed') { 'UninstallFailed -> escalate to Win32 uninstall remediation' }
            elseif ($last -and $last -lt $cut) { 'Offline/Stale -> chase device or mark decommissioned' }
            elseif ($d.installState -eq 'installed') { 'StillInstalled -> check for a winning Required assignment' }
            else { $d.installState }
        [pscustomobject]@{ Device=$d.deviceName; User=$d.userName; State=$d.installState; LastSync=$d.lastSyncDateTime; Class=$class; Detail=$d.installStateDetail }
    }
    if ($rows) {
        $rows | Sort-Object Class | Format-Table -AutoSize
        Write-Host ("Stragglers: {0}" -f $rows.Count) -ForegroundColor Yellow
        if ($CsvPath) { $rows | Export-Csv $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Saved $CsvPath" -ForegroundColor Green }
    } else { Write-Host "No stragglers — every reachable device has removed the app." -ForegroundColor Green }
}
Disconnect-MgGraph | Out-Null
