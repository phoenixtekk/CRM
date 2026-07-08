<#
.SYNOPSIS
    DLPOD-Scope.ps1 — OneDrive DLP scope/health helper: report scope + sharing signal and (with -Commit) set the pilot ring (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        (1) Reports a OneDrive DLP policy's current location scope and mode, plus its included/excluded
        OneDrive member-of scope; (2) reports a tenant OneDrive/SharePoint external-SHARING signal from
        Microsoft Graph as context (read-only, best-effort); and (3) only with -Commit narrows the policy
        to a PILOT RING by setting OneDriveSharedByMemberOf to a group, so enforcement can be limited to a
        ring before tenant-wide expansion. Safe by default: -WhatIf reports only; scope writes require
        -Commit. This helper adjusts SCOPE only — it does NOT flip a policy to enforce (that is a
        deliberate portal/change-control action) and it does NOT change any tenant sharing setting.
    HOW TO RUN
        # Report current scope + tenant sharing signal:
        powershell -File .\DLPOD-Scope.ps1 -PolicyName 'DLP - OneDrive External Share - Simulation' -WhatIf
        # Restrict the policy to a pilot-ring group (still simulation mode):
        powershell -File .\DLPOD-Scope.ps1 -PolicyName 'DLP - OneDrive External Share - Simulation' `
            -PilotRingGroup 'DLPOneDrivePilotRing@contoso.com' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession); Graph (SharePointTenantSettings.Read.All)
        is optional for the sharing signal and is skipped gracefully if unavailable.
    EXPECTED RESULTS
        -WhatIf: prints the policy's OneDrive scope/mode, the tenant sharing signal (if readable), and the
        Set-DlpCompliancePolicy call it WOULD run. -Commit: applies OneDriveSharedByMemberOf and re-prints
        it. PASS: the policy's OneDrive member-of scope now equals the pilot ring and Mode is unchanged
        (still simulation until you enforce in the portal).
.NOTES
    Purview — OneDrive for Business DLP. Scope changes gated behind -Commit; never changes enforcement mode or tenant sharing. No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$PilotRingGroup,
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$p = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction Stop
Write-Host ("=== Scope for '{0}' (Mode={1}) ===" -f $p.Name, $p.Mode) -ForegroundColor Cyan
foreach ($loc in 'OneDriveLocation','SharePointLocation','ExchangeLocation','TeamsLocation') {
    $val = $p.$loc
    if ($val -and $val.Count -gt 0) { Write-Host ("  {0}: {1}" -f $loc, ($val -join ', ')) }
}
foreach ($mo in 'OneDriveSharedByMemberOf','OneDriveSharedByMemberOfException') {
    $val = $p.$mo
    if ($val -and $val.Count -gt 0) { Write-Host ("  {0}: {1}" -f $mo, ($val -join ', ')) -ForegroundColor DarkCyan }
}

if (-not ($p.OneDriveLocation -and $p.OneDriveLocation.Count -gt 0)) {
    Write-Host 'NOTE: this policy does not currently target the OneDrive location — confirm you are scoping the right policy.' -ForegroundColor Yellow
}

# --- Tenant external-sharing signal (context only, read-only, best-effort via Graph) ---
Write-Host '--- Tenant OneDrive/SharePoint sharing signal (context) ---' -ForegroundColor Cyan
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SharePointTenantSettings.Read.All' -NoWelcome -ErrorAction Stop }
    $settings = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/admin/sharepoint/settings' -ErrorAction Stop
    Write-Host ("  sharingCapability            : {0}" -f $settings.sharingCapability)
    Write-Host ("  oneDriveSharingCapability    : {0}" -f $settings.oneDriveSharingCapability)
    Write-Host ("  sharingDomainRestrictionMode : {0}" -f $settings.sharingDomainRestrictionMode)
    if ($settings.sharingCapability -eq 'ExternalUserAndGuestSharing') {
        Write-Host '  Signal: tenant permits "anyone" links broadly — DLP will surface more external over-shares; consider tightening tenant sharing alongside DLP (Req 2.3).' -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Sharing signal skipped (Graph unavailable or insufficient scope): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host '  Verify the OneDrive/SharePoint external-sharing setting in the SharePoint admin center (Policies > Sharing).' -ForegroundColor Yellow
}

# --- Pilot-ring scoping (write path) ---
if (-not $PilotRingGroup) {
    Write-Host 'No -PilotRingGroup supplied — reporting only. Supply a group (and -Commit) to restrict OneDrive scope to a pilot ring.' -ForegroundColor Yellow
    return
}

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    Write-Host ("Set-DlpCompliancePolicy -Identity '{0}' -OneDriveSharedByMemberOf '{1}'  (Mode stays {2})" -f $PolicyName, $PilotRingGroup, $p.Mode)
    Write-Host 'Re-run with -Commit to apply. Enforcement (Mode=Enable) remains a separate portal/change-control step.' -ForegroundColor Yellow
    return
}

if ($p.Mode -eq 'Enable') {
    Write-Host ("NOTE: '{0}' is already ENFORCING. Scoping it now changes who is enforced against — confirm this is intended under change control." -f $PolicyName) -ForegroundColor Yellow
}
Set-DlpCompliancePolicy -Identity $PolicyName -OneDriveSharedByMemberOf $PilotRingGroup -ErrorAction Stop
Write-Host ("Applied OneDriveSharedByMemberOf = {0} to '{1}' (Mode unchanged: {2})." -f $PilotRingGroup, $PolicyName, $p.Mode) -ForegroundColor Green

$after = Get-DlpCompliancePolicy -Identity $PolicyName
Write-Host ("Verify: OneDriveSharedByMemberOf = {0}" -f ($after.OneDriveSharedByMemberOf -join ', ')) -ForegroundColor Green
