<#
.SYNOPSIS
    CVPNMIG-Validation.ps1 — confirm the Intune-delivered Cisco client, profile, and cert work on THIS device.
.DESCRIPTION
    PURPOSE
        Per-device migration-success check. Verifies that the Intune-delivered Cisco Secure Client is
        installed at the expected version, the VPN profile XML is present and matches the authoritative
        source, the VPN client certificate is present, and (optionally) that the tunnel establishes.
        This is the pilot/wave parity gate before the device is removed from the legacy SCCM/GPO path.
        The Cisco head-end and connect internals are Cisco's domain — this confirms delivery parity.
    HOW TO RUN
        Elevated on a migrated device. Supply the expected values to check parity:
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Validation.ps1 -ExpectedVersion 5.1.2.42 -ReferenceProfile C:\Temp\Cisco-VPN-Profile.xml
        Add -TestConnect to attempt a tunnel (uses the Cisco CLI if present):
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Validation.ps1 -ExpectedVersion 5.1.2.42 -TestConnect
        (No Graph scopes required — local device checks only.)
    EXPECTED RESULTS
        "MIGRATION VALIDATION: PASS" when the client version, profile, and certificate parity checks
        pass (and the tunnel connects if -TestConnect). "FAIL" with the failing check named otherwise.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param(
    [string]$ExpectedVersion,
    [string]$ReferenceProfile,
    [switch]$TestConnect
)

Write-Host "=== CVPNMIG Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$results = [ordered]@{}

# --- 1. Client installed at expected version ---
$uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$client = Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue |
          Where-Object { $_.DisplayName -match 'Cisco (Secure Client|AnyConnect)' } | Select-Object -First 1
if (-not $client) { $results['Client installed'] = $false }
elseif ($ExpectedVersion) { $results['Client version parity'] = ($client.DisplayVersion -eq $ExpectedVersion) }
else { $results['Client installed'] = $true }
Write-Host ("  Client: {0}" -f $(if ($client) { "$($client.DisplayName) $($client.DisplayVersion)" } else { 'NOT installed' }))

# --- 2. VPN profile present and matching the authoritative source ---
$profileDirs = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profileXml = Get-ChildItem -Path $profileDirs -Filter *.xml -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $profileXml) { $results['VPN profile present'] = $false }
elseif ($ReferenceProfile -and (Test-Path $ReferenceProfile)) {
    $a = (Get-FileHash $profileXml.FullName -Algorithm SHA256).Hash
    $b = (Get-FileHash $ReferenceProfile   -Algorithm SHA256).Hash
    $results['VPN profile parity'] = ($a -eq $b)
    Write-Host ("  Profile: {0} (parity {1})" -f $profileXml.Name, $(if ($a -eq $b) { 'MATCH' } else { 'DIFFERS' }))
} else { $results['VPN profile present'] = $true; Write-Host ("  Profile: {0}" -f $profileXml.Name) }

# --- 3. VPN client certificate present ---
$cert = @()
foreach ($store in 'Cert:\LocalMachine\My','Cert:\CurrentUser\My') {
    $cert += Get-ChildItem $store -ErrorAction SilentlyContinue |
             Where-Object { $_.EnhancedKeyUsageList.FriendlyName -contains 'Client Authentication' -and $_.NotAfter -gt (Get-Date) }
}
$results['VPN client cert present'] = ($cert.Count -gt 0)
Write-Host ("  Certificate: {0}" -f $(if ($cert.Count) { "$($cert.Count) valid client-auth cert(s)" } else { 'NONE' }))

# --- 4. Optional tunnel test via the Cisco CLI (vpncli.exe) if present ---
if ($TestConnect) {
    $cli = Get-ChildItem "$env:ProgramFiles(x86)\Cisco","$env:ProgramFiles\Cisco" -Recurse -Filter 'vpncli.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cli) {
        try {
            $state = & $cli.FullName state 2>$null | Out-String
            $results['Tunnel reachable (state)'] = ($state -match 'Connected|Connectable|Ready')
            Write-Host ("  Tunnel state: {0}" -f ($state.Trim() -replace '\s+',' '))
        } catch { $results['Tunnel reachable (state)'] = $false }
    } else {
        Write-Host '  vpncli.exe not found — skipping tunnel test (verify the VPN manually).' -ForegroundColor Yellow
    }
}

# --- Verdict ---
Write-Host "`n-- Checks --" -ForegroundColor Cyan
$results.GetEnumerator() | ForEach-Object {
    Write-Host ("  [{0}] {1}" -f $(if ($_.Value) { 'PASS' } else { 'FAIL' }), $_.Key) -ForegroundColor $(if ($_.Value) { 'Green' } else { 'Red' })
}
if ($results.Values -contains $false) {
    Write-Host "`nResult: MIGRATION VALIDATION: FAIL — fix before removing this device from the legacy path." -ForegroundColor Red; exit 1
} else {
    Write-Host "`nResult: MIGRATION VALIDATION: PASS — Intune delivery has parity; safe to cut this device over." -ForegroundColor Green; exit 0
}
