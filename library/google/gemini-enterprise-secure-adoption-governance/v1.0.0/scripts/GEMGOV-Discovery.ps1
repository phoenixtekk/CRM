<#
.SYNOPSIS
    GEMGOV-Discovery.ps1 — AI-readiness / oversharing discovery for Gemini Enterprise (Google Workspace, read-only).
.DESCRIPTION
    PURPOSE
        Read-only assessment of the top Gemini Enterprise risk — oversharing. Enumerates Google Drive
        files and shared drives for broad sharing (public 'anyone with the link', domain-wide 'anyone in
        your organization') and external (outside-domain) sharing, and reports whether DLP/IRM signals
        exist, so you can see the data-exposure surface BEFORE enabling Gemini. Gemini grounds only in
        what the signed-in user can access, so broad access = broad exposure.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GEMGOV-Discovery.ps1 -CustomerId your-customer-id [-MaxFiles 500]
        Requires a Google Cloud OAuth access token for a Workspace super-admin (or delegated service
        account) with READ-ONLY scopes: drive.readonly (or drive.metadata.readonly) and
        admin.directory.group.readonly. Provide the token in the GOOGLE_OAUTH_TOKEN environment variable
        (obtain via 'gcloud auth print-access-token' or your OAuth flow). Nothing is written.
    EXPECTED RESULTS
        A list of Drive items flagged public / domain-wide / externally shared, a shared-drive breadth
        summary, and a DLP/IRM readiness note. Nothing is changed. Feed the flagged items into
        GEMGOV-Remediation.ps1 and GEMGOV-Report.ps1. Verify Gemini-specific admin state in your tenant.
.NOTES
    White-label — the repeatable way. Read-only against the Google Drive & Directory APIs. Gemini
    Enterprise admin toggles are evolving / partly preview and are cited or flagged "verify in your
    tenant"; this script reads the Drive sharing surface Gemini grounds over. DLP/IRM rule inventory is
    confirmed in the Admin console (Security > Data protection).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CustomerId,
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

Write-Host "`n=== Gemini Enterprise AI-readiness / oversharing discovery ===" -ForegroundColor Cyan
Write-Host "Read-only. Gemini grounds only in what a user can access — broad Drive sharing = broad Gemini exposure.`n"

# --- Broadly shared Drive files (domain-wide search as admin) ---
Write-Host "=== Drive items with broad / external sharing ===" -ForegroundColor Cyan
$flagged = 0; $scanned = 0; $pageToken = $null
do {
    $q = [System.Web.HttpUtility]::UrlEncode("visibility='anyoneWithLink' or visibility='anyoneCanFind' or visibility='domainWithLink' or visibility='domainCanFind'")
    $uri = "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=nextPageToken,files(id,name,webViewLink,permissions(type,role,domain,allowFileDiscovery))&q=$q"
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

if ($flagged -eq 0) {
    Write-Host "  No public/domain-wide Drive items detected in the sampled scope." -ForegroundColor Green
}
Write-Host ("  Items scanned: {0}  Flagged broad/external: {1}" -f $scanned, $flagged)

# --- Shared-drive breadth ---
Write-Host "`n=== Shared drives (membership breadth) ===" -ForegroundColor Cyan
$sd = Invoke-GApi "https://www.googleapis.com/drive/v3/drives?pageSize=100&fields=drives(id,name)&useDomainAdminAccess=true"
if ($sd -and $sd.drives) {
    foreach ($d in $sd.drives) {
        Write-Host ("  Shared drive: {0}  (id {1}) — review member breadth & external members" -f $d.name, $d.id)
    }
    Write-Host ("  Shared drives found: {0}" -f $sd.drives.Count)
} else {
    Write-Host "  No shared drives enumerated (or insufficient scope)." -ForegroundColor DarkGray
}

# --- DLP / IRM readiness note ---
Write-Host "`n=== DLP / IRM guardrail readiness ===" -ForegroundColor Cyan
Write-Host "  DLP rules and IRM protection are confirmed in the Admin console:" -ForegroundColor Yellow
Write-Host "    Security > Data protection (DLP rules; apply IRM = prevent download/print/copy)." -ForegroundColor Yellow
Write-Host "  Gemini does NOT retrieve IRM-protected or CSE-encrypted content. Verify coverage in your tenant."

Write-Host "`nNext: review flagged items, then run GEMGOV-Remediation.ps1 (-WhatIf) and GEMGOV-Report.ps1." -ForegroundColor Yellow
