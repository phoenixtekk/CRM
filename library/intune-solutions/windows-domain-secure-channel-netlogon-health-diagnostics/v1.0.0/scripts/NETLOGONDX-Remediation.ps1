<#
.SYNOPSIS
    NETLOGONDX-Remediation.ps1 — safely repair domain secure-channel, time sync, and IPv6 config.
.DESCRIPTION
    PURPOSE
        Repairs the common root causes behind Netlogon Event ID 5719 / a broken secure channel, in a
        safe, reviewable order. It:
          1. repairs the machine secure channel (Test-ComputerSecureChannel -Repair; if that needs
             credentials/fails, resets it with nltest /sc_reset),
          2. re-synchronizes Windows Time with the domain hierarchy (w32tm /resync, service started),
          3. CORRECTS an INVALID IPv6 DisabledComponents value back to the recommended 0x0 (dual-stack
             default) — it never disables IPv6.
        IPv6 policy: IPv6 must stay ENABLED (dual-stack). This script only fixes UNSUPPORTED values
        (e.g. 0xffffffff, 0xff); it leaves the supported values 0x0 / 0x20 / 0x11 untouched. Disabling
        IPv6 breaks DirectAccess, Remote Assistance, and HomeGroup and is not covered by Microsoft's
        testing — so this tool will not do it.
        DEFAULTS TO -WhatIf: with no switch it PREVIEWS every change and modifies nothing. It applies
        only when you pass -WhatIf:$false (or -Force). Suitable as an Intune Proactive Remediations
        REMEDIATION script paired with NETLOGONDX-Validation.ps1 as the detection script.
    HOW TO RUN
        Preview (default — no changes):
          powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Remediation.ps1
        Apply the repairs:
          powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Remediation.ps1 -WhatIf:$false
        As a Proactive Remediations remediation script (runs as SYSTEM) it applies automatically —
        set -Apply behavior by leaving -WhatIf:$false in the packaged script body if desired.
    EXPECTED RESULTS
        In preview: a report of what is unhealthy and exactly what WOULD be repaired.
        When applied: secure channel repaired/reset, time resynced, and any invalid IPv6 value reset
        to 0x0. Re-run NETLOGONDX-Validation.ps1 to confirm HEALTHY. A restart may be required for an
        IPv6 change to take effect.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [pscredential]$Credential,
    [switch]$Force
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
if ($Force) { $WhatIfPreference = $false }

$ErrorActionPreference = 'Continue'

$cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$domain = $env:USERDNSDOMAIN; if (-not $domain -and $cs) { $domain = $cs.Domain }
if (-not [bool]$cs.PartOfDomain) { Write-Host 'Device is not domain-joined — nothing to remediate.' -ForegroundColor Yellow; return }

$changed = @()

# --- 1) Secure channel ---------------------------------------------------------
$scOk = $false
try { $scOk = Test-ComputerSecureChannel -ErrorAction Stop } catch { $scOk = $false }
if ($scOk) {
    Write-Host 'Secure channel already healthy — no repair needed.' -ForegroundColor Green
} elseif ($PSCmdlet.ShouldProcess("secure channel for $domain", 'Repair (Test-ComputerSecureChannel -Repair, else nltest /sc_reset)')) {
    $repaired = $false
    try {
        if ($Credential) { $repaired = Test-ComputerSecureChannel -Repair -Credential $Credential -ErrorAction Stop }
        else { $repaired = Test-ComputerSecureChannel -Repair -ErrorAction Stop }
    } catch { Write-Warning "Repair via Test-ComputerSecureChannel failed: $($_.Exception.Message)" }
    if (-not $repaired) {
        Write-Host 'Falling back to nltest /sc_reset...' -ForegroundColor Yellow
        $reset = (& nltest.exe "/sc_reset:$domain" 2>&1) -join "`n"
        Write-Host $reset
        $repaired = ($reset -match 'Success' -or $reset -match 'NT_STATUS_SUCCESS')
    }
    if ($repaired) { $changed += 'secure channel repaired/reset' }
} else {
    Write-Host "WhatIf: would repair the secure channel (Test-ComputerSecureChannel -Repair; fallback nltest /sc_reset:$domain)." -ForegroundColor Yellow
}

# --- 2) Time re-sync -----------------------------------------------------------
if ($PSCmdlet.ShouldProcess('Windows Time', 'Start w32time and w32tm /resync')) {
    try {
        Set-Service w32time -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service w32time -ErrorAction SilentlyContinue
        $resync = (& w32tm.exe /resync /force 2>&1) -join "`n"
        Write-Host $resync
        $changed += 'time resynced'
    } catch { Write-Warning "Time resync failed: $($_.Exception.Message)" }
} else {
    Write-Host 'WhatIf: would start Windows Time and run w32tm /resync /force.' -ForegroundColor Yellow
}

# --- 3) IPv6 DisabledComponents — correct INVALID value to 0x0 -----------------
$ipv6Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
$dc6 = (Get-ItemProperty -Path $ipv6Path -Name DisabledComponents -ErrorAction SilentlyContinue).DisabledComponents
$dc6Hex = if ($null -ne $dc6) { '0x{0:x}' -f $dc6 } else { '(absent=0x0)' }
$supported = ($null -eq $dc6 -or $dc6 -eq 0 -or $dc6 -eq 0x20 -or $dc6 -eq 0x11)
if ($supported) {
    Write-Host "IPv6 DisabledComponents=$dc6Hex is supported — left unchanged (IPv6 stays enabled)." -ForegroundColor Green
} elseif ($PSCmdlet.ShouldProcess("IPv6 DisabledComponents ($dc6Hex)", 'Reset to recommended 0x0 (IPv6 enabled, dual-stack)')) {
    try {
        Set-ItemProperty -Path $ipv6Path -Name DisabledComponents -Value 0 -Type DWord -Force
        Write-Host "Reset IPv6 DisabledComponents $dc6Hex -> 0x0. A restart is required to take effect." -ForegroundColor Green
        $changed += "IPv6 DisabledComponents reset $dc6Hex -> 0x0 (restart required)"
    } catch { Write-Warning "IPv6 reset failed: $($_.Exception.Message)" }
} else {
    Write-Host "WhatIf: would reset INVALID IPv6 DisabledComponents $dc6Hex -> 0x0 (never disables IPv6; disabling breaks DirectAccess/Remote Assistance/HomeGroup and is unsupported)." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) {
    Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false (or -Force) to apply.' -ForegroundColor Yellow
} elseif ($changed.Count) {
    Write-Host ('Remediation applied: ' + ($changed -join '; ') + '.') -ForegroundColor Green
    Write-Host 'Re-run NETLOGONDX-Validation.ps1 to confirm HEALTHY (restart if IPv6 was changed).' -ForegroundColor Green
} else {
    Write-Host 'Nothing needed remediation — device already healthy.' -ForegroundColor Green
}
