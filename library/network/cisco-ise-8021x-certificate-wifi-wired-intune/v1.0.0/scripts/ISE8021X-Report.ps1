<#
.SYNOPSIS
    ISE8021X-Report.ps1 — Fleet coverage report for the 802.1X EAP-TLS Wi-Fi/wired profiles and the device certificate via Microsoft Graph.
.DESCRIPTION
    PURPOSE
        Read-only reporting of 802.1X EAP-TLS coverage across the managed fleet. For each relevant
        Intune profile (trusted-root, SCEP/PKCS cert, Wi-Fi EAP-TLS, wired 802.1X) it reports how
        many devices report Succeeded, and highlights devices assigned but not yet compliant.
        Nothing is changed. Cisco ISE authentication results live in the ISE console (vendor docs).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISE8021X-Report.ps1 -OutputCsv .\ise8021x-coverage.csv

        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A per-profile coverage table (succeeded / error / pending counts) and an optional CSV of
        device-level status, so you can see fleet cert + Wi-Fi + wired 802.1X coverage and gaps.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE + network-infra internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string]$TrustedRootName = 'Cisco 802.1X - Trusted Root',
    [string]$ScepCertName    = 'Cisco 802.1X - SCEP Cert',
    [string]$WifiName        = 'Corp Wi-Fi - EAP-TLS',
    [string]$WiredName       = 'Wired 802.1X - EAP-TLS',
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    $scopes = @('DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK is not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null; try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Graph tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string]$Uri)
    $out = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}

Connect-Graph
$base = 'https://graph.microsoft.com/beta'

$allProfiles = Invoke-GraphGet -Uri "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
$targets = [ordered]@{
    'TrustedRoot' = $TrustedRootName
    'ScepCert'    = $ScepCertName
    'WiFi'        = $WifiName
    'Wired'       = $WiredName
}

$deviceRows = New-Object System.Collections.Generic.List[object]
$summary    = New-Object System.Collections.Generic.List[object]

Write-Host "`n=== 802.1X EAP-TLS coverage ===" -ForegroundColor Yellow
foreach ($key in $targets.Keys) {
    $name = $targets[$key]
    $match = $allProfiles | Where-Object { $_.displayName -eq $name }
    if (-not $match) {
        Write-Host ("  [{0,-11}] '{1}' NOT FOUND in Intune" -f $key, $name) -ForegroundColor Red
        $summary.Add([pscustomobject]@{ Profile=$key; Name=$name; Found=$false; Succeeded=0; Error=0; Pending=0 })
        continue
    }
    $id = $match[0].id
    $statuses = @()
    try {
        $statuses = Invoke-GraphGet -Uri "$base/deviceManagement/deviceConfigurations/$id/deviceStatuses"
    } catch { Write-Warning "  Could not read deviceStatuses for '$name': $($_.Exception.Message)" }

    $succ = ($statuses | Where-Object { $_.status -match '(?i)compliant|succeeded' }).Count
    $err  = ($statuses | Where-Object { $_.status -match '(?i)error|noncompliant|conflict|failed' }).Count
    $pend = ($statuses | Where-Object { $_.status -match '(?i)pending|notApplicable|unknown' }).Count

    Write-Host ("  [{0,-11}] {1}: Succeeded={2}  Error={3}  Pending={4}" -f $key, $name, $succ, $err, $pend)
    $summary.Add([pscustomobject]@{ Profile=$key; Name=$name; Found=$true; Succeeded=$succ; Error=$err; Pending=$pend })

    foreach ($s in $statuses) {
        $deviceRows.Add([pscustomobject]@{
            Profile     = $key
            ProfileName = $name
            DeviceName  = $s.deviceDisplayName
            UserName    = $s.userName
            Status      = $s.status
            LastReport  = $s.lastReportedDateTime
        })
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Yellow
$summary | Format-Table -AutoSize | Out-String | Write-Host

# Gap: devices with a cert profile succeeded but missing a network profile
$byDevice = $deviceRows | Group-Object DeviceName
$gaps = New-Object System.Collections.Generic.List[object]
foreach ($g in $byDevice) {
    $prof = @{}
    foreach ($r in $g.Group) { $prof[$r.Profile] = $r.Status }
    $hasCert  = ($prof['ScepCert']    -match '(?i)compliant|succeeded')
    $hasWifi  = ($prof['WiFi']        -match '(?i)compliant|succeeded')
    $hasWired = ($prof['Wired']       -match '(?i)compliant|succeeded')
    if ($hasCert -and (-not $hasWifi -or -not $hasWired)) {
        $gaps.Add([pscustomobject]@{ DeviceName=$g.Name; HasCert=$hasCert; HasWiFi=[bool]$hasWifi; HasWired=[bool]$hasWired })
    }
}
if ($gaps.Count -gt 0) {
    Write-Host "Devices with a cert but missing a Wi-Fi/wired profile (remediation candidates):" -ForegroundColor DarkYellow
    $gaps | Format-Table -AutoSize | Out-String | Write-Host
} else {
    Write-Host "No cert-present-but-profile-missing gaps detected." -ForegroundColor Green
}

if ($OutputCsv) {
    $deviceRows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Device-level coverage written to $OutputCsv" -ForegroundColor Cyan
}
