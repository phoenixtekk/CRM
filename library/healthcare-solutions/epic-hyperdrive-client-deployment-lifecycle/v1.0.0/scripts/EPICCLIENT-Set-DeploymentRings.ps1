<#
.SYNOPSIS
    EPICCLIENT-Set-DeploymentRings.ps1 — Creates the pilot/broad Entra device groups and (optionally) wires ring assignments via Graph.

.DESCRIPTION
    PURPOSE
        Provisions the named deployment-ring objects this solution uses:
        "Epic Hyperdrive - Pilot Ring" and "Epic Hyperdrive - Broad Ring" (Microsoft Entra security
        groups, membershipType device-assigned), and — if you pass -AppName — wires the Epic client
        Win32 app's Required assignments to those rings via Microsoft Graph (pilot first). Supports
        -WhatIf so you can preview every create/assignment before it happens.

    HOW TO RUN
        Requires the Microsoft.Graph SDK and an operator with group + Intune app write rights.
            Install-Module Microsoft.Graph -Scope CurrentUser   # one time
        Preview (no changes):
            powershell -ExecutionPolicy Bypass -File .\EPICCLIENT-Set-DeploymentRings.ps1 -WhatIf
        Create the ring groups only:
            .\EPICCLIENT-Set-DeploymentRings.ps1
        Create groups AND assign the app to the pilot ring (Required):
            .\EPICCLIENT-Set-DeploymentRings.ps1 -AppName "Epic Hyperdrive - <EPIC_VERSION>" -AssignRing Pilot

    EXPECTED RESULTS
        The two ring groups exist (created if missing, reused if present). With -AppName/-AssignRing,
        the app gains a Required assignment to the chosen ring. Add devices to the groups in Entra,
        then proceed with Implementation Phase C/E.

.NOTES
    Healthcare Solutions. Creates Entra groups and (optionally) app assignments via Graph; honors
    -WhatIf. Adds no members automatically and changes no devices directly. Never captures patient data.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$PilotGroupName = 'Epic Hyperdrive - Pilot Ring',
    [string]$BroadGroupName = 'Epic Hyperdrive - Broad Ring',
    [string]$AppName,
    [ValidateSet('Pilot','Broad')][string]$AssignRing
)

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Import-Module Microsoft.Graph.Groups -ErrorAction SilentlyContinue
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementApps.ReadWrite.All' -NoWelcome
    }
} catch {
    Write-Error "Microsoft Graph SDK required. Run: Install-Module Microsoft.Graph -Scope CurrentUser. Details: $($_.Exception.Message)"
    return
}

function Ensure-Group([string]$Name) {
    $existing = Get-MgGroup -Filter "displayName eq '$Name'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existing) { Write-Host "Group exists: $Name ($($existing.Id))" -ForegroundColor Green; return $existing }
    if ($PSCmdlet.ShouldProcess($Name, 'Create Entra security group (device-assigned)')) {
        $mailNick = ($Name -replace '[^a-zA-Z0-9]','').ToLower()
        $g = New-MgGroup -DisplayName $Name -Description "Deployment ring for the Epic client (managed by the standard deployment model)." `
                -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true
        Write-Host "Created group: $Name ($($g.Id))" -ForegroundColor Green
        return $g
    }
    Write-Host "(WhatIf) Would create group: $Name" -ForegroundColor Yellow
    return $null
}

$pilot = Ensure-Group $PilotGroupName
$broad = Ensure-Group $BroadGroupName

if ($AppName -and $AssignRing) {
    $app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $app) { Write-Error "Win32 app '$AppName' not found in Intune — create it (Implementation Step 4) before assigning."; return }

    $targetGroup = $(if ($AssignRing -eq 'Pilot') { $pilot } else { $broad })
    if (-not $targetGroup) { Write-Warning "Target ring group not available (WhatIf or not created) — skipping assignment."; return }

    if ($PSCmdlet.ShouldProcess("$AppName -> $($targetGroup.DisplayName)", 'Add Required assignment')) {
        $body = @{
            mobileAppAssignments = @(
                @{
                    '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                    intent        = 'required'
                    target        = @{
                        '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                        groupId       = $targetGroup.Id
                    }
                }
            )
        } | ConvertTo-Json -Depth 6
        Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/assign" `
            -Body $body -ContentType 'application/json' -ErrorAction Stop
        Write-Host "Assigned (Required): '$AppName' -> '$($targetGroup.DisplayName)'" -ForegroundColor Green
    }
}

Write-Host "`nNext: add the in-scope clinical devices to '$PilotGroupName' (test devices first), validate, then expand to '$BroadGroupName' in your change window." -ForegroundColor Yellow
