<#
.SYNOPSIS
    WINPERF-Set-ScopeTargeting.ps1 — build/populate a pilot Entra group via Graph (default preview).
.DESCRIPTION
    PURPOSE
        Creates or updates the Microsoft Entra security group used to scope performance measurement
        and remediation to a controlled pilot (then a wider rollout), keeping you piloting before any
        fleet-wide action. It DEFAULTS TO PREVIEW (-WhatIf) — it describes the group and membership
        changes it would make and changes nothing until you re-run in apply mode.
    HOW TO RUN
        Preview (default, safe):
          powershell -ExecutionPolicy Bypass -File .\WINPERF-Set-ScopeTargeting.ps1 -GroupName "WINPERF-Pilot" -MemberDeviceNames pc-01,pc-02
        Apply for real:
          powershell -ExecutionPolicy Bypass -File .\WINPERF-Set-ScopeTargeting.ps1 -GroupName "WINPERF-Pilot" -MemberDeviceNames pc-01,pc-02 -Apply

        -GroupName          name of the Entra security group to create/use (required)
        -MemberDeviceNames  device display names to add (comma-separated)
        -Apply              actually create/modify the group (omit to preview)
    EXPECTED RESULTS
        Connects to Microsoft Graph, then lists whether the group exists (or WOULD be created) and
        which devices WOULD be added. In preview nothing changes; with -Apply the group is created and
        members added, and the final membership is printed. Requires the Microsoft.Graph module and
        the Group.ReadWrite.All scope.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [string]$GroupName,
    [string[]]$MemberDeviceNames = @(),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

# Default to preview unless -Apply is passed.
if (-not $Apply) { $WhatIfPreference = $true }

$mode = if ($Apply) { 'APPLY' } else { 'PREVIEW (-WhatIf) — nothing will change' }
Write-Host "=== WINPERF Scope Targeting — $mode ===" -ForegroundColor Cyan

# --- Ensure module ---
if (-not (Get-Module Microsoft.Graph.Groups -ListAvailable)) {
    throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Groups -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction SilentlyContinue

# --- Connect ---
Write-Host "Connecting to Microsoft Graph (scope Group.ReadWrite.All)..." -ForegroundColor DarkGray
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

# --- Find or plan the group ---
$existing = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Group exists: $($existing.DisplayName) [$($existing.Id)]" -ForegroundColor Green
    $group = $existing
} else {
    if ($PSCmdlet.ShouldProcess($GroupName, "Create Entra security group")) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]','')
        $group = New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $mailNick `
            -SecurityEnabled:$true -Description "WINPERF performance/reliability pilot scope"
        Write-Host "Created group: $($group.DisplayName) [$($group.Id)]" -ForegroundColor Green
    } else {
        Write-Host "WOULD create Entra security group: $GroupName"
        $group = $null
    }
}

# --- Resolve and add device members ---
foreach ($name in $MemberDeviceNames) {
    $dev = Get-MgDevice -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dev) { Write-Warning "Device not found in Entra: $name"; continue }
    if ($PSCmdlet.ShouldProcess("$name -> $GroupName", "Add device to group")) {
        if ($group) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $dev.Id -ErrorAction Stop
                Write-Host "  added: $name" -ForegroundColor Green
            } catch {
                if ("$_" -match 'already exist') { Write-Host "  already a member: $name" }
                else { Write-Warning "  failed to add $name : $_" }
            }
        }
    } else {
        Write-Host "  WOULD add: $name  (device id $($dev.Id))"
    }
}

# --- Report final membership (apply mode, group exists) ---
if ($Apply -and $group) {
    Write-Host "`nCurrent membership of $($group.DisplayName):" -ForegroundColor Cyan
    Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "  - $($_.AdditionalProperties.displayName)" }
}

Write-Host "`nDone ($mode)." -ForegroundColor $(if ($Apply) {'Green'} else {'Yellow'})
if (-not $Apply) { Write-Host "Re-run with -Apply to create/modify the group for real." }

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
