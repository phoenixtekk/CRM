<#
.SYNOPSIS
    MACCA-Remediation.ps1 — safe, WhatIf-by-default fixes for common macOS compliance gaps (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Nudges non-compliant Macs back toward the gate without touching device configuration
        destructively. For each non-compliant Mac it can request a fresh Intune sync (so a Mac
        that has since been fixed re-evaluates) and, optionally, add the Mac's primary user to a
        named remediation group you use to deliver a fix (FileVault / OS-update policy). Runs in
        preview only unless you pass -Apply; every action honors -WhatIf.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\MACCA-Remediation.ps1
        Apply (request re-sync for non-compliant Macs):
          powershell -ExecutionPolicy Bypass -File .\MACCA-Remediation.ps1 -Apply
        Requires Microsoft Graph SDK and scopes: DeviceManagementManagedDevices.ReadWrite.All
        (Group.ReadWrite.All only if using -RemediationGroup).
    EXPECTED RESULTS
        A list of non-compliant Macs and the action that would run (WhatIf) or did run (-Apply):
        "sync requested". Nothing is changed unless -Apply is supplied.
.NOTES
    White-label — the repeatable way. Read-only by default (preview); mutating actions gated behind -Apply and honor -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')] param(
    [switch]$Apply,
    [string]$RemediationGroup
)
# Default to preview: without -Apply, force WhatIf so nothing mutates.
if (-not $Apply) { $WhatIfPreference = $true }

$rwScopes = @('DeviceManagementManagedDevices.ReadWrite.All')
if ($RemediationGroup) { $rwScopes += 'Group.ReadWrite.All' }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes $rwScopes -NoWelcome

Write-Host ("=== macOS compliance remediation ({0}) ===" -f ($(if($Apply){'APPLY'}else{'PREVIEW / -WhatIf'}))) -ForegroundColor Cyan

# Non-compliant Macs
$macs = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=id,deviceName,complianceState,userId,userPrincipalName"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $macs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$bad = $macs | Where-Object { $_.complianceState -ne 'compliant' }

if (-not $bad) { Write-Host "  All Macs are compliant — nothing to remediate." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

$grpId = $null
if ($RemediationGroup) {
    $grpId = ((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$RemediationGroup'&`$select=id").value | Select-Object -First 1).id
    if (-not $grpId) { Write-Host "  Remediation group '$RemediationGroup' not found — skipping group action." -ForegroundColor Yellow }
}

foreach ($d in $bad) {
    Write-Host ("  {0,-32} state:{1}" -f $d.deviceName, $d.complianceState) -ForegroundColor Yellow

    # Action 1: request a fresh Intune sync so a since-fixed Mac re-evaluates
    if ($PSCmdlet.ShouldProcess($d.deviceName, "Request Intune sync (re-evaluate compliance)")) {
        try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceManagement/managedDevices/$($d.id)/syncDevice"; Write-Host "     sync requested" -ForegroundColor Green }
        catch { Write-Host "     sync failed: $($_.Exception.Message)" -ForegroundColor Red }
    }

    # Action 2 (optional): add the Mac's primary user to a remediation group that delivers the fix
    if ($grpId -and $d.userId) {
        if ($PSCmdlet.ShouldProcess("$($d.userPrincipalName) -> $RemediationGroup", "Add primary user to remediation group")) {
            try {
                $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($d.userId)" }
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$grpId/members/`$ref" -Body $body
                Write-Host "     added $($d.userPrincipalName) to $RemediationGroup" -ForegroundColor Green
            } catch { Write-Host "     group add skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
    }
}

Write-Host ("`nNon-compliant Macs handled: {0} ({1})" -f $bad.Count, ($(if($Apply){'applied'}else{'preview only — re-run with -Apply to act'}))) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
