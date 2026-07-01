<#
.SYNOPSIS
    EPRPT-Set-ReportingScopeTargeting.ps1 — build the reporting-scope Entra security groups.
.DESCRIPTION
    PURPOSE
        Creates (or, in read mode, just reports on) the two reporting-scope groups used to target
        reporting and exports at a pilot population first and the whole fleet second:
          'Endpoint Reporting Scope - Pilot - Stage'
          'Endpoint Reporting Scope - Fleet - Prod'
        Optionally adds device object IDs to the pilot group from a supplied list.
    HOW TO RUN
        Report only (default, read-only):
          powershell -ExecutionPolicy Bypass -File .\EPRPT-Set-ReportingScopeTargeting.ps1
        Create the groups if missing:
          ... -Create
        Add pilot members (Entra device object IDs):
          ... -Create -PilotDeviceObjectIds id1,id2,id3
        Requires the Microsoft Graph SDK. Read mode: Group.Read.All. Create/add: Group.ReadWrite.All.
    EXPECTED RESULTS
        Read mode: existence + membership count for each group.
        Create mode: the groups created if missing and pilot members added; a final summary.
.NOTES
    Workplace Marketplace — Infrastructure. Read-only unless -Create is supplied.
#>
[CmdletBinding()] param(
    [switch]$Create,
    [string[]]$PilotDeviceObjectIds = @()
)
$pilot = 'Endpoint Reporting Scope - Pilot - Stage'
$fleet = 'Endpoint Reporting Scope - Fleet - Prod'

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Create) { 'Group.ReadWrite.All','Device.Read.All' } else { 'Group.Read.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

function Get-Group($name){ (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value | Select-Object -First 1 }
function New-ScopeGroup($name){
    $nick = ($name -replace '[^a-zA-Z0-9]','')
    $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $nick; securityEnabled = $true } | ConvertTo-Json
    Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
}
function Count-Members($id){ try { @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id/members?`$select=id").value).Count } catch { 0 } }

Write-Host "`n=== Reporting-scope groups ===" -ForegroundColor Cyan
foreach ($name in @($pilot,$fleet)) {
    $g = Get-Group $name
    if (-not $g -and $Create) { $g = New-ScopeGroup $name; Write-Host ("  Created: {0}" -f $name) -ForegroundColor Green }
    if ($g) { Write-Host ("  {0,-44}: present  (members {1})" -f $name,(Count-Members $g.id)) -ForegroundColor Green }
    else    { Write-Host ("  {0,-44}: MISSING  (run with -Create)" -f $name) -ForegroundColor Yellow }
}

if ($Create -and $PilotDeviceObjectIds.Count -gt 0) {
    $g = Get-Group $pilot
    foreach ($id in $PilotDeviceObjectIds) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" } | ConvertTo-Json
        try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($g.id)/members/`$ref" -Body $ref -ContentType 'application/json'; Write-Host ("  Added device {0} to pilot" -f $id) -ForegroundColor Green }
        catch { Write-Host ("  Could not add {0}: {1}" -f $id,$_.Exception.Message) -ForegroundColor Yellow }
    }
}
Write-Host "`nDone." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
