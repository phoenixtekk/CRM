<#
.SYNOPSIS
    PURVARCH-Report.ps1 — emit the capability-map scaffold and design-posture rollup to CSV (read-only).
.DESCRIPTION
    PURPOSE
        Produces the "PA Capability Map - Tenant - Design" scaffold and the "PA Design Posture - Report"
        — capability coverage vs licensing, RBAC role-group/member summary, existing policy/scope counts,
        and the phase model — as a leadership-facing CSV rollup. Read-only — it changes nothing. It reads
        the same signals as PURVARCH-Discovery.ps1 and structures them for reporting.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Report.ps1 -CsvPath .\design-posture.csv
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Report.ps1 -IncludeGraph -CsvPath .\design-posture.csv

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession); for -IncludeGraph, Microsoft.Graph with
        Organization.Read.All. Capability availability is INDICATIVE and licensing-gated — the portal is
        authoritative; verify against your tenant.
    EXPECTED RESULTS
        A console summary and (with -CsvPath) a CSV containing the capability map (capability, plan,
        phase, status placeholder), the RBAC summary (group, member count), the estate counts, and the
        phase model. PASS = the report generates and matches the portal.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Microsoft Graph. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/',
    [switch] $IncludeGraph,
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $GraphEnvironment = 'Global',
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Capability -> (indicative plan, phase). Confirm entitlement with Microsoft licensing.
$capMap = @(
    @{ Cap='Unified audit log (core)';            Plan='E3';                                Phase='0 Foundation' }
    @{ Cap='Purview RBAC role groups / scopes';   Plan='E3';                                Phase='0 Foundation' }
    @{ Cap='Content/Activity explorer';           Plan='E5 / E5 Compliance';                Phase='1 Know' }
    @{ Cap='Sensitive information types';         Plan='E3';                                Phase='1 Know' }
    @{ Cap='Trainable classifiers';               Plan='E5 / E5 Compliance';                Phase='1 Know' }
    @{ Cap='Sensitivity labels + policies';       Plan='E3 (auto = E5)';                    Phase='2 Protect' }
    @{ Cap='Container / site labeling';           Plan='E3 / E5';                           Phase='2 Protect' }
    @{ Cap='Automatic labeling';                  Plan='E5 / E5 Compliance';                Phase='2 Protect' }
    @{ Cap='DLP (Exchange/SPO/OneDrive/Teams)';   Plan='E3 (advanced = E5)';                Phase='3 Prevent loss' }
    @{ Cap='Endpoint DLP';                        Plan='E5 / E5 Compliance';                Phase='3 Prevent loss' }
    @{ Cap='Retention labels/policies';           Plan='E3 (adaptive = E5)';                Phase='4 Govern' }
    @{ Cap='Records management';                  Plan='E5 / E5 Compliance';                Phase='4 Govern' }
    @{ Cap='Data lifecycle / disposition';        Plan='E5 / E5 Compliance';                Phase='4 Govern' }
    @{ Cap='Insider Risk Management';             Plan='E5 / E5 Compliance';                Phase='5 Advanced' }
    @{ Cap='Communication Compliance';            Plan='E5 / E5 Compliance';                Phase='5 Advanced' }
    @{ Cap='Adaptive Protection';                 Plan='E5 / E5 Compliance';                Phase='5 Advanced' }
    @{ Cap='Data Security Posture Mgmt (DSPM)';   Plan='E5 / E5 Compliance (some preview)'; Phase='5 Advanced' }
    @{ Cap='AI / Copilot data governance';        Plan='E5 / E5 Compliance (some preview)'; Phase='5 Advanced' }
)

$rbacGroups = @(
    'Compliance Administrator','Information Protection Admins','Records Management',
    'Insider Risk Management Admins','Communication Compliance Admins','eDiscovery Administrator',
    'Audit Manager','Global Reader'
)

$out = @()

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); return }

# --- Licensing (optional) ---------------------------------------------------------------------------
$skuList = @()
if ($IncludeGraph) {
    try {
        if (-not (Get-MgContext)) { Connect-MgGraph -Environment $GraphEnvironment -Scopes @('Organization.Read.All') | Out-Null }
        $skuList = @((Get-MgSubscribedSku -All -ErrorAction Stop).SkuPartNumber)
    } catch { Write-Warning ("Could not read licensing: {0}" -f $_.Exception.Message) }
}

# --- Capability map scaffold ------------------------------------------------------------------------
Write-Section 'PA Capability Map - Tenant - Design (scaffold — complete status with the owners)'
foreach ($c in $capMap) {
    Write-Host ("  {0,-14} {1,-38} {2}" -f $c.Phase, $c.Cap, $c.Plan)
    $out += [pscustomobject]@{
        Section='CapabilityMap'; Phase=$c.Phase; Capability=$c.Cap; MinPlan=$c.Plan
        Status='<in-scope | deferred-not-licensed | out-of-scope>'; Owner='<owner>'
    }
}
Write-Host 'STATUS/OWNER are placeholders — set them with the governance owners. Plan is INDICATIVE; verify.'

# --- RBAC summary -----------------------------------------------------------------------------------
Write-Section 'RBAC summary (role group -> member count)'
foreach ($g in $rbacGroups) {
    try {
        $n = @(Get-RoleGroupMember -Identity $g -ErrorAction Stop).Count
        Write-Host ("  {0,-34} {1}" -f $g, $n)
        $out += [pscustomobject]@{ Section='RBAC'; Phase=''; Capability=$g; MinPlan=''; Status=$n; Owner='members' }
    } catch {
        Write-Host ("  {0,-34} (absent/renamed)" -f $g) -ForegroundColor DarkGray
    }
}

# --- Estate counts ----------------------------------------------------------------------------------
Write-Section 'Existing estate counts'
function Add-Count([string] $cmd, [string] $label) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        try {
            $n = @(& $cmd -ErrorAction Stop).Count
            Write-Host ("  {0,-26} {1}" -f $label, $n)
            $script:out += [pscustomobject]@{ Section='Estate'; Phase=''; Capability=$label; MinPlan=''; Status=$n; Owner='' }
        } catch { Write-Host ("  {0,-26} (unreadable)" -f $label) -ForegroundColor Yellow }
    } else { Write-Host ("  {0,-26} (cmdlet unavailable)" -f $label) -ForegroundColor DarkGray }
}
Add-Count 'Get-Label'                     'Sensitivity labels'
Add-Count 'Get-DlpCompliancePolicy'       'DLP policies'
Add-Count 'Get-RetentionCompliancePolicy' 'Retention policies'
Add-Count 'Get-AdaptiveScope'             'Adaptive scopes'

# --- CSV --------------------------------------------------------------------------------------------
if ($CsvPath) {
    try { $out | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nPA Design Posture - Report written to {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message) }
} else {
    Write-Host "`nTip: pass -CsvPath .\design-posture.csv to save the PA Design Posture - Report."
}

Write-Section 'Report complete'
Write-Host 'The AUTHORITATIVE role/scope/policy/licensing state is the Microsoft Purview portal and admin center.'
Write-Host 'Capability plan mapping is INDICATIVE — confirm entitlement with Microsoft licensing.'
