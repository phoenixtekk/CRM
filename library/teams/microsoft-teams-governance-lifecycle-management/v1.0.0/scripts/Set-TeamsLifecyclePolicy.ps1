<#
.SYNOPSIS
  Configure Teams/M365 Groups lifecycle: expiration policy, Purview retention (compliance-set duration),
  and archival of stale teams. DRY-RUN by default (-WhatIf); writes only with -Commit.
.DESCRIPTION
  Creates/updates the M365 Groups expiration policy (lifetime, scope All/Selected, notification emails),
  optionally creates a Purview retention policy for Teams (duration MUST be supplied by compliance), and
  archives named stale teams read-only via Set-TeamArchivedState. -RemoveExpiration and un-archive support
  rollback. Expiration/labels require Entra ID P1; retention requires a Purview plan (verify in tenant).
.EXAMPLE
  .\Set-TeamsLifecyclePolicy.ps1 -ExpirationDays 180 -ManagedGroupTypes Selected -PilotGroupId <guid> -NotificationEmails "governance@contoso.com" -WhatIf
  .\Set-TeamsLifecyclePolicy.ps1 -ExpirationDays 180 -ManagedGroupTypes Selected -PilotGroupId <guid> -NotificationEmails "governance@contoso.com" -Commit
  .\Set-TeamsLifecyclePolicy.ps1 -ArchiveGroupIds <guid1>,<guid2> -Commit
  (PowerShell 5.1+/7+, Microsoft.Graph, MicrosoftTeams, and Security & Compliance PowerShell)
.NOTES
  Expected results: dry-run prints the expiration/retention/archival actions; -Commit applies them and
  confirms. Retention will NOT be created unless -RetentionDays is explicitly supplied (by compliance).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [int]$ExpirationDays,
    [ValidateSet('All','Selected','None')]
    [string]$ManagedGroupTypes = 'Selected',
    [string[]]$PilotGroupId,
    [string]$NotificationEmails,
    [switch]$RemoveExpiration,

    [switch]$ConfigureRetention,
    [int]$RetentionDays,                     # MUST come from compliance/records owner

    [string[]]$ArchiveGroupIds,
    [switch]$UnArchive,

    [switch]$Commit,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$commit = ($Commit -and -not $WhatIf)

# ============ 1. EXPIRATION (Microsoft Graph) ============
if ($ExpirationDays -or $RemoveExpiration) {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "Directory.ReadWrite.All","Group.ReadWrite.All" | Out-Null }
    Write-Host "`n=== Expiration policy: 'Expiration Policy - M365 Groups - Prod' ===" -ForegroundColor Yellow
    $existing = Get-MgGroupLifecyclePolicy -ErrorAction SilentlyContinue

    if ($RemoveExpiration) {
        Write-Host "  ACTION: remove existing lifecycle policy (rollback)." -ForegroundColor Cyan
        if ($commit -and $existing) {
            if ($PSCmdlet.ShouldProcess("Group lifecycle policy","Remove")) {
                Remove-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $existing.Id
                Write-Host "  Removed." -ForegroundColor Green
            }
        }
    } else {
        Write-Host ("  lifetimeDays={0}  managedGroupTypes={1}  notify={2}" -f $ExpirationDays,$ManagedGroupTypes,$NotificationEmails)
        $params = @{
            GroupLifetimeInDays        = $ExpirationDays
            ManagedGroupTypes          = $ManagedGroupTypes
            AlternateNotificationEmails = $NotificationEmails
        }
        if ($commit) {
            if ($existing) {
                if ($PSCmdlet.ShouldProcess("Lifecycle policy $($existing.Id)","Update")) {
                    Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $existing.Id @params
                    Write-Host "  Updated." -ForegroundColor Green
                }
            } else {
                if ($PSCmdlet.ShouldProcess("Group lifecycle policy","Create")) {
                    $new = New-MgGroupLifecyclePolicy @params
                    Write-Host "  Created ($($new.Id))." -ForegroundColor Green
                    $existing = $new
                }
            }
            # For 'Selected', enroll the pilot groups.
            if ($ManagedGroupTypes -eq 'Selected' -and $PilotGroupId) {
                foreach ($gid in $PilotGroupId) {
                    Add-MgGroupToLifecyclePolicy -GroupLifecyclePolicyId $existing.Id -GroupId $gid -ErrorAction SilentlyContinue
                    Write-Host "  Enrolled selected group $gid" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  DRY-RUN: no expiration change written." -ForegroundColor Cyan
        }
    }
}

# ============ 2. RETENTION (Security & Compliance PowerShell) ============
if ($ConfigureRetention) {
    Write-Host "`n=== Retention policy: 'Retention Policy - Teams - Prod' ===" -ForegroundColor Yellow
    if (-not $RetentionDays) {
        Write-Warning "  -RetentionDays not supplied. Retention DURATION is a compliance/records determination."
        Write-Warning "  No retention policy will be created. Re-run with -RetentionDays supplied BY COMPLIANCE."
    } else {
        Write-Host ("  Would create retention for Teams channel+chat, retain {0} days (compliance-provided)." -f $RetentionDays)
        if ($commit) {
            if ($PSCmdlet.ShouldProcess("Retention Policy - Teams - Prod","Create Purview retention")) {
                # Requires Connect-IPPSSession beforehand.
                New-RetentionCompliancePolicy -Name "Retention Policy - Teams - Prod" `
                    -TeamsChannelLocation All -TeamsChatLocation All | Out-Null
                New-RetentionComplianceRule -Name "Retention Policy - Teams - Prod - Rule" `
                    -Policy "Retention Policy - Teams - Prod" `
                    -RetentionDuration $RetentionDays -RetentionComplianceAction Keep | Out-Null
                Write-Host "  Retention policy created (duration $RetentionDays days, set by compliance)." -ForegroundColor Green
            }
        } else {
            Write-Host "  DRY-RUN: no retention change written." -ForegroundColor Cyan
        }
    }
}

# ============ 3. ARCHIVAL (MicrosoftTeams) ============
if ($ArchiveGroupIds) {
    if (-not (Get-Command Set-TeamArchivedState -ErrorAction SilentlyContinue)) { Connect-MicrosoftTeams | Out-Null }
    $target = if ($UnArchive) { 'UN-ARCHIVE (restore write)' } else { 'ARCHIVE read-only' }
    Write-Host "`n=== Archival: $target ===" -ForegroundColor Yellow
    foreach ($gid in $ArchiveGroupIds) {
        $team = Get-Team -GroupId $gid -ErrorAction SilentlyContinue
        $label = if ($team) { $team.DisplayName } else { $gid }
        Write-Host ("  {0}  ({1})" -f $label, $gid)
        if ($commit) {
            if ($PSCmdlet.ShouldProcess($label, $target)) {
                if ($UnArchive) {
                    Set-TeamArchivedState -GroupId $gid -Archived $false
                } else {
                    Set-TeamArchivedState -GroupId $gid -Archived $true -SetSpoSiteReadOnlyForMembers $true
                }
                Write-Host "    done." -ForegroundColor Green
            }
        } else {
            Write-Host "    DRY-RUN: no archival change written." -ForegroundColor Cyan
        }
    }
}

if (-not ($ExpirationDays -or $RemoveExpiration -or $ConfigureRetention -or $ArchiveGroupIds)) {
    Write-Warning "Nothing to do. Supply -ExpirationDays, -ConfigureRetention, and/or -ArchiveGroupIds."
}
