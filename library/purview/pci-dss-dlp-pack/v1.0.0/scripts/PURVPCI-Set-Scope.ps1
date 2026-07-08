<#
.SYNOPSIS
    PURVPCI-Set-Scope.ps1 — card-data DLP policy scope helper: report and (with -Commit) set the pilot-ring scope (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reports a PAN DLP policy's current locations and mode, and — only with -Commit — narrows an
        Exchange/OneDrive/SharePoint/Teams policy to a PILOT RING by setting the location member-of
        scope (e.g. ExchangeSenderMemberOf / OneDriveSharedByMemberOf), so enforcement can be limited to
        a ring (e.g. 'PCI DLP Pilot Ring - Stage1') before wider expansion. Safe by default: -WhatIf
        reports only; writes require -Commit. This helper adjusts SCOPE only — it does NOT flip a policy
        to enforce (that is a deliberate portal/change-control action).
    HOW TO RUN
        # Report current scope:
        powershell -File .\PURVPCI-Set-Scope.ps1 -PolicyName 'DLP - Email PAN - Simulation' -WhatIf
        # Restrict the Exchange policy to the PCI pilot-ring group (still simulation mode):
        powershell -File .\PURVPCI-Set-Scope.ps1 -PolicyName 'DLP - Email PAN - Simulation' `
            -PilotRingGroup 'PCIDLPPilotRing@contoso.com' -Location Exchange -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        -WhatIf: prints the current locations/mode and the Set-DlpCompliancePolicy call it WOULD run.
        -Commit: applies the member-of scope and re-prints it. PASS: the policy's *MemberOf scope now
        equals the pilot ring, and Mode is unchanged (still simulation until you enforce in the portal).
.NOTES
    Purview — PCI-DSS DLP Pack. Scope changes gated behind -Commit; never changes enforcement mode. No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$PilotRingGroup,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams')][string]$Location = 'Exchange',
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
foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
    $val = $p.$loc
    if ($val -and $val.Count -gt 0) { Write-Host ("  {0}: {1}" -f $loc, ($val -join ', ')) }
}
foreach ($mo in 'ExchangeSenderMemberOf','OneDriveSharedByMemberOf','ExchangeSenderMemberOfException','OneDriveSharedByMemberOfException') {
    $val = $p.$mo
    if ($val -and $val.Count -gt 0) { Write-Host ("  {0}: {1}" -f $mo, ($val -join ', ')) -ForegroundColor DarkCyan }
}

# Map the chosen location to its member-of scoping parameter.
$memberOfParam = switch ($Location) {
    'Exchange'   { 'ExchangeSenderMemberOf' }
    'OneDrive'   { 'OneDriveSharedByMemberOf' }
    'SharePoint' { $null }  # SPO scoping is by site, not member-of — narrow via -SharePointLocation in the portal.
    'Teams'      { $null }
}

if (-not $PilotRingGroup) {
    Write-Host 'No -PilotRingGroup supplied — reporting only. Supply a group (and -Commit) to restrict scope.' -ForegroundColor Yellow
    return
}
if (-not $memberOfParam) {
    Write-Host ("Location '{0}' is scoped by site/channel, not member-of. Narrow it in the portal ({0} location picker)." -f $Location) -ForegroundColor Yellow
    return
}

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    Write-Host ("Set-DlpCompliancePolicy -Identity '{0}' -{1} '{2}'  (Mode stays {3})" -f $PolicyName, $memberOfParam, $PilotRingGroup, $p.Mode)
    Write-Host 'Re-run with -Commit to apply. Enforcement (Mode=Enable) remains a separate portal/change-control step.' -ForegroundColor Yellow
    return
}

if ($p.Mode -eq 'Enable') {
    Write-Host ("NOTE: '{0}' is already ENFORCING. Scoping it now changes who is enforced against — confirm this is intended under change control." -f $PolicyName) -ForegroundColor Yellow
}
$splat = @{ Identity = $PolicyName; $memberOfParam = $PilotRingGroup }
Set-DlpCompliancePolicy @splat -ErrorAction Stop
Write-Host ("Applied {0} = {1} to '{2}' (Mode unchanged: {3})." -f $memberOfParam, $PilotRingGroup, $PolicyName, $p.Mode) -ForegroundColor Green

$after = Get-DlpCompliancePolicy -Identity $PolicyName
Write-Host ("Verify: {0} = {1}" -f $memberOfParam, ($after.$memberOfParam -join ', ')) -ForegroundColor Green
