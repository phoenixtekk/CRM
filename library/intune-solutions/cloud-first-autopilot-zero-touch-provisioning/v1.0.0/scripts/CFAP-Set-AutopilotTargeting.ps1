<#
.SYNOPSIS
    CFAP-Set-AutopilotTargeting.ps1 — Build/maintain the dynamic Autopilot target group and confirm
    deployment-profile and ESP assignment for Cloud-First Autopilot Zero-Touch Provisioning.

PURPOSE
    Creates (if missing) the dynamic Microsoft Entra security group that gathers all Autopilot devices
    by ZTDID, and reports whether the Autopilot deployment profile and the Enrollment Status Page are
    assigned to that group. With -WhatIf (default), it only previews changes; pass -Execute to create
    the group / set the membership rule. Profile and ESP assignment are reported; the script does not
    silently re-point production assignments.

    Default artifact names (override with parameters):
      Group   : Autopilot Devices - All Cloud-First - Provisioning
      Profile : Autopilot Profile - Entra Join - Provisioning
      ESP     : ESP - Cloud-First - Provisioning

HOW TO RUN
    Requires the Microsoft Graph PowerShell SDK and scopes Group.ReadWrite.All +
    DeviceManagementServiceConfig.Read.All.

    Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\CFAP-Set-AutopilotTargeting.ps1

    Create the group and set the dynamic ZTDID rule:
        .\CFAP-Set-AutopilotTargeting.ps1 -Execute

    Use custom names:
        .\CFAP-Set-AutopilotTargeting.ps1 -Execute -GroupName 'AP Devices' -ProfileName 'AP Entra' -EspName 'AP ESP'

EXPECTED RESULTS
    The dynamic group exists with the membership rule
    (device.devicePhysicalIDs -any (_ -contains "[ZTDId]")), and a report of whether the named
    deployment profile and ESP are assigned to it. In default mode, prints intended changes only.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$GroupName   = 'Autopilot Devices - All Cloud-First - Provisioning',
    [string]$ProfileName = 'Autopilot Profile - Entra Join - Provisioning',
    [string]$EspName     = 'ESP - Cloud-First - Provisioning',
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
if (-not $Execute) { $WhatIfPreference = $true }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementServiceConfig.Read.All' | Out-Null
}

$ztdRule = '(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))'

# --- Ensure the dynamic group ---
$escaped = $GroupName.Replace("'","''")
$existing = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$escaped'").value

$groupId = $null
if ($existing -and $existing.Count -gt 0) {
    $groupId = $existing[0].id
    Write-Host ("Group exists: {0} ({1})" -f $GroupName, $groupId) -ForegroundColor Green
    if ($existing[0].membershipRule -ne $ztdRule) {
        if ($PSCmdlet.ShouldProcess($GroupName, 'update dynamic membership rule to ZTDID')) {
            $body = @{ membershipRule = $ztdRule; membershipRuleProcessingState = 'On'; groupTypes = @('DynamicMembership') } | ConvertTo-Json
            Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/groups/$groupId" -Body $body -ContentType 'application/json' | Out-Null
            Write-Host 'Membership rule updated.' -ForegroundColor Green
        } else {
            Write-Host ("WHATIF: would set membership rule to: {0}" -f $ztdRule) -ForegroundColor Yellow
        }
    } else {
        Write-Host 'Membership rule already correct (ZTDID).'
    }
} else {
    if ($PSCmdlet.ShouldProcess($GroupName, 'create dynamic Autopilot security group')) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{
            displayName                   = $GroupName
            description                   = 'Dynamic group of all cloud-first Autopilot devices (by ZTDID).'
            mailEnabled                   = $false
            mailNickname                  = $mailNick
            securityEnabled               = $true
            groupTypes                    = @('DynamicMembership')
            membershipRule                = $ztdRule
            membershipRuleProcessingState = 'On'
        } | ConvertTo-Json
        $new = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body $body -ContentType 'application/json'
        $groupId = $new.id
        Write-Host ("Created group: {0} ({1})" -f $GroupName, $groupId) -ForegroundColor Green
    } else {
        Write-Host ("WHATIF: would create dynamic group '{0}' with rule {1}" -f $GroupName, $ztdRule) -ForegroundColor Yellow
    }
}

# --- Report deployment profile assignment ---
Write-Host "`n=== Deployment profile assignment ===" -ForegroundColor Cyan
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeploymentProfiles').value
    $prof = $profiles | Where-Object displayName -eq $ProfileName | Select-Object -First 1
    if ($prof) {
        $asg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeploymentProfiles/$($prof.id)/assignments").value
        $assignedToGroup = $groupId -and ($asg.target.groupId -contains $groupId)
        Write-Host ("Profile '{0}': found. Assigned to target group: {1}" -f $ProfileName, [bool]$assignedToGroup)
        if (-not $assignedToGroup) { Write-Warning "Profile is not assigned to '$GroupName'. Assign it in the Intune portal (Step 5)." }
    } else {
        Write-Warning "Deployment profile '$ProfileName' not found — create it (Implementation Step 5)."
    }
} catch { Write-Warning "Could not read deployment profiles: $($_.Exception.Message)" }

# --- Report ESP assignment ---
Write-Host "`n=== Enrollment Status Page assignment ===" -ForegroundColor Cyan
try {
    $configs = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceEnrollmentConfigurations').value
    $esp = $configs | Where-Object { $_.displayName -eq $EspName } | Select-Object -First 1
    if ($esp) {
        $asg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceEnrollmentConfigurations/$($esp.id)/assignments").value
        $assignedToGroup = $groupId -and ($asg.target.groupId -contains $groupId)
        Write-Host ("ESP '{0}': found. Assigned to target group: {1}" -f $EspName, [bool]$assignedToGroup)
        if (-not $assignedToGroup) { Write-Warning "ESP is not assigned to '$GroupName'. Assign it in the Intune portal (Step 8)." }
    } else {
        Write-Warning "Enrollment Status Page '$EspName' not found — create it (Implementation Step 8)."
    }
} catch { Write-Warning "Could not read enrollment configurations: $($_.Exception.Message)" }

if (-not $Execute) { Write-Host "`nNo changes were made (default -WhatIf). Re-run with -Execute to apply group changes." -ForegroundColor Yellow }
