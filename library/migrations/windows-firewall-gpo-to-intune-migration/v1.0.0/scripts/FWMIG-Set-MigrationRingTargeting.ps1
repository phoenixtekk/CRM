<#
.SYNOPSIS
    FWMIG-Set-MigrationRingTargeting.ps1 - Create/populate the migration ring Entra groups (Microsoft Graph).

.DESCRIPTION
    PURPOSE
        Builds the targeting backbone for the ringed firewall cutover: the Entra security groups
            'Migration Ring - Pilot'
            'Migration Ring - Wave 1'
            'Migration Ring - Broad'
        and (optionally) adds device members to a chosen ring. These are the groups the Intune
        'Firewall Policy - Migrated Rules - *' and 'Firewall Rules - Migrated * - *' profiles are
        assigned to. Group creation is gated behind -Apply (default is a safe preview).

    HOW TO RUN
        Connect to Microsoft Graph first (delegated, least privilege):
            Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All'
        Preview what would be created (safe, default):
            .\FWMIG-Set-MigrationRingTargeting.ps1
        Create the groups:
            .\FWMIG-Set-MigrationRingTargeting.ps1 -Apply
        Create groups and add devices to a ring (by Entra device object id):
            .\FWMIG-Set-MigrationRingTargeting.ps1 -Apply -Ring Pilot -DeviceObjectId <id1>,<id2>

    EXPECTED RESULTS
        - Default: prints which of the three ring groups exist vs would be created - no changes.
        - -Apply: creates any missing ring groups (idempotent - reuses existing by displayName) and,
          if -DeviceObjectId is supplied, adds those devices to the named -Ring group.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [switch]   $Apply,
    [ValidateSet('Pilot','Wave1','Broad')]
    [string]   $Ring,
    [string[]] $DeviceObjectId
)

if (-not $Apply) { $WhatIfPreference = $true }

if (-not (Get-MgContext)) {
    Write-Error "Not connected. Run: Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All'"
    return
}

$ringGroups = [ordered]@{
    Pilot = 'Migration Ring - Pilot'
    Wave1 = 'Migration Ring - Wave 1'
    Broad = 'Migration Ring - Broad'
}

$created = @{}
foreach ($key in $ringGroups.Keys) {
    $name = $ringGroups[$key]
    $existing = Get-MgGroup -Filter "displayName eq '$name'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "EXISTS: $name ($($existing.Id))" -ForegroundColor Green
        $created[$key] = $existing
        continue
    }
    if ($PSCmdlet.ShouldProcess($name, 'Create Entra security group')) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]', '')
        $g = New-MgGroup -DisplayName $name -SecurityEnabled:$true -MailEnabled:$false `
                         -MailNickname $mailNick -GroupTypes @()
        Write-Host "CREATED: $name ($($g.Id))" -ForegroundColor Cyan
        $created[$key] = $g
    } else {
        Write-Host "WOULD CREATE: $name" -ForegroundColor Yellow
    }
}

# --- Optionally add device members to a ring ---
if ($Ring -and $DeviceObjectId) {
    $target = $created[$Ring]
    if (-not $target) {
        Write-Host "Ring group '$($ringGroups[$Ring])' not available (create it first with -Apply)." -ForegroundColor Red
        return
    }
    foreach ($id in $DeviceObjectId) {
        if ($PSCmdlet.ShouldProcess("$id", "Add to $($ringGroups[$Ring])")) {
            try {
                New-MgGroupMember -GroupId $target.Id -DirectoryObjectId $id -ErrorAction Stop
                Write-Host "  Added device $id to $($ringGroups[$Ring])" -ForegroundColor Green
            } catch {
                Write-Host "  Failed to add $id : $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  WOULD ADD device $id to $($ringGroups[$Ring])" -ForegroundColor Yellow
        }
    }
}

if (-not $Apply) { Write-Host "`nMODE: preview only. Re-run with -Apply to create groups / add members." -ForegroundColor Yellow }
