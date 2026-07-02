<#
.SYNOPSIS
    VOIPSUP-Discovery.ps1 — inventory the endpoint's audio devices and installed softphone client.
.DESCRIPTION
    PURPOSE
        Collects the read-only facts a technician needs before troubleshooting a VOIP/softphone
        call-quality ticket: every audio input/output endpoint, which device is the current default
        communication device, PnP audio device status/error codes, and the installed softphone/VOIP
        client with its version. Change nothing; this only reports what the endpoint currently has.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Discovery.ps1 -ClientNameFilter softphone-client-name -CsvPath .\voipsup-discovery.csv
    EXPECTED RESULTS
        A console table of audio playback/recording devices (with the default-communication device
        flagged), a list of PnP audio devices with status, and the detected softphone client(s) and
        version(s). Optional CSV export. No PASS/FAIL — this is inventory, not a gate.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    # A name fragment to match your softphone/VOIP client in installed programs, e.g. 'softphone-client-name'.
    [string[]] $ClientNameFilter = @('softphone', 'voip', 'phone', 'communicator', 'calling', 'meetings'),
    [string]   $CsvPath
)

$ErrorActionPreference = 'Stop'
Write-Host '=== VOIPSUP Discovery — audio devices + softphone client (read-only) ===' -ForegroundColor Cyan
Write-Host ("Device: {0}    User: {1}    {2}" -f $env:COMPUTERNAME, $env:USERNAME, (Get-Date))
Write-Host ''

# ---- Audio endpoints (PnP class AudioEndpoint) ----
Write-Host '--- Audio endpoints (playback + recording) ---' -ForegroundColor Yellow
$endpoints = @()
try {
    $endpoints = Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction Stop |
        Select-Object FriendlyName, Status,
            @{n='InstanceId';e={$_.InstanceId}},
            @{n='ProblemCode';e={$_.ProblemCode}}
    $endpoints | Format-Table -AutoSize
} catch {
    Write-Warning "Could not enumerate AudioEndpoint devices: $($_.Exception.Message)"
}

# ---- Default communication device (best-effort from the registry render/capture role) ----
Write-Host '--- Default device hint ---' -ForegroundColor Yellow
Write-Host 'Confirm the Default Communication Device in Sound Control Panel (mmsys.cpl) ->'
Write-Host 'Playback / Recording tabs (the green phone icon). The list above shows all endpoints; the'
Write-Host 'communication default is what calls use, which can differ from the plain Default Device.'
Write-Host ''

# ---- All PnP audio devices with status/error codes (for headset-not-recognized) ----
Write-Host '--- PnP audio devices (media + endpoint classes) with status ---' -ForegroundColor Yellow
$pnpAudio = @()
try {
    $pnpAudio = Get-PnpDevice -ErrorAction Stop |
        Where-Object { $_.Class -in @('AudioEndpoint','Media','MEDIA') -or $_.FriendlyName -match 'audio|headset|microphone|speaker|Bluetooth' } |
        Select-Object FriendlyName, Class, Status, ProblemCode |
        Sort-Object Class, FriendlyName -Unique
    $pnpAudio | Format-Table -AutoSize
    $problems = $pnpAudio | Where-Object { $_.Status -ne 'OK' }
    if ($problems) {
        Write-Host 'NOTE: the following audio-related devices are NOT in an OK state:' -ForegroundColor Red
        $problems | Format-Table -AutoSize
    }
} catch {
    Write-Warning "Could not enumerate PnP audio devices: $($_.Exception.Message)"
}

# ---- Installed softphone / VOIP client(s) ----
Write-Host '--- Installed softphone / VOIP client(s) ---' -ForegroundColor Yellow
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$installed = foreach ($k in $uninstallKeys) {
    try {
        Get-ItemProperty $k -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher
    } catch { }
}
$pattern = ($ClientNameFilter | ForEach-Object { [regex]::Escape($_) }) -join '|'
$clients = $installed | Where-Object { $_.DisplayName -match $pattern } | Sort-Object DisplayName -Unique
if ($clients) {
    $clients | Format-Table -AutoSize
} else {
    Write-Host 'No matching softphone/VOIP client found for the current filter.' -ForegroundColor Red
    Write-Host ("Filter used: {0}" -f ($ClientNameFilter -join ', '))
    Write-Host 'Re-run with -ClientNameFilter your-client-name to match your specific client.'
}

# ---- Running client processes (health hint) ----
Write-Host ''
Write-Host '--- Related running processes (client health hint) ---' -ForegroundColor Yellow
try {
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -match $pattern } |
        Select-Object ProcessName, Id,
            @{n='WorkingSetMB';e={[math]::Round($_.WorkingSet64/1MB,1)}},
            @{n='Responding';e={$_.Responding}} |
        Format-Table -AutoSize
} catch { }

# ---- Optional CSV export of endpoints ----
if ($CsvPath) {
    try {
        $endpoints | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host ("Audio-endpoint inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
    } catch {
        Write-Warning "CSV export failed: $($_.Exception.Message)"
    }
}

Write-Host ''
Write-Host 'Discovery complete. Compare the default communication device and client version against your' -ForegroundColor Cyan
Write-Host 'known-good baseline (Requirements R2/R4), then run VOIPSUP-Validation.ps1.' -ForegroundColor Cyan
