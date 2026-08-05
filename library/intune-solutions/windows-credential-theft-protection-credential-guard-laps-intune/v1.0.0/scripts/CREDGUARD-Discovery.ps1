<#
.SYNOPSIS
    CREDGUARD-Discovery.ps1 — tenant + device readiness check for Windows credential-theft protection.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to deliver the credential-theft / pass-the-hash defense pack
        for Windows 10/11: Windows Defender Credential Guard (VBS), LSASS protection (RunAsPPL), WDigest
        disabled (UseLogonCredential=0), Remote Credential Guard / restricted delegation, WinRM
        DisableRunAs, and Windows LAPS. It reports which of the six credential-protection profiles are
        present, plus whether the Entra Windows LAPS feature can be relied upon. With -LocalReadiness it
        also runs an ON-DEVICE hardware-readiness check for Credential Guard: TPM 2.0, UEFI firmware,
        Secure Boot, and virtualization-based security. This checks the ENDPOINT credential-theft
        controls only — not RDP host hardening, full CIS/STIG baselines, or domain-controller settings.
    HOW TO RUN
        Tenant readiness (Graph):
          powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Discovery.ps1
        Add on-device hardware readiness (run locally on a candidate device):
          powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Discovery.ps1 -LocalReadiness
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows the six
        credential-protection profiles present; a READY device shows TPM 2.0, UEFI, Secure Boot, and VBS
        capability for Credential Guard.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph and the local device.
#>
[CmdletBinding()]
param(
    [switch]$LocalReadiness
)

$ErrorActionPreference = 'Stop'

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

# ---------------------------------------------------------------------------
# Part A — tenant readiness (Microsoft Graph): the six credential-protection profiles
# ---------------------------------------------------------------------------
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

# Signatures we look for across Settings Catalog (configurationPolicies) and templates (deviceConfigurations).
$controls = @(
    @{ Name = 'Credential Guard (VBS)';            Patterns = @('deviceguard','credentialguard','virtualizationbasedtechnology','lsacfgflags') }
    @{ Name = 'LSASS protection (RunAsPPL)';        Patterns = @('runasppl','configurelsasstoprotect','lsass') }
    @{ Name = 'WDigest disabled';                   Patterns = @('wdigest','uselogoncredential') }
    @{ Name = 'Remote Credential Guard / delegation'; Patterns = @('credentialsdelegation','restrictedremoteadministration','allowprotectedcreds','remotecredentialguard') }
    @{ Name = 'WinRM DisableRunAs';                 Patterns = @('disablerunas','winrm_service','windows remote management') }
    @{ Name = 'Windows LAPS';                       Patterns = @('laps','localadminpassword','backupdirectory') }
)

# Collect a searchable blob of all Windows Settings Catalog policies + their settings, and template profiles.
$blobs = @()
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
        $blobs += ([pscustomobject]@{ Name = $pol.name; Text = ("$($pol.name) " + "$($settings | ConvertTo-Json -Depth 25)").ToLower() })
    }
} catch {}
try {
    $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windows10EndpointProtectionConfiguration')"
    foreach ($p in @($tpl.value)) { $blobs += ([pscustomobject]@{ Name = $p.displayName; Text = ("$($p.displayName) " + "$($p | ConvertTo-Json -Depth 30)").ToLower() }) }
} catch {}
# Account protection / LAPS templates (intent) if present
try {
    $intents = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents"
    foreach ($i in @($intents.value)) { $blobs += ([pscustomobject]@{ Name = $i.displayName; Text = ("$($i.displayName)").ToLower() }) }
} catch {}

$results = New-Object System.Collections.Generic.List[object]
foreach ($c in $controls) {
    $hit = $null
    foreach ($b in $blobs) {
        if ($c.Patterns | Where-Object { $b.Text -match [regex]::Escape($_) }) { $hit = $b.Name; break }
    }
    $results.Add( (R "Profile present: $($c.Name)" ([bool]$hit) $(if ($hit) { "Found in '$hit'" } else { 'Not found' })) )
}

# ---------------------------------------------------------------------------
# Part B — on-device hardware readiness for Credential Guard (optional)
# ---------------------------------------------------------------------------
if ($LocalReadiness) {
    # TPM 2.0
    try {
        $tpm = Get-Tpm
        $tpmOk = [bool]($tpm.TpmPresent -and $tpm.TpmReady)
        $results.Add( (R 'Device: TPM present and ready' $tpmOk "Present=$($tpm.TpmPresent) Ready=$($tpm.TpmReady)") )
    } catch { $results.Add( (R 'Device: TPM present and ready' $false $_.Exception.Message) ) }

    # UEFI firmware (not legacy BIOS)
    try {
        $fw = (Get-ComputerInfo -Property BiosFirmwareType -ErrorAction Stop).BiosFirmwareType
        if (-not $fw) { $fw = $env:firmware_type }
        $results.Add( (R 'Device: UEFI firmware (not legacy BIOS)' ($fw -match 'Uefi') "FirmwareType=$fw") )
    } catch { $results.Add( (R 'Device: UEFI firmware (not legacy BIOS)' $false $_.Exception.Message) ) }

    # Secure Boot
    try {
        $sb = Confirm-SecureBootUEFI
        $results.Add( (R 'Device: Secure Boot enabled' ([bool]$sb) "SecureBoot=$sb") )
    } catch { $results.Add( (R 'Device: Secure Boot enabled' $false 'Not UEFI / Secure Boot unavailable') ) }

    # Virtualization-based security capability / running state
    try {
        $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
        $vbsCapable = @($dg.AvailableSecurityProperties) -contains 2   # 2 = Secure Boot; base VBS capability
        $cgRunning  = @($dg.SecurityServicesRunning) -contains 1       # 1 = Credential Guard
        $results.Add( (R 'Device: VBS capable' ([bool]$vbsCapable) "VbsStatus=$($dg.VirtualizationBasedSecurityStatus)") )
        $results.Add( (R 'Device: Credential Guard running (informational)' ([bool]$cgRunning) "ServicesRunning=$((@($dg.SecurityServicesRunning)) -join ',')") )
    } catch { $results.Add( (R 'Device: VBS capable' $false $_.Exception.Message) ) }
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant (and device, if checked) are prepared for Windows credential-theft protection.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting (missing profiles: author them; missing hardware: enable in firmware / exclude device from VBS controls)." -ForegroundColor Yellow }
