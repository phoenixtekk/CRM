<#
.SYNOPSIS
    WINGETSTORE-Validate.ps1 — PASS/FAIL check that the pilot Store app + winget app are deployed,
    assigned, and self-service is configured (Microsoft Graph, read-only).
.DESCRIPTION
    PURPOSE
        Confirms the pilot state from the Implementation Guide is correct:
          * the Required Store app exists and is assigned 'required' to the pilot group,
          * the Available (self-service) winget app exists and is assigned 'available' to the pilot
            group (so it appears in Company Portal).
        Prints a PASS/FAIL line per check. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Validate.ps1 `
            -RequiredAppName "Adobe Acrobat Reader – Store – Required" `
            -AvailableAppName "VLC media player – Winget – Available" `
            -PilotGroupName "Store & Winget Apps – Pilot – Ring 1"
        Requires the Microsoft Graph PowerShell SDK.
    GRAPH SCOPES
        DeviceManagementApps.Read.All   (read app definitions + assignments)
        Group.Read.All                  (resolve the pilot group id from its name)
    EXPECTED RESULTS
        PASS for each check when the app exists and carries the expected intent to the pilot group;
        FAIL (with the reason) otherwise. Overall exit is informational only.
.NOTES
    Intune Solutions — read-only. New Store app Graph type = 'microsoft.graph.winGetApp'
    (verify-with-Microsoft).
#>
[CmdletBinding()]
param(
    [string]$RequiredAppName  = 'Adobe Acrobat Reader – Store – Required',
    [string]$AvailableAppName = 'VLC media player – Winget – Available',
    [string]$PilotGroupName   = 'Store & Winget Apps – Pilot – Ring 1'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome

function Write-Result { param($ok,$msg) if ($ok) { Write-Host "  PASS  $msg" -ForegroundColor Green } else { Write-Host "  FAIL  $msg" -ForegroundColor Red } }

# Resolve pilot group id
$escG = $PilotGroupName.Replace("'","''")
$grp  = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escG'").value | Select-Object -First 1
if (-not $grp) { Write-Result $false "Pilot group '$PilotGroupName' not found."; Disconnect-MgGraph | Out-Null; return }
$pilotId = $grp.id
Write-Host "=== WINGETSTORE validation (pilot) ===" -ForegroundColor Cyan
Write-Result $true "Pilot group resolved: $PilotGroupName ($pilotId)"

function Test-AppAssignment {
    param([string]$AppName,[string]$WantIntent)
    $escA = $AppName.Replace("'","''")
    $app = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$filter=displayName eq '$escA'").value | Select-Object -First 1
    if (-not $app) { Write-Result $false "App '$AppName' not found."; return }
    Write-Result $true "App found: $AppName"
    $as = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($app.id)/assignments").value
    $match = $as | Where-Object { $_.intent -eq $WantIntent -and $_.target.groupId -eq $pilotId }
    $self = if ($WantIntent -eq 'available') { ' (self-service)' } else { '' }
    Write-Result ([bool]$match) "'$AppName' assigned '$WantIntent'$self to pilot group."
}

Write-Host "`n[Required Store app]" -ForegroundColor Cyan
Test-AppAssignment -AppName $RequiredAppName  -WantIntent 'required'
Write-Host "`n[Available (self-service) winget app]" -ForegroundColor Cyan
Test-AppAssignment -AppName $AvailableAppName -WantIntent 'available'

Write-Host "`nReview any FAIL lines against Implementation Steps 2-4." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
