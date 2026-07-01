<#
.SYNOPSIS
    NEWSITE-Set-SiteGroupTargeting.ps1 — build a per-site device group (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Creates (or reuses) the per-site Microsoft Entra security device group named with the
        playbook convention "<Purpose> - <Site> - <Stage>" (e.g. "New Site - Site A - Pilot"), then
        adds the site's devices to it — either by a device-name prefix or from an explicit list of
        Entra device object IDs. This is the targeting layer every site assignment is scoped to.
    HOW TO RUN
        By name prefix:
            powershell -ExecutionPolicy Bypass -File .\NEWSITE-Set-SiteGroupTargeting.ps1 `
                -SiteName "Site A" -Stage "Pilot" -DeviceNamePrefix "SITEA-"
        By explicit device IDs:
            powershell -ExecutionPolicy Bypass -File .\NEWSITE-Set-SiteGroupTargeting.ps1 `
                -SiteName "Site A" -Stage "Pilot" -DeviceObjectId "<guid1>","<guid2>"
        Requires the Microsoft Graph SDK and the scopes Group.ReadWrite.All and Device.Read.All.
    EXPECTED RESULTS
        The group "New Site - <SiteName> - <Stage>" exists and contains the matched devices; a summary
        of devices added is printed.
.NOTES
    New-Site Endpoint Rollout Playbook. Creates/updates a group and its members (write operation).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$SiteName,
    [ValidateSet('Pilot','Production')][string]$Stage = 'Pilot',
    [string]$DeviceNamePrefix,
    [string[]]$DeviceObjectId = @()
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome

$groupName = "New Site - $SiteName - $Stage"
Write-Host ("`n=== Site Group Targeting — {0} ===" -f $groupName) -ForegroundColor Cyan

# Find or create the group
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $groupName)).value | Select-Object -First 1
if (-not $grp) {
    if ($PSCmdlet.ShouldProcess($groupName, "Create security group")) {
        $mailNick = ($groupName -replace '[^a-zA-Z0-9]', '')
        $body = @{
            displayName     = $groupName
            description     = "Per-site device targeting for the New-Site Endpoint Rollout Playbook ($SiteName, $Stage)."
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        }
        $grp = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("Created group: {0}" -f $groupName) -ForegroundColor Green
    }
} else {
    Write-Host ("Group already exists: {0}" -f $groupName) -ForegroundColor Yellow
}

# Resolve devices to add
$deviceIds = New-Object System.Collections.Generic.List[string]
if ($DeviceNamePrefix) {
    $devs = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/devices?`$filter=startswith(displayName,'{0}')" -f $DeviceNamePrefix)).value
    $devs | ForEach-Object { $deviceIds.Add($_.id) }
    Write-Host ("Matched {0} device(s) by prefix '{1}'." -f $deviceIds.Count, $DeviceNamePrefix)
}
foreach ($id in $DeviceObjectId) { if ($id) { $deviceIds.Add($id) } }

# Add members
$added = 0
foreach ($id in ($deviceIds | Select-Object -Unique)) {
    if ($PSCmdlet.ShouldProcess($id, "Add device to $groupName")) {
        try {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" }
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $grp.id) -Body ($ref | ConvertTo-Json)
            $added++
        } catch {
            if ($_.Exception.Message -match 'already exist') { Write-Host ("  already a member: {0}" -f $id) -ForegroundColor Yellow }
            else { Write-Host ("  failed to add {0}: {1}" -f $id, $_.Exception.Message) -ForegroundColor Red }
        }
    }
}

Write-Host ("`nDone. {0} device(s) added to {1}." -f $added, $groupName) -ForegroundColor Green
Write-Host "Assign your existing baseline, the site app set, and the site printers to this group." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
