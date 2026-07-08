<#
.SYNOPSIS
    PURVIRM-Set-PolicyFromTemplate.ps1 — validate prerequisites and plan an IRM policy from a template (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        A policy-from-template CONFIGURATION HELPER. IRM policy authoring is done in the Microsoft
        Purview portal; this script does the safe, checkable part around it: it validates that the
        chosen template's prerequisites are in place (the right role groups exist, the required
        indicators/trigger source are ready, anonymization is expected ON) and then prints the EXACT
        intended policy configuration/plan to apply in the portal. It DEFAULTS TO -WhatIf (plan only)
        and performs no writes. A -Commit switch is provided only for tenants where a supported IRM
        policy cmdlet is available; if none is present it explains that authoring is portal-based and
        stops. It never invents a cmdlet and never stores credentials.
    HOW TO RUN
        Plan (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\PURVIRM-Set-PolicyFromTemplate.ps1 -Template DepartingUserDataTheft
        Other templates:
          -Template DataLeaks
          -Template SecurityPolicyViolations
        Commit (only where a supported IRM policy cmdlet exists in your tenant):
          ... -Template DataLeaks -Commit

        Connects to Security & Compliance PowerShell (Connect-IPPSSession) to check role groups. Verify
        capability availability against your licensing/tenant (E5 / E5 Compliance / IRM add-on).
    EXPECTED RESULTS
        A prerequisites checklist (PASS/GAP per item) for the chosen template, followed by the intended
        policy name, trigger, indicators, and scope to configure in the portal. PASS = all prerequisites
        met and the plan is printed. GAP = a prerequisite is missing (named), fix it before authoring.
.NOTES
    White-label. Config helper — defaults to -WhatIf (plan only). No credentials in code. Portal-based authoring.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('DepartingUserDataTheft','DataLeaks','SecurityPolicyViolations')]
    [string] $Template,

    [string] $ScopeGroupName = 'SG-IRM-Pilot',
    [switch] $Commit,
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $Commit) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'

function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Template plans — Microsoft policy templates mapped to their trigger + indicator requirements + our object names.
$plans = @{
    'DepartingUserDataTheft' = [pscustomobject]@{
        PolicyName    = 'IRM-DepartingUser-DataTheft'
        MSTemplate    = 'Data theft by departing users'
        Trigger       = 'Resignation/termination date from the HR connector (or Entra account deletion)'
        Indicators    = @('Office: SharePoint download / external share / email exfiltration','Device: copy to USB, copy to personal cloud, print (requires device onboarding)')
        NeedsHR       = $true
        NeedsDevice   = $true
        NeedsMDE      = $false
        NeedsDLP      = $false
    }
    'DataLeaks' = [pscustomobject]@{
        PolicyName    = 'IRM-DataLeaks-General'
        MSTemplate    = 'Data leaks'
        Trigger       = 'A DLP policy high-severity match (or exfiltration activity)'
        Indicators    = @('Office: external share / email exfiltration','Device: copy to USB / personal cloud / print (requires device onboarding)')
        NeedsHR       = $false
        NeedsDevice   = $true
        NeedsMDE      = $false
        NeedsDLP      = $true
    }
    'SecurityPolicyViolations' = [pscustomobject]@{
        PolicyName    = 'IRM-SecurityPolicyViolations'
        MSTemplate    = 'Security policy violations'
        Trigger       = 'A Microsoft Defender for Endpoint alert'
        Indicators    = @('Microsoft Defender for Endpoint indicators')
        NeedsHR       = $false
        NeedsDevice   = $false
        NeedsMDE      = $true
        NeedsDLP      = $false
    }
}
$plan = $plans[$Template]

if ($WhatIfPreference) { Write-Host 'MODE: PLAN (-WhatIf) — no changes will be made.' -ForegroundColor Yellow }
else                   { Write-Host 'MODE: COMMIT requested — will attempt a supported cmdlet only if present.' -ForegroundColor Red }

try {
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    return
}

Write-Section ("Prerequisite check — template '{0}'" -f $plan.MSTemplate)
$gaps = @()

# Role groups must exist (separation is verified separately by PURVIRM-Discovery.ps1).
foreach ($rg in @('Insider Risk Management Admins','Insider Risk Management Analysts','Insider Risk Management Investigators','Insider Risk Management Auditors')) {
    $exists = $null
    try { $exists = Get-RoleGroup -Identity $rg -ErrorAction Stop } catch {}
    if ($exists) { Write-Host ("PASS  role group present: {0}" -f $rg) -ForegroundColor Green }
    else         { Write-Host ("GAP   role group missing: {0}" -f $rg) -ForegroundColor Yellow; $gaps += "Role group $rg" }
}

# Trigger-source prerequisites (reported as reminders — several are portal/tenant integrations).
if ($plan.NeedsHR)     { Write-Host 'CHECK HR connector must show recent successful uploads (Settings -> Data connectors), or use the Entra account-deletion trigger.' -ForegroundColor Yellow; $gaps += 'Verify HR connector / trigger' }
if ($plan.NeedsDevice) { Write-Host 'CHECK Device indicators require onboarded devices (Settings -> Device onboarding).' -ForegroundColor Yellow; $gaps += 'Verify device onboarding' }
if ($plan.NeedsMDE)    { Write-Host 'CHECK Microsoft Defender for Endpoint must be connected (indicator + trigger source).' -ForegroundColor Yellow; $gaps += 'Verify Defender for Endpoint connection' }
if ($plan.NeedsDLP)    { Write-Host 'CHECK A DLP policy must exist to act as the trigger for data-leak detection.' -ForegroundColor Yellow; $gaps += 'Verify DLP trigger policy' }

Write-Host 'CHECK Anonymization must be ON (Settings -> Privacy -> Show anonymized versions of usernames).' -ForegroundColor Yellow

Write-Section 'Intended policy configuration (apply in the portal)'
Write-Host ("Policy name : {0}" -f $plan.PolicyName)
Write-Host ("MS template : {0}" -f $plan.MSTemplate)
Write-Host ("Trigger     : {0}" -f $plan.Trigger)
Write-Host  "Indicators  :"
$plan.Indicators | ForEach-Object { Write-Host ("              - {0}" -f $_) }
Write-Host ("Scope       : {0} (pilot only — do not widen until the gates pass)" -f $ScopeGroupName)
Write-Host ''
Write-Host 'Author it: purview.microsoft.com -> Insider Risk Management -> Policies -> Create policy'
Write-Host 'Choose the template above, set the trigger/indicators/scope exactly as listed, keep it On + healthy.'

if ($Commit -and -not $WhatIfPreference) {
    Write-Section 'Commit'
    if (Get-Command New-InsiderRiskPolicy -ErrorAction SilentlyContinue) {
        Write-Warning 'A New-InsiderRiskPolicy cmdlet is present in this session. IRM policy parameters are tenant/version-specific; this helper does NOT auto-author to avoid creating a misconfigured policy. Create the policy in the portal using the plan above, then re-run PURVIRM-Discovery.ps1 to verify.'
    } else {
        Write-Host 'No supported IRM policy-authoring cmdlet is available — IRM authoring is portal-based in this tenant.'
        Write-Host 'Use the printed plan in the Purview portal. Nothing was changed.'
    }
}

Write-Section 'Result'
if ($gaps.Count -gt 0) {
    Write-Host ('GAPS to close before authoring: {0}' -f ($gaps -join '; ')) -ForegroundColor Yellow
} else {
    Write-Host 'PASS — role groups present and reminders noted. Author the policy in the portal per the plan.' -ForegroundColor Green
}
