<#
.SYNOPSIS
    CISEDIAG-Collect.ps1 — end-to-end read-only diagnostic collection for the Cisco ISE VPN + Intune stack.
.DESCRIPTION
    PURPOSE
        Snapshots the whole device-side and Intune/Graph state for one connection failure into a
        timestamped bundle, so triage is spent reasoning instead of gathering. Collects certificate
        state (L1), Cisco Secure Client / VPN profile state (L2), and — if you connect to Graph —
        compliance and enrollment state (L4, Intune side). Fill in your-tenant-id / your-client-id
        only if you use the app-only path. Read-only: nothing on the device, tenant, or ISE changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Collect.ps1

        Optional Intune/Graph collection (interactive, read-only scopes):
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementConfiguration.Read.All","Directory.Read.All"
        Required Graph scopes: DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All, Directory.Read.All
    EXPECTED RESULTS
        A folder named CISEDIAG-Bundle-hostname-timestamp containing certificate, VPN-client, and
        compliance JSON/text files plus a summary. The summary points at the failing layer: no cert
        => L1 (Branch A); bad chain => L1 (Branch B); missing profile/gateway => L2 (Branch C);
        non-compliant/unenrolled => L4 (Branch E). Hand the bundle to the Diagnostic Playbook.
.NOTES
    White-label — the repeatable way. Read-only. Cisco ISE / Secure Client internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $OutputRoot = (Get-Location).Path,
    [string] $ManagedDeviceName = $env:COMPUTERNAME,
    [switch] $IncludeGraph
)

$ErrorActionPreference = 'Continue'
$stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$hostName = $env:COMPUTERNAME
$bundle   = Join-Path $OutputRoot ("CISEDIAG-Bundle-{0}-{1}" -f $hostName, $stamp)
New-Item -ItemType Directory -Path $bundle -Force | Out-Null

Write-Host "CISEDIAG-Collect : writing bundle to $bundle" -ForegroundColor Cyan
$summary = [System.Collections.Generic.List[string]]::new()
$summary.Add("CISEDIAG diagnostic bundle")
$summary.Add("Host        : $hostName")
$summary.Add("Collected   : $(Get-Date -Format o)")
$summary.Add("Read-only   : yes (no device/tenant/ISE changes)")
$summary.Add('')

# ---- L1: certificate state on this device -----------------------------------
Write-Host "  [L1] Collecting certificate store state..." -ForegroundColor Gray
$certs = foreach ($store in @('Cert:\CurrentUser\My','Cert:\LocalMachine\My')) {
    Get-ChildItem $store -ErrorAction SilentlyContinue | ForEach-Object {
        $hasClientAuth = ($_.EnhancedKeyUsageList | Where-Object { $_.FriendlyName -eq 'Client Authentication' -or $_.ObjectId -eq '1.3.6.1.5.5.7.3.2' }) -ne $null
        [pscustomobject]@{
            Store        = $store
            Subject      = $_.Subject
            Issuer       = $_.Issuer
            Thumbprint   = $_.Thumbprint
            NotBefore    = $_.NotBefore
            NotAfter     = $_.NotAfter
            Expired      = ($_.NotAfter -lt (Get-Date))
            HasPrivateKey= $_.HasPrivateKey
            ClientAuthEku= $hasClientAuth
        }
    }
}
$certs | ConvertTo-Json -Depth 4 | Out-File (Join-Path $bundle 'certificates.json') -Encoding utf8
$clientAuthCerts = @($certs | Where-Object { $_.ClientAuthEku -and -not $_.Expired -and $_.HasPrivateKey })
$summary.Add("[L1] Client-auth certificates (valid, w/ key) : $($clientAuthCerts.Count)")
if ($clientAuthCerts.Count -eq 0) { $summary.Add("     => No usable VPN certificate -> Branch A (or B if a cert exists but is invalid).") }

# ---- L2: Cisco Secure Client / VPN client + profile state -------------------
Write-Host "  [L2] Collecting VPN client/profile state..." -ForegroundColor Gray
$svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Cisco|Secure Client|AnyConnect|VPN' } |
    Select-Object Name, DisplayName, Status
$svc | ConvertTo-Json -Depth 3 | Out-File (Join-Path $bundle 'vpn-services.json') -Encoding utf8

$profilePaths = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profiles = foreach ($p in $profilePaths) {
    if (Test-Path $p) { Get-ChildItem $p -Filter *.xml -ErrorAction SilentlyContinue | Select-Object FullName, Length, LastWriteTime }
}
$profiles | ConvertTo-Json -Depth 3 | Out-File (Join-Path $bundle 'vpn-profiles.json') -Encoding utf8
$summary.Add("[L2] Cisco/VPN services found                 : $(@($svc).Count)")
$summary.Add("[L2] VPN profile XML files found              : $(@($profiles).Count)")
if (@($profiles).Count -eq 0) { $summary.Add("     => No VPN configuration profile on device -> Branch C.") }

# ---- L4 (Intune side): compliance/enrollment via Graph ----------------------
if ($IncludeGraph -or (Get-MgContext -ErrorAction SilentlyContinue)) {
    Write-Host "  [L4] Collecting Intune compliance state via Graph..." -ForegroundColor Gray
    try {
        if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementConfiguration.Read.All","Directory.Read.All" -NoWelcome
        }
        $md = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$ManagedDeviceName'" -ErrorAction Stop |
            Select-Object DeviceName, Id, ComplianceState, ManagementState, EnrolledDateTime, OperatingSystem, OsVersion, ManagedDeviceOwnerType
        $md | ConvertTo-Json -Depth 4 | Out-File (Join-Path $bundle 'intune-compliance.json') -Encoding utf8
        $summary.Add("[L4] Intune compliance state                 : $(($md.ComplianceState -join ',') )")
    } catch {
        $summary.Add("[L4] Graph collection skipped/failed         : $($_.Exception.Message)")
    }
} else {
    $summary.Add("[L4] Graph not connected — run with -IncludeGraph or Connect-MgGraph first for compliance data.")
}

$summary.Add('')
$summary.Add("Next: open the Diagnostic Playbook (03-implementation.md) and pick the branch for the flagged symptom.")
$summary | Out-File (Join-Path $bundle 'SUMMARY.txt') -Encoding utf8
$summary | ForEach-Object { Write-Host $_ }
Write-Host "CISEDIAG-Collect : done. Bundle at $bundle" -ForegroundColor Green
