<#
.SYNOPSIS
    ENROLLID-Set-DeviceScopeTargeting.ps1 — build/maintain device-scope targeting groups (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Adds Entra device objects to the device-scope targeting groups used by this solution:
        the pilot group and the shared-devices (no-primary-user) group. It looks up each device by
        name and adds it to the named group, so app/primary-user logic targets the right scope.
    HOW TO RUN
        Pilot:  powershell -ExecutionPolicy Bypass -File .\ENROLLID-Set-DeviceScopeTargeting.ps1 -GroupName "Enrollment - Pilot Devices - Pilot" -DeviceNames PC-001,PC-002
        Shared: ... -GroupName "Enrollment - Shared Devices - Production" -DeviceNames KIOSK-01,KIOSK-02
        Add -WhatIf to preview. Requires the Microsoft Graph SDK with Group.ReadWrite.All and Device.Read.All.
    EXPECTED RESULTS
        Each named device is found as an Entra device and added to the target group (or reported as
        already a member / not found). With -WhatIf it only previews.
.NOTES
    White-label — Intune Solutions. Writes group membership only.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupName,
    [Parameter(Mandatory)] [string[]]$DeviceNames
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome
Write-Host "=== ENROLLID Device-scope targeting — group '$GroupName' ===" -ForegroundColor Cyan
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$([uri]::EscapeDataString($GroupName))'").value | Select-Object -First 1
if (-not $grp) { Write-Host "Group '$GroupName' not found — create it first (Implementation Step 1)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
$members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id").value.id
foreach ($name in $DeviceNames) {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=displayName eq '$([uri]::EscapeDataString($name))'").value | Select-Object -First 1
    if (-not $dev) { Write-Host ("  {0}: not found in Entra devices — skipped." -f $name) -ForegroundColor Yellow; continue }
    if ($members -contains $dev.id) { Write-Host ("  {0}: already a member." -f $name) -ForegroundColor DarkGray; continue }
    if ($PSCmdlet.ShouldProcess($name, "Add to group '$GroupName'")) {
        $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/devices/$($dev.id)" } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body $body -ContentType 'application/json'
        Write-Host ("  {0}: added." -f $name) -ForegroundColor Green
    }
}
Disconnect-MgGraph | Out-Null
