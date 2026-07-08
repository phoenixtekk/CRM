<#
.SYNOPSIS
    DLPMac-Onboarding-Check.ps1 — scope/health helper: managed macOS devices + onboarding/extension profiles from Intune (read-only, Graph).
.DESCRIPTION
    PURPOSE
        Helps confirm the macOS onboarding prerequisites for Endpoint DLP are in place: reports managed
        macOS devices and their OS versions from Intune (are they on a supported release?), and lists
        macOS configuration profiles that look like the onboarding / system-extension / network-extension
        / Full-Disk-Access (PPPC) payloads this solution requires. Read-only against Microsoft Graph.
        NOTE: definitive Endpoint DLP onboarding status lives in the Purview portal (Settings -> Device
        onboarding) — there is no supported cmdlet for it; this is a management-plane health check, not
        a substitute for the portal confirmation.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPMac-Onboarding-Check.ps1
        PowerShell 5.1+/7+. Requires the Microsoft Graph PowerShell SDK; connects with delegated read
        scopes: DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All. No secrets.
    EXPECTED RESULTS
        A count of managed macOS devices with OS-version breakdown (flags anything below the three-latest
        support window heuristically), and a list of macOS config profiles matching onboarding/extension/
        PPPC name patterns. Then confirm the Macs appear onboarded in the Purview portal.
.NOTES
    Purview category — macOS Endpoint DLP. Read-only. macOS supported for the three latest major releases —
    verify the current supported version list against Microsoft guidance.
#>
[CmdletBinding()]
param(
    [string]$ProfileNamePattern = 'onboard|defender|dlp|purview|extension|full disk|pppc|content filter'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Microsoft Graph module not found — installing for current user..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host "`n=== macOS onboarding / scope health (Intune management plane) ===" -ForegroundColor Cyan

# 1) Managed macOS devices + OS versions
Write-Host "`n-- Managed macOS devices --" -ForegroundColor Cyan
try {
    $macs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,osVersion,complianceState,lastSyncDateTime").value
    if (-not $macs -or $macs.Count -eq 0) {
        Write-Host "  No managed macOS devices found — enroll the Macs in Intune/Jamf before onboarding (Requirement 2.5)." -ForegroundColor Yellow
    } else {
        Write-Host ("  {0} managed macOS device(s)." -f $macs.Count) -ForegroundColor Green
        $macs | Group-Object osVersion | Sort-Object Name -Descending | ForEach-Object {
            # Heuristic: flag clearly old majors (< 13) — verify the current supported list.
            $major = 0; [void][int]::TryParse((("$($_.Name)".Split('.')[0])), [ref]$major)
            $col = if ($major -gt 0 -and $major -lt 13) { 'Yellow' } else { 'Gray' }
            Write-Host ("    macOS {0,-10} : {1} device(s)" -f $_.Name, $_.Count) -ForegroundColor $col
        }
        Write-Host "    (Endpoint DLP supports the three latest major macOS versions — verify the current list.)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host ("  Unable to read managed devices: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 2) macOS config profiles that look like onboarding / extension / PPPC payloads
Write-Host "`n-- macOS configuration profiles (onboarding / extension / Full Disk Access) --" -ForegroundColor Cyan
try {
    $cfgs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$select=id,displayName,'@odata.type'").value
    $macCfgs = $cfgs | Where-Object { "$($_.'@odata.type')" -match 'macOS|mac' -or "$($_.displayName)" -match $ProfileNamePattern }
    $hits = $macCfgs | Where-Object { "$($_.displayName)" -match $ProfileNamePattern }
    if (-not $hits -or $hits.Count -eq 0) {
        Write-Host "  No profiles matched the onboarding/extension/PPPC name patterns — confirm 'Purview DLP - macOS Onboarding' and the extension / Full Disk Access profiles exist (Implementation Step 2)." -ForegroundColor Yellow
    } else {
        Write-Host ("  {0} candidate profile(s):" -f $hits.Count) -ForegroundColor Green
        foreach ($c in $hits) { Write-Host ("    {0}   [{1}]" -f $c.displayName, ("$($c.'@odata.type')" -replace '#microsoft.graph.','')) }
        Write-Host "    (Confirm each is assigned to the pilot Mac group and actually applies on-device.)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host ("  Unable to read device configurations: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nDefinitive onboarding status: Purview -> Settings -> Device onboarding -> Devices (no supported cmdlet enumerates it)." -ForegroundColor DarkGray
Write-Host "On a pilot Mac, verify: system extension allowed + Full Disk Access granted (System Settings -> Privacy & Security)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
