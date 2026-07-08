<#
.SYNOPSIS
    CMPHIPAA-Discovery.ps1 — HIPAA program readiness: licensing, Compliance Manager roles, and
    technical-safeguard baseline (read-only).
.DESCRIPTION
    PURPOSE
        Reports HIPAA-program readiness with no changes: the licensing SKUs it can read (E5 / E5
        Compliance entitlement that gates the HIPAA/HITECH + HITRUST templates and the advanced controls),
        the membership of each Compliance Manager role group (the HIPAA Roles - Separation Evidence
        snapshot, flagging any administrator who is also a contributor), and the current state of the
        common technical safeguards (unified audit ingestion, DLP / retention / sensitivity-label
        presence). Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPHIPAA-Discovery.ps1
        PowerShell 5.1+ / 7+. Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for the
        licensing section, Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All.
        Interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A readiness summary: E5/E5-Compliance plan present Yes/No with an assigned-user count; each
        Compliance Manager role group's membership with admin-also-contributor flagged; and a technical
        baseline (audit ingestion on/off, count of DLP / retention / label policies). Any
        "verify your licensing/tenant" item is flagged, not asserted.
.NOTES
    Purview category — HIPAA compliance program. Read-only. Compliance Manager is portal-managed; this
    script does not create assessments. Feature/template availability is licensing-/tenant-dependent and
    evolving — confirm against your entitlements and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,          # optional: admin UPN to pass to Connect-* prompts
    [switch]$SkipGraphLicensing          # skip the Graph licensing section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Info($m){ Write-Host $m -ForegroundColor Gray }

# --- Connect: Security & Compliance PowerShell (roles + technical evidence) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# --- Compliance Manager role groups: least-privilege separation snapshot ---
Write-Section "Compliance Manager role groups (HIPAA Roles - Separation Evidence)"
$cmGroups = @(
    'Compliance Manager Administrators',
    'Compliance Manager Assessors',
    'Compliance Manager Contributors',
    'Compliance Manager Readers'
)
$membership = @{}
foreach ($g in $cmGroups) {
    try {
        $members = Get-RoleGroupMember -Identity $g -ErrorAction Stop | Select-Object -ExpandProperty Name
        $membership[$g] = @($members)
        if ($members) { Ok ("{0}: {1}" -f $g, ($members -join ', ')) }
        else { Info ("{0}: (empty)" -f $g) }
    } catch {
        Warn ("{0}: could not read ({1}). Verify the exact role-group name in your tenant — Purview role naming evolves." -f $g, $_.Exception.Message)
        $membership[$g] = @()
    }
}
# Flag admin-also-contributor (separation-of-duties concern)
$admins = $membership['Compliance Manager Administrators']
$contribs = $membership['Compliance Manager Contributors']
$overlap = @($admins | Where-Object { $contribs -contains $_ })
if ($overlap.Count -gt 0) {
    Warn ("Separation-of-duties flag: {0} in BOTH Administrators AND Contributors. Confirm the governance owners accepted this." -f ($overlap -join ', '))
} else {
    Ok "No administrator is also a contributor (separation looks clean)."
}

# --- Technical-safeguard baseline (read-only) ---
Write-Section "Technical safeguard baseline"
try {
    $auditCfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($auditCfg.UnifiedAuditLogIngestionEnabled) { Ok "Unified audit log ingestion: ON  (§164.312(b) audit controls signal present)" }
    else { Warn "Unified audit log ingestion: OFF (§164.312(b) audit controls signal absent — enable in its own solution/change control; NOT retroactive)" }
} catch { Warn "Could not read AdminAuditLogConfig (audit signal): $($_.Exception.Message)" }

try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    Info ("DLP policies present: {0}  (candidate ePHI access/transmission evidence — verify one targets ePHI)" -f @($dlp).Count)
} catch { Warn "Could not enumerate DLP policies: $($_.Exception.Message)" }

try {
    $ret = Get-RetentionCompliancePolicy -ErrorAction Stop
    Info ("Retention policies present: {0}  (candidate integrity/contingency evidence — §164.312(c) / §164.308(a)(7))" -f @($ret).Count)
} catch { Warn "Could not enumerate retention policies: $($_.Exception.Message)" }

try {
    $labels = Get-Label -ErrorAction Stop
    Info ("Sensitivity labels present: {0}  (candidate access-control/transmission evidence — §164.312(a),(e))" -f @($labels).Count)
} catch { Warn "Could not enumerate sensitivity labels: $($_.Exception.Message)" }

# --- Licensing (Microsoft Graph) ---
if (-not $SkipGraphLicensing) {
    Write-Section "Compliance licensing (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing section. Install-Module Microsoft.Graph -Scope CurrentUser (or re-run with -SkipGraphLicensing)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome -ErrorAction Stop
            $skus = Get-MgSubscribedSku -ErrorAction Stop
            # E5 / E5 Compliance skuPartNumbers vary by agreement — match on common patterns, then flag to verify.
            $patterns = 'ENTERPRISEPREMIUM|SPE_E5|Microsoft_365_E5|INFORMATION_PROTECTION_COMPLIANCE|IP_COMP|E5_COMP'
            $matches = $skus | Where-Object { $_.SkuPartNumber -match $patterns }
            if ($matches) {
                foreach ($m in $matches) {
                    Ok ("Compliance-capable SKU: {0}  (enabled units: {1}, consumed: {2})" -f $m.SkuPartNumber, $m.PrepaidUnits.Enabled, $m.ConsumedUnits)
                }
                Warn "SKU names vary by agreement — CONFIRM E5 / E5 Compliance entitlement and HIPAA/HITECH + HITRUST template availability with Microsoft licensing. Do not assume from the SKU string alone."
            } else {
                Warn "No obvious E5 / E5 Compliance SKU matched. The HIPAA/HITECH and HITRUST premium templates and several advanced controls are entitlement-gated — verify your licensing/tenant."
            }
        } catch {
            Warn "Graph licensing check failed: $($_.Exception.Message)"
        }
    }
}

Write-Section "Done"
Info "Read-only. Record the score from the portal (Compliance Manager dashboard). Next: assign/verify least-privilege roles (CMPHIPAA-Set-Scope.ps1) and build the plan (CMPHIPAA-Configuration.ps1)."
