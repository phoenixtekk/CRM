<#
.SYNOPSIS
    NSSWG-Set-ScopeTargeting.ps1 — create/populate the SWG steering-scope Entra groups.
.DESCRIPTION
    PURPOSE
        Creates the two steering-scope security groups used to stage the rollout —
        'Web Steering - Pilot - Stage 1' and 'Web Steering - Broad - Stage 2' — and optionally adds
        members from a CSV of object ids. These groups scope which devices/users are steered into the
        gateway and are referenced by the Intune client/cert assignments and the Netskope steering
        configuration.
    HOW TO RUN
        Create groups only:
          powershell -ExecutionPolicy Bypass -File .\NSSWG-Set-ScopeTargeting.ps1
        Create and add members (CSV with a header 'ObjectId'):
          powershell -ExecutionPolicy Bypass -File .\NSSWG-Set-ScopeTargeting.ps1 -PilotMembersCsv .\pilot.csv -BroadMembersCsv .\broad.csv
    EXPECTED RESULTS
        Both groups exist (created if missing) and any supplied members are added. The names are
        emitted so you can reference them verbatim in Intune and Netskope.
.NOTES
    Workplace Marketplace — Network Solutions. Creates groups and adds members (mutating) — uses
    -WhatIf via ShouldProcess; pass -Confirm:$false to skip prompts in automation.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$PilotGroup = 'Web Steering - Pilot - Stage 1',
    [string]$BroadGroup = 'Web Steering - Broad - Stage 2',
    [string]$PilotMembersCsv,
    [string]$BroadMembersCsv
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

function Get-OrNew-Group($name) {
    $enc = [uri]::EscapeDataString($name)
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1
    if ($g) { Write-Host ("Group exists: {0}" -f $name) -ForegroundColor Green; return $g }
    if ($PSCmdlet.ShouldProcess($name, 'create security group')) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Created group: {0}" -f $name) -ForegroundColor Green
        return $g
    }
}

function Add-Members($group, $csvPath) {
    if (-not $csvPath) { return }
    if (-not (Test-Path $csvPath)) { Write-Host "CSV not found: $csvPath" -ForegroundColor Yellow; return }
    $ids = (Import-Csv $csvPath).ObjectId | Where-Object { $_ }
    foreach ($id in $ids) {
        if ($PSCmdlet.ShouldProcess("$id", "add to '$($group.displayName)'")) {
            $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" }
            try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($group.id)/members/`$ref" -Body ($body | ConvertTo-Json); Write-Host "  + $id" -ForegroundColor Green }
            catch { Write-Host "  ! $id (already a member or invalid id)" -ForegroundColor DarkGray }
        }
    }
}

$pilot = Get-OrNew-Group $PilotGroup
$broad = Get-OrNew-Group $BroadGroup
Add-Members $pilot $PilotMembersCsv
Add-Members $broad $BroadMembersCsv

Write-Host "`nReference these names verbatim in Intune assignments and Netskope steering:" -ForegroundColor Cyan
Write-Host "  $PilotGroup"
Write-Host "  $BroadGroup"
Disconnect-MgGraph | Out-Null
