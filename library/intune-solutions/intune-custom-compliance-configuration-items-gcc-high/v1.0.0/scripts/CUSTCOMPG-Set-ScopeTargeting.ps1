<#
.SYNOPSIS
    CUSTCOMPG-Set-ScopeTargeting.ps1 — Stage devices into the GCC High pilot/production target groups (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Controlled scope/target-group builder for the Government (GCC High) edition of Intune
        Custom Compliance, gated behind -WhatIf so it PREVIEWS membership changes and changes
        nothing until you opt in. Adds the devices you supply (by device name or object id) to
        the named Entra security group used for compliance-policy assignment, so you can expand
        in controlled waves. Point -GroupName at your group (e.g. 'CUSTCOMPG-Prod-Devices') and
        supply devices via -DeviceNames or -DeviceObjectIds.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\CUSTCOMPG-Set-ScopeTargeting.ps1 -GroupName "CUSTCOMPG-Prod-Devices" -DeviceNames "PC-001","PC-002"
        Apply (explicit):
          powershell -ExecutionPolicy Bypass -File .\CUSTCOMPG-Set-ScopeTargeting.ps1 -GroupName "CUSTCOMPG-Prod-Devices" -DeviceNames "PC-001","PC-002" -WhatIf:$false
        (Graph scopes: Group.ReadWrite.All, Device.Read.All; -Environment USGov)
    EXPECTED RESULTS
        In preview: the exact add operations that WOULD run, and nothing changes. When applied:
        the listed devices are added to the target group (existing members are skipped).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string] $GroupName,
    [string[]] $DeviceNames     = @(),
    [string[]] $DeviceObjectIds = @()
)

# Default posture: preview only unless caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

function Connect-UsGovGraph {
    param([string[]] $Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if ((Get-MgContext).Environment -ne 'USGov') {
        Write-Host "Connecting to Microsoft Graph US Gov (GCC High) — Environment USGov..." -ForegroundColor Cyan
        Connect-MgGraph -Environment USGov -Scopes $Scopes | Out-Null
    }
    if ((Get-MgContext).Environment -ne 'USGov') {
        throw "Connected environment is not 'USGov'. Reconnect with: Connect-MgGraph -Environment USGov"
    }
    Write-Host "Connected. Environment=USGov" -ForegroundColor Green
}

function Get-AllUsGov { param([string] $RelativeUri)
    $items=@(); $uri="https://graph.microsoft.us/beta/$RelativeUri"
    while ($uri) { $r=Invoke-MgGraphRequest -Method GET -Uri $uri; if($r.value){$items+=$r.value}; $uri=$r.'@odata.nextLink' }
    return $items
}

if ($DeviceNames.Count -eq 0 -and $DeviceObjectIds.Count -eq 0) {
    throw "Supply at least one of -DeviceNames or -DeviceObjectIds."
}

Connect-UsGovGraph -Scopes @('Group.ReadWrite.All','Device.Read.All')

# Resolve the target group
$group = (Get-AllUsGov -RelativeUri "groups?`$filter=displayName eq '$GroupName'") | Select-Object -First 1
if (-not $group) { throw "Group '$GroupName' not found. Create it in entra.microsoft.us (03-implementation.md Step 1.1)." }
Write-Host "Target group '$GroupName' id=$($group.id)" -ForegroundColor Cyan

# Current members (device object ids)
$currentMembers = (Get-AllUsGov -RelativeUri "groups/$($group.id)/members?`$select=id").id

# Resolve device object ids from names
$resolvedIds = New-Object System.Collections.Generic.List[string]
foreach ($id in $DeviceObjectIds) { $resolvedIds.Add($id) }
foreach ($name in $DeviceNames) {
    $dev = (Get-AllUsGov -RelativeUri "devices?`$filter=displayName eq '$name'&`$select=id,displayName") | Select-Object -First 1
    if ($dev) { $resolvedIds.Add($dev.id); Write-Host "  resolved '$name' -> $($dev.id)" -ForegroundColor DarkGray }
    else      { Write-Warning "Device '$name' not found in the GCC High tenant — skipping." }
}

$toAdd = $resolvedIds | Where-Object { $_ -and ($currentMembers -notcontains $_) } | Select-Object -Unique

Write-Host "`n=== Planned membership changes for '$GroupName' ===" -ForegroundColor Yellow
if (-not $toAdd) { Write-Host "  Nothing to add — all supplied devices are already members." -ForegroundColor Green }
foreach ($id in $toAdd) {
    if ($PSCmdlet.ShouldProcess("group '$GroupName'", "ADD device object $id")) {
        $body = @{ '@odata.id' = "https://graph.microsoft.us/beta/directoryObjects/$id" } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.us/beta/groups/$($group.id)/members/`$ref" -Body $body | Out-Null
        Write-Host "  ADDED $id" -ForegroundColor Green
    } else {
        Write-Host "  WOULD ADD $id" -ForegroundColor DarkYellow
    }
}

if ($WhatIfPreference) {
    Write-Host "`nPREVIEW ONLY (-WhatIf). No changes were made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
} else {
    Write-Host "`nScope targeting applied. Confirm assignment on 'CUSTCOMPG-Compliance-Baseline' in intune.microsoft.us." -ForegroundColor Green
}
