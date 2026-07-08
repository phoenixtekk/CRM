<#
.SYNOPSIS
    PURVARCH-Discovery.ps1 — baseline the Purview estate: licensing/capabilities, role groups, policies, scopes, audit (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell (and, optionally, Microsoft Graph) to capture the
        Microsoft Purview design baseline BEFORE the architecture is scaled. It reports the subscribed
        SKUs it can read and an INDICATIVE capability-availability mapping, the current compliance role
        groups and their membership, existing sensitivity labels / DLP / retention policies and any
        adaptive scopes, and the unified-audit-log state. This is the "PA Design Baseline - Tenant -
        Assess" snapshot. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Discovery.ps1 -IncludeGraph
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Discovery.ps1 -IncludeGraph -CsvPath .\baseline.csv

        Prereqs: ExchangeOnlineManagement module (Connect-IPPSSession) and an MFA-capable admin with at
        least read access to compliance configuration. For -IncludeGraph, the Microsoft.Graph module and
        Organization.Read.All / Directory.Read.All. The capability-availability mapping is INDICATIVE —
        Purview features are licensing-gated and the portal evolves; confirm entitlement with Microsoft
        licensing and verify capability nodes appear in purview.microsoft.com.
    EXPECTED RESULTS
        A baseline summary: licensing SKUs + indicative capability availability, a table of compliance
        role groups with member counts, counts of existing labels / DLP / retention policies / adaptive
        scopes, and the audit-ingestion state. PASS overall = the baseline is captured without error and
        can be used to build the capability map and RBAC model.
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

# Compliance role groups that typically anchor the RBAC model. Names EVOLVE and the tenant may use the
# unified Purview RBAC surface — treat this list as a probe, not an assertion.
$rbacGroups = @(
    'Compliance Administrator','Compliance Data Administrator','Organization Management',
    'Information Protection','Information Protection Admins','Information Protection Analysts',
    'Information Protection Investigators','Information Protection Readers',
    'Records Management','Data Investigator',
    'Insider Risk Management','Insider Risk Management Admins','Insider Risk Management Analysts',
    'Insider Risk Management Investigators','Insider Risk Management Auditors',
    'Communication Compliance','Communication Compliance Admins','Communication Compliance Analysts',
    'Communication Compliance Investigators','Communication Compliance Viewers',
    'eDiscovery Manager','eDiscovery Administrator','Audit Manager','Audit Reader','Global Reader'
)

# Indicative capability -> minimum plan family. Confirm entitlement with Microsoft licensing.
$capabilityPlan = [ordered]@{
    'Unified audit log (core)'            = 'E3'
    'Manual sensitivity labels'           = 'E3'
    'Manual retention labels/policies'    = 'E3'
    'Basic DLP (Exchange/SPO/OneDrive)'   = 'E3'
    'Content/Activity explorer'           = 'E5 / E5 Compliance'
    'Automatic labeling (client+service)' = 'E5 / E5 Compliance'
    'Trainable classifiers'               = 'E5 / E5 Compliance'
    'Endpoint DLP'                        = 'E5 / E5 Compliance'
    'Records management'                  = 'E5 / E5 Compliance'
    'Insider Risk Management'             = 'E5 / E5 Compliance'
    'Communication Compliance'            = 'E5 / E5 Compliance'
    'Audit (Premium)'                     = 'E5 / E5 Compliance'
    'Adaptive Protection'                 = 'E5 / E5 Compliance'
    'Data Security Posture Mgmt (DSPM)'   = 'E5 / E5 Compliance (some preview)'
    'AI / Copilot data governance'        = 'E5 / E5 Compliance (some preview)'
}

$rows = @()

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    Write-Host 'Install ExchangeOnlineManagement and sign in with an MFA-capable admin, then retry.'
    return
}

# --- Licensing + indicative capability availability (Graph) ------------------------------------------
Write-Section 'Licensing (Graph) and INDICATIVE capability availability'
$skuText = @()
if ($IncludeGraph) {
    try {
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Environment $GraphEnvironment -Scopes @('Organization.Read.All','Directory.Read.All') | Out-Null
        }
        $skus = @(Get-MgSubscribedSku -All -ErrorAction Stop)
        Write-Host ("Subscribed SKUs found: {0}" -f $skus.Count)
        $skus | Select-Object SkuPartNumber, @{n='Enabled';e={$_.PrepaidUnits.Enabled}}, ConsumedUnits |
            Format-Table -AutoSize
        $skuText = $skus.SkuPartNumber
    }
    catch {
        Write-Warning ("Could not read licensing via Graph: {0}" -f $_.Exception.Message)
        Write-Host 'Confirm SKUs in the Microsoft 365 admin center -> Billing -> Licenses.'
    }
} else {
    Write-Host 'Graph not requested (-IncludeGraph). Confirm SKUs in admin center -> Billing -> Licenses.'
}

Write-Host ''
Write-Host 'Indicative capability -> minimum plan (CONFIRM entitlement with Microsoft licensing):'
foreach ($cap in $capabilityPlan.Keys) {
    Write-Host ("  {0,-38} {1}" -f $cap, $capabilityPlan[$cap])
    $rows += [pscustomobject]@{ Section='Capability'; Item=$cap; Value=$capabilityPlan[$cap]; Note='indicative - verify' }
}

# --- Role groups (RBAC baseline) --------------------------------------------------------------------
Write-Section 'Compliance role groups (RBAC baseline)'
foreach ($g in $rbacGroups) {
    try {
        $rg = Get-RoleGroup -Identity $g -ErrorAction Stop
        $members = @(Get-RoleGroupMember -Identity $g -ErrorAction SilentlyContinue)
        Write-Host ("  [PRESENT] {0,-42} members: {1}" -f $g, $members.Count) -ForegroundColor Green
        $rows += [pscustomobject]@{ Section='RoleGroup'; Item=$g; Value=$members.Count; Note='members' }
    }
    catch {
        Write-Host ("  [absent ] {0}" -f $g) -ForegroundColor DarkGray
        $rows += [pscustomobject]@{ Section='RoleGroup'; Item=$g; Value=0; Note='absent-or-renamed' }
    }
}
Write-Host 'Role-group names EVOLVE and the tenant may use unified Purview RBAC (Roles & scopes). Verify.'

# --- Existing policy estate -------------------------------------------------------------------------
Write-Section 'Existing policy estate (labels / DLP / retention / adaptive scopes)'
function Count-Objects([string] $cmd, [string] $label) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        try {
            $c = @(& $cmd -ErrorAction Stop).Count
            Write-Host ("  {0,-28} {1}" -f $label, $c)
            $script:rows += [pscustomobject]@{ Section='Estate'; Item=$label; Value=$c; Note=$cmd }
        } catch {
            Write-Host ("  {0,-28} (unreadable: {1})" -f $label, $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  {0,-28} (cmdlet {1} not available)" -f $label, $cmd) -ForegroundColor DarkGray
    }
}
Count-Objects 'Get-Label'                    'Sensitivity labels'
Count-Objects 'Get-LabelPolicy'              'Label policies'
Count-Objects 'Get-DlpCompliancePolicy'      'DLP policies'
Count-Objects 'Get-RetentionCompliancePolicy' 'Retention policies'
Count-Objects 'Get-ComplianceTag'            'Retention labels'
Count-Objects 'Get-AdaptiveScope'            'Adaptive scopes'
Write-Host 'Adaptive scopes are licensing-gated; absence of the cmdlet is a readiness signal, not an error.'

# --- Audit state ------------------------------------------------------------------------------------
Write-Section 'Unified audit log state'
if (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue) {
    try {
        $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
        $ingest = $cfg.UnifiedAuditLogIngestionEnabled
        $color = if ($ingest) { 'Green' } else { 'Yellow' }
        Write-Host ("  UnifiedAuditLogIngestionEnabled: {0}" -f $ingest) -ForegroundColor $color
        $rows += [pscustomobject]@{ Section='Audit'; Item='UnifiedAuditLogIngestionEnabled'; Value=$ingest; Note='' }
    } catch {
        Write-Warning ("Could not read audit config: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host '  Get-AdminAuditLogConfig not available in this session (needs Exchange Online cmdlets).' -ForegroundColor DarkGray
}

# --- Optional CSV -----------------------------------------------------------------------------------
if ($CsvPath) {
    try {
        $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host ("`nBaseline written to {0}" -f $CsvPath) -ForegroundColor Green
    } catch {
        Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message)
    }
}

# --- Verdict ----------------------------------------------------------------------------------------
Write-Section 'Discovery complete'
Write-Host 'BASELINE captured as "PA Design Baseline - Tenant - Assess".'
Write-Host 'Next: build "PA Capability Map - Tenant - Design" (map capabilities to licensing + phase),'
Write-Host 'then the "PA RBAC Model - Tenant - Design" and "PA Scoping Plan - Tenant - Design".'
Write-Host 'Capability availability is INDICATIVE — verify against your licensing/tenant in the portal.'
