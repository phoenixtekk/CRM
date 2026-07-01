<#
.SYNOPSIS
    WS1IOS-Set-MigrationRingTargeting.ps1 — create the pilot and broad migration ring groups.

.DESCRIPTION
    PURPOSE
        Creates the two assigned (static) Microsoft Entra security groups used to ring the migration:
        'iOS Migration – Pilot Ring – Pilot' and 'iOS Migration – Broad Ring – Expand'. Assign the
        Intune ADE enrollment profile, parity apps, parity configuration profiles, and the compliance
        policy to these groups, then add devices/users per wave. Idempotent — skips a group that
        already exists.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\WS1IOS-Set-MigrationRingTargeting.ps1 -WhatIf      # preview (default posture)
        .\WS1IOS-Set-MigrationRingTargeting.ps1              # create the ring groups

    EXPECTED RESULTS
        Two security groups exist in Entra ready for ring assignment. Existing groups are left untouched.

.NOTES
    Creates groups; supports -WhatIf. The repeatable Workspace ONE to Intune iOS/iPadOS migration.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PilotGroupName    = 'iOS Migration – Pilot Ring – Pilot',
    [string]$PilotMailNickname = 'ios-migration-pilot-ring',
    [string]$BroadGroupName    = 'iOS Migration – Broad Ring – Expand',
    [string]$BroadMailNickname = 'ios-migration-broad-ring'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'Group.ReadWrite.All' | Out-Null

function New-RingGroup {
    param([string]$Name, [string]$Nick, [string]$Desc)

    $existing = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $Name.Replace("'","''"))).value
    if ($existing) {
        Write-Host "Group '$Name' already exists (id $($existing[0].id)) — skipping." -ForegroundColor Yellow
        return
    }

    $body = @{
        displayName     = $Name
        description     = $Desc
        mailEnabled     = $false
        mailNickname    = $Nick
        securityEnabled = $true
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create assigned security group')) {
        $new = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host "Created '$Name' (id $($new.id))." -ForegroundColor Green
    } else {
        Write-Host "[WhatIf] Would create assigned security group '$Name'."
    }
}

New-RingGroup -Name $PilotGroupName -Nick $PilotMailNickname -Desc 'Pilot ring for the Workspace ONE to Intune iOS/iPadOS migration. Assign the ADE profile, parity apps/profiles, and compliance here first.'
New-RingGroup -Name $BroadGroupName -Nick $BroadMailNickname -Desc 'Broad ring for the Workspace ONE to Intune iOS/iPadOS migration. Expand after the pilot gate passes.'

Write-Host ''
Write-Host 'Next: assign iOS Migration – Corporate Supervised – Pilot/Broad, the parity profiles, the parity apps,'
Write-Host 'and iOS Parity – Compliance Baseline – Cutover to these groups, then add devices/users per wave.'
