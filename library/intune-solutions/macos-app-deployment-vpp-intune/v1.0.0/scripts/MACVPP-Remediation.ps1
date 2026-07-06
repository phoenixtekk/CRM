<#
.SYNOPSIS
    MACVPP-Remediation.ps1 — safe remediation helpers for macOS app deployment via Apple VPP.
.DESCRIPTION
    PURPOSE
        Performs the common fixes that unblock VPP app delivery: re-sync the Apple VPP token with
        Apple, surface tokens nearing expiry, and (optionally) re-assign named App Store (VPP) and
        enterprise (LOB) apps to a target Entra group. Read-only by default (-WhatIf); changes
        require -Apply. Pass ids like your-entra-group-object-id, not angle-bracket placeholders.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        # Read-only audit / preview (default — makes NO changes):
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Remediation.ps1
        # Sync the VPP token(s) and re-assign named apps (explicit opt-in):
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Remediation.ps1 -Apply -GroupId your-entra-group-object-id -AppIds id1,id2
        Required Graph scopes: DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementApps.ReadWrite.All
    EXPECTED RESULTS
        Without -Apply: an audit of token expiry/sync and what WOULD be done.
        With -Apply: a token sync is requested and the named apps are assigned Required to the group.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -Apply. Read-only against
    Microsoft Graph unless -Apply is supplied.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Apply,
    [string]$GroupId,
    [string[]]$AppIds
)

$ErrorActionPreference = 'Stop'
$scopes = if ($Apply) { 'DeviceManagementServiceConfig.ReadWrite.All','DeviceManagementApps.ReadWrite.All' }
          else        { 'DeviceManagementServiceConfig.Read.All','DeviceManagementApps.Read.All' }
Connect-MgGraph -Scopes $scopes | Out-Null

function DaysLeft($iso) { if (-not $iso) { return $null }; [int]([datetime]$iso - (Get-Date)).TotalDays }

# --- Expiry / sync audit (always) ---
Write-Host '== VPP token audit ==' -ForegroundColor Cyan
$tokens = @()
try {
    $vpp = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceAppManagement/vppTokens'
    $tokens = @($vpp.value)
    if ($tokens.Count -eq 0) { Write-Host 'No Apple VPP token connected (Requirements R3).' -ForegroundColor Yellow }
    foreach ($t in $tokens) {
        $label = if ($t.displayName) { $t.displayName } else { $t.appleId }
        $d = DaysLeft $t.expirationDateTime
        $flag = if ($d -lt 30) { '  <-- RENEW SOON' } else { '' }
        $syncDays = DaysLeft $t.lastSyncDateTime
        $syncAge  = if ($syncDays -ne $null) { [math]::Abs($syncDays) } else { 'n/a' }
        Write-Host ("VPP token '{0}' (state={1}): {2} day(s) to expiry{3}; last sync ~{4} day(s) ago" -f $label, $t.state, $d, $flag, $syncAge)
    }
} catch { Write-Host "VPP token: unreadable — $($_.Exception.Message)" -ForegroundColor Yellow }

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Read-only mode (default -WhatIf). Re-run with -Apply (and -GroupId / -AppIds) to make changes.' -ForegroundColor Yellow
    return
}

# --- Re-sync VPP token(s) ---
foreach ($t in $tokens) {
    $label = if ($t.displayName) { $t.displayName } else { $t.appleId }
    if ($PSCmdlet.ShouldProcess($label, 'Sync Apple VPP token')) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/vppTokens/$($t.id)/syncLicenses" | Out-Null
            Write-Host "Synced VPP token '$label'." -ForegroundColor Green
        } catch { Write-Warning "Sync failed for '$label': $($_.Exception.Message)" }
    }
}

# --- Re-assign named apps (Required) to the group ---
if ($AppIds -and $GroupId) {
    foreach ($appId in $AppIds) {
        if ($PSCmdlet.ShouldProcess($appId, "Assign app Required to group $GroupId")) {
            $body = @{ mobileAppAssignments = @(@{
                '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                intent = 'required'
                target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId }
                settings = @{ '@odata.type' = '#microsoft.graph.macOsVppAppAssignmentSettings'; useDeviceLicensing = $true }
            }) }
            try {
                Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$appId/assign" -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' | Out-Null
                Write-Host "App $appId assigned Required (device-licensed) to $GroupId." -ForegroundColor Green
            } catch { Write-Warning "Assign failed for $appId: $($_.Exception.Message)" }
        }
    }
} elseif ($AppIds -or $GroupId) {
    Write-Warning 'Provide BOTH -GroupId and -AppIds to re-assign apps.'
}

Write-Host ''
Write-Host 'Remediation complete. Re-run MACVPP-Discovery.ps1 to confirm.' -ForegroundColor Green
