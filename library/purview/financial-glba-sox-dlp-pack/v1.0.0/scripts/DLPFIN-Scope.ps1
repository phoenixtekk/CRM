<#
.SYNOPSIS
    DLPFIN-Scope.ps1 — financial DLP scope/health helper: report policy scope + endpoint/licensing health, and (with -Commit) set the finance pilot-ring scope (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Two read-only health signals plus one gated write. (1) HEALTH: reports whether any DLP policy
        uses the Endpoint (Devices) location and a Graph-based licensing signal for advanced-compliance
        service plans, so you know Endpoint DLP can actually function before scoping finance endpoints.
        (2) SCOPE: reports the named policy's current locations, mode, and member-of scope, and — only
        with -Commit — narrows an Exchange/OneDrive policy to the FINANCE PILOT RING by setting the
        location member-of scope (e.g. ExchangeSenderMemberOf / OneDriveSharedByMemberOf), so
        enforcement can be limited to Finance/Treasury before tenant-wide expansion. Safe by default:
        -WhatIf reports only; writes require -Commit. This helper adjusts SCOPE only — it does NOT flip a
        policy to enforce (that is a deliberate portal/change-control action).
    HOW TO RUN
        # Health + report current scope for a policy:
        powershell -File .\DLPFIN-Scope.ps1 -PolicyName 'DLP - Email NPI - Simulation' -WhatIf
        # Restrict the Exchange policy to the finance pilot-ring group (still simulation mode):
        powershell -File .\DLPFIN-Scope.ps1 -PolicyName 'DLP - Email NPI - Simulation' `
            -PilotRingGroup 'DLPFinancePilot@contoso.com' -Location Exchange -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession); Graph (Organization.Read.All) for the licensing signal.
    EXPECTED RESULTS
        Health lines (endpoint location in use? advanced-compliance plan present?) plus, for scope:
        -WhatIf prints the current locations/mode and the Set-DlpCompliancePolicy call it WOULD run;
        -Commit applies the member-of scope and re-prints it. PASS: the policy's *MemberOf scope now
        equals the finance ring, and Mode is unchanged (still simulation until you enforce in the portal).
.NOTES
    Purview — Financial (GLBA/SOX) DLP Pack. Scope changes gated behind -Commit; never changes enforcement mode. No credentials in code.
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

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# --- HEALTH signals (read-only) ---
if (-not $SkipHealth) {
    Write-Host '=== Endpoint / licensing health (read-only) ===' -ForegroundColor Cyan
    # Endpoint (Devices) location in use by any policy?
    $endpointPolicies = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue |
        Where-Object { $_.EndpointDlpLocation -and $_.EndpointDlpLocation.Count -gt 0 }
    if ($endpointPolicies) {
        Write-Host ("Endpoint (Devices) location in use by {0} policy(ies)." -f (@($endpointPolicies).Count)) -ForegroundColor Green
    } else {
        Write-Host 'No DLP policy currently targets the Endpoint (Devices) location.' -ForegroundColor Yellow
    }
    # Licensing signal via Graph subscribedSkus (advanced-compliance / Endpoint DLP indicative plans).
    if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
        Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
        try {
            Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome -ErrorAction Stop
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $capablePlans = 'MICROSOFTENDPOINTDLP','MIP_S_CLP2','M365_ADVANCED_AUDITING','Content_Explorer','INFO_GOVERNANCE'
            $found = @()
            foreach ($s in $skus) { foreach ($sp in $s.servicePlans) {
                if ($capablePlans -contains $sp.servicePlanName -and $sp.provisioningStatus -eq 'Success') { $found += $sp.servicePlanName }
            } }
            $found = $found | Select-Object -Unique
            if ($found -contains 'MICROSOFTENDPOINTDLP') {
                Write-Host 'Licensing: MICROSOFTENDPOINTDLP service plan present — Endpoint DLP capable.' -ForegroundColor Green
            } elseif ($found.Count -gt 0) {
                Write-Host ("Licensing: advanced-compliance plans present ({0}) — likely E5/E5 Compliance; CONFIRM in admin center." -f ($found -join ', ')) -ForegroundColor Yellow
            } else {
                Write-Host 'Licensing: no advanced-compliance service-plan signal — VERIFY your licensing (E5 / E5 Compliance).' -ForegroundColor Red
            }
        } catch {
            Write-Host ("Licensing signal skipped: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
        }
    } else {
        Write-Host 'Microsoft.Graph.Authentication not installed — skipping licensing signal (use -SkipHealth to suppress).' -ForegroundColor DarkYellow
    }
    Write-Host 'Reminder: authoritative device-onboarding state is Purview portal > Settings > Device onboarding.' -ForegroundColor Cyan
}

# --- SCOPE (report always; write only with -Commit) ---
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
    Write-Host 'No -PilotRingGroup supplied — reporting only. Supply the finance ring group (and -Commit) to restrict scope.' -ForegroundColor Yellow
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
