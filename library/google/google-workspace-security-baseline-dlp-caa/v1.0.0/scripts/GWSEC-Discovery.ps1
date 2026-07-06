<#
.SYNOPSIS
    GWSEC-Discovery.ps1 — read-only Google Workspace security-posture discovery (baseline, DLP, CAA signals).
.DESCRIPTION
    PURPOSE
        Read-only assessment of the current Google Workspace security posture BEFORE any change:
        two-step verification (2SV) enrollment across users, Drive external-sharing exposure
        (public 'anyone with link' / domain-wide / external), the count of super-admins, and whether
        DLP rules / Context-Aware Access levels already exist. The output is your rollback baseline
        and the list of risky defaults to fix. Nothing is changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWSEC-Discovery.ps1 [-MaxUsers 500] [-MaxFiles 500]
        Requires a Google super-admin OAuth access token in the GOOGLE_OAUTH_TOKEN environment
        variable (obtain via 'gcloud auth print-access-token' or your OAuth flow) with READ-ONLY
        scopes: admin.directory.user.readonly, admin.directory.rolemanagement.readonly, and
        drive.metadata.readonly. DLP-rule and Context-Aware Access inventory that is not exposed by
        API is confirmed in the Admin console (Security > Access and data control) — the script prints
        where to look.
    EXPECTED RESULTS
        A posture summary: users without 2SV, Drive items shared public/domain-wide/externally,
        super-admin count, and a DLP/CAA presence note. PASS = 2SV broadly enrolled, no broad sharing,
        minimal super-admins. FAIL signals feed GWSEC-Remediation.ps1, GWSEC-Validation.ps1, and
        GWSEC-Report.ps1. Edition-gated (DLP-rule/CAA) state is verified in your tenant.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems (Admin Directory & Drive
    metadata APIs). DLP-for-Drive/Gmail rule authoring and Context-Aware Access are edition-gated
    (Enterprise/Education tiers); their presence is confirmed in the Admin console.
#>
[CmdletBinding()]
param(
    [int]$MaxUsers = 500,
    [int]$MaxFiles = 500
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

Write-Host "`n=== Google Workspace security-posture discovery (read-only) ===" -ForegroundColor Cyan
Write-Host "Captures your starting posture (2SV, sharing, admins, DLP/CAA presence) = your rollback baseline.`n"

# --- 2SV enrollment across users ---
Write-Host "=== 2-Step Verification enrollment ===" -ForegroundColor Cyan
$usersScanned = 0; $no2sv = 0; $admins = 0; $pageToken = $null
do {
    $uri = "https://admin.googleapis.com/admin/directory/v1/users?customer=my_customer&maxResults=100&fields=nextPageToken,users(primaryEmail,isEnrolledIn2Sv,isAdmin,isDelegatedAdmin)"
    if ($pageToken) { $uri += "&pageToken=$pageToken" }
    $resp = Invoke-GApi $uri
    if (-not $resp) { break }
    foreach ($u in $resp.users) {
        $usersScanned++
        if ($u.isAdmin) { $admins++ }
        if (-not $u.isEnrolledIn2Sv) {
            $no2sv++
            Write-Host ("  NO 2SV  {0}{1}" -f $u.primaryEmail, ($(if ($u.isAdmin) { '  [SUPER-ADMIN]' } else { '' }))) -ForegroundColor Yellow
        }
        if ($usersScanned -ge $MaxUsers) { break }
    }
    $pageToken = $resp.nextPageToken
} while ($pageToken -and $usersScanned -lt $MaxUsers)
if ($no2sv -eq 0 -and $usersScanned -gt 0) { Write-Host "  All sampled users are enrolled in 2SV." -ForegroundColor Green }
Write-Host ("  Users scanned: {0}  Not enrolled in 2SV: {1}  Super-admins: {2}" -f $usersScanned, $no2sv, $admins)
if ($admins -gt 4) { Write-Host ("  NOTE: {0} super-admins — minimize this count." -f $admins) -ForegroundColor Yellow }

# --- Drive external / broad sharing exposure ---
Write-Host "`n=== Drive external / broad sharing exposure ===" -ForegroundColor Cyan
$flagged = 0; $scanned = 0; $pageToken = $null
do {
    $q = [uri]::EscapeDataString("visibility='anyoneWithLink' or visibility='anyoneCanFind' or visibility='domainWithLink' or visibility='domainCanFind'")
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
if ($flagged -eq 0) { Write-Host "  No public/domain-wide Drive items detected in the sampled scope." -ForegroundColor Green }
Write-Host ("  Items scanned: {0}  Flagged broad/external: {1}" -f $scanned, $flagged)

# --- DLP / CAA presence (edition-gated; confirm in Admin console) ---
Write-Host "`n=== DLP & Context-Aware Access presence (edition-gated) ===" -ForegroundColor Cyan
Write-Host "  Confirm in the Admin console (these are edition-gated — verify in your tenant):" -ForegroundColor Yellow
Write-Host "    Security > Access and data control > Data protection  (DLP rules for Drive/Gmail)" -ForegroundColor Yellow
Write-Host "    Security > Access and data control > Context-Aware Access  (access levels + assignments)" -ForegroundColor Yellow
Write-Host "    Security > Access and data control > Google session control  (web session duration)" -ForegroundColor Yellow

Write-Host "`nNext: record these values as rollback targets, then run GWSEC-Remediation.ps1 (-WhatIf), GWSEC-Validation.ps1, GWSEC-Report.ps1." -ForegroundColor Yellow
