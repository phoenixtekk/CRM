<#
.SYNOPSIS
    GWREG-Discovery.ps1 — controlled-data posture discovery for regulated Google Workspace (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline of the controlled-data posture BEFORE any change. Enumerates organizational
        units (the controlled-data scope), reports data-region residency where readable, samples Drive
        for external/broad sharing on controlled OUs, and prints where each compliance control lives in
        the Admin console (Access Management, Access Approvals, Data regions, Client-side encryption) so
        the operator can confirm state. Interpretation of what posture is REQUIRED is deferred to
        legal/compliance — this only reports what IS.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWREG-Discovery.ps1 -CustomerId your-customer-id [-MaxFiles 300]
        Requires a Google super-admin OAuth access token with READ-ONLY scopes:
        admin.directory.orgunit.readonly, admin.directory.group.readonly, drive.metadata.readonly.
        Put the token in the GOOGLE_OAUTH_TOKEN environment variable (e.g. 'gcloud auth print-access-token').
        Nothing is written.
    EXPECTED RESULTS
        A list of OUs, a broad/external Drive-sharing sample, and an Admin-console control-location map
        with a "verify in your tenant" note for add-on-gated features. Nothing changes. Feed OUs into
        GWREG-Set-ScopeTargeting.ps1 and controls into GWREG-Validation.ps1 / GWREG-Report.ps1.
.NOTES
    White-label — the repeatable way. Read-only against the Google Directory & Drive APIs. Assured
    Controls / Access Management state and policy options are add-on-/edition-dependent and are cited or
    flagged "verify in your tenant"; regulatory interpretation is deferred to legal/compliance.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CustomerId,
    [int]$MaxFiles = 300
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }

function Invoke-GApi([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop }
    catch { Write-Host ("  API error: {0}" -f $_.Exception.Message) -ForegroundColor Red; $null }
}

Write-Host "`n=== Regulated Google Workspace — controlled-data posture discovery ===" -ForegroundColor Cyan
Write-Host "Read-only. Reports current posture only; REQUIRED posture is a legal/compliance decision.`n"

# --- Organizational units (the controlled-data scope) ---
Write-Host "=== Organizational units (controlled-data scope) ===" -ForegroundColor Cyan
$ous = Invoke-GApi ("https://admin.googleapis.com/admin/directory/v1/customer/{0}/orgunits?type=all" -f [uri]::EscapeDataString($CustomerId))
if ($ous -and $ous.organizationUnits) {
    foreach ($ou in $ous.organizationUnits) {
        Write-Host ("  OU: {0}   (path {1})" -f $ou.name, $ou.orgUnitPath)
    }
    Write-Host ("  OUs found: {0}" -f $ous.organizationUnits.Count)
    Write-Host "  Map controlled data to a dedicated OU (e.g. 'Regulated Workspace - Controlled Data - Pilot')." -ForegroundColor Yellow
} else {
    Write-Host "  No OUs enumerated (or insufficient scope)." -ForegroundColor DarkGray
}

# --- Broad / external Drive sharing on controlled data (sample) ---
Write-Host "`n=== Drive sample: broad / external sharing (controlled-data exposure) ===" -ForegroundColor Cyan
$flagged = 0; $scanned = 0; $pageToken = $null
do {
    $q   = [uri]::EscapeDataString("visibility='anyoneWithLink' or visibility='anyoneCanFind' or visibility='domainWithLink' or visibility='domainCanFind'")
    $uri = "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=nextPageToken,files(id,name,webViewLink,permissions(type,role,domain))&q=$q"
    if ($pageToken) { $uri += "&pageToken=$pageToken" }
    $resp = Invoke-GApi $uri
    if (-not $resp) { break }
    foreach ($f in $resp.files) {
        $scanned++
        $broad = @()
        foreach ($p in $f.permissions) {
            if ($p.type -eq 'anyone') { $broad += 'PUBLIC (anyone with link)' }
            elseif ($p.type -eq 'domain') { $broad += "DOMAIN-WIDE ($($p.domain))" }
        }
        if ($broad.Count) {
            $flagged++
            Write-Host ("  FLAG  {0}  [{1}]  {2}" -f $f.name, ($broad -join ', '), $f.webViewLink) -ForegroundColor Yellow
        }
        if ($scanned -ge $MaxFiles) { break }
    }
    $pageToken = $resp.nextPageToken
} while ($pageToken -and $scanned -lt $MaxFiles)
if ($flagged -eq 0) { Write-Host "  No public/domain-wide items in the sampled scope." -ForegroundColor Green }
Write-Host ("  Sampled: {0}  Flagged broad: {1}" -f $scanned, $flagged)

# --- Admin-console control-location map (confirm state here) ---
Write-Host "`n=== Compliance control locations (confirm current state in Admin console) ===" -ForegroundColor Cyan
Write-Host "  Data regions (residency):     Menu > Data > Compliance > Data regions ( + Advanced settings )" -ForegroundColor Yellow
Write-Host "  Access Management:            Menu > Data > Compliance > Access Management (super-admin; Assured Controls Plus)" -ForegroundColor Yellow
Write-Host "  Access Approvals:             Menu > Data > Compliance > Access Approvals" -ForegroundColor Yellow
Write-Host "  Access Transparency (logs):   Reporting > 'Access Transparency log events'" -ForegroundColor Yellow
Write-Host "  Client-side encryption (CSE): Menu > Data > Compliance > Client-side encryption (only if legal relies on the ITAR e2ee carve-out)" -ForegroundColor Yellow
Write-Host "  Add-on/edition gating and policy options VARY - verify in your tenant. Do not assume." -ForegroundColor DarkYellow

Write-Host "`nNext: confirm REQUIRED posture with legal/compliance, then run GWREG-Validation.ps1 and GWREG-Report.ps1." -ForegroundColor Yellow
