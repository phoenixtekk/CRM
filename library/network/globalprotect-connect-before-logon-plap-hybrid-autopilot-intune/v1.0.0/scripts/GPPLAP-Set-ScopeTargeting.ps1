<#
.SYNOPSIS
    GPPLAP-Set-ScopeTargeting.ps1 — create/populate the pilot (and production) Autopilot DEVICE group(s) and set the Provisioning Client SP as owner.
.DESCRIPTION
    PURPOSE
        Creates the enrollment-time assignment target groups for the GlobalProtect Connect Before Logon
        (PLAP) Autopilot deployment — 'PILOT – GlobalProtect PLAP – Autopilot Devices' and (optionally)
        'PROD – GlobalProtect PLAP – Autopilot Devices' — as ASSIGNED security groups (NOT dynamic), adds
        the DEVICES you supply (by device display name), AND sets the Intune Provisioning Client
        first-party service principal (AppId f1346770-5b25-470b-88bd-d5744ab7952c) as an OWNER of each
        group. The SP owner is what makes enrollment-time device grouping work: without it the Assigned
        group stays empty at enrollment and nothing (apps/profiles) deploys during Autopilot. Idempotent:
        an existing group is reused, members/owner already present are skipped. Defaults to preview only
        (-WhatIf); re-run with -WhatIf:$false to actually create/populate.
    HOW TO RUN
        Preview:
            powershell -ExecutionPolicy Bypass -File .\GPPLAP-Set-ScopeTargeting.ps1 -PilotDevices DEVICE01,DEVICE02
        Apply:
            powershell -ExecutionPolicy Bypass -File .\GPPLAP-Set-ScopeTargeting.ps1 -PilotDevices DEVICE01 -WhatIf:$false
        Required Microsoft Graph scopes (delegated):
            Group.ReadWrite.All
            GroupMember.ReadWrite.All
            Device.Read.All
            Application.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        The pilot group (and prod group if -CreateProd) exist as ASSIGNED security groups, contain the
        listed devices, and have the Provisioning Client SP as an owner. In preview each create/add is
        prefixed [WHATIF]; with -WhatIf:$false each prints [DONE]/[FAILED]. These exact group names are the
        enrollment-time assignment targets in 03-implementation.md.
.NOTES
    White-label — the repeatable way. Write actions gated behind -WhatIf (default ON). GlobalProtect portal/gateway and app internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [bool]     $WhatIf = $true,
    [string]   $PilotGroupName = 'PILOT – GlobalProtect PLAP – Autopilot Devices',
    [string]   $ProdGroupName  = 'PROD – GlobalProtect PLAP – Autopilot Devices',
    [string[]] $PilotDevices = @(),
    [string[]] $ProdDevices  = @(),
    [switch]   $CreateProd
)

$ErrorActionPreference = 'Stop'

# Intune Provisioning Client first-party SP — must OWN the Assigned group for enrollment-time targeting.
$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('Group.ReadWrite.All','GroupMember.ReadWrite.All','Device.Read.All','Application.Read.All','Directory.Read.All')
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
    $existing = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName,groupTypes"
    if ($existing) {
        if ($existing[0].groupTypes -contains 'DynamicMembership') {
            Write-Host "  WARNING: '$Name' exists but is DYNAMIC — enrollment-time targeting needs an ASSIGNED group. Recreate it as Assigned." -ForegroundColor Red
        } else {
            Write-Host "  Group '$Name' already exists ($($existing[0].id))." -ForegroundColor DarkGray
        }
        return $existing[0].id
    }
    if ($WhatIf) {
        Write-Host "[WHATIF] Create ASSIGNED security group '$Name'" -ForegroundColor Yellow
        return $null
    }
    $mailNick = ('gpplap-' + ($Name -replace '[^a-zA-Z0-9]', '')).ToLower()
    if ($mailNick.Length -gt 60) { $mailNick = $mailNick.Substring(0,60) }
    $body = @{
        displayName     = $Name
        description      = 'GlobalProtect Connect Before Logon (PLAP) Autopilot device target group (created by GPPLAP-Set-ScopeTargeting).'
        mailEnabled     = $false
        mailNickname    = $mailNick
        securityEnabled = $true
        # No 'groupTypes' => Assigned (static) membership, required for enrollment-time targeting.
    } | ConvertTo-Json
    $g = Invoke-MgGraphRequest -Method POST -Uri "$base/groups" -Body $body -ContentType 'application/json'
    Write-Host "[DONE]   Created ASSIGNED group '$Name' ($($g.id))." -ForegroundColor Green
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
    foreach ($dn in $Devices) {
        $dn = $dn.Trim()
        if (-not $dn) { continue }
        $enc = [uri]::EscapeDataString($dn)
        $dev = Invoke-Graph "$base/devices?`$filter=displayName eq '$enc'&`$select=id,displayName"
        if (-not $dev) { Write-Host "  (skip) device '$dn' not found in Entra." -ForegroundColor Red; continue }
        $did = $dev[0].id
        if ($current | Where-Object { $_.id -eq $did }) {
            Write-Host "  device '$dn' already a member of '$GroupName'." -ForegroundColor DarkGray
            continue
        }
        if ($WhatIf) {
            Write-Host "[WHATIF] Add device '$dn' to '$GroupName'" -ForegroundColor Yellow
        } else {
            $refBody = @{ '@odata.id' = "$base/directoryObjects/$did" } | ConvertTo-Json
            try {
                Invoke-MgGraphRequest -Method POST -Uri "$base/groups/$GroupId/members/`$ref" -Body $refBody -ContentType 'application/json' | Out-Null
                Write-Host "[DONE]   Added device '$dn' to '$GroupName'." -ForegroundColor Green
            } catch {
                Write-Host "[FAILED] Add device '$dn' to '$GroupName' :: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

function Set-ProvisioningClientOwner {
    param([string] $GroupId, [string] $GroupName)
    # Resolve the Intune Provisioning Client service principal by AppId.
    $sp = Invoke-Graph "$base/servicePrincipals?`$filter=appId eq '$ProvisioningClientAppId'&`$select=id,appId,displayName"
    if (-not $sp) {
        Write-Host "  WARNING: Provisioning Client SP (AppId $ProvisioningClientAppId) not found in the tenant." -ForegroundColor Red
        Write-Host "           Provision it by opening the Intune portal once as Global Administrator, then re-run." -ForegroundColor Red
        return
    }
    $spId = $sp[0].id
    if (-not $GroupId) {
        Write-Host "[WHATIF] Set SP '$($sp[0].displayName)' (AppId $ProvisioningClientAppId) as OWNER of '$GroupName'" -ForegroundColor Yellow
        return
    }
    $owners = Invoke-Graph "$base/groups/$GroupId/owners?`$select=id,appId"
    if ($owners | Where-Object { $_.appId -eq $ProvisioningClientAppId }) {
        Write-Host "  Provisioning Client SP already an owner of '$GroupName'." -ForegroundColor DarkGray
        return
    }
    if ($WhatIf) {
        Write-Host "[WHATIF] Add SP '$($sp[0].displayName)' as OWNER of '$GroupName'" -ForegroundColor Yellow
        return
    }
    $refBody = @{ '@odata.id' = "$base/directoryObjects/$spId" } | ConvertTo-Json
    try {
        Invoke-MgGraphRequest -Method POST -Uri "$base/groups/$GroupId/owners/`$ref" -Body $refBody -ContentType 'application/json' | Out-Null
        Write-Host "[DONE]   Set Provisioning Client SP as OWNER of '$GroupName' (enrollment-time targeting enabled)." -ForegroundColor Green
    } catch {
        Write-Host "[FAILED] Add SP owner to '$GroupName' :: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Connect-Graph
$mode = if ($WhatIf) { 'PREVIEW (-WhatIf) — no changes will be made' } else { 'APPLY — changes WILL be made' }
Write-Host "`n=== GlobalProtect PLAP — Autopilot Device Scope Targeting [$mode] ===" -ForegroundColor Cyan

Write-Host "`n[1] Pilot device group" -ForegroundColor Cyan
$pilotId = Ensure-Group -Name $PilotGroupName
Add-Devices -GroupId $pilotId -GroupName $PilotGroupName -Devices $PilotDevices
Set-ProvisioningClientOwner -GroupId $pilotId -GroupName $PilotGroupName

if ($CreateProd -or $ProdDevices.Count -gt 0) {
    Write-Host "`n[2] Production device group" -ForegroundColor Cyan
    $prodId = Ensure-Group -Name $ProdGroupName
    Add-Devices -GroupId $prodId -GroupName $ProdGroupName -Devices $ProdDevices
    Set-ProvisioningClientOwner -GroupId $prodId -GroupName $ProdGroupName
}

Write-Host "`n=== Scope targeting complete ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "This was a PREVIEW. Re-run with -WhatIf:`$false to create/populate the group(s) and set the SP owner." -ForegroundColor Yellow
} else {
    Write-Host "Groups ready (Assigned + SP owner). Assign the GlobalProtect PLAP app to them per 03-implementation.md." -ForegroundColor Green
}
