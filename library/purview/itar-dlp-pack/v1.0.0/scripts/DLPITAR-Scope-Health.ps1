<#
.SYNOPSIS
    DLPITAR-Scope-Health.ps1 — report DLP workload coverage, licensing-dependent surfaces, and any coverage gaps (read-only).
.DESCRIPTION
    PURPOSE
        Produces the "Workload Scope - ITAR DLP - Map": for each M365 egress channel (Exchange,
        SharePoint, OneDrive, Teams, and Endpoint devices) it reports whether an existing DLP policy
        already covers it, and flags the licensing-dependent surfaces (Endpoint DLP, Exact Data Match,
        trainable classifiers) that generally require Microsoft 365 E5 / E5 Compliance. It also checks
        whether an EDM schema exists (a hint that EDM is licensed/onboarded). Read-only: it changes
        nothing. Its job is to make coverage EXPLICIT and licensing-aware so an un-onboarded channel is
        recorded as a gap, never assumed protected.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPITAR-Scope-Health.ps1

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession) and read access to compliance policies.
        Endpoint device-onboarding status and precise licensing are confirmed in the portal / M365 admin
        center (Billing -> Licenses; Purview -> Settings -> Device onboarding) — this script reports what
        is readable via cmdlet and tells you what to confirm in-portal. For a sovereign cloud pass the
        matching -ConnectionUri. No credentials in code.
    EXPECTED RESULTS
        A per-channel coverage table (Covered / Not covered), a licensing-surface note, and an EDM-schema
        presence hint. PASS = the map prints, covered channels are listed, and any required-but-uncovered
        channel is flagged as a gap to license/onboard or de-scope explicitly.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell. No credentials in code.
    Endpoint onboarding + exact licensing are verified in the portal — availability is licensing-/tenant-dependent.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect: {0}" -f $_.Exception.Message)
    return
}

# --- Which egress channels are covered by an existing DLP policy ------------------------------------
Write-Section 'Workload Scope - ITAR DLP - Map (which egress channels are covered)'
$channels = @(
    [pscustomobject]@{ Channel = 'Exchange (email)';        Property = 'ExchangeLocation';   Licensing = 'Broadly available' },
    [pscustomobject]@{ Channel = 'SharePoint (sharing)';    Property = 'SharePointLocation'; Licensing = 'Broadly available' },
    [pscustomobject]@{ Channel = 'OneDrive (sharing)';      Property = 'OneDriveLocation';   Licensing = 'Broadly available' },
    [pscustomobject]@{ Channel = 'Teams (chat/channel)';    Property = 'TeamsLocation';      Licensing = 'Broadly available' },
    [pscustomobject]@{ Channel = 'Endpoint (USB/print/upload)'; Property = 'EndpointDlpLocation'; Licensing = 'Requires E5 / E5 Compliance + device onboarding' }
)

try {
    $policies = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    $map = foreach ($c in $channels) {
        $covered = $false
        foreach ($p in $policies) {
            $val = $p.PSObject.Properties[$c.Property]
            if ($val -and $val.Value -and (@($val.Value).Count -gt 0)) { $covered = $true; break }
        }
        [pscustomobject]@{
            Channel   = $c.Channel
            Covered   = if ($covered) { 'Covered' } else { 'NOT covered' }
            Licensing = $c.Licensing
        }
    }
    $map | Format-Table -AutoSize
    $gaps = $map | Where-Object { $_.Covered -eq 'NOT covered' }
    if ($gaps) {
        Write-Host 'Uncovered channels — decide per channel: license/onboard OR de-scope explicitly (do NOT assume protected):' -ForegroundColor Yellow
        $gaps | ForEach-Object { Write-Host ("  - {0}  [{1}]" -f $_.Channel, $_.Licensing) }
    } else {
        Write-Host 'All listed egress channels are touched by at least one DLP policy.' -ForegroundColor Green
        Write-Host 'Confirm the ITAR policy specifically covers them (DLPITAR-Validation.ps1).'
    }
}
catch { Write-Warning ("Could not read DLP policy locations: {0}" -f $_.Exception.Message) }

# --- Licensing-dependent surfaces (EDM presence hint) -----------------------------------------------
Write-Section 'Licensing-dependent surfaces'
Write-Host 'Endpoint DLP, Exact Data Match (EDM), and trainable classifiers generally require'
Write-Host 'Microsoft 365 E5 or the E5 Compliance add-on. Confirm in M365 admin center -> Billing ->'
Write-Host 'Licenses, and endpoint onboarding in Purview -> Settings -> Device onboarding (verify path).'

if (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue) {
    try {
        $edm = @(Get-DlpEdmSchema -ErrorAction Stop)
        if ($edm.Count -gt 0) { Write-Host ("EDM schema(s) present: {0} — EDM appears available for high-precision controlled-item matching." -f $edm.Count) -ForegroundColor Green }
        else { Write-Host 'No EDM schema found. EDM may be unlicensed or simply not configured yet.' }
    }
    catch { Write-Host 'Could not read EDM schemas (may be unlicensed/portal-only). Confirm EDM availability in your tenant.' }
} else {
    Write-Host 'Get-DlpEdmSchema not available in this session — confirm EDM availability in the portal.'
}

Write-Section 'Scope/health check complete'
Write-Host 'Record covered channels and any gaps in Workload Scope - ITAR DLP - Map. A mail-only policy'
Write-Host 'leaves SharePoint/Teams/USB open — a common ITAR egress gap. Endpoint onboarding + licensing'
Write-Host 'are confirmed in the portal; availability is licensing-/tenant-dependent.'
