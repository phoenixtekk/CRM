<#
.SYNOPSIS
    CSCVPN-Set-ScopeTargeting.ps1 — create/populate the pilot (and production) Entra group(s).
.DESCRIPTION
    PURPOSE
        Creates the assignment target groups for the Cisco Secure Client VPN deployment —
        'PILOT – Cisco VPN Users' and (optionally) 'PROD – Cisco VPN Users' — as assignable security
        groups, and adds the members you supply (by user principal name). Idempotent: if a group
        already exists it is reused, and members already present are skipped. Defaults to preview
        only (-WhatIf); re-run with -WhatIf:$false to actually create/populate.
    HOW TO RUN
        Preview:
            powershell -ExecutionPolicy Bypass -File .\CSCVPN-Set-ScopeTargeting.ps1 -PilotMembers user1@your-domain.com,user2@your-domain.com
        Apply:
            powershell -ExecutionPolicy Bypass -File .\CSCVPN-Set-ScopeTargeting.ps1 -PilotMembers user1@your-domain.com -WhatIf:$false
        Required Microsoft Graph scopes (delegated):
            Group.ReadWrite.All
            GroupMember.ReadWrite.All
            User.Read.All
    EXPECTED RESULTS
        The pilot group (and prod group if -CreateProd) exist and contain the listed members. In
        preview each create/add is prefixed [WHATIF]; with -WhatIf:$false each prints [DONE]/[FAILED].
        These exact group names are what the app + VPN profile assignments target in 03-implementation.md.
.NOTES
    White-label — the repeatable way. Write actions gated behind -WhatIf (default ON). Cisco-specific internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [bool]     $WhatIf = $true,
    [string]   $PilotGroupName = 'PILOT – Cisco VPN Users',
    [string]   $ProdGroupName  = 'PROD – Cisco VPN Users',
    [string[]] $PilotMembers = @(),
    [string[]] $ProdMembers  = @(),
    [switch]   $CreateProd
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('Group.ReadWrite.All','GroupMember.ReadWrite.All','User.Read.All')
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
    $mailNick = ('cscvpn-' + ($Name -replace '[^a-zA-Z0-9]', '')).ToLower()
    if ($mailNick.Length -gt 60) { $mailNick = $mailNick.Substring(0,60) }
    $body = @{
        displayName     = $Name
        description      = 'Cisco Secure Client VPN deployment target group (created by CSCVPN-Set-ScopeTargeting).'
        mailEnabled     = $false
        mailNickname    = $mailNick
        securityEnabled = $true
    } | ConvertTo-Json
    $g = Invoke-MgGraphRequest -Method POST -Uri "$base/groups" -Body $body -ContentType 'application/json'
    Write-Host "[DONE]   Created group '$Name' ($($g.id))." -ForegroundColor Green
    return $g.id
}

function Add-Members {
    param([string] $GroupId, [string] $GroupName, [string[]] $Members)
    if (-not $Members -or $Members.Count -eq 0) { return }
    if (-not $GroupId) {
        foreach ($m in $Members) { Write-Host "[WHATIF] Add '$m' to '$GroupName' (group not yet created)" -ForegroundColor Yellow }
        return
    }
    $current = Invoke-Graph "$base/groups/$GroupId/members?`$select=id,userPrincipalName"
    foreach ($upn in $Members) {
        $upn = $upn.Trim()
        if (-not $upn) { continue }
        $enc = [uri]::EscapeDataString($upn)
        $user = Invoke-Graph "$base/users?`$filter=userPrincipalName eq '$enc'&`$select=id,userPrincipalName"
        if (-not $user) { Write-Host "  (skip) user '$upn' not found." -ForegroundColor Red; continue }
        $uid = $user[0].id
        if ($current | Where-Object { $_.id -eq $uid }) {
            Write-Host "  '$upn' already a member of '$GroupName'." -ForegroundColor DarkGray
            continue
        }
        if ($WhatIf) {
            Write-Host "[WHATIF] Add '$upn' to '$GroupName'" -ForegroundColor Yellow
        } else {
            $refBody = @{ '@odata.id' = "$base/directoryObjects/$uid" } | ConvertTo-Json
            try {
                Invoke-MgGraphRequest -Method POST -Uri "$base/groups/$GroupId/members/`$ref" -Body $refBody -ContentType 'application/json' | Out-Null
                Write-Host "[DONE]   Added '$upn' to '$GroupName'." -ForegroundColor Green
            } catch {
                Write-Host "[FAILED] Add '$upn' to '$GroupName' :: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Connect-Graph
$mode = if ($WhatIf) { 'PREVIEW (-WhatIf) — no changes will be made' } else { 'APPLY — changes WILL be made' }
Write-Host "`n=== Cisco Secure Client VPN — Scope Targeting [$mode] ===" -ForegroundColor Cyan

Write-Host "`n[1] Pilot group" -ForegroundColor Cyan
$pilotId = Ensure-Group -Name $PilotGroupName
Add-Members -GroupId $pilotId -GroupName $PilotGroupName -Members $PilotMembers

if ($CreateProd -or $ProdMembers.Count -gt 0) {
    Write-Host "`n[2] Production group" -ForegroundColor Cyan
    $prodId = Ensure-Group -Name $ProdGroupName
    Add-Members -GroupId $prodId -GroupName $ProdGroupName -Members $ProdMembers
}

Write-Host "`n=== Scope targeting complete ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "This was a PREVIEW. Re-run with -WhatIf:`$false to create/populate the group(s)." -ForegroundColor Yellow
} else {
    Write-Host "Groups ready. Assign the Secure Client apps + VPN profiles to them per 03-implementation.md." -ForegroundColor Green
}
