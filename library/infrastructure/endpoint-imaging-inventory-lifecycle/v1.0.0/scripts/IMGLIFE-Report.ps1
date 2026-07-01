<#
.SYNOPSIS
    IMGLIFE-Report.ps1 - lifecycle and hardware asset-reconciliation report.
.DESCRIPTION
    PURPOSE
        Produces the inventory source-of-truth report across two Microsoft Graph surfaces:
        (1) Intune managed devices (manufacturer, model, serial, storage, enrollment + last-sync
        dates), and (2) the Windows Autopilot registered-devices list (the procurement-to-deployment
        ledger). It then reconciles them so gaps are obvious: devices registered to Autopilot but not
        enrolled in Intune (procured/registered but not deployed), and enrolled devices flagged as
        refresh-due by an age threshold. This is the report you reconcile against your purchase list.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IMGLIFE-Report.ps1 -RefreshAfterDays 1460
        -RefreshAfterDays sets the age (since enrollment) at which a device is flagged refresh-due
        (default 1460 = ~4 years). Requires the Microsoft Graph PowerShell SDK and consent for
        DeviceManagementManagedDevices.Read.All and DeviceManagementServiceConfig.Read.All (delegated).
    EXPECTED RESULTS
        A managed-device inventory table, the Autopilot registered list, a reconciliation of
        registered-but-not-enrolled devices, and a refresh-due list - so coverage and aging gaps are
        clear before you procure, refresh, or retire.
.NOTES
    Infrastructure solution - the repeatable way. Read-only (GET only against Graph).
#>
[CmdletBinding()]
param(
    [int]$RefreshAfterDays = 1460
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All', 'DeviceManagementServiceConfig.Read.All' -NoWelcome

# ---- Intune managed devices (the hardware inventory source of truth) ----
Write-Host "`n=== Intune managed devices (hardware inventory) ===" -ForegroundColor Cyan
$managed = @()
try {
    $uri = '/v1.0/deviceManagement/managedDevices'
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        $managed += $resp.value
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
} catch {
    Write-Host "  Could not read managed devices: $($_.Exception.Message)" -ForegroundColor Yellow
}
$managed |
    Select-Object deviceName, manufacturer, model, serialNumber, operatingSystem, enrolledDateTime, lastSyncDateTime |
    Format-Table -AutoSize

# ---- Windows Autopilot registered devices (the procurement ledger) ----
Write-Host "=== Windows Autopilot registered devices ===" -ForegroundColor Cyan
$autopilot = @()
try {
    $autopilot = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities').value
} catch {
    Write-Host "  Could not read Autopilot identities: $($_.Exception.Message)" -ForegroundColor Yellow
}
$autopilot |
    Select-Object serialNumber, manufacturer, model, enrollmentState |
    Format-Table -AutoSize

# ---- Reconciliation: registered to Autopilot but not enrolled in Intune ----
Write-Host "=== Reconciliation: registered but NOT deployed (no Intune enrollment) ===" -ForegroundColor Cyan
$enrolledSerials = $managed | ForEach-Object { $_.serialNumber } | Where-Object { $_ }
$gap = $autopilot | Where-Object { $_.serialNumber -and ($enrolledSerials -notcontains $_.serialNumber) }
if ($gap) { $gap | Select-Object serialNumber, model, enrollmentState | Format-Table -AutoSize }
else      { Write-Host "  (none - every registered device is enrolled)" -ForegroundColor Green }

# ---- Refresh-due by age since enrollment ----
Write-Host ("=== Refresh-due (enrolled more than {0} days ago) ===" -f $RefreshAfterDays) -ForegroundColor Cyan
$cutoff = (Get-Date).AddDays(-$RefreshAfterDays)
$refresh = $managed | Where-Object {
    $_.enrolledDateTime -and ([datetime]$_.enrolledDateTime -lt $cutoff)
}
if ($refresh) { $refresh | Select-Object deviceName, model, serialNumber, enrolledDateTime | Format-Table -AutoSize }
else          { Write-Host "  (none within the threshold)" -ForegroundColor Green }

Write-Host ("`nSummary: {0} managed device(s), {1} Autopilot-registered, {2} registration gap(s), {3} refresh-due." -f `
    $managed.Count, $autopilot.Count, ($gap | Measure-Object).Count, ($refresh | Measure-Object).Count) -ForegroundColor Green

Disconnect-MgGraph | Out-Null
Write-Host "Reconcile this report against your procurement list to find devices off the books." -ForegroundColor Green
