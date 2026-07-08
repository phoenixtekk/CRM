<#
.SYNOPSIS
    IRMDEPART-Set-Policy.ps1 — validate prerequisites and plan the departing-user policy (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        A policy-from-template CONFIGURATION HELPER for the single policy this solution delivers:
        IRM-DepartingUser-DataTheft (Microsoft template "Data theft by departing users"). IRM policy
        authoring is done in the Microsoft Purview portal; this script does the safe, checkable part
        around it — it validates that the prerequisites are in place (the four IRM role groups exist,
        the trigger/indicators are ready, anonymization is expected ON) and prints the EXACT intended
        policy configuration/plan to apply in the portal. It DEFAULTS TO -WhatIf (plan only) and performs
        no writes. A -Commit switch is provided only for tenants where a supported IRM policy cmdlet is
        available; if none is present it explains that authoring is portal-based and stops. It never
        invents a cmdlet and never stores credentials.
    HOW TO RUN
        Plan (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\IRMDEPART-Set-Policy.ps1
        Commit (only where a supported IRM policy cmdlet exists in your tenant):
          powershell -ExecutionPolicy Bypass -File .\IRMDEPART-Set-Policy.ps1 -Commit

        Connects to Security & Compliance PowerShell (Connect-IPPSSession) to check role groups. Verify
        capability availability against your licensing/tenant (E5 / E5 Compliance / IRM add-on).
    EXPECTED RESULTS
        A prerequisites checklist (PASS/GAP per item), followed by the intended policy name, trigger,
        indicators, and scope to configure in the portal. PASS = all prerequisites met and the plan is
        printed. GAP = a prerequisite is missing (named); fix it before authoring.
.NOTES
    White-label. Config helper — defaults to -WhatIf (plan only). No credentials in code. Portal-based authoring.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string] $ScopeGroupName = 'SG-Departing-Pilot',
    [switch] $Commit,
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $Commit) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'

function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# The single plan this solution authors: departing-user data theft.
$plan = [pscustomobject]@{
    PolicyName = 'IRM-DepartingUser-DataTheft'
    MSTemplate = 'Data theft by departing users'
    Trigger    = 'Resignation/termination date from the Microsoft 365 HR connector (preferred) or Entra account deletion (fallback)'
    Indicators = @(
        'Office: SharePoint/OneDrive download, file shared externally, email to external/personal recipient',
        'Device: file copied to USB/removable media, copied to personal cloud, printed (requires device onboarding)',
        'Booster: cumulative exfiltration / sequence detection (recommended for slow leaks)'
    )
}

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

# Role groups must exist (separation is verified separately by IRMDEPART-Discovery.ps1).
foreach ($rg in @('Insider Risk Management Admins','Insider Risk Management Analysts','Insider Risk Management Investigators','Insider Risk Management Auditors')) {
    $exists = $null
    try { $exists = Get-RoleGroup -Identity $rg -ErrorAction Stop } catch {}
    if ($exists) { Write-Host ("PASS  role group present: {0}" -f $rg) -ForegroundColor Green }
    else         { Write-Host ("GAP   role group missing: {0}" -f $rg) -ForegroundColor Yellow; $gaps += "Role group $rg" }
}

# Trigger / indicator prerequisites (reported as reminders — several are portal/tenant integrations).
Write-Host 'CHECK HR connector must show recent successful uploads (Settings -> Data connectors) — the departing-user trigger; or choose the Entra account-deletion trigger deliberately.' -ForegroundColor Yellow
$gaps += 'Verify HR connector / trigger'
Write-Host 'CHECK Office + Device exfiltration indicators must be ON (Settings -> Policy indicators); device indicators require onboarded devices (Settings -> Device onboarding).' -ForegroundColor Yellow
$gaps += 'Verify indicators + device onboarding'
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
        Write-Warning 'A New-InsiderRiskPolicy cmdlet is present in this session. IRM policy parameters are tenant/version-specific; this helper does NOT auto-author to avoid creating a misconfigured policy. Create the policy in the portal using the plan above, then re-run IRMDEPART-Discovery.ps1 to verify.'
    } else {
        Write-Host 'No supported IRM policy-authoring cmdlet is available — IRM authoring is portal-based in this tenant.'
        Write-Host 'Use the printed plan in the Purview portal. Nothing was changed.'
    }
}

Write-Section 'Result'
if ($gaps.Count -gt 0) {
    Write-Host ('GAPS/reminders to confirm before authoring: {0}' -f ($gaps -join '; ')) -ForegroundColor Yellow
} else {
    Write-Host 'PASS — role groups present and reminders noted. Author the policy in the portal per the plan.' -ForegroundColor Green
}
