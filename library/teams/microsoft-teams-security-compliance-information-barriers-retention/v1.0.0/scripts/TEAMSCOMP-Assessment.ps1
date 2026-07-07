<#
.SYNOPSIS
  Read-only assessment of the Teams-specific compliance posture (information barriers, Teams retention, Teams DLP).
.DESCRIPTION
  Connects to Security & Compliance PowerShell (Connect-IPPSSession) and reports the current
  Teams compliance posture: information-barrier segments and policies with application status,
  retention policies that touch the Teams locations, Teams-location DLP policies with their mode,
  and (via the MicrosoftTeams module, if available) the scoped-directory-search setting. Nothing is
  changed. This is the "what exists today" read used to plan the controls.
.EXAMPLE
  .\TEAMSCOMP-Assessment.ps1
  # read-only; sign in as a Compliance/Information-Barriers/DLP reader when prompted
  (PowerShell 5.1+/7+, ExchangeOnlineManagement + optional MicrosoftTeams; connect via Connect-IPPSSession)
.NOTES
  Expected results: tables of IB segments/policies (+ latest application status), Teams-location
  retention policies, Teams DLP policies with MODE, and the scoped-directory-search flag. Read-only.
  White-label. Government cloud: pass the cloud-specific -ConnectionUri (verify in your tenant).
#>
[CmdletBinding()]
param()

function Connect-Compliance {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop
}

Connect-Compliance
Write-Host "`n=== Microsoft Teams — compliance posture assessment (read-only) ===" -ForegroundColor Cyan

# --- Information barriers -------------------------------------------------------
Write-Host "`n--- IB organization segments ---" -ForegroundColor Cyan
$segments = Get-OrganizationSegment -ErrorAction SilentlyContinue
if ($segments) { $segments | Select-Object Name, UserGroupFilter | Format-Table -AutoSize -Wrap }
else { Write-Host "  No organization segments found." -ForegroundColor Yellow }

Write-Host "`n--- IB policies ---" -ForegroundColor Cyan
$ibPolicies = Get-InformationBarrierPolicy -ErrorAction SilentlyContinue
if ($ibPolicies) {
    $ibPolicies | Select-Object Name, State,
        @{n='AssignedSegment';e={$_.AssignedSegment}},
        @{n='SegmentsBlocked';e={($_.SegmentsBlocked -join ', ')}},
        @{n='SegmentsAllowed';e={($_.SegmentsAllowed -join ', ')}} | Format-Table -AutoSize -Wrap
} else { Write-Host "  No information-barrier policies found." -ForegroundColor Yellow }

Write-Host "`n--- IB latest application status ---" -ForegroundColor Cyan
$ibStatus = Get-InformationBarrierPoliciesApplicationStatus -ErrorAction SilentlyContinue
if ($ibStatus) { $ibStatus | Select-Object Identity, Status | Format-Table -AutoSize }
else { Write-Host "  No IB application run recorded yet." -ForegroundColor Yellow }

# --- Teams retention -----------------------------------------------------------
Write-Host "`n--- Retention policies touching the Teams locations ---" -ForegroundColor Cyan
$allRet = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue
$teamsRet = @($allRet | Where-Object {
    $_.TeamsChatLocation.Count -gt 0 -or $_.TeamsChannelLocation.Count -gt 0 -or
    $_.TeamsPrivateChannelLocation.Count -gt 0 -or $_.TeamsSharedChannelLocation.Count -gt 0
})
if ($teamsRet) {
    $teamsRet | Select-Object Name, Enabled, Mode,
        @{n='ChatLocs';e={$_.TeamsChatLocation.Count}},
        @{n='ChannelLocs';e={$_.TeamsChannelLocation.Count}} | Format-Table -AutoSize
} else { Write-Host "  No retention policy currently covers the Teams locations." -ForegroundColor Yellow }

# --- Teams DLP -----------------------------------------------------------------
Write-Host "`n--- Teams-location DLP policies (mode: test vs enforce) ---" -ForegroundColor Cyan
$allDlp = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
$teamsDlp = @($allDlp | Where-Object { $_.TeamsLocation.Count -gt 0 })
if ($teamsDlp) {
    $teamsDlp | Select-Object Name, Mode, Enabled,
        @{n='TeamsLocs';e={$_.TeamsLocation.Count}} | Format-Table -AutoSize
    $enforcing = @($teamsDlp | Where-Object { $_.Mode -match 'Enable' })
    if ($enforcing) { Write-Host ("  NOTE: {0} Teams DLP policy(ies) already enforcing." -f $enforcing.Count) -ForegroundColor Yellow }
} else { Write-Host "  No DLP policy currently scopes the Teams location." -ForegroundColor Yellow }

# --- Scoped directory search (IB dependency, best-effort via MicrosoftTeams) ----
Write-Host "`n--- Scoped directory search (IB dependency) ---" -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name MicrosoftTeams) {
    try {
        Import-Module MicrosoftTeams -ErrorAction Stop
        Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
        $cfg = Get-CsTeamsClientConfiguration -Identity Global -ErrorAction SilentlyContinue
        if ($cfg) {
            Write-Host ("  RestrictedSenderList / directory scoping present on client config: review 'ScopedDirectorySearch' in Teams admin center.") -ForegroundColor Gray
            $cfg | Select-Object Identity, AllowScopedPeopleSearchandAccess | Format-Table -AutoSize
        }
        Disconnect-MicrosoftTeams -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-Host "  Could not read Teams client configuration — verify scoped directory search in the Teams admin center (Org-wide settings)." -ForegroundColor Yellow
    }
} else {
    Write-Host "  MicrosoftTeams module not installed — verify scoped directory search in the Teams admin center (Org-wide settings)." -ForegroundColor Yellow
}

Write-Host "`nAssessment complete. Use TEAMSCOMP-Validation.ps1 to check the expected named artifacts." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
