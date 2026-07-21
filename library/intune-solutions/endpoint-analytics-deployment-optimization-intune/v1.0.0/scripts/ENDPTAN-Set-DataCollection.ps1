<#
.SYNOPSIS
    ENDPTAN-Set-DataCollection.ps1 — create/assign the Endpoint Analytics data-collection policy.

.DESCRIPTION
    PURPOSE
        The ONE state-changing script in this pack. Ensures the pilot device group exists, then
        creates/assigns the Endpoint Analytics data-collection policy ('EPA – Data Collection – Pilot')
        to that group so pilot devices begin submitting experience telemetry. Idempotent — skips
        objects that already exist.

    SAFETY — DEFAULTS TO -WhatIf (PREVIEW ONLY)
        This script DEFAULTS TO -WhatIf: run with no switches and it ONLY PREVIEWS the changes and
        makes NO modifications. To actually apply changes, re-run with -Apply (or -WhatIf:$false).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTAN-Set-DataCollection.ps1                    # preview only (default, no changes)
        .\ENDPTAN-Set-DataCollection.ps1 -Apply             # actually create/assign

    GRAPH SCOPES (write)
        DeviceManagementConfiguration.ReadWrite.All
        Group.ReadWrite.All

    EXPECTED RESULTS
        In preview (default): a printed list of what WOULD be created/assigned, no changes.
        With -Apply: 'EPA – Pilot Devices' group and the 'EPA – Data Collection – Pilot' policy exist
        and the policy is assigned to the group.

    IMPORTANT — VERIFY THE RESOURCE
        The Endpoint Analytics data-collection object and its Graph resource CHANGE over time. This
        script uses a placeholder shape and will NOT invent an endpoint — before applying, VERIFY the
        current data-collection resource/settings against Microsoft documentation and adjust
        $DataCollectionUri / $body accordingly. If unset, the script previews the intended action and
        directs you to configure it in Reports > Endpoint analytics > Settings.

.NOTES
    White-label — Intune Solutions. Creates/assigns a policy; DEFAULTS TO -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PilotGroupName   = 'EPA – Pilot Devices',
    [string]$MailNickname     = 'epa-pilot-devices',
    [string]$PolicyName       = 'EPA – Data Collection – Pilot',
    # Switch to actually apply. Absent = preview only (this script DEFAULTS TO -WhatIf).
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

# DEFAULT TO -WhatIf: unless -Apply is passed, force WhatIf preview mode.
if (-not $Apply) { $WhatIfPreference = $true }

Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All','Group.ReadWrite.All' | Out-Null

if ($WhatIfPreference) {
    Write-Host '=== PREVIEW MODE (-WhatIf) — no changes will be made. Re-run with -Apply to commit. ===' -ForegroundColor Cyan
}

# 1) Ensure the pilot device group exists
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroupName.Replace("'","''"))).value
if ($grp) {
    Write-Host "Group '$PilotGroupName' already exists (id $($grp[0].id)) — skipping." -ForegroundColor Yellow
    $groupId = $grp[0].id
} else {
    $groupBody = @{
        displayName     = $PilotGroupName
        description     = 'Pilot Windows devices for Endpoint Analytics data collection. Managed by ENDPTAN solution.'
        mailEnabled     = $false
        mailNickname    = $MailNickname
        securityEnabled = $true
    }
    if ($PSCmdlet.ShouldProcess($PilotGroupName, 'Create assigned security group')) {
        $new = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body ($groupBody | ConvertTo-Json)
        $groupId = $new.id
        Write-Host "Created group '$PilotGroupName' (id $groupId)." -ForegroundColor Green
        Write-Host 'Next: add the pilot Windows devices as members (Entra > Groups > EPA – Pilot Devices > Members).'
    } else {
        Write-Host "[WhatIf] Would create assigned security group '$PilotGroupName'."
        $groupId = '<new-group-id>'
    }
}

# 2) Create/assign the Endpoint Analytics data-collection policy
#    NOTE: the data-collection resource/shape EVOLVES — VERIFY against current Microsoft documentation
#    before enabling the write below. Left as a preview-only intent so the script never invents an API.
$DataCollectionUri = $null   # <-- set to the current Endpoint Analytics data-collection resource after verifying with MS docs
$body = @{
    displayName = $PolicyName
    description = 'Endpoint Analytics data collection for the pilot device group. Managed by ENDPTAN solution.'
    # settings   = @{ ... }   # populate per the CURRENT Endpoint Analytics data-collection schema (VERIFY with MS docs)
}

if (-not $DataCollectionUri) {
    Write-Host ''
    Write-Host "INTENT: create policy '$PolicyName' and assign it to '$PilotGroupName' (group id $groupId)." -ForegroundColor Cyan
    Write-Host 'ACTION REQUIRED: the Endpoint Analytics data-collection Graph resource is not set in this script.' -ForegroundColor Yellow
    Write-Host '  VERIFY the current resource/settings against Microsoft documentation, set $DataCollectionUri + $body,'
    Write-Host '  OR enable data collection directly in Intune > Reports > Endpoint analytics > Settings and assign it to'
    Write-Host "  '$PilotGroupName'. This script will not invent an endpoint."
    return
}

if ($PSCmdlet.ShouldProcess($PolicyName, "Create + assign Endpoint Analytics data-collection policy to '$PilotGroupName'")) {
    $created = Invoke-MgGraphRequest -Method POST -Uri $DataCollectionUri -Body ($body | ConvertTo-Json -Depth 6)
    Write-Host "Created '$PolicyName' (id $($created.id))." -ForegroundColor Green
    Write-Host "Now assign it to group id $groupId per the current assignment resource (VERIFY with MS docs)."
} else {
    Write-Host "[WhatIf] Would create '$PolicyName' and assign it to '$PilotGroupName' (group id $groupId)."
}
