<#
.SYNOPSIS
    PERIDEV-Set-ScopeTargeting.ps1 — create/populate the PERIDEV pilot and targeting groups.
.DESCRIPTION
    PURPOSE
        Sets up the security groups this solution targets: the pilot group, the production
        group, and the USB exception group, and optionally adds seed devices to the pilot.
        Defaults to preview mode (-WhatIf) and changes nothing until you re-run to confirm.
        Uses the exact PERIDEV names so all guides and scripts line up.
    HOW TO RUN
        Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Set-ScopeTargeting.ps1

        Apply, seeding two pilot devices:
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Set-ScopeTargeting.ps1 -WhatIf:$false -PilotDeviceNames DESKTOP-01,DESKTOP-02

        Required Graph scopes: Group.ReadWrite.All, Device.Read.All,
        DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        In preview: the groups and memberships that WOULD be created. When applied: the three
        groups exist and any named pilot devices are added to SG-PERIDEV-Pilot. Pass =
        planned/applied actions listed without error.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; re-run with -WhatIf:$false to apply.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string[]]$PilotDeviceNames = @(),
    [string]$PilotGroupName      = 'SG-PERIDEV-Pilot',
    [string]$ProductionGroupName = 'SG-PERIDEV-Production',
    [string]$ExceptionGroupName  = 'SG-PERIDEV-USB-Exception'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

function Connect-PeridevGraph {
    $scopes = @('Group.ReadWrite.All','Device.Read.All','DeviceManagementManagedDevices.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph." -ForegroundColor Green
}

function Get-OrCreateGroup {
    param([string]$Name, [string]$Description)
    try {
        $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$Name'" -ErrorAction Stop
        if ($g.value -and $g.value[0].id) {
            Write-Host ("  OK  group '{0}' already exists." -f $Name) -ForegroundColor DarkGray
            return $g.value[0].id
        }
    } catch { }
    if ($PSCmdlet.ShouldProcess($Name, "Create security group")) {
        $mailNick = ($Name -replace '[^a-zA-Z0-9]','')
        $body = @{
            displayName     = $Name
            description     = $Description
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        } | ConvertTo-Json
        $new = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups" -Body $body -ContentType 'application/json' -ErrorAction Stop
        Write-Host ("  CREATED  group '{0}'." -f $Name) -ForegroundColor Green
        return $new.id
    }
    Write-Host ("  WOULD CREATE  group '{0}'." -f $Name) -ForegroundColor Yellow
    return $null
}

Connect-PeridevGraph

Write-Host "`n=== Ensure PERIDEV targeting groups ===" -ForegroundColor Cyan
$pilotId = Get-OrCreateGroup -Name $PilotGroupName      -Description 'PERIDEV pilot ring - drivers, peripherals, device control.'
$null    = Get-OrCreateGroup -Name $ProductionGroupName -Description 'PERIDEV production population.'
$null    = Get-OrCreateGroup -Name $ExceptionGroupName  -Description 'PERIDEV approved removable-storage exception.'

if ($PilotDeviceNames.Count -gt 0) {
    Write-Host "`n=== Seed pilot devices ===" -ForegroundColor Cyan
    if (-not $pilotId) {
        Write-Host "  (pilot group not yet created in preview - devices would be added after creation)" -ForegroundColor Yellow
    }
    try {
        $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$top=200" -ErrorAction Stop
        foreach ($name in $PilotDeviceNames) {
            $dev = $md.value | Where-Object { $_.deviceName -eq $name } | Select-Object -First 1
            if (-not $dev) { Write-Warning "  Device '$name' not found in Intune - skipped."; continue }
            # Resolve the Entra device object id from the Azure AD device id
            $aadId = $dev.azureADDeviceId
            $entra = $null
            if ($aadId) {
                try {
                    $e = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$aadId'" -ErrorAction Stop
                    $entra = $e.value[0]
                } catch { }
            }
            if (-not $entra) { Write-Warning "  Could not resolve Entra device object for '$name' - skipped."; continue }
            if ($PSCmdlet.ShouldProcess($name, "Add to $PilotGroupName")) {
                if ($pilotId) {
                    $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($entra.id)" } | ConvertTo-Json
                    try {
                        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups/$pilotId/members/`$ref" -Body $ref -ContentType 'application/json' -ErrorAction Stop | Out-Null
                        Write-Host ("  ADDED  '{0}' to {1}." -f $name, $PilotGroupName) -ForegroundColor Green
                    } catch {
                        if ($_.Exception.Message -match 'already exist') { Write-Host ("  OK  '{0}' already a member." -f $name) -ForegroundColor DarkGray }
                        else { Write-Warning "  Add failed for '$name': $($_.Exception.Message)" }
                    }
                }
            } else {
                Write-Host ("  WOULD ADD  '{0}' to {1}." -f $name, $PilotGroupName) -ForegroundColor Yellow
            }
        }
    } catch { Write-Warning "Device seeding failed: $($_.Exception.Message)" }
}

if ($WhatIfPreference) {
    Write-Host "`nPreview only. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
} else {
    Write-Host "`nScope targeting applied." -ForegroundColor Green
}
