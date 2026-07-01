<#
.SYNOPSIS
    NSDIAG-Report.ps1 — client-health and device-context report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Read-only. Builds the device-context half of the Diagnostic Bundle - Endpoint - Collect:
        managed-device context from Microsoft Graph (OS, compliance, last sync) so triage can tell a
        client fault from an enrollment/compliance fault. Also prints the local client summary and a
        reminder to attach the vendor-deferred client logs for escalation.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSDIAG-Report.ps1 [-DeviceName <name>] [-CsvPath C:\Temp\nsdiag.csv]
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Local client summary, the device's Graph context (compliance/last sync/OS), optional CSV, and
        a vendor-log handoff reminder.
.NOTES
    Network category — client troubleshooting toolkit. Read-only against Graph.
#>
[CmdletBinding()]
param(
    [string]$DeviceName = $env:COMPUTERNAME,
    [string]$CsvPath
)

Write-Host "=== Netskope client report — device context for '$DeviceName' ===" -ForegroundColor Cyan

# Local client summary (quick, no elevation assumptions)
$svc = Get-Service -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'netskope|stAgent' -or $_.DisplayName -match 'Netskope' }
Write-Host ("Local client services running: {0}" -f (@($svc | Where-Object Status -eq 'Running').Count))

# Microsoft Graph device context
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

$filter = "deviceName eq '$DeviceName'"
$uri = "/v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,osVersion,complianceState,lastSyncDateTime,enrolledDateTime&`$filter=$filter"
$resp = Invoke-MgGraphRequest -Method GET -Uri $uri
$rows = @($resp.value | ForEach-Object {
    [pscustomobject]@{
        Device     = $_.deviceName
        OS         = $_.operatingSystem
        OSVersion  = $_.osVersion
        Compliance = $_.complianceState
        LastSync   = $_.lastSyncDateTime
        Enrolled   = $_.enrolledDateTime
    }
})

if ($rows.Count -eq 0) {
    Write-Host "No matching managed device in Intune (check enrollment / device name)." -ForegroundColor Yellow
} else {
    $rows | Format-Table -AutoSize
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
}

Disconnect-MgGraph | Out-Null

Write-Host "`nNOTE: For escalation, attach this bundle PLUS the Netskope client's own logs." -ForegroundColor DarkCyan
Write-Host "      Locate the client log path via Netskope's official documentation for your client version (vendor-deferred)." -ForegroundColor DarkCyan
