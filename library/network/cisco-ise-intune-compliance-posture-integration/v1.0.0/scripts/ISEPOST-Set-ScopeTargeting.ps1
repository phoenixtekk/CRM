<#
.SYNOPSIS
    ISEPOST-Set-ScopeTargeting.ps1 — create and populate the pilot / expansion Entra group(s) used for staged rollout.
.DESCRIPTION
    PURPOSE
        Creates the Entra security group 'PILOT – ISE Posture Devices' (and optionally
        'PROD – ISE Posture Devices') used to scope the compliance policies and ISE
        authorization rules pilot-first. Can add members you supply by object id. Runs in
        preview by default: it reports what it WOULD create/add and changes nothing until
        you pass -Execute.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Set-ScopeTargeting.ps1
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Set-ScopeTargeting.ps1 -Execute -MemberObjectIds id-1,id-2
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Set-ScopeTargeting.ps1 -Execute -IncludeProd

        Required Graph scopes: Group.ReadWrite.All (with -Execute), GroupMember.ReadWrite.All
    EXPECTED RESULTS
        Reports whether each group exists / would be created and which members would be added.
        Default -WhatIf makes no change; with -Execute the group(s) are created/populated.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph by default. Cisco ISE internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [switch]$Execute,
    [switch]$IncludeProd,
    [string[]]$MemberObjectIds = @()
)

$ErrorActionPreference = 'Stop'
$whatIf = -not $Execute

$PilotGroupName = 'PILOT – ISE Posture Devices'
$ProdGroupName  = 'PROD – ISE Posture Devices'

function Connect-GraphSafe {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('Group.Read.All')
    if ($Execute) { $scopes = @('Group.ReadWrite.All','GroupMember.ReadWrite.All') }
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null }
}

function New-MailNickname {
    param([string]$Name)
    # Strip anything non-alphanumeric for a valid mailNickname.
    return (($Name -replace '[^a-zA-Z0-9]', '')).ToLower()
}

function Ensure-Group {
    param([string]$Name)
    $existing = Get-MgGroup -Filter "displayName eq '$Name'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existing) {
        Write-Host "  EXISTS  '$Name'  (id: $($existing.Id))" -ForegroundColor Green
        return $existing
    }
    if ($whatIf) {
        Write-Host "  WOULD CREATE  security group '$Name'" -ForegroundColor Yellow
        return $null
    }
    $g = New-MgGroup -DisplayName $Name -MailEnabled:$false -MailNickname (New-MailNickname $Name) `
                     -SecurityEnabled:$true -Description 'ISE ↔ Intune posture staged-rollout scope group' -ErrorAction Stop
    Write-Host "  CREATED  '$Name'  (id: $($g.Id))" -ForegroundColor Green
    return $g
}

function Add-Members {
    param($Group, [string[]]$Ids)
    if (-not $Ids -or $Ids.Count -eq 0) { return }
    if (-not $Group) { Write-Host "    (group not created in preview; $($Ids.Count) member(s) would be added)" -ForegroundColor Yellow; return }
    foreach ($id in $Ids) {
        if ($whatIf) {
            Write-Host "    WOULD ADD member: $id" -ForegroundColor Yellow
        } else {
            try {
                New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $id -ErrorAction Stop
                Write-Host "    ADDED member: $id" -ForegroundColor Green
            } catch {
                Write-Host "    SKIP member $id : $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "=== ISEPOST Set-ScopeTargeting — rollout scope groups ===" -ForegroundColor Cyan
if ($whatIf) {
    Write-Host "MODE: -WhatIf (preview). No changes will be made. Pass -Execute to apply." -ForegroundColor Yellow
} else {
    Write-Host "MODE: -Execute. Groups/members WILL be created/added." -ForegroundColor Red
}

Connect-GraphSafe

Write-Host "`n[1] Pilot group" -ForegroundColor Cyan
$pilot = Ensure-Group -Name $PilotGroupName
Add-Members -Group $pilot -Ids $MemberObjectIds

if ($IncludeProd) {
    Write-Host "`n[2] Expansion (prod) group" -ForegroundColor Cyan
    Ensure-Group -Name $ProdGroupName | Out-Null
}

Write-Host "`nNext: assign the 'Compliance – <platform> – Baseline' policies to '$PilotGroupName',"
Write-Host "and scope the ISE authorization rules to the pilot population (Cisco ISE — deferred to Cisco documentation)."
Write-Host "`n=== Done ===" -ForegroundColor Cyan
