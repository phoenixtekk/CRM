<#
.SYNOPSIS
    CPAVPN-Report.ps1 — per-app VPN coverage across managed mobile devices (read-only).
.DESCRIPTION
    PURPOSE
        Produces a coverage report for Cisco per-app VPN across managed iOS and Android devices:
        which devices carry the 'Cisco Per-App VPN - iOS' / 'Cisco Per-App VPN - Android' profile,
        the applied/not-applied state, and a rollup by platform. Optionally writes a CSV. Read-only.
        Cisco head-end coverage is confirmed on the Cisco side, not here.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPAVPN-Report.ps1 -CsvPath .\cpavpn-coverage.csv

        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A per-device table (device, OS, profile applied yes/no, state) and a coverage summary
        (covered vs total, per platform). Optional CSV. No changes are made (read-only).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param(
    [string] $ProfileName = 'Cisco Per-App VPN',
    [string] $CsvPath
)

Write-Host "`n=== CPAVPN Report — per-app VPN coverage (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

# --- Enumerate managed mobile devices (iOS + Android) ---
$devices = @()
try {
    $uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS' or operatingSystem eq 'Android'&`$top=200"
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        $devices += $resp.value
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
} catch {
    Write-Host ("  Could not enumerate managed devices: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

if (-not $devices) {
    Write-Host "  No iOS/Android managed devices found." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($d in $devices) {
    $applied = $false; $state = 'not-applied'
    try {
        $states = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices/$($d.id)/deviceConfigurationStates").value
        $vpn = $states | Where-Object { $_.displayName -match $ProfileName } | Select-Object -First 1
        if ($vpn) { $applied = $true; $state = $vpn.state }
    } catch { }
    $rows.Add([pscustomobject]@{
        DeviceName     = $d.deviceName
        OS             = $d.operatingSystem
        User           = $d.userPrincipalName
        Compliance     = $d.complianceState
        PerAppVpn      = if ($applied) { 'yes' } else { 'no' }
        ProfileState   = $state
    })
}

# --- Print table ---
Write-Host ""
$rows | Sort-Object OS, DeviceName | Format-Table DeviceName, OS, User, Compliance, PerAppVpn, ProfileState -AutoSize

# --- Coverage rollup ---
Write-Host "`n[Coverage summary]" -ForegroundColor Cyan
foreach ($os in ($rows.OS | Sort-Object -Unique)) {
    $set = $rows | Where-Object { $_.OS -eq $os }
    $cov = ($set | Where-Object { $_.PerAppVpn -eq 'yes' }).Count
    $pct = if ($set.Count) { [math]::Round(100.0 * $cov / $set.Count, 1) } else { 0 }
    Write-Host ("  {0,-8} {1}/{2} covered ({3}%)" -f $os, $cov, $set.Count, $pct) -ForegroundColor Green
}
$total = $rows.Count
$totalCov = ($rows | Where-Object { $_.PerAppVpn -eq 'yes' }).Count
Write-Host ("  TOTAL    {0}/{1} covered" -f $totalCov, $total) -ForegroundColor Green

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`n  CSV written: {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Host ("  Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "`n[Cisco head-end coverage — DEFERRED] confirm live sessions on the Cisco side per Cisco docs." -ForegroundColor DarkYellow
Disconnect-MgGraph | Out-Null
