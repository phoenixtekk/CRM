<#
.SYNOPSIS
    AOVDT-Set-ScopeTargeting.ps1 — create/populate the pilot (and production) Entra DEVICE group(s).
.DESCRIPTION
    PURPOSE
        Creates the assignment target groups for the Always On VPN device-tunnel deployment —
        'PILOT – AOVPN Device Tunnel – Devices' and (optionally) 'PROD – AOVPN Device Tunnel – Devices'
        — as assignable security groups, and adds the DEVICES you supply (by device display name).
        Because the device-tunnel ProfileXML deploys in device/SYSTEM context, these groups contain
        DEVICE objects, not users. Idempotent: if a group already exists it is reused, and devices
        already present are skipped. Defaults to preview only (-WhatIf); re-run with -WhatIf:$false to
        actually create/populate.
    HOW TO RUN
        Preview:
            powershell -ExecutionPolicy Bypass -File .\AOVDT-Set-ScopeTargeting.ps1 -PilotDevices DEVICE01,DEVICE02
        Apply:
            powershell -ExecutionPolicy Bypass -File .\AOVDT-Set-ScopeTargeting.ps1 -PilotDevices DEVICE01 -WhatIf:$false
        Required Microsoft Graph scopes (delegated):
            Group.ReadWrite.All
            GroupMember.ReadWrite.All
            Device.Read.All
    EXPECTED RESULTS
        The pilot group (and prod group if -CreateProd) exist and contain the listed DEVICES. In
        preview each create/add is prefixed [WHATIF]; with -WhatIf:$false each prints [DONE]/[FAILED].
        These exact group names are what the ProfileXML + certificate profile assignments target in
        03-implementation.md.
.NOTES
    White-label — the repeatable way. Write actions gated behind -WhatIf (default ON). VPN gateway head-end internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [bool]     $WhatIf = $true,
    [string]   $PilotGroupName = 'PILOT – AOVPN Device Tunnel – Devices',
    [string]   $ProdGroupName  = 'PROD – AOVPN Device Tunnel – Devices',
    [string[]] $PilotDevices = @(),
    [string[]] $ProdDevices  = @(),
    [switch]   $CreateProd
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('Group.ReadWrite.All','GroupMember.ReadWrite.All','Device.Read.All')
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

$base = 'https://graph.microsoft.com/v1.0'

function Ensure-Group {
    param([string] $Name)
    $enc = [uri]::EscapeDataString($Name)
    $existing = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName"
    if ($existing) {
        Write-Host "  Group '$Name' already exists ($($existing[0].id))." -ForegroundColor DarkGray
        return $existing[0].id
    }
    if ($WhatIf) {
        Write-Host "[WHATIF] Create security group '$Name'" -ForegroundColor Yellow
        return $null
    }
    $mailNick = ('aovdt-' + ($Name -replace '[^a-zA-Z0-9]', '')).ToLower()
    if ($mailNick.Length -gt 60) { $mailNick = $mailNick.Substring(0,60) }
    $body = @{
        displayName     = $Name
        description     = 'Always On VPN device-tunnel deployment target DEVICE group (created by AOVDT-Set-ScopeTargeting).'
        mailEnabled     = $false
        mailNickname    = $mailNick
        securityEnabled = $true
    } | ConvertTo-Json
    $g = Invoke-MgGraphRequest -Method POST -Uri "$base/groups" -Body $body -ContentType 'application/json'
    Write-Host "[DONE]   Created group '$Name' ($($g.id))." -ForegroundColor Green
    return $g.id
}

function Add-Devices {
    param([string] $GroupId, [string] $GroupName, [string[]] $Devices)
    if (-not $Devices -or $Devices.Count -eq 0) { return }
    if (-not $GroupId) {
        foreach ($d in $Devices) { Write-Host "[WHATIF] Add device '$d' to '$GroupName' (group not yet created)" -ForegroundColor Yellow }
        return
    }
    $current = Invoke-Graph "$base/groups/$GroupId/members?`$select=id"
    foreach ($name in $Devices) {
        $name = $name.Trim()
        if (-not $name) { continue }
        $enc = [uri]::EscapeDataString($name)
        # Resolve DEVICE object(s) by display name.
        $dev = Invoke-Graph "$base/devices?`$filter=displayName eq '$enc'&`$select=id,displayName"
        if (-not $dev) { Write-Host "  (skip) device '$name' not found." -ForegroundColor Red; continue }
        if ($dev.Count -gt 1) { Write-Host "  (warn) '$name' matches $($dev.Count) devices — adding all." -ForegroundColor Yellow }
        foreach ($d in $dev) {
            $did = $d.id
            if ($current | Where-Object { $_.id -eq $did }) {
                Write-Host "  '$name' ($did) already a member of '$GroupName'." -ForegroundColor DarkGray
                continue
            }
            if ($WhatIf) {
                Write-Host "[WHATIF] Add device '$name' ($did) to '$GroupName'" -ForegroundColor Yellow
            } else {
                $refBody = @{ '@odata.id' = "$base/directoryObjects/$did" } | ConvertTo-Json
                try {
                    Invoke-MgGraphRequest -Method POST -Uri "$base/groups/$GroupId/members/`$ref" -Body $refBody -ContentType 'application/json' | Out-Null
                    Write-Host "[DONE]   Added device '$name' to '$GroupName'." -ForegroundColor Green
                } catch {
                    Write-Host "[FAILED] Add device '$name' to '$GroupName' :: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

Connect-Graph
$mode = if ($WhatIf) { 'PREVIEW (-WhatIf) — no changes will be made' } else { 'APPLY — changes WILL be made' }
Write-Host "`n=== Always On VPN Device Tunnel — Scope Targeting [$mode] ===" -ForegroundColor Cyan

Write-Host "`n[1] Pilot DEVICE group" -ForegroundColor Cyan
$pilotId = Ensure-Group -Name $PilotGroupName
Add-Devices -GroupId $pilotId -GroupName $PilotGroupName -Devices $PilotDevices

if ($CreateProd -or $ProdDevices.Count -gt 0) {
    Write-Host "`n[2] Production DEVICE group" -ForegroundColor Cyan
    $prodId = Ensure-Group -Name $ProdGroupName
    Add-Devices -GroupId $prodId -GroupName $ProdGroupName -Devices $ProdDevices
}

Write-Host "`n=== Scope targeting complete ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "This was a PREVIEW. Re-run with -WhatIf:`$false to create/populate the group(s)." -ForegroundColor Yellow
} else {
    Write-Host "DEVICE groups ready. Assign the ProfileXML + certificate profiles to them per 03-implementation.md." -ForegroundColor Green
}
