<#
.SYNOPSIS
    VOIPSUP-Remediation.ps1 — apply safe endpoint fixes for common audio/device/client issues.
.DESCRIPTION
    PURPOSE
        Applies the low-risk endpoint remediations that resolve most VOIP/softphone tickets: set the
        default communication device to the intended headset, restart the Windows audio service,
        rescan for PnP devices (headset not recognized), and restart the softphone client. Every action
        defaults to preview only (-WhatIf) so you review before anything changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Remediation.ps1                (preview / -WhatIf)
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Remediation.ps1 -RestartAudio -RescanDevices -Execute
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Remediation.ps1 -RestartClient -ClientProcessName softphone-client-name -Execute
    EXPECTED RESULTS
        In preview mode: a list of the actions that WOULD run, no changes made. With -Execute: each
        selected action runs and reports success/failure. Some actions (audio service, device rescan)
        require local administrator rights.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
    Remediation defaults to -WhatIf; pass -Execute (or -WhatIf:$false) to apply.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $RestartAudio,
    [switch] $RescanDevices,
    [switch] $RestartClient,
    # Process name of the softphone client to restart, e.g. softphone-client-name (no .exe).
    [string] $ClientProcessName,
    # Convenience switch to apply changes; equivalent to -WhatIf:$false.
    [switch] $Execute
)

# Default to preview unless the operator explicitly asks to execute.
if ($Execute) { $WhatIfPreference = $false }
elseif (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Write-Host '=== VOIPSUP Remediation — safe endpoint fixes ===' -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host 'MODE: PREVIEW (-WhatIf). No changes will be made. Add -Execute to apply.' -ForegroundColor Yellow }
else { Write-Host 'MODE: EXECUTE. Changes will be applied.' -ForegroundColor Red }
Write-Host ("Device: {0}    User: {1}    {2}" -f $env:COMPUTERNAME,$env:USERNAME,(Get-Date))
Write-Host ''

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not ($RestartAudio -or $RescanDevices -or $RestartClient)) {
    Write-Host 'No action selected. Choose one or more: -RestartAudio, -RescanDevices, -RestartClient.' -ForegroundColor Yellow
    Write-Host 'Example: .\VOIPSUP-Remediation.ps1 -RestartAudio -RescanDevices -Execute'
    return
}

# ---- Restart the Windows audio service ----
if ($RestartAudio) {
    Write-Host '--- Restart Windows audio service (Audiosrv) ---' -ForegroundColor Yellow
    if (-not $WhatIfPreference -and -not (Test-IsAdmin)) {
        Write-Warning 'Restarting the audio service requires local administrator rights. Skipping.'
    } else {
        if ($PSCmdlet.ShouldProcess('Windows Audio (Audiosrv, AudioEndpointBuilder)', 'Restart service')) {
            try {
                Restart-Service -Name 'AudioEndpointBuilder' -Force -ErrorAction Stop
                Restart-Service -Name 'Audiosrv' -Force -ErrorAction Stop
                Write-Host 'Audio service restarted.' -ForegroundColor Green
            } catch {
                Write-Warning "Audio service restart failed: $($_.Exception.Message)"
            }
        }
    }
    Write-Host ''
}

# ---- Rescan for PnP devices (headset not recognized) ----
if ($RescanDevices) {
    Write-Host '--- Rescan for hardware changes (PnP) ---' -ForegroundColor Yellow
    if (-not $WhatIfPreference -and -not (Test-IsAdmin)) {
        Write-Warning 'Device rescan requires local administrator rights. Skipping.'
    } else {
        if ($PSCmdlet.ShouldProcess('Plug-and-Play devices', 'Rescan for hardware changes')) {
            try {
                # pnputil ships in-box; triggers a device tree rescan.
                & pnputil.exe /scan-devices | Out-Null
                Write-Host 'Device rescan triggered. Re-run VOIPSUP-Discovery.ps1 to confirm the headset now appears.' -ForegroundColor Green
            } catch {
                Write-Warning "Device rescan failed: $($_.Exception.Message)"
            }
        }
    }
    Write-Host ''
}

# ---- Restart the softphone client ----
if ($RestartClient) {
    Write-Host '--- Restart softphone client ---' -ForegroundColor Yellow
    if (-not $ClientProcessName) {
        Write-Warning 'Provide -ClientProcessName your-client-name (process name without .exe) to restart the client.'
    } else {
        $procs = @(Get-Process -Name $ClientProcessName -ErrorAction SilentlyContinue)
        if ($procs.Count -eq 0) {
            Write-Host ("No running process named '{0}' found; nothing to stop." -f $ClientProcessName)
        } else {
            $exePath = ($procs | Select-Object -First 1).Path
            if ($PSCmdlet.ShouldProcess($ClientProcessName, 'Stop process')) {
                try {
                    Stop-Process -Name $ClientProcessName -Force -ErrorAction Stop
                    Write-Host ("Stopped {0} instance(s) of {1}." -f $procs.Count,$ClientProcessName) -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to stop client: $($_.Exception.Message)"
                }
            }
            if ($exePath -and (Test-Path $exePath)) {
                if ($PSCmdlet.ShouldProcess($exePath, 'Start process')) {
                    try {
                        Start-Sleep -Seconds 2
                        Start-Process -FilePath $exePath -ErrorAction Stop
                        Write-Host 'Client relaunched.' -ForegroundColor Green
                    } catch {
                        Write-Warning "Failed to relaunch client: $($_.Exception.Message). Launch it manually."
                    }
                }
            } else {
                Write-Host 'Client executable path unavailable; relaunch the client manually.' -ForegroundColor Yellow
            }
        }
    }
    Write-Host ''
}

Write-Host 'Remediation routine complete. Re-run VOIPSUP-Validation.ps1 / VOIPSUP-Report.ps1 to confirm the gates now pass.' -ForegroundColor Cyan
Write-Host 'NOTE: setting the Default Communication Device programmatically is not exposed by in-box Windows cmdlets;' -ForegroundColor Yellow
Write-Host 'set it in Sound Control Panel (mmsys.cpl) -> Playback/Recording -> right-click device -> Set as Default Communication Device.' -ForegroundColor Yellow
