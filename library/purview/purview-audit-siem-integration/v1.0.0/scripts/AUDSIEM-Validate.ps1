<#
.SYNOPSIS
    AUDSIEM-Validate.ps1 — List available Management Activity API content blobs and counts for a window (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the Office 365 Management Activity API is publishing content the SIEM should be collecting:
        enumerates the available content blobs for a content type over a time window and (optionally) counts
        the records inside them. Read-only — makes NO changes. Use it after starting a subscription to prove
        the API side is delivering, then check the SIEM ingested the same events (end-to-end).
    HOW TO RUN
        # List blobs published for the last hour for the Entra feed:
        powershell -File .\AUDSIEM-Validate.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb> `
            -ContentType Audit.AzureActiveDirectory -Hours 1
        # Include a record count (downloads each blob — heavier):
        .\AUDSIEM-Validate.ps1 ... -ContentType Audit.Exchange -Hours 6 -CountRecords
        Requires the Entra app with ActivityFeed.Read (ActivityFeed.ReadDlp for DLP), admin-consented, and the
        certificate on this host. PowerShell 5.1+/7+.
    EXPECTED RESULTS
        Prints the number of content blobs available for the window (and, with -CountRecords, the total audit
        records). Non-zero after allowing for feed latency = the API is publishing. Zero after latency = check
        that the activity generated audit records and that the content type is actually subscribed.
.NOTES
    Purview category — Audit → SIEM integration. Read-only; no writes; NO secrets in code. Resource is
    https://manage.office.com. The feed is near-real-time (minutes) — the newest minutes may not yet be
    published. Content blobs are available for a limited window; a down collector loses un-collected blobs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TenantId,
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)][string]$CertificateThumbprint,
    [Parameter(Mandatory)]
    [ValidateSet('Audit.AzureActiveDirectory','Audit.Exchange','Audit.SharePoint','Audit.General','DLP.All')]
    [string]$ContentType,
    [ValidateRange(1,168)][int]$Hours = 1,
    [switch]$CountRecords
)

$ErrorActionPreference = 'Stop'
$resource = 'https://manage.office.com'
$base = "$resource/api/v1.0/$TenantId/activity/feed"

function Get-AudSiemToken {
    param([string]$TenantId,[string]$AppId,[string]$CertificateThumbprint,[string]$Resource='https://manage.office.com')
    $cert = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $cert) { $cert = Get-Item "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue }
    if (-not $cert) { throw "Certificate $CertificateThumbprint not found in CurrentUser/LocalMachine My store (private key required)." }
    function B64Url([byte[]]$b){ [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $header  = @{ alg='RS256'; typ='JWT'; x5t=(B64Url ($cert.GetCertHash())) } | ConvertTo-Json -Compress
    $payload = @{ aud=$tokenUri; iss=$AppId; sub=$AppId; jti=[guid]::NewGuid().ToString(); nbf=$now; exp=($now+600) } | ConvertTo-Json -Compress
    $unsigned = (B64Url ([Text.Encoding]::UTF8.GetBytes($header))) + '.' + (B64Url ([Text.Encoding]::UTF8.GetBytes($payload)))
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
    $sig = $rsa.SignData([Text.Encoding]::UTF8.GetBytes($unsigned), [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $body = @{ client_id=$AppId; scope="$Resource/.default"; grant_type='client_credentials'
        client_assertion_type='urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion=($unsigned + '.' + (B64Url $sig)) }
    (Invoke-RestMethod -Method POST -Uri $tokenUri -Body $body -ContentType 'application/x-www-form-urlencoded').access_token
}

$token = Get-AudSiemToken -TenantId $TenantId -AppId $AppId -CertificateThumbprint $CertificateThumbprint -Resource $resource
$headers = @{ Authorization = "Bearer $token" }

$end = [DateTime]::UtcNow
$start = $end.AddHours(-$Hours)
$fmt = 'yyyy-MM-ddTHH:mm:ss'
$uri = "$base/subscriptions/content?contentType=$ContentType&startTime=$($start.ToString($fmt))&endTime=$($end.ToString($fmt))"

Write-Host ("=== AUDSIEM Validate — {0}, last {1}h (UTC {2} .. {3}) ===" -f $ContentType,$Hours,$start.ToString($fmt),$end.ToString($fmt)) -ForegroundColor Cyan

# Page through the content list (Management API paginates via NextPageUri response header).
$blobs = New-Object System.Collections.Generic.List[object]
$next = $uri
$pages = 0
while ($next) {
    $resp = Invoke-WebRequest -Method GET -Uri $next -Headers $headers -UseBasicParsing
    $page = $resp.Content | ConvertFrom-Json
    foreach ($b in @($page)) { $blobs.Add($b) }
    $pages++
    $next = $resp.Headers['NextPageUri']
    if ($next -is [array]) { $next = $next[0] }
}
Write-Host ("Content blobs available: {0} (across {1} page(s))" -f $blobs.Count, $pages) -ForegroundColor $(if($blobs.Count -gt 0){'Green'}else{'Yellow'})

if ($blobs.Count -eq 0) {
    Write-Host "No blobs for the window. Allow for feed latency (minutes); confirm the activity generated audit records and the content type is subscribed." -ForegroundColor Yellow
    return
}

if ($CountRecords) {
    $total = 0
    foreach ($b in $blobs) {
        try {
            $records = Invoke-RestMethod -Method GET -Uri $b.contentUri -Headers $headers
            $total += @($records).Count
        } catch {
            Write-Host ("  Could not read blob {0}: {1}" -f $b.contentId, $_.Exception.Message) -ForegroundColor DarkYellow
        }
    }
    Write-Host ("Total audit records in window: {0}" -f $total) -ForegroundColor Green
    Write-Host "Compare this against your SIEM's ingested count for the same window (use AUDSIEM-Reconcile.ps1 for the source-of-truth comparison)." -ForegroundColor Cyan
} else {
    Write-Host "Re-run with -CountRecords to total the records inside the blobs (heavier). Then confirm the SIEM ingested them." -ForegroundColor Cyan
}
Write-Host "Read-only validation complete. No changes made." -ForegroundColor Cyan
