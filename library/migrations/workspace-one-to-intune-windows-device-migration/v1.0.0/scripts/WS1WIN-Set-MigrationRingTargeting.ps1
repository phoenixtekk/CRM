<#
.SYNOPSIS
    WS1WIN-Set-MigrationRingTargeting.ps1 — build/maintain the migration-ring Entra groups (Graph).
.DESCRIPTION
    PURPOSE
        Ensures the migration ring groups exist in Microsoft Entra ID and previews/sets membership
        for the ringed cutover:
          "Group - Migration Pilot - Windows"
          "Group - Migration Broad - Windows"
          "Group - Workspace ONE Managed - Windows"   (inventory/source)
        Given a list of pilot device names, it shows which devices would move into the pilot group
        (and out of the source group). Defaults to -WhatIf: it reports the planned changes and
        creates/changes nothing until you re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (safe, default):
          powershell -ExecutionPolicy Bypass -File .\WS1WIN-Set-MigrationRingTargeting.ps1 -PilotDeviceNames PC01,PC02
        Apply:
          powershell -ExecutionPolicy Bypass -File .\WS1WIN-Set-MigrationRingTargeting.ps1 -PilotDeviceNames PC01,PC02 -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK and:
          Group.ReadWrite.All, Device.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        Confirmation that the three groups exist (created in apply mode if missing), and a preview/
        application of pilot-device membership. Read WS1WIN-Report.ps1 afterwards to see counts.
.NOTES
    Workplace Marketplace — Migrations. Defaults to -WhatIf. Creates only the named ring groups.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string[]]$PilotDeviceNames = @(),
    [string]$PilotGroup  = 'Group - Migration Pilot - Windows',
    [string]$BroadGroup  = 'Group - Migration Broad - Windows',
    [string]$SourceGroup = 'Group - Workspace ONE Managed - Windows'
)
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== Migration ring targeting ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  MODE: -WhatIf (preview only). Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }

function Get-OrCreateGroup([string]$displayName){
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$displayName'&`$select=id,displayName").value | Select-Object -First 1
    if ($g) { Write-Host ("  EXISTS: {0}" -f $displayName) -ForegroundColor Green; return $g }
    if ($PSCmdlet.ShouldProcess($displayName, "Create security group")) {
        $mailNick = ($displayName -replace '[^a-zA-Z0-9]','')
        $body = @{ displayName = $displayName; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  CREATED: {0}" -f $displayName) -ForegroundColor Green
        return $new
    } else {
        Write-Host ("  WOULD CREATE: {0}" -f $displayName) -ForegroundColor Yellow
        return $null
    }
}

$pilot  = Get-OrCreateGroup $PilotGroup
$broad  = Get-OrCreateGroup $BroadGroup
$source = Get-OrCreateGroup $SourceGroup

if ($PilotDeviceNames.Count -eq 0) {
    Write-Host "`n  No -PilotDeviceNames supplied; group existence check only." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

Write-Host "`n--- Pilot membership plan ---" -ForegroundColor Cyan
foreach ($name in $PilotDeviceNames) {
    # Resolve the Entra device object (directory object) for group membership
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=displayName eq '$name'&`$select=id,displayName").value | Select-Object -First 1
    if (-not $dev) { Write-Host ("  SKIP {0}: no Entra device object found." -f $name) -ForegroundColor Yellow; continue }
    if (-not $pilot) { Write-Host ("  WOULD ADD {0} to {1} (group not yet created)." -f $name, $PilotGroup) -ForegroundColor Yellow; continue }
    if ($PSCmdlet.ShouldProcess($name, "Add to $PilotGroup")) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($dev.id)" }
        try {
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($pilot.id)/members/`$ref" -Body ($ref | ConvertTo-Json)
            Write-Host ("  ADDED {0} -> {1}" -f $name, $PilotGroup) -ForegroundColor Green
        } catch {
            Write-Host ("  {0}: {1}" -f $name, $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  WOULD ADD {0} -> {1}" -f $name, $PilotGroup) -ForegroundColor Yellow
    }
}

Write-Host "`n  Note: keep '$SourceGroup' as the inventory of un-migrated devices; move devices into" -ForegroundColor Green
Write-Host "  '$BroadGroup' in waves as you cut them over. Use WS1WIN-Report.ps1 to track counts." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
