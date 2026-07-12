<#
.SYNOPSIS
    SOPEIS-ConflictReport.ps1 — report devices/settings in Conflict or Error and the policies
    contributing to each. Read-only. The map for consolidating to one authoritative policy.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Solution Optimization — Endpoint Security with Microsoft
        Intune" solution. Policy conflict (one setting set by two policies) is the number-one
        drift symptom. This script enumerates managed devices whose configuration/compliance
        state is 'conflict' or 'error', and for a chosen device lists the per-setting states so
        you can see which policies overlap. Makes no changes.
    HOW TO RUN
        # Summary across the estate (or scope to a group via -GroupName):
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-ConflictReport.ps1
        # Drill into one device's per-setting states:
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-ConflictReport.ps1 -DeviceName 'PILOT-01'
        Requires Microsoft.Graph.Authentication with DeviceManagementManagedDevices.Read.All and
        DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A count of devices in conflict/error and a list of the worst offenders; with -DeviceName,
        the per-setting states for that device (the settings to consolidate). Compare the count to
        the saved baseline to prove conflicts fell.
.NOTES
    White-label. Read-only. Reports state only; consolidation is done in the portal per
    Implementation Step 3.
#>
[CmdletBinding()]
param(
    [string]$DeviceName,
    [string]$GroupName,
    [string]$OutputPath = ".\SOPEIS-conflicts.json"
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome | Out-Null }

function Get-All($uri) {
    $items = @()
    while ($uri) {
        $r = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        if ($r.value) { $items += $r.value }
        $uri = $r.'@odata.nextLink'
    }
    return $items
}

Write-Host "`n=== SOPEIS conflict report (read-only) ===" -ForegroundColor Cyan

if ($DeviceName) {
    # Per-device drill-down: list configuration setting states that are conflict/error.
    $dev = Get-All ("https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=deviceName eq '{0}'" -f $DeviceName) | Select-Object -First 1
    if (-not $dev) { Write-Host ("Device '{0}' not found." -f $DeviceName) -ForegroundColor Red; return }
    Write-Host ("Device: {0} ({1})" -f $dev.deviceName, $dev.id)
    try {
        $states = Get-All ("https://graph.microsoft.com/beta/deviceManagement/managedDevices/{0}/deviceConfigurationStates" -f $dev.id)
        $bad = $states | Where-Object { $_.state -in 'conflict','error' }
        if ($bad) {
            foreach ($s in $bad) {
                Write-Host ("   [{0}] {1}" -f $s.state.ToUpper(), $s.displayName) -ForegroundColor Yellow
                $settingStates = Get-All ("https://graph.microsoft.com/beta/deviceManagement/managedDevices/{0}/deviceConfigurationStates/{1}/settingStates" -f $dev.id, $s.id)
                $settingStates | Where-Object { $_.state -in 'conflict','error' } | ForEach-Object { Write-Host ("       setting: {0}  = {1}" -f $_.setting, $_.state) }
            }
        } else { Write-Host "   No conflict/error configuration states on this device." -ForegroundColor Green }
    } catch { Write-Host ("   Could not read device states: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    return
}

# Estate/group summary: count devices with a conflict/error compliance or configuration state.
$devices = Get-All 'https://graph.microsoft.com/beta/deviceManagement/managedDevices?$select=id,deviceName,complianceState&$top=200'
Write-Host ("Managed devices scanned: {0}" -f $devices.Count)

$conflict = 0; $error = 0; $offenders = @()
foreach ($d in $devices) {
    try {
        $states = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices/{0}/deviceConfigurationStates?`$select=state,displayName" -f $d.id) -ErrorAction SilentlyContinue
        $bad = $states.value | Where-Object { $_.state -in 'conflict','error' }
        if ($bad) {
            $c = ($bad | Where-Object { $_.state -eq 'conflict' }).Count
            $e = ($bad | Where-Object { $_.state -eq 'error' }).Count
            $conflict += $c; $error += $e
            $offenders += [pscustomobject]@{ Device = $d.deviceName; Conflicts = $c; Errors = $e }
        }
    } catch {}
}

Write-Host ("`nTotal setting-conflicts: {0}   errors: {1}" -f $conflict, $error) -ForegroundColor $(if ($conflict + $error -eq 0) { 'Green' } else { 'Yellow' })
if ($offenders) {
    Write-Host "`nTop offenders (drill in with -DeviceName):" -ForegroundColor Cyan
    $offenders | Sort-Object { $_.Conflicts + $_.Errors } -Descending | Select-Object -First 15 | Format-Table -AutoSize | Out-String | Write-Host
}
@{ Timestamp = (Get-Date).ToString('s'); Conflicts = $conflict; Errors = $error; Offenders = $offenders } |
    ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Saved: {0}. Consolidate to one authoritative policy per setting (Implementation Step 3)." -f $OutputPath) -ForegroundColor Green
