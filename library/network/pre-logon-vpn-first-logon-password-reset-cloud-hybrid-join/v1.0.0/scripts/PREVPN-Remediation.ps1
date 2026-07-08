<#
.SYNOPSIS
    PREVPN-Remediation.ps1 — safely add in-scope devices/users lacking a pre-logon path to the pilot group.
.DESCRIPTION
    PURPOSE
        Safe remediation for the pre-logon VPN decision. Finds IN-SCOPE Windows devices (Entra
        hybrid-joined / domain-joined) that are NOT yet members of the segmentation group for the
        chosen approach, and adds them so the companion product's pre-logon assignment reaches them.
        It does NOT create VPN profiles or apps — that is the job of the companion device-tunnel /
        SBL-PLAP products. Defaults to preview only (-WhatIf): it PRINTS what it would do and changes
        nothing until you re-run with -WhatIf:$false. Entra-joined (cloud-only) devices are skipped by
        design (they do not need a pre-logon tunnel).
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\PREVPN-Remediation.ps1
        Apply changes:
            powershell -ExecutionPolicy Bypass -File .\PREVPN-Remediation.ps1 -WhatIf:$false
        Required Microsoft Graph scopes (delegated):
            Device.Read.All
            Group.ReadWrite.All
            GroupMember.ReadWrite.All
            Directory.Read.All
    EXPECTED RESULTS
        A plan listing each in-scope device to add to the target group. In preview every line is
        prefixed [WHATIF]. With -WhatIf:$false each add prints [DONE]/[FAILED]. After applying, deploy
        (or confirm) the chosen approach via its companion product, then re-run PREVPN-Report.ps1.
.NOTES
    White-label — the repeatable way. Write actions gated behind -WhatIf (default ON). No VPN profiles created here. Vendor internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [bool]   $WhatIf = $true,
    [string] $TargetGroupName = 'PILOT – Pre-Logon First-Logon Users',
    [switch] $IncludeDomainJoinedOnly
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'Device.Read.All',
        'Group.ReadWrite.All',
        'GroupMember.ReadWrite.All',
        'Directory.Read.All'
    )
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph as $((Get-MgContext).Account)" -ForegroundColor Green
}

function Invoke-Graph {
    param([string] $Uri)
    $results = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $Uri = $resp.'@odata.nextLink'
    } while ($Uri)
    return $results
}

function Do-Action {
    param([string] $Description, [scriptblock] $Action)
    if ($WhatIf) {
        Write-Host "[WHATIF] $Description" -ForegroundColor Yellow
    } else {
        try {
            & $Action
            Write-Host "[DONE]   $Description" -ForegroundColor Green
        } catch {
            Write-Host "[FAILED] $Description :: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

$mode = if ($WhatIf) { 'PREVIEW (-WhatIf) — no changes will be made' } else { 'APPLY — changes WILL be made' }
Write-Host "`n=== Pre-Logon VPN — Remediation [$mode] ===" -ForegroundColor Cyan
Write-Host "This adds IN-SCOPE devices to the segmentation group only. It creates NO VPN profiles." -ForegroundColor DarkGray

# Resolve target group
$enc = [uri]::EscapeDataString($TargetGroupName)
$grp = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName"
if (-not $grp) { throw "Target group '$TargetGroupName' not found. Create it first (PREVPN-Set-ScopeTargeting.ps1)." }
$groupId = $grp[0].id
Write-Host "Target group: $TargetGroupName ($groupId)`n"

# Current device members of the group (by device object id)
$currentMembers = Invoke-Graph "$base/groups/$groupId/members?`$select=id"
$currentIds = @($currentMembers | ForEach-Object { $_.id })

# In-scope devices: Windows, hybrid-joined or domain-joined
$devices = Invoke-Graph "$base/devices?`$select=id,displayName,operatingSystem,trustType,onPremisesSyncEnabled&`$top=999"
$win = $devices | Where-Object { $_.operatingSystem -match 'Windows' }

$inScope = foreach ($d in $win) {
    $type = switch ($d.trustType) {
        'AzureAd'  { 'entra-joined' }
        'ServerAd' { if ($d.onPremisesSyncEnabled) { 'hybrid-joined' } else { 'domain-joined' } }
        default    { 'other' }
    }
    if ($IncludeDomainJoinedOnly) {
        if ($type -eq 'domain-joined') { [pscustomobject]@{ Id=$d.id; Name=$d.displayName; Type=$type } }
    } else {
        if ($type -in @('hybrid-joined','domain-joined')) { [pscustomobject]@{ Id=$d.id; Name=$d.displayName; Type=$type } }
    }
}

Write-Host "[1] In-scope devices lacking group membership" -ForegroundColor Cyan
$toAdd = $inScope | Where-Object { $currentIds -notcontains $_.Id }
if (-not $toAdd -or $toAdd.Count -eq 0) {
    Write-Host "  All in-scope devices are already members of '$TargetGroupName'. Nothing to do." -ForegroundColor DarkGray
} else {
    foreach ($dev in $toAdd) {
        Do-Action "Add device '$($dev.Name)' [$($dev.Type)] to '$TargetGroupName'" {
            $refBody = @{ '@odata.id' = "$base/directoryObjects/$($dev.Id)" } | ConvertTo-Json
            Invoke-MgGraphRequest -Method POST -Uri "$base/groups/$groupId/members/`$ref" -Body $refBody -ContentType 'application/json' | Out-Null
        }
    }
}

Write-Host "`n=== Remediation complete ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "This was a PREVIEW. Re-run with -WhatIf:`$false to apply the actions above." -ForegroundColor Yellow
} else {
    Write-Host "Devices added. Now deploy/confirm the chosen approach via its COMPANION product, then re-run PREVPN-Report.ps1." -ForegroundColor Green
}
Write-Host "Note: this script does NOT create device-tunnel profiles or the SBL app — build those in the companion products (see 03-implementation.md)." -ForegroundColor DarkGray
