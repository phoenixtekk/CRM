<#
.SYNOPSIS
    Imprivata SSO / Badge-Tap / EPCS - create the 'IMPRIVATA - Clinical Endpoints'
    group and optionally assign the named apps/profile. Supports -WhatIf.

    PURPOSE:
        Provisions the Entra security group 'IMPRIVATA - Clinical Endpoints' used to
        target the deployment, and (optionally, with -AssignObjects) assigns the
        named agent app, reader-driver app, and baseline configuration profile to it
        as Required. Idempotent: if the group already exists it is reused.

    HOW TO RUN:
        Preview group creation:
            .\IMPRIVATA-Set-ClinicalGroup.ps1 -WhatIf
        Create the group:
            .\IMPRIVATA-Set-ClinicalGroup.ps1
        Create the group AND assign the apps + profile:
            .\IMPRIVATA-Set-ClinicalGroup.ps1 -AssignObjects

    EXPECTED RESULTS:
        The security group exists (created or reused). With -AssignObjects, the
        named agent app, reader-driver app, and baseline profile are assigned to it
        as Required. -WhatIf previews every change without applying it.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [string]$GroupName           = 'IMPRIVATA - Clinical Endpoints',
    [string]$MailNickname        = 'imprivata-clinical-endpoints',
    [string]$AgentAppName        = 'Imprivata Agent - Clinical Endpoints - Deploy',
    [string]$ReaderDriverAppName = 'Proximity Reader Driver - Clinical Endpoints - Deploy',
    [string]$ProfileName         = 'Imprivata Endpoint - Clinical Endpoints - Baseline',
    [switch]$AssignObjects
)

$ErrorActionPreference = 'Stop'

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('Group.ReadWrite.All','DeviceManagementApps.ReadWrite.All','DeviceManagementConfiguration.ReadWrite.All')
    Connect-MgGraph -Scopes $scopes -NoWelcome
}
catch { Write-Error "Unable to connect to Microsoft Graph: $($_.Exception.Message)"; exit 1 }

# --- Ensure the group ---
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($group) {
    Write-Host ("Group '{0}' already exists (id {1}). Reusing." -f $GroupName, $group.Id)
} else {
    if ($PSCmdlet.ShouldProcess($GroupName, "Create security group")) {
        $group = New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $MailNickname `
                             -SecurityEnabled:$true -Description 'Shared clinical endpoints targeted for the Imprivata deployment.'
        Write-Host ("CREATED group '{0}' (id {1})." -f $GroupName, $group.Id)
    } else {
        Write-Host ("[WhatIf] Would CREATE security group '{0}'." -f $GroupName)
    }
}

if (-not $AssignObjects) {
    Write-Host 'Group ready. Re-run with -AssignObjects to assign the apps + profile.'
    return
}

if (-not $group) { Write-Host '[WhatIf] Group not yet created; skipping assignments in preview.'; return }
$groupTarget = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $group.Id }

# --- Assign a Win32 app as Required to the group ---
function Set-AppRequiredAssignment {
    param([string]$AppName)
    $app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $app) { Write-Warning ("App '{0}' not found - create it per 03-implementation.md." -f $AppName); return }
    if ($PSCmdlet.ShouldProcess("$AppName -> $GroupName", "Assign app (Required)")) {
        $body = @{ '@odata.type'='#microsoft.graph.mobileAppAssignment'; intent='required'; target=$groupTarget }
        $uri  = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/assignments"
        Invoke-MgGraphRequest -Method POST -Uri $uri -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
        Write-Host ("ASSIGNED app '{0}' (Required) to '{1}'." -f $AppName, $GroupName)
    } else {
        Write-Host ("[WhatIf] Would ASSIGN app '{0}' (Required) to '{1}'." -f $AppName, $GroupName)
    }
}

Set-AppRequiredAssignment -AppName $AgentAppName
Set-AppRequiredAssignment -AppName $ReaderDriverAppName

# --- Assign the configuration profile to the group ---
$profile = Get-MgDeviceManagementDeviceConfiguration -Filter "displayName eq '$ProfileName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $profile) {
    # Settings-catalog profiles live under configurationPolicies (beta); try that too.
    try {
        $resp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$ProfileName'" -ErrorAction Stop
        $profilePolicy = $resp.value | Select-Object -First 1
    } catch { $profilePolicy = $null }

    if ($profilePolicy) {
        if ($PSCmdlet.ShouldProcess("$ProfileName -> $GroupName", "Assign settings-catalog profile")) {
            $body = @{ assignments = @(@{ target = $groupTarget }) }
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profilePolicy.id)/assign" -Body ($body | ConvertTo-Json -Depth 6) | Out-Null
            Write-Host ("ASSIGNED profile '{0}' to '{1}'." -f $ProfileName, $GroupName)
        } else {
            Write-Host ("[WhatIf] Would ASSIGN profile '{0}' to '{1}'." -f $ProfileName, $GroupName)
        }
    } else {
        Write-Warning ("Profile '{0}' not found - create it per 03-implementation.md." -f $ProfileName)
    }
} else {
    if ($PSCmdlet.ShouldProcess("$ProfileName -> $GroupName", "Assign device configuration profile")) {
        $body = @{ assignments = @(@{ target = $groupTarget }) }
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($profile.Id)/assign" -Body ($body | ConvertTo-Json -Depth 6) | Out-Null
        Write-Host ("ASSIGNED profile '{0}' to '{1}'." -f $ProfileName, $GroupName)
    } else {
        Write-Host ("[WhatIf] Would ASSIGN profile '{0}' to '{1}'." -f $ProfileName, $GroupName)
    }
}

Write-Host 'Done. Verify in Intune: Apps > Assignments and Devices > Configuration > Assignments.'
