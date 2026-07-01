<#
.SYNOPSIS
    NSMIG-Remediation.ps1 — remove the legacy Forcepoint Neo agent (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Safely removes the legacy Forcepoint Neo web-filtering agent from a device AFTER that device's
        migration ring has passed the parity gate. By default it runs in preview (-WhatIf) and only
        reports what it would uninstall; pass -Confirm to actually remove. It locates the agent's
        uninstall string from the registry and invokes it. It does NOT remove the Netskope client.
        Some Forcepoint Neo builds enforce tamper protection / an uninstall password — that is
        deferred to Forcepoint console/admin (supply it per Forcepoint docs if removal is blocked).
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\NSMIG-Remediation.ps1
        Remove for real:   powershell -ExecutionPolicy Bypass -File .\NSMIG-Remediation.ps1 -Confirm
    EXPECTED RESULTS
        -WhatIf: prints the uninstall command(s) it would run, changes nothing.
        -Confirm: invokes the Forcepoint Neo uninstaller; re-run NSMIG-Validation.ps1 afterward.
.NOTES
    Network Solutions. Defaults to -WhatIf. Only remove the legacy agent after the ring passes parity.
#>
[CmdletBinding()] param(
    [switch]$WhatIf = $true,
    [switch]$Confirm
)
if ($Confirm) { $WhatIf = $false }
Write-Host "=== NSMIG Remediation — remove Forcepoint Neo agent ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if($WhatIf){'PREVIEW (-WhatIf) — no changes'}else{'REMOVE (-Confirm)'}))) -ForegroundColor ($(if($WhatIf){'Yellow'}else{'Red'}))

$keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$targets = Get-ItemProperty $keys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Forcepoint|Neo' -and $_.UninstallString }

if (-not $targets) {
    Write-Host "No Forcepoint Neo uninstall entry found — nothing to remove." -ForegroundColor Green
    return
}

foreach ($t in $targets) {
    $cmd = $t.UninstallString
    # Prefer a silent MSI uninstall when the entry is an MSI product
    if ($cmd -match 'msiexec' -and $t.PSChildName -match '^\{[0-9A-Fa-f-]+\}$') {
        $cmd = "msiexec.exe /x $($t.PSChildName) /qn /norestart"
    }
    Write-Host ("Target: {0}" -f $t.DisplayName) -ForegroundColor Cyan
    Write-Host ("  Uninstall command: {0}" -f $cmd)
    if ($WhatIf) {
        Write-Host "  [WhatIf] would run the command above." -ForegroundColor Yellow
    } else {
        try {
            Write-Host "  Removing..." -ForegroundColor Red
            Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $cmd -Wait -WindowStyle Hidden
            Write-Host "  Uninstall invoked." -ForegroundColor Green
        } catch {
            Write-Host ("  Uninstall failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
            Write-Host "  If blocked by tamper protection/uninstall password, obtain it from the Forcepoint console (deferred to Forcepoint docs)." -ForegroundColor Yellow
        }
    }
}
Write-Host "`nRe-run NSMIG-Validation.ps1 to confirm Netskope is now the sole enforcing agent." -ForegroundColor Green
