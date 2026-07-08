<#
.SYNOPSIS
    AUDSIEM-Report.ps1 — Audit-to-SIEM pipeline health scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Produces the 'Audit Pipeline - Coverage - Report': a read-only scorecard of the export pipeline's
        health across concrete gates — unified audit ingestion on (source), each Management Activity API
        content subscription enabled, recent blob delivery per content type, webhook attached where expected,
        and the app certificate's expiry. Makes NO changes. Schedule it (with AUDSIEM-Discovery/Reconcile) so
        drift — a stopped subscription, an expired webhook, a lapsing certificate, a dark content type —
        surfaces as an alert rather than a missed detection.
    HOW TO RUN
        powershell -File .\AUDSIEM-Report.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb>
        # Skip the Exchange Online source check (subscriptions/cert only):
        .\AUDSIEM-Report.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb> -SkipExchange
        Requires the Entra app with ActivityFeed.Read (ActivityFeed.ReadDlp for DLP), admin-consented, the
        certificate on this host, and (for the source gate) ExchangeOnlineManagement. PowerShell 5.1+/7+.
    EXPECTED RESULTS
        A PASS/FAIL/WARN line per gate and an overall verdict. All PASS = the pipeline is healthy for the
        checked content types. Any FAIL/WARN (subscription disabled, no recent blobs, cert near expiry) is a
        pipeline-health finding to remediate under change control.
.NOTES
    Purview category — Audit → SIEM integration. Read-only; no writes; NO secrets in code. Resource is
    https://manage.office.com. Pipeline health is a first-class alert — a dark feed blinds the SOC. Webhook
    subscriptions expire and must be renewed. Verify licensing/tenant for API bandwidth/availability.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TenantId,
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)][string]$CertificateThumbprint,
    [string[]]$ExpectedContentTypes = @('Audit.AzureActiveDirectory','Audit.Exchange','Audit.SharePoint','Audit.General'),
    [int]$RecentBlobHours = 2,
    [int]$CertWarnDays = 30,
    [switch]$SkipExchange
)

$ErrorActionPreference = 'Stop'
$resource = 'https://manage.office.com'
$base = "$resource/api/v1.0/$TenantId/activity/feed"
$results = New-Object System.Collections.Generic.List[object]
function Gate($name,$status,$detail){ $results.Add([pscustomobject]@{ Gate=$name; Status=$status; Detail=$detail }) }

function Get-CertObj {
    $c = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $c) { $c = Get-Item "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue }
    $c
}
function Get-AudSiemToken {
    param([string]$TenantId,[string]$AppId,[string]$CertificateThumbprint,[string]$Resource='https://manage.office.com')
    $cert = Get-CertObj
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

Write-Host "=== AUDSIEM Report — audit-to-SIEM pipeline scorecard (read-only) ===" -ForegroundColor Cyan

# --- Gate: source ingestion on ---
if (-not $SkipExchange) {
    try {
        if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) { Import-Module ExchangeOnlineManagement -ErrorAction Stop }
        if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
        $on = [bool](Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
        Gate 'Source: unified audit ingestion' $(if($on){'PASS'}else{'FAIL'}) $(if($on){'Enabled'}else{'DISABLED — nothing to export (enable audit first)'})
    } catch { Gate 'Source: unified audit ingestion' 'WARN' ("Could not verify: {0}" -f $_.Exception.Message) }
} else { Gate 'Source: unified audit ingestion' 'SKIP' 'Skipped (-SkipExchange)' }

# --- Gate: certificate expiry ---
$certObj = Get-CertObj
if ($certObj) {
    $days = [math]::Round(($certObj.NotAfter - (Get-Date)).TotalDays)
    if ($days -lt 0)        { Gate 'App certificate' 'FAIL' ("EXPIRED on {0}" -f $certObj.NotAfter.ToString('yyyy-MM-dd')) }
    elseif ($days -le $CertWarnDays) { Gate 'App certificate' 'WARN' ("Expires in {0} day(s) ({1}) — rotate soon" -f $days, $certObj.NotAfter.ToString('yyyy-MM-dd')) }
    else                    { Gate 'App certificate' 'PASS' ("Valid — {0} day(s) remaining" -f $days) }
} else { Gate 'App certificate' 'FAIL' 'Certificate not found on this host (private key required)' }

# --- Gate: subscriptions + recent blob delivery per content type ---
try {
    $token = Get-AudSiemToken -TenantId $TenantId -AppId $AppId -CertificateThumbprint $CertificateThumbprint -Resource $resource
    $headers = @{ Authorization = "Bearer $token" }
    $subs = Invoke-RestMethod -Method GET -Uri "$base/subscriptions/list" -Headers $headers
    $subMap = @{}; foreach ($s in @($subs)) { $subMap[$s.contentType] = $s }

    $end = [DateTime]::UtcNow; $start = $end.AddHours(-$RecentBlobHours); $fmt='yyyy-MM-ddTHH:mm:ss'
    foreach ($ct in $ExpectedContentTypes) {
        $s = $subMap[$ct]
        if (-not $s -or $s.status -ne 'enabled') {
            Gate ("Subscription: $ct") 'FAIL' 'Not enabled (coverage gap)'
            continue
        }
        $hasHook = [bool]$s.webhook
        # recent blob delivery
        try {
            $c = Invoke-RestMethod -Method GET -Uri "$base/subscriptions/content?contentType=$ct&startTime=$($start.ToString($fmt))&endTime=$($end.ToString($fmt))" -Headers $headers
            $n = @($c).Count
            $hookTxt = if ($hasHook) { 'webhook attached' } else { 'poll (no webhook)' }
            if ($n -gt 0) { Gate ("Subscription: $ct") 'PASS' ("enabled, {0}, {1} blob(s) in last {2}h" -f $hookTxt,$n,$RecentBlobHours) }
            else          { Gate ("Subscription: $ct") 'WARN' ("enabled, {0}, but NO blobs in last {1}h (low activity or delivery issue)" -f $hookTxt,$RecentBlobHours) }
        } catch { Gate ("Subscription: $ct") 'WARN' ("enabled but content list failed: {0}" -f $_.Exception.Message) }
    }
} catch {
    Gate 'Management API auth' 'FAIL' ("Auth/list failed: {0}" -f $_.Exception.Message)
}

# --- Scorecard ---
Write-Host "`n=== Pipeline scorecard ===" -ForegroundColor Cyan
foreach ($r in $results) {
    $color = switch ($r.Status) { 'PASS'{'Green'} 'WARN'{'Yellow'} 'FAIL'{'Red'} default{'DarkGray'} }
    Write-Host ("  [{0,-4}] {1,-34} {2}" -f $r.Status, $r.Gate, $r.Detail) -ForegroundColor $color
}
$fail = @($results | Where-Object Status -eq 'FAIL').Count
$warn = @($results | Where-Object Status -eq 'WARN').Count
$verdict = if ($fail -gt 0) { 'ATTENTION — pipeline gaps present' } elseif ($warn -gt 0) { 'REVIEW — warnings to check' } else { 'HEALTHY — all checked gates pass' }
Write-Host ("`nOverall: {0}  ({1} fail, {2} warn)" -f $verdict,$fail,$warn) -ForegroundColor $(if($fail){'Red'}elseif($warn){'Yellow'}else{'Green'})
Write-Host "Read-only report complete. No changes made. Schedule this with AUDSIEM-Reconcile.ps1 to catch silent loss." -ForegroundColor Cyan
