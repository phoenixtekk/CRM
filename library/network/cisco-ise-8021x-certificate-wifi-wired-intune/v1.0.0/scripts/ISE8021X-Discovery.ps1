<#
.SYNOPSIS
    ISE8021X-Discovery.ps1 — Tenant-wide readiness check for 802.1X EAP-TLS (cert connectors + trusted-root/SCEP/PKCS/Wi-Fi/wired profiles) via Microsoft Graph.
.DESCRIPTION
    PURPOSE
        Read-only discovery of whether the tenant is ready for Cisco ISE 802.1X EAP-TLS.
        Reports the Intune certificate connectors and the device-configuration profiles that
        matter: trusted-root, SCEP/PKCS certificate, Wi-Fi (EAP-TLS) and wired 802.1X.
        Nothing is changed. Cisco ISE / switch / WLC internals are out of scope (vendor docs).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISE8021X-Discovery.ps1

        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementServiceConfig.Read.All
    EXPECTED RESULTS
        A summary listing certificate connectors and each relevant profile found (name + type).
        PASS when at least one connector plus a trusted-root, a SCEP/PKCS cert, a Wi-Fi EAP-TLS
        and a wired 802.1X profile are present; otherwise it lists what is missing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE + network-infra internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementServiceConfig.Read.All'
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK is not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Graph tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-Graph

$base = 'https://graph.microsoft.com/beta'
$findings = New-Object System.Collections.Generic.List[object]

# 1) Certificate connectors
Write-Host "`n=== Intune Certificate Connectors ===" -ForegroundColor Yellow
$connectors = @()
try {
    $connectors = Invoke-GraphGet -Uri "$base/deviceManagement/ndesConnectors"
} catch {
    Write-Warning "Could not read certificate connectors: $($_.Exception.Message)"
}
if ($connectors.Count -gt 0) {
    foreach ($c in $connectors) {
        Write-Host ("  [{0}] {1}  (last connection: {2})" -f $c.state, $c.displayName, $c.lastConnectionDateTime)
        $findings.Add([pscustomobject]@{ Category='CertificateConnector'; Name=$c.displayName; Detail=$c.state })
    }
} else {
    Write-Host "  (none found — required for SCEP/PKCS unless using Microsoft Cloud PKI)" -ForegroundColor DarkYellow
}

# 2) Device configuration profiles of interest
Write-Host "`n=== Device Configuration Profiles ===" -ForegroundColor Yellow
$profiles = Invoke-GraphGet -Uri "$base/deviceManagement/deviceConfigurations?`$select=id,displayName,@odata.type"

$buckets = [ordered]@{
    'TrustedRoot' = @('trustedRootCertificate')
    'ScepCert'    = @('windows81SCEPCertificate','androidWorkProfileScepCertificate','iosScepCertificate','scepCertificate','macOSScepCertificate','androidDeviceOwnerScepCertificate')
    'PkcsCert'    = @('windows81PkcsCertificate','pkcsCertificate','iosPkcsCertificate','macOSPkcsCertificate','androidDeviceOwnerPkcsCertificate')
    'WiFi'        = @('WifiConfiguration','wifiConfiguration','Enterprise')
    'Wired'       = @('wiredNetworkConfiguration','WiredNetwork')
}

$counts = @{ TrustedRoot=0; ScepCert=0; PkcsCert=0; WiFi=0; Wired=0 }

foreach ($p in $profiles) {
    $otype = [string]$p.'@odata.type'
    foreach ($k in $buckets.Keys) {
        foreach ($needle in $buckets[$k]) {
            if ($otype -match [regex]::Escape($needle)) {
                $counts[$k]++
                $findings.Add([pscustomobject]@{ Category=$k; Name=$p.displayName; Detail=$otype })
                Write-Host ("  [{0,-11}] {1}" -f $k, $p.displayName)
                break
            }
        }
    }
}

# Settings-Catalog profiles (Wi-Fi / wired often live here) — name-based hint
$scProfiles = @()
try {
    $scProfiles = Invoke-GraphGet -Uri "$base/deviceManagement/configurationPolicies?`$select=id,name"
    foreach ($sc in $scProfiles) {
        if ($sc.name -match '(?i)wi-?fi|wired|802\.?1x|eap') {
            $findings.Add([pscustomobject]@{ Category='SettingsCatalog(name-match)'; Name=$sc.name; Detail='configurationPolicy' })
            Write-Host ("  [{0,-11}] {1}" -f 'SettingsCat', $sc.name)
        }
    }
} catch { Write-Verbose "configurationPolicies not readable: $($_.Exception.Message)" }

# 3) Readiness verdict
Write-Host "`n=== Readiness Summary ===" -ForegroundColor Yellow
$certReady = ($counts.ScepCert + $counts.PkcsCert) -gt 0
$rootReady = $counts.TrustedRoot -gt 0
$wifiReady = $counts.WiFi -gt 0
$wiredReady = $counts.Wired -gt 0
$connReady = ($connectors.Count -gt 0)

function Show-Check($label, $ok, $note) {
    $tag = if ($ok) { 'PASS' } else { 'GAP ' }
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} {2}" -f $tag, $label, $note) -ForegroundColor $color
}
Show-Check 'Certificate connector (or Cloud PKI)' $connReady '(N/A if Microsoft Cloud PKI is used)'
Show-Check 'Trusted-root profile'                 $rootReady ''
Show-Check 'SCEP/PKCS certificate profile'        $certReady ''
Show-Check 'Wi-Fi (EAP-TLS) profile'              $wifiReady ''
Show-Check 'Wired 802.1X profile'                 $wiredReady ''

if ($rootReady -and $certReady -and $wifiReady -and $wiredReady) {
    Write-Host "`nOVERALL: PASS — the Intune building blocks for 802.1X EAP-TLS are present." -ForegroundColor Green
} else {
    Write-Host "`nOVERALL: GAP — build the missing profiles (see the Implementation guide)." -ForegroundColor Red
}

if ($OutputCsv) {
    $findings | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "`nFindings written to $OutputCsv" -ForegroundColor Cyan
}
