<#
.SYNOPSIS
    PLAPDX-Collect-Diagnostics.ps1 — on-device master collector for pre-logon VPN (SBL/PLAP + device tunnel).
.DESCRIPTION
    PURPOSE
        The entry point. Read-only, on-device snapshot of EVERY precondition for both pre-logon VPN
        mechanisms into one report, so triage is spent reasoning instead of gathering. Collects:
        OS SKU + build; join type (dsregcmd); Cisco Secure Client version; vpnplap64.dll presence +
        PLAP credential-provider registration; the UseStartBeforeLogon value in the Secure Client VPN
        profile; the Always On VPN device tunnel (Get-VpnConnection -AllUserConnection) with its
        DeviceTunnel/AlwaysOn/TunnelType; and the machine certificate (LocalMachine\My: EKU + expiry +
        private key). Ends with a flagged mechanism + symptom. Makes NO changes.
    HOW TO RUN
        Run ELEVATED (needed to read LocalMachine\My, all-user VPN, and the Credential Providers key):
            powershell -ExecutionPolicy Bypass -File .\PLAPDX-Collect-Diagnostics.ps1
            powershell -ExecutionPolicy Bypass -File .\PLAPDX-Collect-Diagnostics.ps1 -OutFile .\plapdx-report.txt
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A console summary and (with -OutFile) a text report of every precondition, plus a flagged
        mechanism/symptom pointing at the focused Check-* tool to run next (see 03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only local inspection. VPN head-end / gateway internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $OutFile = ''
)

$ErrorActionPreference = 'Continue'
$report = [System.Collections.Generic.List[string]]::new()
function Add-Line { param([string]$Text) $report.Add($Text); Write-Host $Text }

Add-Line "=== Pre-Logon VPN — Diagnostic Collection ==="
Add-Line ("Device      : {0}" -f $env:COMPUTERNAME)
Add-Line ("Collected   : {0}" -f (Get-Date -Format o))
Add-Line ("Read-only   : yes (no device/tenant/gateway changes)")
Add-Line ''

# --- OS SKU + build ----------------------------------------------------------
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$caption = $os.Caption
$build   = "$($os.Version) (build $($os.BuildNumber))"
$isEntEd = ($caption -match 'Enterprise|Education')
Add-Line "[OS]  $caption"
Add-Line "[OS]  Version/build : $build"
Add-Line ("[OS]  Enterprise/Education (device-tunnel eligible SKU) : {0}" -f $(if ($isEntEd) { 'YES' } else { 'NO' }))

# --- Join type (dsregcmd) ----------------------------------------------------
$joinAzureAd = $false; $joinDomain = $false; $joinEnterprise = $false
try {
    $ds = dsregcmd /status 2>$null
    foreach ($l in $ds) {
        if ($l -match 'AzureAdJoined\s*:\s*YES')    { $joinAzureAd = $true }
        if ($l -match 'DomainJoined\s*:\s*YES')     { $joinDomain = $true }
        if ($l -match 'EnterpriseJoined\s*:\s*YES') { $joinEnterprise = $true }
    }
} catch {}
$joinDesc = @()
if ($joinDomain)   { $joinDesc += 'DomainJoined' }
if ($joinAzureAd)  { $joinDesc += 'AzureADJoined' }
if ($joinEnterprise){ $joinDesc += 'EnterpriseJoined' }
if (-not $joinDesc) { $joinDesc = @('Workgroup/Unknown') }
# Device tunnel needs domain-joined or hybrid (domain + AzureAD) join.
$tunnelJoinOk = ($joinDomain -or ($joinDomain -and $joinAzureAd))
Add-Line ("[JOIN] {0}" -f ($joinDesc -join ', '))
Add-Line ("[JOIN] Domain/Hybrid joined (device-tunnel eligible)   : {0}" -f $(if ($joinDomain) { 'YES' } else { 'NO' }))

# --- Cisco Secure Client version --------------------------------------------
$scVersion = $null
foreach ($k in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
    $app = Get-ItemProperty $k -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Cisco (Secure Client|AnyConnect)' } | Select-Object -First 1
    if ($app) { $scVersion = $app.DisplayVersion; break }
}
Add-Line ("[SBL] Cisco Secure Client version : {0}" -f $(if ($scVersion) { $scVersion } else { 'not detected' }))

# --- vpnplap64.dll presence --------------------------------------------------
$dllCandidates = @(
    "$env:ProgramFiles\Cisco\Cisco Secure Client\vpnplap64.dll",
    "${env:ProgramFiles(x86)}\Cisco\Cisco Secure Client\vpnplap64.dll",
    "${env:ProgramFiles(x86)}\Cisco\Cisco AnyConnect Secure Mobility Client\vpnplap64.dll"
)
$dllPresent = $false
foreach ($d in $dllCandidates) { if (Test-Path $d) { $dllPresent = $true; break } }
Add-Line ("[SBL] vpnplap64.dll present       : {0}" -f $(if ($dllPresent) { 'YES' } else { 'NO' }))

# --- PLAP credential-provider registration -----------------------------------
$plapRegistered = $false
$cpRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers'
try {
    foreach ($cp in (Get-ChildItem $cpRoot -ErrorAction SilentlyContinue)) {
        $inproc = "HKLM:\SOFTWARE\Classes\CLSID\$($cp.PSChildName)\InprocServer32"
        if (Test-Path $inproc) {
            $dll = (Get-ItemProperty $inproc -ErrorAction SilentlyContinue).'(default)'
            if ($dll -match 'vpnplap64\.dll') { $plapRegistered = $true; break }
        }
    }
} catch {}
Add-Line ("[SBL] PLAP provider registered    : {0}" -f $(if ($plapRegistered) { 'YES' } else { 'NO' }))

# --- UseStartBeforeLogon in the Secure Client VPN profile --------------------
$profileDirs = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$sblFlag = $null; $profileCount = 0
foreach ($dir in $profileDirs) {
    if (Test-Path $dir) {
        foreach ($f in (Get-ChildItem $dir -Filter *.xml -ErrorAction SilentlyContinue)) {
            $profileCount++
            try {
                $raw = Get-Content -Raw -Path $f.FullName -ErrorAction SilentlyContinue
                if ($raw -match '(?i)<UseStartBeforeLogon>\s*true\s*</UseStartBeforeLogon>')  { $sblFlag = 'true' }
                elseif ($null -eq $sblFlag -and $raw -match '(?i)<UseStartBeforeLogon>\s*false\s*</UseStartBeforeLogon>') { $sblFlag = 'false' }
            } catch {}
        }
    }
}
Add-Line ("[SBL] VPN profile files present   : {0}" -f $profileCount)
Add-Line ("[SBL] UseStartBeforeLogon         : {0}" -f $(if ($sblFlag) { $sblFlag } else { 'not found' }))

# --- Always On VPN device tunnel ---------------------------------------------
$deviceTunnels = @()
try {
    $allTunnels = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue
    $deviceTunnels = @($allTunnels | Where-Object { $_.DeviceTunnel -eq $true })
} catch {}
Add-Line ("[TUNNEL] Device tunnels found     : {0}" -f $deviceTunnels.Count)
foreach ($t in $deviceTunnels) {
    Add-Line ("[TUNNEL]   '{0}' : TunnelType={1}; AlwaysOn={2}; Status={3}" -f $t.Name, $t.TunnelType, $t.AlwaysOn, $t.ConnectionStatus)
}

# --- Machine certificate -----------------------------------------------------
$clientAuthOid = '1.3.6.1.5.5.7.3.2'
$machineCerts = @()
foreach ($c in (Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue)) {
    $hasClientAuth = $false
    foreach ($eku in $c.EnhancedKeyUsageList) {
        if ($eku.ObjectId -eq $clientAuthOid -or $eku.FriendlyName -eq 'Client Authentication') { $hasClientAuth = $true }
    }
    $machineCerts += [pscustomobject]@{
        Subject = $c.Subject; Issuer = $c.Issuer; NotAfter = $c.NotAfter
        Expired = ($c.NotAfter -lt (Get-Date)); HasPrivateKey = $c.HasPrivateKey; ClientAuthEku = $hasClientAuth
    }
}
$usableCerts = @($machineCerts | Where-Object { $_.ClientAuthEku -and -not $_.Expired -and $_.HasPrivateKey })
Add-Line ("[CERT] LocalMachine\My certs      : {0} (usable client-auth w/ key: {1})" -f $machineCerts.Count, $usableCerts.Count)

# --- Flagged mechanism + symptom ---------------------------------------------
Add-Line ''
Add-Line "=== Flagged findings ==="
$sblReady    = ($dllPresent -and $plapRegistered -and $sblFlag -eq 'true' -and $profileCount -gt 0)
$tunnelReady = ($deviceTunnels.Count -eq 1 -and $isEntEd -and $joinDomain -and $usableCerts.Count -gt 0)

if (-not $sblReady) {
    Add-Line "  SBL/PLAP not ready -> run PLAPDX-Check-PlapSbl.ps1 (Network sign-in tile will be missing)."
} else {
    Add-Line "  SBL/PLAP preconditions look complete."
}
if ($deviceTunnels.Count -gt 1) {
    Add-Line "  MORE THAN ONE device tunnel -> only one is allowed; run PLAPDX-Check-DeviceTunnel.ps1."
} elseif (-not $tunnelReady) {
    Add-Line "  Device tunnel not ready -> run PLAPDX-Check-DeviceTunnel.ps1 (SKU/join/IKEv2/cert/AlwaysOn)."
} else {
    Add-Line "  Device-tunnel preconditions look complete."
}
if ($usableCerts.Count -eq 0) {
    Add-Line "  No usable machine certificate -> run PLAPDX-Check-Certificate.ps1 (auth will be rejected)."
}
Add-Line ''
Add-Line "Next: open 03-implementation.md and run the focused Check-* tool for the flagged symptom."

if ($OutFile) {
    $report | Out-File -FilePath $OutFile -Encoding utf8
    Write-Host "`nReport written to $OutFile" -ForegroundColor Green
}
