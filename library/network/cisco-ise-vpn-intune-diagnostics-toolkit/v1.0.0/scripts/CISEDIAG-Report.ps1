<#
.SYNOPSIS
    CISEDIAG-Report.ps1 — consolidated cross-layer diagnostics report for the Cisco ISE VPN + Intune stack.
.DESCRIPTION
    PURPOSE
        Runs the layer checks and rolls them into one PASS/FAIL report across L1 (certificate + chain),
        L2 (Cisco Secure Client / VPN profile), and the Intune side of L4 (compliance/enrollment), so
        you see the whole device-side picture at a glance and know which branch to open. Pass the
        Intune device name with -DeviceName and, for compliance, connect Graph or supply your-tenant-id
        / your-client-id / your-cert-thumbprint. Read-only end to end. L3/L4 Cisco-side confirmation
        (EAP-TLS success, authorization result) is read from the ISE live logs per vendor docs.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Report.ps1 -DeviceName your-device-name

        With compliance (interactive):
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Directory.Read.All"
            powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Report.ps1 -DeviceName your-device-name -IncludeCompliance
        Required Graph scopes (only if -IncludeCompliance): DeviceManagementManagedDevices.Read.All, Directory.Read.All
    EXPECTED RESULTS
        A layered PASS/FAIL summary. All green (L1/L2/L4-Intune) plus a live tunnel and an ISE
        success+permit result means the fix is done. Any FAIL names the branch to open in the
        Diagnostic Playbook. Use this as the closing gate after any single-layer fix.
.NOTES
    White-label — the repeatable way. Read-only. Cisco ISE / Secure Client internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $DeviceName = $env:COMPUTERNAME,
    [string] $Gateway,
    [switch] $IncludeCompliance,
    [string] $TenantId,
    [string] $ClientId,
    [string] $CertThumbprint
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " CISEDIAG consolidated diagnostics report" -ForegroundColor Cyan
Write-Host " Host: $env:COMPUTERNAME   Device: $DeviceName   $(Get-Date -Format o)" -ForegroundColor Cyan
Write-Host " Read-only: yes (no device/tenant/ISE changes)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($layer, $check, $result, $note) {
    $rows.Add([pscustomobject]@{ Layer = $layer; Check = $check; Result = $result; Note = $note })
}

# ---- L1: certificate + chain ------------------------------------------------
$clientAuthOid = '1.3.6.1.5.5.7.3.2'
$best = $null
foreach ($store in @('Cert:\CurrentUser\My','Cert:\LocalMachine\My')) {
    foreach ($c in (Get-ChildItem $store -ErrorAction SilentlyContinue)) {
        $isClientAuth = ($c.EnhancedKeyUsageList | Where-Object { $_.ObjectId -eq $clientAuthOid }) -ne $null
        if (-not $isClientAuth) { continue }
        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Online
        $chainOk = $false; try { $chainOk = $chain.Build($c) } catch { }
        $ok = ($c.HasPrivateKey -and ($c.NotAfter -gt (Get-Date)) -and $chainOk)
        if ($ok -and -not $best) { $best = $c }
    }
}
if ($best) {
    Add-Row 'L1' 'VPN client-auth certificate + chain' 'PASS' "Issuer: $($best.Issuer)"
} else {
    Add-Row 'L1' 'VPN client-auth certificate + chain' 'FAIL' 'No valid cert w/ key + trusted chain -> Branch A or B'
}

# ---- L2: VPN client + profile ----------------------------------------------
$svcRunning = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Cisco|Secure Client|AnyConnect|VPN' -and $_.Status -eq 'Running' }).Count
$profileCount = 0
foreach ($p in @("$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile","$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile")) {
    if (Test-Path $p) { $profileCount += @(Get-ChildItem $p -Filter *.xml -ErrorAction SilentlyContinue).Count }
}
if ($svcRunning -gt 0 -and $profileCount -gt 0) {
    Add-Row 'L2' 'Cisco Secure Client + VPN profile' 'PASS' "$svcRunning service(s), $profileCount profile(s)"
} else {
    Add-Row 'L2' 'Cisco Secure Client + VPN profile' 'FAIL' "service running: $svcRunning, profiles: $profileCount -> Branch C"
}

if ($Gateway) {
    $reach = $false; try { $reach = (Test-NetConnection -ComputerName $Gateway -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded } catch { }
    Add-Row 'L2' "Gateway reachable ($Gateway)" ($(if ($reach) { 'PASS' } else { 'FAIL' })) $(if ($reach) { 'TCP/443 open' } else { 'unreachable -> Branch C' })
}

# ---- L4 (Intune side): compliance ------------------------------------------
if ($IncludeCompliance) {
    try {
        if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
            if ($TenantId -and $ClientId -and $CertThumbprint) {
                Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertThumbprint -NoWelcome
            } else {
                Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Directory.Read.All" -NoWelcome
            }
        }
        $md = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" -ErrorAction Stop | Select-Object -First 1
        if (-not $md) {
            Add-Row 'L4' 'Intune compliance/enrollment' 'FAIL' 'Device not enrolled/unknown -> Branch A step 3'
        } elseif ($md.ComplianceState -eq 'compliant') {
            Add-Row 'L4' 'Intune compliance/enrollment' 'PASS' 'Compliant + managed'
        } else {
            Add-Row 'L4' 'Intune compliance/enrollment' 'FAIL' "ComplianceState: $($md.ComplianceState) -> Branch E"
        }
    } catch {
        Add-Row 'L4' 'Intune compliance/enrollment' 'SKIP' "Graph read failed: $($_.Exception.Message)"
    }
} else {
    Add-Row 'L4' 'Intune compliance/enrollment' 'SKIP' 'Run with -IncludeCompliance (+ Graph read scopes) to include'
}

# ---- Cisco-side (informational; confirmed from ISE live logs per vendor docs)
Add-Row 'L3' 'EAP-TLS success (ISE live log)' 'MANUAL' 'Read ISE detailed authentication report (Cisco docs)'
Add-Row 'L4' 'Authorization = permit (ISE live log)' 'MANUAL' 'Read matched authorization rule (Cisco docs)'

$rows | Format-Table Layer, Check, Result, Note -AutoSize

$fails = @($rows | Where-Object Result -eq 'FAIL')
if ($fails.Count -eq 0) {
    Write-Host "OVERALL: device-side layers PASS. Confirm the live tunnel + ISE success/permit (vendor docs) to close." -ForegroundColor Green
} else {
    Write-Host "OVERALL: $($fails.Count) failing layer(s). Open the Diagnostic Playbook branch named in each FAIL note." -ForegroundColor Yellow
}
