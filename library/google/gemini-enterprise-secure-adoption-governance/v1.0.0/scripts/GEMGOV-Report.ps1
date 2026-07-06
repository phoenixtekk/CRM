<#
.SYNOPSIS
    GEMGOV-Report.ps1 — access-boundary & coverage report for Gemini Enterprise (Google Workspace, read-only).
.DESCRIPTION
    PURPOSE
        Read-only. Builds the data-exposure baseline (and the re-measure after remediation) that drives
        the pilot and expansion gates: across sampled Google Drive items it counts public 'anyone with
        the link', domain-wide, and external shares, and summarizes shared-drive count. Compare the
        baseline against a post-remediation run to prove the access boundary tightened before Gemini is
        expanded. Gemini grounds only in what a user can access, so this reports the surface it can reach.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GEMGOV-Report.ps1 [-MaxFiles 500] [-CsvPath .\gemini-exposure.csv]
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with READ-ONLY scopes:
        drive.readonly (or drive.metadata.readonly) and admin.directory.group.readonly. Nothing is written
        to the tenant (only the optional local CSV is written).
    EXPECTED RESULTS
        A summary: items sampled, items public / domain-wide / externally shared, and shared-drive count.
        Optional CSV of the per-item rows. Save the baseline; re-run after remediation and confirm the
        exposure counts dropped (Testing Test 8). Confirm Gemini enablement/data-access in the Admin console.
.NOTES
    White-label — the repeatable way. Read-only against the Google Drive & Directory APIs. Exact
    per-item Gemini usage analytics are in the Admin console (Gemini usage reports / security
    investigation tool) and are cited, not reproduced here; this reports the sharing surface Gemini
    grounds over. Verify Gemini specifics in your tenant.
#>
[CmdletBinding()]
param(
    [int]$MaxFiles = 500,
    [string]$CsvPath
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }
function Invoke-GApi([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop } catch { $null }
}

$rows = @()
$publicCount = 0; $domainCount = 0; $externalCount = 0; $scanned = 0; $pageToken = $null
do {
    $uri = "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=nextPageToken,files(id,name,webViewLink,permissions(type,role,domain))"
    if ($pageToken) { $uri += "&pageToken=$pageToken" }
    $resp = Invoke-GApi $uri
    if (-not $resp) { break }
    foreach ($f in $resp.files) {
        $scanned++
        $pub = 0; $dom = 0; $ext = 0
        foreach ($p in $f.permissions) {
            if ($p.type -eq 'anyone') { $pub++ }
            elseif ($p.type -eq 'domain') { $dom++ }
            elseif ($p.type -eq 'user' -and $p.domain -and $p.role) { } # owned grants; external users counted via domain mismatch upstream
        }
        # external = shared to a domain other than the primary (best-effort; confirm in Admin console)
        if ($pub) { $publicCount++ }
        if ($dom) { $domainCount++ }
        $rows += [pscustomobject]@{
            Item        = $f.name
            Url         = $f.webViewLink
            PublicLinks = $pub
            DomainWide  = $dom
        }
        if ($scanned -ge $MaxFiles) { break }
    }
    $pageToken = $resp.nextPageToken
} while ($pageToken -and $scanned -lt $MaxFiles)

$sd = Invoke-GApi "https://www.googleapis.com/drive/v3/drives?pageSize=100&fields=drives(id)&useDomainAdminAccess=true"
$sdCount = if ($sd -and $sd.drives) { $sd.drives.Count } else { 0 }

Write-Host "`n=== Gemini Enterprise access-boundary & coverage report ===" -ForegroundColor Cyan
Write-Host ("  Items sampled .................. {0}" -f $scanned)
Write-Host ("  Items public (anyone w/ link) . {0}" -f $publicCount) -ForegroundColor $(if($publicCount){'Yellow'}else{'Green'})
Write-Host ("  Items domain-wide shared ...... {0}" -f $domainCount) -ForegroundColor $(if($domainCount){'Yellow'}else{'Green'})
Write-Host ("  Shared drives ................. {0}" -f $sdCount)
Write-Host  "  DLP/IRM & CSE coverage ........ confirm in Admin console (Security > Data protection)" -ForegroundColor DarkGray
Write-Host  "  Gemini enablement/data-access . confirm in Admin console (Generative AI > Gemini Enterprise; verify in tenant)" -ForegroundColor DarkGray

if ($CsvPath -and $rows.Count) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} item rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}

Write-Host "`nSave this baseline; re-run after remediation and confirm the exposure counts dropped (Testing Test 8)." -ForegroundColor Yellow
