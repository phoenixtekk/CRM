<#
.SYNOPSIS
    WS1MAC-Set-MigrationRingTargeting.ps1 — build/populate the macOS migration ring groups (Entra, Graph).
.DESCRIPTION
    PURPOSE
        Creates (if missing) the two migration ring security groups used throughout this solution —
        'WS1MAC Migration - Pilot Ring' and 'WS1MAC Migration - Production Ring' — and adds the
        supplied Macs to the chosen ring. This is how you target which devices move in which wave.
        Group names are reused verbatim by the parity-object assignments in the Implementation Guide.
        It changes Entra group membership, so it defaults to -WhatIf (preview). It does NOT reassign
        devices in Apple Business Manager or unenroll from Workspace ONE — those are vendor-console
        actions (deferred to vendor docs).
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\WS1MAC-Set-MigrationRingTargeting.ps1 -Ring Pilot -DeviceNames "MAC-001","MAC-002"
        Apply:              powershell -ExecutionPolicy Bypass -File .\WS1MAC-Set-MigrationRingTargeting.ps1 -Ring Pilot -DeviceNames "MAC-001","MAC-002" -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK and these scopes:
        Group.ReadWrite.All, DeviceManagementManagedDevices.Read.All, Device.Read.All.
    EXPECTED RESULTS
        With -WhatIf (default): reports which groups would be created and which Macs would be added.
        With -WhatIf:$false: creates the ring groups if missing and adds the named Macs to the chosen
        ring. Re-run WS1MAC-Validation.ps1 after assigning parity objects to confirm targeting.
.NOTES
    Migrations — Workspace ONE to Intune macOS. Defaults to -WhatIf. ABM reassignment / WS1 release are vendor-console actions.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [ValidateSet('Pilot','Production')]
    [string]$Ring = 'Pilot',
    [string[]]$DeviceNames = @()
)

# Default to WhatIf unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementManagedDevices.Read.All','Device.Read.All' -NoWelcome

$groupName = if ($Ring -eq 'Pilot') { 'WS1MAC Migration - Pilot Ring' } else { 'WS1MAC Migration - Production Ring' }
Write-Host "=== WS1->Intune macOS — migration ring targeting ($Ring) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (WhatIf mode — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

# Find or create the ring group
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $groupName)).value | Select-Object -First 1
if (-not $grp) {
    if ($PSCmdlet.ShouldProcess($groupName, "Create Entra security group")) {
        $body = @{
            displayName     = $groupName
            mailEnabled     = $false
            mailNickname    = ($groupName -replace '[^A-Za-z0-9]','')
            securityEnabled = $true
            description     = "Migration ring for Workspace ONE to Intune macOS migration ($Ring)."
        }
        $grp = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body ($body | ConvertTo-Json)
        Write-Host "  Created group '$groupName'." -ForegroundColor Green
    } else { Write-Host "  Would create group '$groupName'." -ForegroundColor Yellow }
} else { Write-Host "  Group '$groupName' already exists." -ForegroundColor Green }

if (-not $DeviceNames -or $DeviceNames.Count -eq 0) {
    Write-Host "`nNo -DeviceNames supplied — group ensured, no members added." -ForegroundColor Cyan
    Disconnect-MgGraph | Out-Null; exit 0
}

foreach ($name in $DeviceNames) {
    # Resolve the managed Mac, then its Entra device object (membership is by directory device object)
    $mdev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'&`$select=azureADDeviceId,deviceName" -f $name)).value | Select-Object -First 1
    if (-not $mdev -or -not $mdev.azureADDeviceId) { Write-Host "  (skip) $name not found as a managed Mac with an Entra device id." -ForegroundColor Yellow; continue }
    $dirDev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/devices?`$filter=deviceId eq '{0}'" -f $mdev.azureADDeviceId)).value | Select-Object -First 1
    if (-not $dirDev) { Write-Host "  (skip) $name has no Entra directory device object yet." -ForegroundColor Yellow; continue }

    if ($PSCmdlet.ShouldProcess($name, "Add to '$groupName'")) {
        if (-not $grp.id) { Write-Host "  (skip) group not created in WhatIf preview — $name not added." -ForegroundColor Yellow; continue }
        try {
            $ref = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($dirDev.id)" }
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $grp.id) -Body ($ref | ConvertTo-Json) | Out-Null
            Write-Host "  Added $name to '$groupName'." -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -match 'already exist') { Write-Host "  $name already a member of '$groupName'." -ForegroundColor DarkGray }
            else { Write-Host "  Failed to add ${name}: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
    }
}

Write-Host "`nNext: assign the WS1MAC Parity objects to '$groupName', then reassign these Macs in ABM and re-enroll (Implementation Step 8)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
