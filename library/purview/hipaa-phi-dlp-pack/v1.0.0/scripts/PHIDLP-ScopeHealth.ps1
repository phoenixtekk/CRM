<#
.SYNOPSIS
    PHIDLP-ScopeHealth.ps1 — PHI DLP scope + endpoint/licensing health helper: report, and (with -Commit) set the pilot-ring scope (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Two jobs for the pilot phase. (1) HEALTH (read-only): reports Endpoint-DLP readiness signals —
        an E5/E5-Compliance licensing signal via Microsoft Graph and whether any DLP policy already uses
        the Endpoint (Devices) location — so you know the Devices location can function before you scope
        it. (2) SCOPE: reports a named PHI policy's locations, mode, and current member-of scope, and —
        only with -Commit — narrows an Exchange/OneDrive policy to a PILOT RING group so enforcement can
        be limited before tenant-wide expansion. Safe by default: -WhatIf reports only; writes require
        -Commit. This helper adjusts SCOPE only — it NEVER flips a policy to enforce (that is a deliberate
        portal/change-control action).
    HOW TO RUN
        # Health + scope report only (no group supplied):
        powershell -File .\PHIDLP-ScopeHealth.ps1 -PolicyName 'DLP - PHI Email - Simulation' -WhatIf
        # Restrict the Exchange policy to a pilot-ring group (still simulation mode):
        powershell -File .\PHIDLP-ScopeHealth.ps1 -PolicyName 'DLP - PHI Email - Simulation' `
            -PilotRingGroup 'PHIDLPPilotRing@contoso.com' -Location Exchange -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession); the licensing signal also uses
        Microsoft Graph (Organization.Read.All).
    EXPECTED RESULTS
        A readiness summary (licensing signal + endpoint-location usage) and the policy's current scope.
        -WhatIf: prints the Set-DlpCompliancePolicy call it WOULD run. -Commit: applies the member-of
        scope and re-prints it. PASS: endpoint capable/onboarded where needed; the policy's *MemberOf
        scope equals the pilot ring; Mode unchanged (still simulation until you enforce in the portal).
.NOTES
    Purview — HIPAA / PHI DLP Pack. Scope changes gated behind -Commit; never changes enforcement mode. No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$PilotRingGroup,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams')][string]$Location = 'Exchange',
    [switch]$SkipHealth,
    [string]$UserPrincipalName,
    [switch]$Commit
)

# ---------------------------------------------------------------------------
# 1) HEALTH — Endpoint DLP readiness signal (read-only)
# ---------------------------------------------------------------------------
if (-not $SkipHealth) {
    Write-Host '=== Endpoint DLP Readiness (read-only) ===' -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    try {
        Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome -ErrorAction Stop
        $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
        # Service plans indicative of advanced compliance / Endpoint DLP (verify in admin center — indicative only):
        $capablePlans = 'MICROSOFTENDPOINTDLP','MIP_S_CLP2','M365_ADVANCED_AUDITING','Content_Explorer','INFO_GOVERNANCE'
        $found = @()
        foreach ($s in $skus) {
            foreach ($sp in $s.servicePlans) {
                if ($capablePlans -contains $sp.servicePlanName -and $sp.provisioningStatus -eq 'Success') { $found += $sp.servicePlanName }
            }
        }
        $found = $found | Select-Object -Unique
        if ($found -contains 'MICROSOFTENDPOINTDLP') {
            Write-Host 'Licensing: MICROSOFTENDPOINTDLP service plan present — Endpoint DLP capable.' -ForegroundColor Green
        } elseif ($found.Count -gt 0) {
            Write-Host ("Licensing: advanced-compliance plans present ({0}) — likely E5/E5 Compliance; CONFIRM Endpoint DLP in admin center." -f ($found -join ', ')) -ForegroundColor Yellow
        } else {
            Write-Host 'Licensing: no Endpoint-DLP service-plan signal found — VERIFY your licensing (E5 / E5 Compliance).' -ForegroundColor Red
        }
    } catch {
        Write-Host ("Graph licensing check skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# 2) SCOPE — report and optionally set the pilot-ring scope
# ---------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# Endpoint-location usage across the tenant (context for readiness).
if (-not $SkipHealth) {
    $endpointPolicies = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue |
        Where-Object { $_.EndpointDlpLocation -and $_.EndpointDlpLocation.Count -gt 0 }
    if ($endpointPolicies) {
        Write-Host ("Endpoint (Devices) location in use by {0} policy(ies):" -f (@($endpointPolicies).Count)) -ForegroundColor Cyan
        $endpointPolicies | Select-Object Name, Mode | Format-Table -AutoSize
    } else {
        Write-Host 'No DLP policy currently targets the Endpoint (Devices) location.' -ForegroundColor Yellow
    }
    Write-Host 'NOTE: confirm onboarded devices in Purview portal > Settings > Device onboarding — a Devices policy is inert until devices are onboarded.' -ForegroundColor DarkCyan
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
    Write-Host 'No -PilotRingGroup supplied — reporting only. Supply a group (and -Commit) to restrict scope to the pilot ring.' -ForegroundColor Yellow
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
