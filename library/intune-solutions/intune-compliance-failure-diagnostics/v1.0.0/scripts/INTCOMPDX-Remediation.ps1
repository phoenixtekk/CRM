<#
.SYNOPSIS
    INTCOMPDX-Remediation.ps1 — apply safe, common fixes for compliance failures with a preview-first (-WhatIf) default.
.DESCRIPTION
    PURPOSE
        Applies the safe, common remediations for a compliance failure: force a device
        re-evaluation (sync) so a fixed setting re-reports, and preview a staged grace
        adjustment on a named policy. Defaults to -WhatIf so it only previews; re-run with
        -WhatIf:$false to commit. Never disables or loosens a policy fleet-wide. Replace the
        sample values your-device-name / your-policy-name.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDX-Remediation.ps1 -DeviceName your-device-name
        (preview only; add -WhatIf:$false to commit)

        Required Graph scopes:
            DeviceManagementManagedDevices.ReadWrite.All
            DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        A plan of the actions that would run (WhatIf) or a confirmation that a sync was
        triggered / grace preview shown when committed. Pass = planned action matches
        intent before you commit.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph unless -WhatIf:$false is set.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$DeviceName,
    [switch]$SyncDevice,
    [string]$PolicyName,
    [int]$GraceHours,
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
# Honour the -WhatIf default: unless the caller explicitly passed -WhatIf:$false, preview only.
if ($WhatIf) { $WhatIfPreference = $true }

function Connect-Graph {
    $scopes = @(
        'DeviceManagementManagedDevices.ReadWrite.All',
        'DeviceManagementConfiguration.ReadWrite.All'
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or -not ($scopes | Where-Object { $ctx.Scopes -contains $_ })) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-Graph

if ($WhatIfPreference) {
    Write-Host "`n*** PREVIEW MODE (-WhatIf). No changes will be made. Re-run with -WhatIf:`$false to commit. ***`n" -ForegroundColor Yellow
}

# --- Safe fix 1: force a device sync so a fixed setting re-evaluates and re-reports ---
if ($DeviceName -or $SyncDevice) {
    if (-not $DeviceName) { throw "Provide -DeviceName your-device-name to sync a device." }
    $devs = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}'" -f $DeviceName)
    if (-not $devs) { Write-Warning "No managed device named '$DeviceName'." }
    foreach ($d in $devs) {
        $target = "Device '$($d.deviceName)' [$($d.complianceState)]"
        if ($PSCmdlet.ShouldProcess($target, "Trigger Intune sync (re-evaluate compliance)")) {
            Invoke-MgGraphRequest -Method POST -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/syncDevice" -f $d.id) | Out-Null
            Write-Host "Sync triggered for $($d.deviceName)." -ForegroundColor Green
        }
    }
}

# --- Safe fix 2: staged grace adjustment on a named policy (preview the change) ---
if ($PolicyName -and $PSBoundParameters.ContainsKey('GraceHours')) {
    $policies = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies"
    $p = $policies | Where-Object { $_.displayName -eq $PolicyName }
    if (-not $p) { throw "Policy '$PolicyName' not found." }
    $actions = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/{0}/scheduledActionsForRule?`$expand=scheduledActionConfigurations" -f $p.id)
    $rule = $actions | Select-Object -First 1
    $target = "Policy '$($p.displayName)' grace period"
    $change = "Set 'Mark device noncompliant' grace to $GraceHours hours"
    Write-Host "`nSTAGING NOTE: apply grace changes to a pilot-scoped assignment first — never loosen the fleet policy to unblock one device." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($target, $change)) {
        if (-not $rule) { throw "No scheduled action rule found on policy to update." }
        $body = @{
            deviceComplianceScheduledActionForRules = @(
                @{
                    ruleName = 'PasswordRequired'
                    scheduledActionConfigurations = @(
                        @{ actionType = 'block'; gracePeriodHours = $GraceHours; notificationTemplateId = '' }
                    )
                }
            )
        } | ConvertTo-Json -Depth 6
        Invoke-MgGraphRequest -Method POST -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/{0}/scheduleActionsForRules" -f $p.id) -Body $body | Out-Null
        Write-Host "Grace updated on '$($p.displayName)' to $GraceHours hours." -ForegroundColor Green
    }
}

if (-not ($DeviceName -or $SyncDevice) -and -not ($PolicyName -and $PSBoundParameters.ContainsKey('GraceHours'))) {
    Write-Host "Nothing to do. Provide -DeviceName your-device-name (to sync) and/or -PolicyName your-policy-name -GraceHours N (to preview a staged grace change)." -ForegroundColor Yellow
}

Write-Host "`nRemediation run complete." -ForegroundColor Green
