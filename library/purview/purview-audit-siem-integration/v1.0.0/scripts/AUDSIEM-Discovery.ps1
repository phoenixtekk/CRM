<#
.SYNOPSIS
    AUDSIEM-Discovery.ps1 — Assess the Purview audit-to-SIEM export surface (read-only).
.DESCRIPTION
    PURPOSE
        Read-only assessment of the audit export pipeline: reports whether unified audit ingestion is on
        (the source precondition), which Office 365 Management Activity API content subscriptions exist and
        their status, and whether the app identity authenticates app-only with its certificate and carries
        ActivityFeed access. Makes NO changes. Prompts you to confirm any existing native SIEM connector so
        you don't stand up a duplicate feed.
    HOW TO RUN
        # Full surface (source state via Exchange Online + subscriptions via the Management API):
        powershell -File .\AUDSIEM-Discovery.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb>
        # Source state only (skip the Management API app check):
        .\AUDSIEM-Discovery.ps1 -SkipManagementApi
        Requires ExchangeOnlineManagement (Connect-ExchangeOnline) for the source-on check, and — for the
        subscription/app check — an Entra app registration with Office 365 Management APIs ActivityFeed.Read
        (ActivityFeed.ReadDlp for DLP), admin-consented, authenticating with a certificate (private key on
        this host by thumbprint). PowerShell 5.1+/7+.
    EXPECTED RESULTS
        Prints: UnifiedAuditLogIngestionEnabled (pass=True), the list of content subscriptions with status,
        and whether app-only auth succeeds. Any gap (ingestion off, no subscriptions, auth failure) is
        flagged as a finding to remediate.
.NOTES
    Purview category — Audit → SIEM integration. Read-only; no writes; NO secrets in code. Management
    Activity API resource is https://manage.office.com. Content types: Audit.AzureActiveDirectory,
    Audit.Exchange, Audit.SharePoint, Audit.General, DLP.All. Verify licensing/tenant for API bandwidth.
#>
[CmdletBinding()]
param(
    [string]$TenantId,
    [string]$AppId,
    [string]$CertificateThumbprint,
    [switch]$SkipManagementApi,
    [switch]$SkipExchange
)

$ErrorActionPreference = 'Stop'
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }
$findings = @()

# ---------------------------------------------------------------------------
# Shared app-only certificate token helper (client_assertion; NO secret).
# ---------------------------------------------------------------------------
function Get-AudSiemToken {
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$AppId,
        [Parameter(Mandatory)][string]$CertificateThumbprint,
        [string]$Resource = 'https://manage.office.com'
    )
    $cert = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $cert) { $cert = Get-Item "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue }
    if (-not $cert) { throw "Certificate $CertificateThumbprint not found in CurrentUser/LocalMachine My store (private key required)." }
    function B64Url([byte[]]$b){ [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $x5t = B64Url ($cert.GetCertHash())
    $header  = @{ alg='RS256'; typ='JWT'; x5t=$x5t } | ConvertTo-Json -Compress
    $payload = @{ aud=$tokenUri; iss=$AppId; sub=$AppId; jti=[guid]::NewGuid().ToString(); nbf=$now; exp=($now+600) } | ConvertTo-Json -Compress
    $unsigned = (B64Url ([Text.Encoding]::UTF8.GetBytes($header))) + '.' + (B64Url ([Text.Encoding]::UTF8.GetBytes($payload)))
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
    $sig = $rsa.SignData([Text.Encoding]::UTF8.GetBytes($unsigned), [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $assertion = $unsigned + '.' + (B64Url $sig)
    $body = @{
        client_id             = $AppId
        scope                 = "$Resource/.default"
        grant_type            = 'client_credentials'
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion      = $assertion
    }
    (Invoke-RestMethod -Method POST -Uri $tokenUri -Body $body -ContentType 'application/x-www-form-urlencoded').access_token
}

Say "=== AUDSIEM Discovery — audit-to-SIEM export surface (read-only) ===" 'Cyan'

# --- 1. Source precondition: is unified audit ingestion on? ---
if (-not $SkipExchange) {
    try {
        if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
            Import-Module ExchangeOnlineManagement -ErrorAction Stop
        }
        if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
            Say "Connecting to Exchange Online (modern auth)..." 'DarkGray'
            Connect-ExchangeOnline -ShowBanner:$false | Out-Null
        }
        $cfg = Get-AdminAuditLogConfig
        $on = [bool]$cfg.UnifiedAuditLogIngestionEnabled
        Say ("Unified audit ingestion (UnifiedAuditLogIngestionEnabled): {0}" -f $on) ($(if($on){'Green'}else{'Red'}))
        if (-not $on) { $findings += "SOURCE OFF: unified audit ingestion is disabled — no export path can ship what audit isn't capturing. Enable audit first (companion Purview Audit solution)." }
    } catch {
        Say ("Could not read audit config via Exchange Online: {0}" -f $_.Exception.Message) 'Yellow'
        $findings += "Could not confirm source (Exchange Online) — install ExchangeOnlineManagement and sign in with an audit-read admin."
    }
} else { Say "Skipping Exchange Online source check (-SkipExchange)." 'DarkGray' }

# --- 2. Management Activity API: app auth + current subscriptions ---
if (-not $SkipManagementApi) {
    if (-not ($TenantId -and $AppId -and $CertificateThumbprint)) {
        Say "Skipping Management API check — provide -TenantId, -AppId, -CertificateThumbprint to include it." 'Yellow'
        $findings += "Management API app identity not checked (parameters not supplied)."
    } else {
        try {
            $resource = 'https://manage.office.com'
            $base = "$resource/api/v1.0/$TenantId/activity/feed"
            $token = Get-AudSiemToken -TenantId $TenantId -AppId $AppId -CertificateThumbprint $CertificateThumbprint -Resource $resource
            $headers = @{ Authorization = "Bearer $token" }
            Say "App-only certificate auth: SUCCEEDED" 'Green'
            $subs = Invoke-RestMethod -Method GET -Uri "$base/subscriptions/list" -Headers $headers
            if ($subs) {
                Say "Current content subscriptions:" 'Cyan'
                $subs | Format-Table contentType, status, webhook -AutoSize | Out-String | Write-Host
                $enabled = @($subs | Where-Object { $_.status -eq 'enabled' }).contentType
                foreach ($ct in 'Audit.AzureActiveDirectory','Audit.Exchange','Audit.SharePoint','Audit.General') {
                    if ($ct -notin $enabled) { $findings += "Content type not subscribed/enabled: $ct (coverage gap if you need it)." }
                }
            } else {
                Say "No content subscriptions enabled." 'Yellow'
                $findings += "No Management API content subscriptions enabled — nothing is exporting via this path yet."
            }
        } catch {
            Say ("Management API check failed: {0}" -f $_.Exception.Message) 'Red'
            $findings += "Management API auth/list failed — verify ActivityFeed.Read is granted+consented and the certificate is present (Req 2.3/2.4)."
        }
    }
} else { Say "Skipping Management API check (-SkipManagementApi)." 'DarkGray' }

# --- 3. Native connector (manual confirmation, avoids double-feed) ---
Say "`nNote: confirm in your SIEM whether a NATIVE connector (e.g. Sentinel Office 365 / M365, Splunk Add-on)" 'DarkGray'
Say "already ingests any of these content types — do NOT stand up a duplicate Management API feed for them." 'DarkGray'

# --- Findings ---
Say "`n=== Findings ===" 'Cyan'
if ($findings.Count -eq 0) { Say "No gaps found in the checked items." 'Green' }
else { $i=1; foreach ($f in $findings) { Say ("{0}. {1}" -f $i++, $f) 'Yellow' } }
Say "`nRead-only assessment complete. No changes made." 'Cyan'
