<#
.SYNOPSIS
    DLPPRINT-EndpointReadiness.ps1 — Endpoint DLP Print readiness: licensing signal and Devices-location usability for the Print activity (read-only).
.DESCRIPTION
    PURPOSE
        Reports the readiness signals an Endpoint DLP Print restriction depends on: (1) a licensing
        signal for Endpoint DLP (typically E5 / E5 Compliance) read from the tenant's subscribed SKUs via
        Microsoft Graph, and (2) whether the Devices/Endpoint DLP location is usable — i.e. whether any
        DLP policy can scope Devices — read from Security & Compliance PowerShell. Read-only — makes no
        changes. Onboarded-device count is confirmed in the portal (Settings → Device onboarding); there
        is no reliable S&C cmdlet for it, so the script flags it for portal verification rather than
        inventing one.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPPRINT-EndpointReadiness.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for the licensing signal, Microsoft
        Graph PowerShell (Connect-MgGraph -Scopes 'Organization.Read.All'). The script connects if no
        session is present; skip -CheckLicensing to run S&C-only.
    EXPECTED RESULTS
        A licensing signal (E5 / E5 Compliance service plans present or "verify your licensing/tenant"),
        confirmation that the Devices DLP location is usable, and an explicit reminder to verify onboarded,
        reporting devices in the portal before expecting the Print activity to fire. Nothing is modified.
.NOTES
    Purview category — Print DLP (Endpoint DLP). Read-only. Endpoint DLP is licensing-gated and the Print
    activity is OS-/build-dependent (Windows most complete; macOS varies) — verify against current
    Microsoft guidance / your tenant. Regulatory/records/legal determinations are deferred to the
    relevant governance functions.
#>
[CmdletBinding()]
param(
    [switch]$CheckLicensing = $true
)

function Check([string]$name, [string]$state, [string]$col, [string]$detail) {
    Write-Host ("  [{0}] {1} {2}" -f $state, $name, $detail) -ForegroundColor $col
}

Write-Host "`n=== Endpoint DLP Print readiness (read-only) ===" -ForegroundColor Cyan

# --- 1. Licensing signal (Graph subscribedSkus) ---
Write-Host "`n-- Licensing signal --" -ForegroundColor Cyan
if ($CheckLicensing) {
    try {
        if (-not (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue)) {
            Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
        }
        if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
            Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome -ErrorAction Stop
        }
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        # Service plans that indicate advanced compliance / Endpoint DLP eligibility. Plan names evolve -
        # this is a SIGNAL, not a determination. Verify your licensing/tenant.
        $planNames = @()
        foreach ($s in $skus) { foreach ($p in $s.ServicePlans) { $planNames += "$($p.ServicePlanName)" } }
        $signals = $planNames | Where-Object { $_ -match 'INFORMATION_PROTECTION|COMPLIANCE|MIP_S_CLP|M365_ADVANCED_AUDITING|E5' } | Sort-Object -Unique
        if ($signals) {
            Check 'Advanced compliance / Endpoint DLP signal' 'PASS' 'Green' "(plans: $((@($signals) | Select-Object -First 6) -join ', ')…)"
        } else {
            Check 'Advanced compliance / Endpoint DLP signal' 'WARN' 'Yellow' '(no obvious E5/E5-Compliance plan matched - VERIFY YOUR LICENSING/TENANT)'
        }
    } catch {
        Check 'Licensing signal' 'SKIP' 'Yellow' "(Graph not available - $($_.Exception.Message). Verify E5 / E5 Compliance in the M365 admin center.)"
    }
} else {
    Check 'Licensing signal' 'SKIP' 'Gray' '(-CheckLicensing:$false - verify E5 / E5 Compliance manually)'
}

# --- 2. Devices/Endpoint DLP location usable (S&C PowerShell) ---
Write-Host "`n-- Devices (Endpoint) DLP location --" -ForegroundColor Cyan
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop | Out-Null
    }
    $policies = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    $scopingDevices = @($policies | Where-Object { $_.EndpointDlpLocation -and @($_.EndpointDlpLocation).Count -gt 0 })
    if ($scopingDevices.Count -gt 0) {
        Check 'Devices location in use' 'PASS' 'Green' "($($scopingDevices.Count) policy(ies) already scope Devices - location is usable)"
    } else {
        Check 'Devices location in use' 'INFO' 'Yellow' '(no policy scopes Devices yet - build the simulation policy per the Implementation Guide; the location is available once devices are onboarded)'
    }
} catch {
    Check 'Devices location check' 'FAIL' 'Red' "(unable to read DLP policies - confirm your DLP role / S&C session: $($_.Exception.Message))"
}

# --- 3. Onboarded-device reminder (portal-verified) ---
Write-Host "`n-- Onboarded devices (portal-verified) --" -ForegroundColor Cyan
Write-Host "  [VERIFY] The Print activity only reports from onboarded, checked-in devices meeting the" -ForegroundColor Yellow
Write-Host "           minimum OS build. Confirm in Purview -> Settings -> Device onboarding that target" -ForegroundColor Yellow
Write-Host "           devices show as onboarded and reporting. There is no reliable S&C cmdlet for this -" -ForegroundColor Yellow
Write-Host "           VERIFY IN THE PORTAL / your tenant (Windows most complete; macOS Print support varies)." -ForegroundColor Yellow

Write-Host "`n=== Readiness summary ===" -ForegroundColor Cyan
Write-Host "Print DLP will only detect once: licensing is sufficient, the Devices location is usable, AND" -ForegroundColor Gray
Write-Host "target devices are onboarded and reporting. Resolve any WARN/FAIL above before authoring the rule." -ForegroundColor Gray
