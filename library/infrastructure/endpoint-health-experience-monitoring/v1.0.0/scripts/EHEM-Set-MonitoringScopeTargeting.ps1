<#
.SYNOPSIS
    EHEM-Set-MonitoringScopeTargeting.ps1 — build/update the monitoring-scope Entra group (Graph).
.DESCRIPTION
    PURPOSE
        Creates (or reuses) the Microsoft Entra security group used to scope the Endpoint analytics
        monitoring population and its proactive remediations, following the naming convention
        "<Purpose> - <Scope> - <Stage>" (e.g. "Endpoint Analytics - All Windows - Monitoring").
        Optionally seeds the group with all Windows managed devices so monitoring/remediations can be
        assigned to one consistent target. Idempotent.
    HOW TO RUN
        Preview:  powershell -ExecutionPolicy Bypass -File .\EHEM-Set-MonitoringScopeTargeting.ps1 `
                    -GroupName "Endpoint Analytics - All Windows - Monitoring" -WhatIf
        Apply:    powershell -ExecutionPolicy Bypass -File .\EHEM-Set-MonitoringScopeTargeting.ps1 `
                    -GroupName "Endpoint Analytics - All Windows - Monitoring" -SeedWindowsDevices
        Requires the Microsoft Graph SDK and Group.ReadWrite.All + DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        The named security group exists; with -SeedWindowsDevices, all Windows managed devices are
        added as members. Assign Endpoint analytics proactive remediations to this group in Intune.
.NOTES
    Endpoint Health & Digital Experience Monitoring — Infrastructure. Naming: <Purpose> - <Scope> - <Stage>.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)][string]$GroupName,
    [switch]$SeedWindowsDevices
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# Find or create the scope group
$escaped = $GroupName.Replace("'", "''")
$existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escaped'").value
if ($existing) {
    $group = $existing[0]
    Write-Host ("Group exists: {0}  (id {1})" -f $group.displayName, $group.id) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($GroupName, 'Create Entra security group')) {
        $body = @{
            displayName     = $GroupName
            description     = 'Monitoring scope for Intune Endpoint analytics and proactive remediations.'
            mailEnabled     = $false
            mailNickname    = (($GroupName -replace '[^a-zA-Z0-9]','')).ToLower()
            securityEnabled = $true
        }
        $group = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Created group: {0}  (id {1})" -f $group.displayName, $group.id) -ForegroundColor Green
    } else { Write-Host "WhatIf: would create group '$GroupName'." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
}

# Optionally seed with Windows managed devices (by their Entra device object)
if ($SeedWindowsDevices) {
    $uri = "/v1.0/deviceManagement/managedDevices?`$select=azureADDeviceId,deviceName,operatingSystem&`$filter=operatingSystem eq 'Windows'"
    $devs = @(); do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    Write-Host ("Windows managed devices found: {0}" -f $devs.Count) -ForegroundColor Cyan
    $added = 0
    foreach ($d in $devs) {
        if (-not $d.azureADDeviceId) { continue }
        $obj = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=deviceId eq '$($d.azureADDeviceId)'&`$select=id").value
        if (-not $obj) { continue }
        if ($PSCmdlet.ShouldProcess($d.deviceName, 'Add device to monitoring scope group')) {
            try {
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($group.id)/members/`$ref" `
                    -Body (@{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($obj[0].id)" } | ConvertTo-Json)
                $added++
            } catch { } # already a member -> ignore
        }
    }
    Write-Host ("Members added: {0}" -f $added) -ForegroundColor Green
}

Write-Host "`nNext: assign Endpoint analytics proactive remediations to this group in Intune." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
