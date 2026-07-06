<#
.SYNOPSIS
    MACCA-Set-ScopeTargeting.ps1 — build/update the pilot or rollout group from the Mac inventory (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Keeps the scope groups behind the compliance and Conditional Access policies accurate.
        Given a target Entra group (e.g. macOS-ZeroTrust-Pilot), it works out which enrolled Macs
        should be members and previews the additions before making them. Use it to stand up the
        pilot, then to widen scope wave by wave during expansion. Runs in preview only unless you
        pass -Apply; every change honors -WhatIf.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\MACCA-Set-ScopeTargeting.ps1 -GroupName macOS-ZeroTrust-Pilot
        Preview a filtered wave, then apply:
          powershell -ExecutionPolicy Bypass -File .\MACCA-Set-ScopeTargeting.ps1 -GroupName macOS-ZeroTrust-Pilot -DeviceNameLike 'LAB-' -Apply
        Requires Microsoft Graph SDK and scopes: Group.ReadWrite.All,
        DeviceManagementManagedDevices.Read.All, Device.Read.All.
    EXPECTED RESULTS
        A list of Macs that would be added to the group (WhatIf) or were added (-Apply), skipping
        those already members. Nothing is changed unless -Apply is supplied.
.NOTES
    White-label — the repeatable way. Read-only by default (preview); membership changes gated behind -Apply and honor -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')] param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$DeviceNameLike,
    [switch]$Apply
)
# Default to preview: without -Apply, force WhatIf so no membership changes.
if (-not $Apply) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementManagedDevices.Read.All','Device.Read.All' -NoWelcome

Write-Host ("=== Scope targeting for '{0}' ({1}) ===" -f $GroupName, ($(if($Apply){'APPLY'}else{'PREVIEW / -WhatIf'}))) -ForegroundColor Cyan

$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$GroupName'&`$select=id,displayName").value | Select-Object -First 1
if (-not $grp) { Write-Host "Group '$GroupName' not found — create it first (Entra → Groups → New group → Security)." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; exit 1 }

# Current device members (by directory object id)
$existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id").value.id

# Enrolled Macs -> their Entra device objects
$macs = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,azureADDeviceId"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $macs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
if ($DeviceNameLike) { $macs = $macs | Where-Object { $_.deviceName -like "*$DeviceNameLike*" } }

$added = 0; $skipped = 0
foreach ($m in $macs) {
    if (-not $m.azureADDeviceId) { continue }
    # Resolve the Entra device object id from the azureADDeviceId
    $devObj = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=deviceId eq '$($m.azureADDeviceId)'&`$select=id").value | Select-Object -First 1
    if (-not $devObj) { continue }
    if ($existing -contains $devObj.id) { $skipped++; continue }

    if ($PSCmdlet.ShouldProcess("$($m.deviceName) -> $GroupName", "Add Mac device to group")) {
        try {
            $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($devObj.id)" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body $body
            Write-Host ("  added  {0}" -f $m.deviceName) -ForegroundColor Green; $added++
        } catch { Write-Host ("  failed {0}: {1}" -f $m.deviceName, $_.Exception.Message) -ForegroundColor Red }
    } else {
        Write-Host ("  would add  {0}" -f $m.deviceName) -ForegroundColor Yellow; $added++
    }
}

Write-Host ("`nMacs matched: {0} | to add: {1} | already members: {2} ({3})" -f $macs.Count, $added, $skipped, ($(if($Apply){'applied'}else{'preview only — re-run with -Apply to change membership'}))) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
