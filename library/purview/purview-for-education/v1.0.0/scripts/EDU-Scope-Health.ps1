<#
.SYNOPSIS
    EDU-Scope-Health.ps1 — Read-only readiness check: compliance licensing, operator roles, in-scope workloads, gaps vs Requirements.
.DESCRIPTION
    PURPOSE
        Reports whether the tenant is ready for the education/FERPA Purview program before you configure
        anything: the compliance licensing the tenant exposes (via Microsoft Graph subscribedSkus), the
        operator's visible Purview role-group membership, the in-scope workloads, and the gaps against
        the Requirements Guide. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDU-Scope-Health.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for licensing, Microsoft.Graph with
        delegated Organization.Read.All / Directory.Read.All. MFA-capable admin; no secrets in code.
        Optional: -PilotGroup 'EDU Pilot Users' to check the pilot group resolves.
    EXPECTED RESULTS
        A readiness summary: indicative compliance plans present (flagged "verify for your tenant"),
        visible compliance role groups, and reachability of the S&C PowerShell / Graph endpoints.
        PASS = licensing present + endpoints reachable + roles visible; FAIL = a gap to close first.
.NOTES
    Purview category — Microsoft Purview for Education (FERPA). Read-only. Capability availability is
    licensing-/plan-dependent (E5 / E5 Compliance; some preview) — verify your licensing/tenant. Plan and
    service-plan names change; confirm against your entitlements and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$PilotGroup,
    [switch]$SkipGraph
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

Write-Host "=== Education Purview program — scope & health (read-only) ===" -ForegroundColor Cyan

# --- Endpoint: Security & Compliance PowerShell ---
Write-Section "Security & Compliance PowerShell"
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$ippsOk = $false
try { Connect-IPPSSession -ErrorAction Stop | Out-Null; $ippsOk = $true; Ok "Connect-IPPSSession : reachable" }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }

# --- Operator role groups (least-privilege visibility) ---
if ($ippsOk) {
    Write-Section "Compliance role groups (operator visibility)"
    try {
        $rg = Get-RoleGroup -ErrorAction Stop | Where-Object { $_.Name -match 'Compliance|Records|Retention|Information Protection|Audit|Data' }
        if ($rg) {
            $rg | Select-Object Name, @{n='Members';e={ @($_.Members).Count }} | Format-Table -AutoSize | Out-String | Write-Host
            Warn "Confirm you hold ONLY the least-privilege roles you need (Information Protection, DLP/Compliance Admin, Records Management)."
        } else { Warn "No matching compliance role groups visible (permissions may be limited)." }
    } catch { Warn "Could not enumerate role groups (Get-RoleGroup): $($_.Exception.Message)" }
}

# --- Licensing (Microsoft Graph) ---
if (-not $SkipGraph) {
    Write-Section "Compliance licensing (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraph)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome
            # Indicative service plans — VERIFY names for your tenant; naming changes over time.
            $wanted = @{
                'Information Protection & Governance (advanced labels/DLP/auto-label)' = 'INFORMATION_PROTECTION_AND_GOVERNANCE_SERVICE_PLAN'
                'Records Management'                                                    = 'RECORDS_MANAGEMENT'
                'Audit (Premium / Advanced Auditing)'                                   = 'M365_ADVANCED_AUDITING'
            }
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $planNames = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique
            foreach ($k in $wanted.Keys) {
                if ($planNames -contains $wanted[$k]) { Ok "$k : plan '$($wanted[$k])' present (confirm it is ASSIGNED to in-scope users)." }
                else { Warn "$k : plan '$($wanted[$k])' NOT found — may be unlicensed (verify plan name/licensing for your tenant)." }
            }
            if ($PilotGroup) {
                $esc = $PilotGroup.Replace("'","''")
                $grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $esc)).value
                if ($grp) { Ok "Pilot group '$PilotGroup' resolves (id $($grp[0].id)) — target 'EDU - Label Policy - Pilot' / DLP pilot here." }
                else { Warn "Pilot group '$PilotGroup' not found — confirm the exact display name before publishing to the pilot." }
            }
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Close any licensing/role/endpoint gap before configuring. Feature availability is licensing-/tenant-dependent — verify. FERPA applicability, retention periods, and holds are governance determinations." -ForegroundColor White
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
