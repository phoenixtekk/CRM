<#
.SYNOPSIS
    PURVSOX-Scope.ps1 — SOX program readiness/health: connectivity, roles + SoD, licensing, Compliance Manager reach (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready for the SOX-aligned Purview program with no changes: which
        endpoints (Security & Compliance PowerShell, Exchange Online, Graph) are reachable, the Purview
        role groups and their members (for segregation-of-duties review), whether E5 / E5-Compliance
        service plans are present, and whether Compliance Manager / DLP appear licensed. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVSOX-Scope.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession) and, for licensing/roles,
        Microsoft.Graph with delegated Organization.Read.All / RoleManagement.Read.Directory. Uses an
        interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A readiness summary: endpoints reachable Yes/No, the Purview role groups + members to review for
        SoD, whether an E5/E5-Compliance plan is present, and a reminder to verify Compliance Manager
        template availability in the portal. Any "verify your licensing/tenant" item is flagged.
.NOTES
    Purview category — SOX Compliance Program. Read-only. Advanced DLP/auto-labeling/long-term audit
    retention/Compliance Manager templates are licensing-/tenant-dependent and evolving; confirm against
    your entitlements and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,                      # optional: admin UPN passed to Connect-* prompts
    [switch]$SkipGraph                               # skip the Graph licensing/role section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# --- Security & Compliance PowerShell (labels/DLP/retention/audit-retention live here) ---
Write-Section "Security & Compliance PowerShell reachability"
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; Ok "Connect-IPPSSession OK (labels, DLP, retention, audit-retention cmdlets available)." }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }

# --- Exchange Online (unified audit config + search) ---
Write-Section "Exchange Online PowerShell reachability"
try { Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null; Ok "Connect-ExchangeOnline OK (Get/Set-AdminAuditLogConfig, Search-UnifiedAuditLog available)." }
catch { Warn "Connect-ExchangeOnline failed: $($_.Exception.Message)" }

# --- Purview role groups + SoD review ---
Write-Section "Purview role groups (review for segregation of duties)"
try {
    $soxRoles = 'ComplianceAdministrator','Compliance Administrator','Compliance Data Administrator',
                'Information Protection','Information Protection Admins','Records Management',
                'Audit Manager','Audit Reader','Organization Management'
    $rgs = Get-RoleGroup -ErrorAction Stop | Where-Object { $soxRoles -contains $_.Name -or $_.Name -match 'Compliance|Protection|Records|Audit' }
    if ($rgs) {
        foreach ($rg in $rgs) {
            $members = (Get-RoleGroupMember -Identity $rg.Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ', '
            Write-Host ("  {0}: {1}" -f $rg.Name, ($(if($members){$members}else{'<no members>'})))
        }
        Warn "SoD check: the party that CONFIGURES a control should not be the sole party that REVIEWS its evidence. Confirm the separation above."
    } else { Warn "No matching compliance/protection/records/audit role groups returned — verify permissions to read role groups." }
} catch { Warn "Could not enumerate role groups (Get-RoleGroup): $($_.Exception.Message)" }

# --- Licensing + Compliance Manager (Microsoft Graph) ---
if (-not $SkipGraph) {
    Write-Section "Licensing for advanced controls (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing section. Install-Module Microsoft.Graph -Scope CurrentUser (or re-run with -SkipGraph)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome
            # Service plans that indicate the advanced compliance controls — verify plan names for your tenant.
            $wanted = 'INFORMATION_BARRIERS','M365_ADVANCED_AUDITING','MIP_S_CLP2','Content_Explorer','ContentExplorer_Standard','ComplianceManager_Premium','RMS_S_PREMIUM2'
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $planNames = $skus.servicePlans.servicePlanName | Sort-Object -Unique
            $found = $wanted | Where-Object { $planNames -contains $_ }
            if ($found) { Ok ("Advanced-compliance service plan(s) present: {0}" -f ($found -join ', ')) }
            else { Warn "No advanced-compliance service plans matched the sample list — E5/E5-Compliance may not be licensed (verify your licensing/tenant; plan names change)." }
            Warn "Verify in the Purview portal that COMPLIANCE MANAGER and DLP are visible, and that a SOX/ICFR (or custom) assessment template is available for your licensing."
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Confirm endpoints reachable, SoD separation documented, and advanced-control licensing before configuring. Verify Compliance Manager template availability in the portal." -ForegroundColor White
