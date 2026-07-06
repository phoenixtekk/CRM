<#
.SYNOPSIS
    GWSEC-Report.ps1 — read-only fleet posture coverage / exceptions report across organizational units.
.DESCRIPTION
    PURPOSE
        Read-only reporting of Google Workspace security-posture coverage across all organizational
        units: per-OU 2SV enrollment coverage and broad-Drive-sharing exposure, plus a checklist of
        the edition-gated DLP and Context-Aware Access surfaces to confirm in the Admin console. Use
        it to see what is applied, what is missing, and which OUs are tracked exceptions as you expand
        the posture fleet-wide. Optionally writes a CSV.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWSEC-Report.ps1 [-CsvPath .\gwsec-coverage.csv]
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with READ-ONLY scopes:
        admin.directory.user.readonly, admin.directory.orgunit.readonly, drive.metadata.readonly.
    EXPECTED RESULTS
        A coverage table (one row per OU: users, 2SV-enrolled, 2SV coverage %) and a fleet broad-sharing
        count, with a note listing the DLP/CAA/session surfaces to confirm per OU. PASS = high 2SV
        coverage and no untracked broad sharing across OUs. Rows below target are the exceptions to
        track and remediate.
.NOTES
    White-label — the repeatable way. Read-only against the Admin Directory & Drive metadata APIs.
    DLP-for-Drive/Gmail and Context-Aware Access coverage is edition-gated and confirmed in the Admin
    console; this report frames coverage and points to where to verify the gated surfaces.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the read-only scopes in this header." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }

function Invoke-GApi([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop }
    catch { Write-Host ("  API error: {0}" -f $_.Exception.Message) -ForegroundColor Red; $null }
}

Write-Host "`n=== GWSEC fleet posture coverage report (read-only) ===" -ForegroundColor Cyan

# --- Enumerate OUs ---
$ouResp = Invoke-GApi "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/orgunits?type=all&fields=organizationUnits(orgUnitPath,name)"
$ouPaths = @('/')
if ($ouResp -and $ouResp.organizationUnits) { $ouPaths += ($ouResp.organizationUnits | ForEach-Object { $_.orgUnitPath }) }
$ouPaths = $ouPaths | Sort-Object -Unique

# --- Per-OU 2SV coverage ---
$rows = @()
foreach ($ou in $ouPaths) {
    $total = 0; $enrolled = 0; $pageToken = $null
    $q = [uri]::EscapeDataString("orgUnitPath='$ou'")
    do {
        $uri = "https://admin.googleapis.com/admin/directory/v1/users?customer=my_customer&maxResults=100&query=$q&fields=nextPageToken,users(isEnrolledIn2Sv)"
        if ($pageToken) { $uri += "&pageToken=$pageToken" }
        $resp = Invoke-GApi $uri
        if (-not $resp) { break }
        foreach ($u in $resp.users) { $total++; if ($u.isEnrolledIn2Sv) { $enrolled++ } }
        $pageToken = $resp.nextPageToken
    } while ($pageToken)
    $pct = if ($total) { [math]::Round(($enrolled / $total) * 100, 1) } else { 0 }
    $rows += [pscustomobject]@{ OrgUnit = $ou; Users = $total; Enrolled2SV = $enrolled; Coverage = "$pct%" }
}

Write-Host "`n--- 2SV coverage by OU ---" -ForegroundColor Cyan
$rows | Where-Object { $_.Users -gt 0 } | Format-Table -AutoSize

# --- Fleet broad-sharing exposure ---
$flagged = 0
$sq = [uri]::EscapeDataString("visibility='anyoneWithLink' or visibility='anyoneCanFind' or visibility='domainWithLink' or visibility='domainCanFind'")
$resp = Invoke-GApi "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=files(id,permissions(type))&q=$sq"
if ($resp) { foreach ($f in $resp.files) { if ($f.permissions | Where-Object { $_.type -in @('anyone','domain') }) { $flagged++ } } }
Write-Host ("--- Fleet broad Drive sharing (sampled): {0} item(s) ---" -f $flagged) -ForegroundColor $(if ($flagged) { 'Yellow' } else { 'Green' })

# --- Edition-gated coverage checklist ---
Write-Host "`n--- Edition-gated coverage to confirm per OU (verify in your tenant) ---" -ForegroundColor Cyan
Write-Host "  DLP     : 'DLP - Drive - Sensitive - External' + 'DLP - Gmail - Sensitive - Outbound' active at intended action." -ForegroundColor Yellow
Write-Host "  CAA     : 'Access - Corp Network' / 'Access - Managed Device' assigned (monitor->enforce) incl. Admin console for privileged OUs." -ForegroundColor Yellow
Write-Host "  Session : Google session control web-session duration set." -ForegroundColor Yellow

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nCoverage written to {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Red }
}

Write-Host "`nTrack any OU below target 2SV coverage or with untracked broad sharing as a named, owned exception." -ForegroundColor Yellow
