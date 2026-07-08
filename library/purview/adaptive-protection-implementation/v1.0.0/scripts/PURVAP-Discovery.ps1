<#
.SYNOPSIS
    PURVAP-Discovery.ps1 — assess Adaptive Protection readiness: IRM source signal, DLP policies, and CA presence (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell (and, optionally, Microsoft Graph) to assess
        readiness for Microsoft Purview ADAPTIVE PROTECTION. It reports whether an Insider Risk
        Management source policy is present/scoring where readable (Adaptive Protection maps IRM scoring
        onto Elevated/Moderate/Minor risk levels), inventories existing DLP policies and whether any DLP
        rule already references the adaptive-protection risk-level condition, prompts you to confirm the
        IRM privacy (anonymization) posture in the portal, and — if Graph is available — reports
        Conditional Access policy presence. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVAP-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVAP-Discovery.ps1 -IncludeConditionalAccess

        Prereqs: ExchangeOnlineManagement module (Connect-IPPSSession) and an MFA-capable admin with at
        least read access to compliance policies. For -IncludeConditionalAccess, the Microsoft.Graph
        module and Policy.Read.All. Adaptive Protection SETUP and the DLP risk-level CONDITION are
        managed in the portals (purview.microsoft.com / entra.microsoft.com); some objects have no
        PowerShell read surface — where that is the case this script says so. Verify capability
        availability against your licensing/tenant (E5 / E5 Compliance for IRM+DLP; Entra ID P2 for CA).
    EXPECTED RESULTS
        A readiness summary: IRM source-policy signal (present/scoring or "confirm in portal"), a table
        of DLP policies with whether any rule text references the risk-level condition, a privacy
        confirmation prompt, and (optionally) CA policy count. PASS overall = an IRM scoring source is
        evident and the assessment completes without error.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Microsoft Graph. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/',
    [switch] $IncludeConditionalAccess,
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Text fragments that indicate a DLP rule uses the adaptive-protection risk-level condition. The exact
# property/label evolves and may be portal-only; we scan readable rule text rather than assume a param.
$riskLevelHints = @('adaptive', 'risk level', 'insider risk', 'RiskLevel')

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    Write-Host 'Install ExchangeOnlineManagement and sign in with an MFA-capable admin, then retry.'
    return
}

# --- IRM source signal ------------------------------------------------------------------------------
Write-Section 'Insider Risk Management source signal (drives risk levels)'
$irmSignal = $false
if (Get-Command Get-InsiderRiskPolicy -ErrorAction SilentlyContinue) {
    try {
        $pol = Get-InsiderRiskPolicy -ErrorAction Stop
        if ($pol) {
            $irmSignal = $true
            $pol | Select-Object Name, Enabled, Guid | Format-Table -AutoSize
            Write-Host 'An IRM policy is readable. Adaptive Protection maps its scoring onto risk levels.' -ForegroundColor Green
        } else {
            Write-Host 'No IRM policy returned. Adaptive Protection needs an insider-risk scoring source.' -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning ("Could not read IRM policies via cmdlet: {0}" -f $_.Exception.Message)
        Write-Host 'Confirm in purview.microsoft.com -> Insider Risk Management -> Policies.'
    }
} else {
    Write-Host 'Get-InsiderRiskPolicy not available in this session/tenant (IRM authoring is largely'
    Write-Host 'portal-based). Confirm an active insider-risk policy in the Purview portal. Adaptive'
    Write-Host 'Protection has no signal without one. Verify availability against your licensing/tenant.'
}

# --- DLP policies + risk-level condition scan -------------------------------------------------------
Write-Section 'DLP policies (and whether any rule references the risk-level condition)'
try {
    $dlpPolicies = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    if ($dlpPolicies.Count -eq 0) {
        Write-Host 'No DLP policies found. The adaptive policy DLP-Adaptive-Protection is built in the portal.' -ForegroundColor Yellow
    } else {
        $dlpPolicies | Select-Object Name, Mode, Enabled | Format-Table -AutoSize
    }

    $rules = @(Get-DlpComplianceRule -ErrorAction SilentlyContinue)
    $adaptiveRules = @()
    foreach ($r in $rules) {
        $blob = ($r | Out-String)
        if ($riskLevelHints | Where-Object { $blob -match [regex]::Escape($_) }) {
            $adaptiveRules += [pscustomobject]@{ Rule = $r.Name; Policy = $r.ParentPolicyName }
        }
    }
    if ($adaptiveRules.Count -gt 0) {
        Write-Host 'DLP rules that appear to reference the adaptive-protection / risk-level condition:' -ForegroundColor Green
        $adaptiveRules | Format-Table -AutoSize
    } else {
        Write-Host 'No DLP rule appears to reference the risk-level condition yet. Expected rules:'
        Write-Host '  AP-Elevated-Block / AP-Moderate-WarnOverride / AP-Minor-Audit in DLP-Adaptive-Protection.'
        Write-Host '  The risk-level condition is added in the portal (verify availability in your tenant).'
    }
}
catch {
    Write-Warning ("Could not enumerate DLP policies/rules: {0}" -f $_.Exception.Message)
}

# --- IRM privacy posture (portal-managed) -----------------------------------------------------------
Write-Section 'IRM privacy / anonymization posture (confirm in portal)'
Write-Host 'Adaptive Protection consumes IRM scoring, so keep the IRM privacy guardrails ON:'
Write-Host '  purview.microsoft.com -> Insider Risk Management -> Settings -> Privacy'
Write-Host '  -> "Show anonymized versions of usernames" should be SELECTED (ON).'

# --- Conditional Access (optional, Graph) -----------------------------------------------------------
if ($IncludeConditionalAccess) {
    Write-Section 'Conditional Access policies (Graph)'
    try {
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Environment $GraphEnvironment -Scopes @('Policy.Read.All') | Out-Null
        }
        $ca = @(Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop)
        Write-Host ("Conditional Access policies found: {0}" -f $ca.Count)
        $ca | Where-Object { $_.DisplayName -match 'insider|risk|adaptive' } |
            Select-Object DisplayName, State | Format-Table -AutoSize
        Write-Host 'Expected: CA-InsiderRisk-Elevated (Insider risk = Elevated), report-only first, break-glass excluded.'
        Write-Host 'The "Insider risk" CA condition requires Entra ID P2 — verify in your tenant.'
    }
    catch {
        Write-Warning ("Could not read Conditional Access via Graph: {0}" -f $_.Exception.Message)
        Write-Host 'Confirm in entra.microsoft.com -> Protection -> Conditional Access.'
    }
}

# --- Verdict ----------------------------------------------------------------------------------------
Write-Section 'Discovery complete'
if ($irmSignal) {
    Write-Host 'READINESS: an IRM scoring source is evident — Adaptive Protection has a signal to map.' -ForegroundColor Green
} else {
    Write-Host 'READINESS: confirm an active insider-risk policy in the portal — Adaptive Protection'  -ForegroundColor Yellow
    Write-Host '           cannot assign risk levels without one.'
}
Write-Host 'Expected object names: SG-AP-Pilot; DLP-Adaptive-Protection (AP-Elevated-Block /'
Write-Host 'AP-Moderate-WarnOverride / AP-Minor-Audit); CA-InsiderRisk-Elevated.'
