<#
.SYNOPSIS
    DLPITAR-Validation.ps1 — read-only pass/fail validation of the ITAR technical-data DLP policy before enforce (safe: read-only).
.DESCRIPTION
    PURPOSE
        Checks the ITAR technical-data egress DLP policy against the Step-5 pass/fail gates and prints one
        PASS/FAIL line per gate:
          * the policy "ITAR Technical-Data Egress - AllWorkloads - Pilot" exists and is in the EXPECTED
            mode (SIMULATION during pilot; Enable only when -ExpectEnforce is passed post-promotion),
          * it is scoped to the intended workloads (Exchange / SharePoint / OneDrive / Teams; Endpoint where
            designed),
          * the detection rule "Technical-Data Egress Rule - Markings+Label - v1" is present and references
            the technical-data classification (the custom SIT and/or the "Export Controlled // ITAR" label)
            with an external-recipient / external-share scope.
        Read-only — it queries Get-DlpCompliancePolicy / Get-DlpComplianceRule and changes nothing. Run it
        immediately before promoting to enforce, and again afterwards with -ExpectEnforce to confirm the
        enforced state.
    HOW TO RUN
        Validate the pilot (expects SIMULATION):
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Validation.ps1
        Validate after promotion (expects Enable):
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Validation.ps1 -ExpectEnforce
        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession); a Compliance/DLP read role. No credentials in code.
    EXPECTED RESULTS
        Every gate PASS during pilot (policy in simulation, correctly scoped, rule references the
        classification) = gates green, safe to seek enforce approval. Any FAIL = fix in test mode and
        re-validate before enforcing. Exit code 1 on any FAIL.
.NOTES
    White-label. Read-only against Security & Compliance PowerShell. No credentials in code.
    Verify capability/paths against your licensing/tenant. ITAR/export/legal determinations deferred to the owners.
#>
[CmdletBinding()]
param(
    [string] $PolicyName = 'ITAR Technical-Data Egress - AllWorkloads - Pilot',
    [string] $RuleName   = 'Technical-Data Egress Rule - Markings+Label - v1',
    [string] $SitName    = 'Technical Data SIT - Export Markings - Custom',
    [string] $LabelName  = 'Export Controlled // ITAR',
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Endpoint')]
    [string[]] $ExpectedLocations = @('Exchange','SharePoint','OneDrive','Teams'),
    [switch] $ExpectEnforce,
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
}

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

Write-Host '=== ITAR DLP Validation (read-only) ===' -ForegroundColor Cyan
Write-Host ("Policy : {0}" -f $PolicyName)

$p = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $p) {
    Write-Gate $false ("Policy '{0}' not found (check name / role / connection)." -f $PolicyName)
    Write-Host 'OVERALL: FAIL' -ForegroundColor Red
    exit 1
}

# Gate 1 — mode
if ($ExpectEnforce) {
    Write-Gate ($p.Mode -eq 'Enable') ("Mode is Enable (enforcing) as expected — actual: {0}" -f $p.Mode)
} else {
    Write-Gate ($p.Mode -like 'Test*') ("Mode is SIMULATION (Test*) — actual: {0}" -f $p.Mode)
}

# Gate 2 — workload scope
foreach ($loc in $ExpectedLocations) {
    $val = $p.($locProp[$loc])
    $covered = ($val -and $val.Count -gt 0)
    Write-Gate $covered ("Workload '{0}' is in scope" -f $loc)
    if ($loc -eq 'Endpoint' -and $covered) {
        Write-Host '        NOTE: confirm devices are ONBOARDED and reporting in the portal (verify your licensing/tenant).' -ForegroundColor Yellow
    }
}

# Gate 3 — detection rule present and references the technical-data classification + external scope
$rule = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue
if (-not $rule) {
    Write-Gate $false ("Detection rule '{0}' exists on the policy" -f $RuleName)
} else {
    Write-Gate $true ("Detection rule '{0}' exists" -f $RuleName)
    $ruleText = ($rule | Out-String)
    # Either the SIT or the sensitivity label is an acceptable technical-data signal (label is preferred).
    $hasSit   = $ruleText -match [regex]::Escape($SitName)
    $hasLabel = $ruleText -match [regex]::Escape($LabelName)
    Write-Gate ($hasSit -or $hasLabel) ("Rule references the technical-data classification (SIT '{0}' and/or label '{1}')" -f $SitName, $LabelName)
    # External-recipient / external-share scope is the ITAR-relevant egress condition.
    $externalScope = ($rule.AccessScope -eq 'NotInOrganization') -or ($ruleText -match 'NotInOrganization|outside the organization|external')
    Write-Gate $externalScope 'Rule scope targets egress OUTSIDE the organization (external recipient/share)'
    if ($ExpectEnforce) {
        Write-Gate ($ruleText -match 'BlockAccess|Block') 'Enforced rule carries a Block / restrict action'
    }
}

Write-Host ''
if ($overall) {
    Write-Host 'OVERALL: PASS — all gates green.' -ForegroundColor Green
    if (-not $ExpectEnforce) {
        Write-Host 'Gates green + signed-off simulation results = seek export/legal + change approval, then promote:' -ForegroundColor Green
        Write-Host '  DLPITAR-Set-Policy.ps1 -PromoteToEnforce -Commit'
    }
} else {
    Write-Host 'OVERALL: FAIL — one or more gates red. Fix in test mode and re-validate before enforcing.' -ForegroundColor Red
    exit 1
}
