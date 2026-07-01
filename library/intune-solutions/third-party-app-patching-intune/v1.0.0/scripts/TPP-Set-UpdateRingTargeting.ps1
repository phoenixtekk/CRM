<#
.SYNOPSIS
    TPP-Set-UpdateRingTargeting.ps1 — build the Pilot/Broad update-ring groups for third-party patching.
.DESCRIPTION
    PURPOSE
        Creates the two Microsoft Entra security groups used to ring third-party app assignments and
        (optionally) seeds the Pilot group with a set of device names, so catalog auto-update apps and
        packaged Win32 updates can be assigned Pilot-first, then Broad. Uses the naming convention
        "<Purpose> - <Scope> - <Stage>".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TPP-Set-UpdateRingTargeting.ps1
        Optional: -PilotDeviceNames 'PC-001','PC-002'   to seed the Pilot group with those devices.
        Optional: -WhatIf                                to preview without creating anything.
        Requires the Microsoft Graph PowerShell SDK and the scopes:
            Group.ReadWrite.All, Device.Read.All
    EXPECTED RESULTS
        The two groups exist (created if missing):
            Third-Party Patching - Devices - Pilot
            Third-Party Patching - Devices - Broad
        and, if -PilotDeviceNames is supplied, those devices are added to the Pilot group.
        Assign your catalog apps and Win32 updates to these groups in Intune (Implementation Steps 3-4).
.NOTES
    Workplace Marketplace — Intune Solutions. Supports -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param([string[]]$PilotDeviceNames)

$groupNames = @(
    'Third-Party Patching - Devices - Pilot',
    'Third-Party Patching - Devices - Broad'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome

function Get-OrNewGroup {
    param([string]$Name)
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$Name'").value
    if ($existing) { Write-Host ("  exists: {0}" -f $Name) -ForegroundColor DarkGray; return $existing[0] }
    if ($PSCmdlet.ShouldProcess($Name, 'Create security group')) {
        $mailNick = ($Name -replace '[^a-zA-Z0-9]', '')
        $body = @{ displayName = $Name; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  created: {0}" -f $Name) -ForegroundColor Green
        return $g
    }
}

Write-Host "=== Third-party patching ring groups ===" -ForegroundColor Cyan
$groups = @{}
foreach ($n in $groupNames) { $groups[$n] = Get-OrNewGroup -Name $n }

if ($PilotDeviceNames) {
    $pilot = $groups['Third-Party Patching - Devices - Pilot']
    foreach ($name in $PilotDeviceNames) {
        $dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=displayName eq '$name'").value | Select-Object -First 1
        if (-not $dev) { Write-Host ("  device not found: {0}" -f $name) -ForegroundColor Yellow; continue }
        if ($PSCmdlet.ShouldProcess("$name -> Pilot", 'Add device to Pilot group')) {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($dev.id)" }
            try {
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($pilot.id)/members/`$ref" -Body ($ref | ConvertTo-Json)
                Write-Host ("  added to Pilot: {0}" -f $name) -ForegroundColor Green
            } catch { Write-Host ("  could not add {0}: {1}" -f $name, $_.Exception.Message) -ForegroundColor Yellow }
        }
    }
}

Write-Host "`nAssign catalog apps and Win32 updates to these groups in Intune (Implementation Steps 3-4)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
