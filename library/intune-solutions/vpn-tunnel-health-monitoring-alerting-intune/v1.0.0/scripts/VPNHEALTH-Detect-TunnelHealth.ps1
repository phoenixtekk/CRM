<#
.SYNOPSIS
    VPNHEALTH-Detect-TunnelHealth.ps1 — read-only DEVICE-SIDE VPN tunnel health check (Proactive Remediations detection).

.DESCRIPTION
    PURPOSE
        A READ-ONLY device health check that evaluates a VPN tunnel against concrete health signals and
        returns a single verdict (Healthy / Degraded / Unhealthy) plus a per-signal breakdown. Signals:
          - VPN adapter/profile present
          - Tunnel established/connected
          - Gateway/endpoint reachable
          - Key route reachable THROUGH the tunnel
          - Internal DNS resolves THROUGH the tunnel
          - Auth certificate valid and not near expiry (default warning window: 30 days)
        It is VPN-TYPE AWARE (Microsoft Tunnel / Always On device tunnel / Always On user tunnel /
        third-party client such as Cisco Secure Client) and adapts what it probes per type.

        *** THIS SCRIPT MAKES NO CHANGES. *** It never restarts, reconnects, renews, or re-pushes the
        VPN. It only OBSERVES and REPORTS. This is monitoring, not remediation — fixes are deferred to
        the VPN deployment/troubleshooting products. Detection is read-only by contract.

    HOW TO RUN
        This is UPLOADED to Intune as the DETECTION script of a Proactive Remediations package
        (Reports > Endpoint analytics > Remediations > Create — verify path with Microsoft docs). Leave
        the REMEDIATION script EMPTY — this is a detection-only monitor. Intune's management extension
        runs it on-device on the assignment's schedule. You can also run it locally on a pilot device to
        test the verdict. Run context: SYSTEM for Microsoft Tunnel / Always On DEVICE tunnel / most
        third-party checks; USER context for an Always On USER tunnel or a user-store certificate.

    GRAPH SCOPES
        None — this runs ON THE DEVICE via the Intune Management Extension, not against Graph.

    EXPECTED RESULTS
        Writes ONE structured health line (surfaced in the console's detection output column) and sets
        the exit code:  exit 0 = Healthy;  exit 1 = Degraded or Unhealthy (shows as "With issue").
        Also writes a full timestamped record to C:\ProgramData\VPNHealth\ for on-device evidence and
        for an optional Log Analytics data-collection path. It NEVER changes the device.

.NOTES
    White-label — Intune Solutions. READ-ONLY device health check (monitoring only — no tunnel changes).
    Per-vendor detection specifics (adapter/service names, status surfaces) are VENDOR-SPECIFIC — verify
    against the vendor's documentation. Proactive Remediations behavior — verify against Microsoft docs.
#>

# =============================== CONFIGURATION (edit these) ====================================
$VpnType            = 'MicrosoftTunnel'          # MicrosoftTunnel | AlwaysOnDevice | AlwaysOnUser | ThirdParty
$ExpectedProfileName= 'Contoso VPN'              # VPN profile/connection name to look for
$ThirdPartyAdapter  = 'Cisco AnyConnect'         # ThirdParty only: adapter/service name — VERIFY with vendor docs
$TestRouteTarget    = '10.20.0.10'               # internal host/IP that should be reachable THROUGH the tunnel
$TestDnsName        = 'intranet.contoso.com'     # internal name that should resolve THROUGH the tunnel
$GatewayEndpoint    = 'vpn.contoso.com'          # VPN head-end/gateway FQDN or IP (reachability signal)
$CertSubjectMatch   = 'Contoso VPN Client'       # substring of the VPN auth certificate subject...
$CertIssuerMatch    = 'Contoso Issuing CA'       # ...or issuer (either match is accepted)
$CertWarningDays    = 30                          # cert-expiry WARNING window (days): inside => Degraded
$LogDir             = "$env:ProgramData\VPNHealth"
# ==============================================================================================

$ErrorActionPreference = 'SilentlyContinue'
$signals = [ordered]@{}                            # signal -> $true (pass) / $false (fail) / $null (n/a)
$notes   = [System.Collections.Generic.List[string]]::new()
$certDaysToExpiry = $null
$gatewayResolved  = $GatewayEndpoint

function Set-Signal($name, $value, $note) {
    $signals[$name] = $value
    if ($note) { $notes.Add("$name=$note") }
}

# --- Signal 1: VPN adapter / profile present (READ-ONLY) --------------------------------------
$profilePresent = $false
try {
    switch ($VpnType) {
        'ThirdParty' {
            $profilePresent = [bool](Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*$ThirdPartyAdapter*" -or $_.Name -like "*$ThirdPartyAdapter*" })
        }
        default {
            # Windows Always On / Microsoft Tunnel client profiles surface as VPN connections (read-only enumeration).
            $conn = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -eq $ExpectedProfileName }
            if (-not $conn) { $conn = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $ExpectedProfileName } }
            $profilePresent = [bool]$conn
            $script:__conn = $conn
        }
    }
} catch {}
Set-Signal 'ProfilePresent' $profilePresent $(if ($profilePresent) { 'yes' } else { 'MISSING' })

# --- Signal 2: Tunnel established / connected (READ-ONLY) -------------------------------------
$connected = $false
try {
    if ($VpnType -eq 'ThirdParty') {
        $ad = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*$ThirdPartyAdapter*" -or $_.Name -like "*$ThirdPartyAdapter*" }
        $connected = [bool]($ad | Where-Object { $_.Status -eq 'Up' })
    } else {
        $connected = ($script:__conn -and $script:__conn.ConnectionStatus -eq 'Connected')
    }
} catch {}
Set-Signal 'TunnelConnected' $connected $(if ($connected) { 'Connected' } else { 'not connected' })

# --- Signal 3: Gateway / endpoint reachable (READ-ONLY) --------------------------------------
$gatewayOk = $false
try {
    $t = Test-NetConnection -ComputerName $GatewayEndpoint -InformationLevel Quiet -WarningAction SilentlyContinue
    $gatewayOk = [bool]$t
} catch {}
Set-Signal 'GatewayReachable' $gatewayOk $(if ($gatewayOk) { 'reachable' } else { 'UNREACHABLE' })

# --- Signal 4: Key route reachable THROUGH the tunnel (READ-ONLY) -----------------------------
$routeOk = $false
try {
    $routeOk = Test-Connection -ComputerName $TestRouteTarget -Count 2 -Quiet -ErrorAction SilentlyContinue
} catch {}
Set-Signal 'RouteThroughTunnel' $routeOk $(if ($routeOk) { "reached $TestRouteTarget" } else { "cannot reach $TestRouteTarget" })

# --- Signal 5: Internal DNS resolves THROUGH the tunnel (READ-ONLY) ---------------------------
$dnsOk = $false
try {
    $r = Resolve-DnsName -Name $TestDnsName -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress }
    $dnsOk = [bool]$r
} catch {}
Set-Signal 'DnsThroughTunnel' $dnsOk $(if ($dnsOk) { "resolved $TestDnsName" } else { "cannot resolve $TestDnsName" })

# --- Signal 6: Auth certificate valid and not near expiry (READ-ONLY) ------------------------
$certState = 'fail'   # pass | warn | fail
try {
    $store = if ($VpnType -eq 'AlwaysOnUser') { 'Cert:\CurrentUser\My' } else { 'Cert:\LocalMachine\My' }
    $cert = Get-ChildItem $store -ErrorAction SilentlyContinue |
            Where-Object { ($CertSubjectMatch -and $_.Subject -like "*$CertSubjectMatch*") -or ($CertIssuerMatch -and $_.Issuer -like "*$CertIssuerMatch*") } |
            Sort-Object NotAfter -Descending | Select-Object -First 1
    if ($cert) {
        $certDaysToExpiry = [int]([math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays))
        if     ($certDaysToExpiry -lt 0)               { $certState = 'fail' }   # expired
        elseif ($certDaysToExpiry -le $CertWarningDays) { $certState = 'warn' }   # near expiry
        else                                            { $certState = 'pass' }
    } else {
        $certState = 'fail'   # certificate not found
    }
} catch { $certState = 'fail' }
Set-Signal 'CertValid' $([bool]($certState -eq 'pass')) "state=$certState;daysToExpiry=$certDaysToExpiry"

# --- Compute overall verdict ------------------------------------------------------------------
# Hard-fail signals => Unhealthy. Cert 'warn' (near expiry) => Degraded. All pass => Healthy.
$hardFail = @('ProfilePresent','TunnelConnected','GatewayReachable','RouteThroughTunnel','DnsThroughTunnel') |
            Where-Object { $signals[$_] -eq $false }
if ($hardFail.Count -gt 0 -or $certState -eq 'fail') {
    $verdict = 'Unhealthy'
} elseif ($certState -eq 'warn') {
    $verdict = 'Degraded'
} else {
    $verdict = 'Healthy'
}

# --- Emit structured line + on-device record (no device changes) ------------------------------
$line = "VPNHealth verdict=$verdict type=$VpnType gateway=$gatewayResolved certDaysToExpiry=$certDaysToExpiry " +
        (( $signals.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } ) -join ' ')
Write-Output $line

try {
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }  # log dir only; not a tunnel change
    $record = [pscustomobject]@{
        Timestamp        = (Get-Date).ToString('s')
        DeviceName       = $env:COMPUTERNAME
        VpnType          = $VpnType
        Gateway          = $gatewayResolved
        Verdict          = $verdict
        CertDaysToExpiry = $certDaysToExpiry
        Signals          = ($signals | ConvertTo-Json -Compress)
    }
    $record | ConvertTo-Json -Compress | Add-Content -Path (Join-Path $LogDir 'tunnel-health.log')
} catch {}

# --- Exit-code contract (detection-only; no remediation is paired) ----------------------------
if ($verdict -eq 'Healthy') { exit 0 } else { exit 1 }
