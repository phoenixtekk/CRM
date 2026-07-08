<#
.SYNOPSIS
    GPPLAP-Collect-Logs.ps1 — the test-window diagnostic collector for a GlobalProtect Connect Before Logon (PLAP) Autopilot device.
.DESCRIPTION
    PURPOSE
        Local, collection-only diagnostic runbook for a Windows 11 Autopilot test device. Gathers, into a
        single timestamped ZIP, everything needed to diagnose a Connect Before Logon / Autopilot failure —
        the "unzipping" (0x87D30067) error, a missing sign-in tile, a reboot loop, or a hybrid first-logon
        failure — BEFORE the device is wiped and the evidence is lost:
          - Intune Management Extension logs
            (C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\*  — IntuneManagementExtension.log,
             AgentExecutor.log, AppWorkload.log, and siblings)
          - Autopilot / MDM diagnostics via
            MdmDiagnosticsTool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -zip
          - GlobalProtect PanGPS / PanGPA logs from the GlobalProtect install / ProgramData directories
          - Relevant Event Viewer channels (application/system + MDM/DeviceManagement providers)
          - A snapshot of the PanSetup registry and the app install exit codes seen in the IME log
        Makes NO configuration changes — it only reads and copies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap
        Run ELEVATED (SYSTEM/admin) so the IME logs, MDM diagnostics, and Event logs can be read. No
        Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A ZIP at <OutFolder>\GPPLAP-Logs-<COMPUTERNAME>-<timestamp>.zip containing the IME logs, the MDM
        diagnostics ZIP, the GlobalProtect logs, the exported Event Viewer channels, and a summary.txt with
        the detected app exit codes and PanSetup state. Hand this ZIP to whoever is diagnosing the failure.
.NOTES
    White-label — the repeatable way. Read-only/collection only. GlobalProtect portal/gateway and app internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $OutFolder = "$env:TEMP\gpplap"
)

$ErrorActionPreference = 'Continue'
$stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$work    = Join-Path $OutFolder "GPPLAP-Logs-$env:COMPUTERNAME-$stamp"
$null = New-Item -ItemType Directory -Path $work -Force

Write-Host "=== GlobalProtect PLAP — Diagnostic Log Collection ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME   Output: $work`n"

$summary = New-Object System.Collections.Generic.List[string]
$summary.Add("GlobalProtect PLAP diagnostic collection")
$summary.Add("Device      : $env:COMPUTERNAME")
$summary.Add("Collected   : $(Get-Date -Format o)")
$summary.Add("Collector   : GPPLAP-Collect-Logs.ps1")
$summary.Add("")

function Copy-IfExists {
    param([string] $Path, [string] $DestName)
    if (Test-Path $Path) {
        $dest = Join-Path $work $DestName
        $null = New-Item -ItemType Directory -Path $dest -Force
        Copy-Item -Path (Join-Path $Path '*') -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [ok]  copied $Path" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  [--]  not found: $Path" -ForegroundColor DarkGray
        return $false
    }
}

# --- 1. Intune Management Extension logs -------------------------------------
Write-Host "[1] Intune Management Extension logs" -ForegroundColor Cyan
$imeLogs = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
$haveIme = Copy-IfExists -Path $imeLogs -DestName 'IME-Logs'
$summary.Add("IME logs collected: $haveIme  ($imeLogs)")

# Scan the IME logs for the app exit codes and the unzip error.
if ($haveIme) {
    $imeText = Get-ChildItem (Join-Path $work 'IME-Logs') -Filter *.log -ErrorAction SilentlyContinue |
        Get-Content -ErrorAction SilentlyContinue
    $codes = $imeText | Select-String -Pattern '0x87D30067|exit code|return code|3010|1618|1707' -ErrorAction SilentlyContinue |
        Select-Object -First 40
    $summary.Add("")
    $summary.Add("--- IME log hits (exit codes / unzip error) ---")
    if ($codes) { $codes | ForEach-Object { $summary.Add($_.Line.Trim()) } }
    else { $summary.Add("(no exit-code / 0x87D30067 lines matched)") }
    if ($imeText | Select-String -Pattern '0x87D30067' -Quiet) {
        Write-Host "  [!!]  0x87D30067 (unzipping) error present in IME log — see 06-troubleshooting.md" -ForegroundColor Yellow
        $summary.Add("")
        $summary.Add("NOTE: 0x87D30067 (unzipping) detected — check AV/IMECache exclusion, disk space, and re-wrap the .intunewin cleanly.")
    }
}

# --- 2. Autopilot / MDM diagnostics ------------------------------------------
Write-Host "[2] Autopilot / MDM diagnostics (MdmDiagnosticsTool.exe)" -ForegroundColor Cyan
$mdmZip = Join-Path $work 'MDMDiagnostics.zip'
try {
    Start-Process -FilePath "$env:WINDIR\System32\MdmDiagnosticsTool.exe" `
        -ArgumentList "-area Autopilot;DeviceEnrollment;DeviceProvisioning -zip `"$mdmZip`"" `
        -Wait -NoNewWindow -ErrorAction Stop
    if (Test-Path $mdmZip) { Write-Host "  [ok]  MDM diagnostics captured" -ForegroundColor Green; $summary.Add("MDM diagnostics: MDMDiagnostics.zip") }
    else { Write-Host "  [--]  MdmDiagnosticsTool produced no zip" -ForegroundColor DarkGray; $summary.Add("MDM diagnostics: (no zip produced)") }
} catch {
    Write-Host "  [--]  MdmDiagnosticsTool failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    $summary.Add("MDM diagnostics: FAILED ($($_.Exception.Message))")
}
# Optional community tool, if present on this device.
if (Get-Command Get-AutopilotDiagnostics -ErrorAction SilentlyContinue) {
    try {
        Get-AutopilotDiagnostics -Online 2>$null | Out-File (Join-Path $work 'Get-AutopilotDiagnostics.txt') -ErrorAction SilentlyContinue
        Write-Host "  [ok]  Get-AutopilotDiagnostics captured" -ForegroundColor Green
    } catch {}
}

# --- 3. GlobalProtect PanGPS / PanGPA logs -----------------------------------
Write-Host "[3] GlobalProtect logs (PanGPS / PanGPA)" -ForegroundColor Cyan
$gpDirs = @(
    "$env:ProgramData\Palo Alto Networks\GlobalProtect",
    "$env:ProgramFiles\Palo Alto Networks\GlobalProtect",
    "${env:ProgramFiles(x86)}\Palo Alto Networks\GlobalProtect",
    "$env:LOCALAPPDATA\Palo Alto Networks\GlobalProtect"
)
$gpAny = $false
foreach ($d in $gpDirs) {
    $dest = Join-Path $work ('GlobalProtect-' + ($d -replace '[:\\ ]', '_'))
    if (Test-Path $d) {
        $null = New-Item -ItemType Directory -Path $dest -Force
        Get-ChildItem -Path $d -Include *.log,*.txt,PanGPS*,PanGPA* -Recurse -ErrorAction SilentlyContinue |
            Copy-Item -Destination $dest -Force -ErrorAction SilentlyContinue
        $gpAny = $true
        Write-Host "  [ok]  collected GlobalProtect logs from $d" -ForegroundColor Green
    }
}
$summary.Add("GlobalProtect logs collected: $gpAny")

# --- 4. Event Viewer channels ------------------------------------------------
Write-Host "[4] Event Viewer channels" -ForegroundColor Cyan
$evtDest = Join-Path $work 'EventLogs'
$null = New-Item -ItemType Directory -Path $evtDest -Force
$channels = @(
    'Application',
    'System',
    'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin',
    'Microsoft-Windows-ModernDeployment-Diagnostics-Provider/Autopilot',
    'Microsoft-Windows-ModernDeployment-Diagnostics-Provider/ManagementService',
    'Microsoft-Windows-User Device Registration/Admin'
)
foreach ($ch in $channels) {
    $safe = ($ch -replace '[\\/ ]', '_')
    $out  = Join-Path $evtDest "$safe.evtx"
    try {
        wevtutil epl "$ch" "$out" 2>$null
        if (Test-Path $out) { Write-Host "  [ok]  exported $ch" -ForegroundColor Green }
    } catch { Write-Host "  [--]  could not export $ch" -ForegroundColor DarkGray }
}

# --- 5. PanSetup registry snapshot -------------------------------------------
Write-Host "[5] PanSetup registry snapshot" -ForegroundColor Cyan
$panSetup = 'HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup'
try {
    $ps = Get-ItemProperty -Path $panSetup -ErrorAction SilentlyContinue
    if ($ps) {
        $ps | Out-File (Join-Path $work 'PanSetup-registry.txt')
        $summary.Add("")
        $summary.Add("--- PanSetup ---")
        $summary.Add("Prelogon = $($ps.Prelogon)")
        $summary.Add("Portal   = $($ps.Portal)")
        Write-Host "  [ok]  PanSetup: Prelogon=$($ps.Prelogon) Portal=$($ps.Portal)" -ForegroundColor Green
    } else {
        $summary.Add("PanSetup registry key not found (Connect Before Logon not enabled).")
        Write-Host "  [!!]  PanSetup key not found" -ForegroundColor Yellow
    }
} catch {}

# --- Write summary + ZIP -----------------------------------------------------
$summary | Out-File (Join-Path $work 'summary.txt') -Encoding UTF8
$zip = Join-Path $OutFolder "GPPLAP-Logs-$env:COMPUTERNAME-$stamp.zip"
try {
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path (Join-Path $work '*') -DestinationPath $zip -Force
    Write-Host "`nEvidence ZIP: $zip" -ForegroundColor Green
} catch {
    Write-Host "`nCould not create ZIP ($($_.Exception.Message)). Collected files are in: $work" -ForegroundColor Yellow
}
Write-Host "Collection complete (read-only). No configuration changes were made." -ForegroundColor Green
