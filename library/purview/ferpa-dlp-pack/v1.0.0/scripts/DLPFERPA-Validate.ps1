<#
.SYNOPSIS
    DLPFERPA-Validate.ps1 — read-only pass/fail validation of the FERPA DLP policy set before enforce (safe: read-only).
.DESCRIPTION
    PURPOSE
        Checks the education-record DLP policy set against the pilot pass/fail gates: that each named
        policy is still in SIMULATION (Mode = Test*), that it is scoped to the intended locations, that its
        rule references the expected education-record sensitive information types (e.g. the Student ID
        custom SIT), and — where Endpoint is in scope — flags that device onboarding must be confirmed in
        the portal. Read-only: makes no changes. Run it immediately before any decision to promote a policy
        to enforce, and again after enforcement to confirm the intended state.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPFERPA-Validate.ps1 `
            -PolicyNames 'DLP - Email Education Records - Simulation' `
            -ExpectedLocations Exchange -ExpectedSITs 'Student ID - Custom SIT - FERPA'
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
.EXAMPLE
    .\DLPFERPA-Validate.ps1 -PolicyNames 'DLP - Email Education Records - Simulation' -ExpectedLocations Exchange
    Prints one PASS/FAIL line per gate for the named policy and an overall result.
.NOTES
    Purview — FERPA DLP Pack. Read-only against Security & Compliance PowerShell. No credentials in code.
    Expected results: every gate PASS during pilot (policies in simulation, correctly scoped) = safe to
    proceed to the enforce decision; any FAIL = fix in simulation and re-validate before enforcing.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$PolicyNames,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Endpoint')]
    [string[]]$ExpectedLocations = @('Exchange'),
    [string[]]$ExpectedSITs = @('Student ID - Custom SIT - FERPA'),
    # Set when you are validating an INTENTIONALLY enforced policy (post-promotion); default expects simulation.
    [switch]$ExpectEnforce,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# Map friendly location names to the policy's location properties.
$locProp = @{
    Exchange   = 'ExchangeLocation'
    SharePoint = 'SharePointLocation'
    OneDrive   = 'OneDriveLocation'
    Teams      = 'TeamsLocation'
    Endpoint   = 'EndpointDlpLocation'
}

$overall = $true
function Write-Gate($ok, $text) {
    if ($ok) { Write-Host ("  PASS  {0}" -f $text) -ForegroundColor Green }
    else     { Write-Host ("  FAIL  {0}" -f $text) -ForegroundColor Red; $script:overall = $false }
}

Write-Host '=== FERPA DLP Validation (read-only) ===' -ForegroundColor Cyan

foreach ($name in $PolicyNames) {
    Write-Host ("--- Policy: {0} ---" -f $name) -ForegroundColor Cyan
    $p = Get-DlpCompliancePolicy -Identity $name -ErrorAction SilentlyContinue
    if (-not $p) {
        Write-Gate $false ("Policy '{0}' not found (check name / role)." -f $name)
        continue
    }

    # Gate 1 — mode (simulation during pilot; Enable only when -ExpectEnforce)
    if ($ExpectEnforce) {
        Write-Gate ($p.Mode -eq 'Enable') ("Mode is Enable (enforcing) as expected — actual: {0}" -f $p.Mode)
    } else {
        Write-Gate ($p.Mode -like 'Test*') ("Mode is SIMULATION (Test*) — actual: {0}" -f $p.Mode)
    }

    # Gate 2 — location scope matches expectation
    foreach ($loc in $ExpectedLocations) {
        $prop = $locProp[$loc]
        $val = $p.$prop
        $covered = ($val -and $val.Count -gt 0)
        Write-Gate $covered ("Location '{0}' is in scope" -f $loc)
        if ($loc -eq 'Endpoint' -and $covered) {
            Write-Host '        NOTE: confirm target devices are ONBOARDED and reporting in the Purview portal (verify your licensing/tenant).' -ForegroundColor Yellow
        }
    }

    # Gate 3 — rule references the expected sensitive information types
    $rules = Get-DlpComplianceRule -Policy $name -ErrorAction SilentlyContinue
    if (-not $rules) {
        Write-Gate $false 'At least one content rule exists on the policy'
    } else {
        $ruleText = ($rules | ForEach-Object { $_ | Out-String }) -join "`n"
        foreach ($sit in $ExpectedSITs) {
            Write-Gate ($ruleText -match [regex]::Escape($sit)) ("Rule references SIT '{0}'" -f $sit)
        }
    }
}

Write-Host ''
if ($overall) {
    Write-Host 'OVERALL: PASS — all gates green.' -ForegroundColor Green
    if (-not $ExpectEnforce) { Write-Host 'Safe to proceed to the enforce decision (a FERPA/registrar change-control action).' -ForegroundColor Green }
} else {
    Write-Host 'OVERALL: FAIL — one or more gates red. Fix in simulation and re-run before enforcing.' -ForegroundColor Red
    exit 1
}
