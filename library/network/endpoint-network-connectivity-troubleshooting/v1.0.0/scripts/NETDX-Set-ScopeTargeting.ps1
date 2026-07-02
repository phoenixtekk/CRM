<#
.SYNOPSIS
    NETDX-Set-ScopeTargeting.ps1 — build/maintain a pilot Entra group for staged connectivity testing.
.DESCRIPTION
    PURPOSE
        Creates (if missing) and populates a Microsoft Entra security group of pilot devices via
        Microsoft Graph so connectivity changes and validation runs are scoped to a small pilot before
        fleet-wide rollout. Defaults to preview mode (-WhatIf on) so no group or membership changes
        are made until you confirm. Supply device object IDs (or device names) to add to the pilot.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NETDX-Set-ScopeTargeting.ps1 -GroupName "NETDX-Pilot-Devices" -DeviceIds id1,id2
        (preview only)
        powershell -ExecutionPolicy Bypass -File .\NETDX-Set-ScopeTargeting.ps1 -GroupName "NETDX-Pilot-Devices" -DeviceIds id1,id2 -WhatIf:$false
        Required Graph scopes: Group.ReadWrite.All, GroupMember.ReadWrite.All
        Requires the Microsoft.Graph module: Install-Module Microsoft.Graph -Scope CurrentUser
    EXPECTED RESULTS
        In preview, admin sees the group that would be created and members that would be added, with
        no changes. With -WhatIf:$false the group is created if missing and the devices are added.
        Pass = the pilot group exists and contains the requested devices; use it to scope validation.
.NOTES
    White-label — the repeatable way. Scope targeting defaults to -WhatIf (preview).
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string]$GroupName,

    [string]$GroupDescription = 'Pilot devices for staged network connectivity validation (NETDX).',

    [string[]]$DeviceIds = @()
)

$ErrorActionPreference = 'Stop'

# Default posture: -WhatIf ON unless the caller explicitly disabled it (-WhatIf:$false).
if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
    Write-Host "[preview] Running in -WhatIf mode; no Entra changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
}

# --- module + connection ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    throw "Microsoft.Graph module not found. Install it with: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

Write-Host 'Connecting to Microsoft Graph...' -ForegroundColor Cyan
Connect-MgGraph -Scopes 'Group.ReadWrite.All', 'GroupMember.ReadWrite.All' -NoWelcome -ErrorAction Stop

# --- find or create the group ---
$existing = Get-MgGroup -Filter "displayName eq '$GroupName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue |
    Select-Object -First 1

$group = $existing
if (-not $existing) {
    if ($PSCmdlet.ShouldProcess($GroupName, 'Create Entra security group')) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '')
        if (-not $mailNick) { $mailNick = 'netdxpilot' }
        $group = New-MgGroup -DisplayName $GroupName -Description $GroupDescription `
            -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -ErrorAction Stop
        Write-Host ("  PASS  Created group '{0}' (id {1})" -f $GroupName, $group.Id) -ForegroundColor Green
    }
    else {
        Write-Host ("  What if: would create Entra security group '{0}'." -f $GroupName) -ForegroundColor Yellow
    }
}
else {
    Write-Host ("Group '{0}' already exists (id {1})." -f $GroupName, $existing.Id) -ForegroundColor Green
}

# --- add members ---
foreach ($id in $DeviceIds) {
    if ([string]::IsNullOrWhiteSpace($id)) { continue }
    if ($PSCmdlet.ShouldProcess($id, "Add device to group '$GroupName'")) {
        try {
            if (-not $group -or -not $group.Id) {
                Write-Host ("  SKIP  Add {0}: group not yet created (preview)." -f $id) -ForegroundColor Yellow
                continue
            }
            New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $id -ErrorAction Stop
            Write-Host ("  PASS  Added device {0}" -f $id) -ForegroundColor Green
        }
        catch {
            Write-Host ("  FAIL  Add device {0}: {1}" -f $id, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Write-Host ''
if ($WhatIfPreference) {
    Write-Host 'Preview complete. Review above, then re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow
}
else {
    Write-Host ("Pilot group '{0}' is ready. Scope your validation run to these devices." -f $GroupName) -ForegroundColor Green
}

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
