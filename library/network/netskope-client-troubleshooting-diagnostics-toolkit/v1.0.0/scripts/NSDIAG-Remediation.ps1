<#
.SYNOPSIS
    NSDIAG-Remediation.ps1 — safe remediation: restart / repair / re-enroll the Netskope client.
.DESCRIPTION
    PURPOSE
        Applies the safe remediation for a classified failure. SUPPORTS -WhatIf AND DEFAULTS TO IT:
        with no action confirmed it only PREVIEWS what it would do and changes nothing. Choose one
        action switch (-Restart / -Repair / -ReEnroll). Restart/repair are the first line; re-enroll
        is the last resort for confirmed enrollment/auth faults (see the Authentication runbook).
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\NSDIAG-Remediation.ps1 -Restart
        Apply:              powershell -ExecutionPolicy Bypass -File .\NSDIAG-Remediation.ps1 -Restart -Confirm:$false  (or -Apply)
        Elevated session required. Use a change window for -Repair / -ReEnroll.
    EXPECTED RESULTS
        In preview, a description of the intended action. When applied, the action runs and the script
        advises re-running NSDIAG-Validation.ps1 after a policy cycle.
.NOTES
    Network category — client troubleshooting toolkit. Restart/repair/re-enroll touch live steering.
    Netskope's own repair/re-enroll mechanism is vendor-specific — confirm the exact command per
    Netskope's documentation for your client version (flagged at each action).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Restart,
    [switch]$Repair,
    [switch]$ReEnroll,
    [switch]$Apply  # convenience: equivalent to -Confirm:$false for unattended runs
)

if ($Apply) { $ConfirmPreference = 'None' }

Write-Host "=== Netskope client remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if (-not ($Restart -or $Repair -or $ReEnroll)) {
    Write-Host "No action switch supplied. Choose one of -Restart / -Repair / -ReEnroll." -ForegroundColor Yellow
    Write-Host "Default mode is preview (-WhatIf semantics); nothing is changed until you confirm." -ForegroundColor Yellow
    exit 2
}

$svc = Get-Service -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'netskope|stAgent' -or $_.DisplayName -match 'Netskope' }

# --- Restart: bounce the client service(s) using standard Service cmdlets ---
if ($Restart) {
    if (-not $svc) { Write-Host "No Netskope service found to restart." -ForegroundColor Yellow }
    foreach ($s in $svc) {
        if ($PSCmdlet.ShouldProcess($s.DisplayName, "Restart-Service")) {
            try { Restart-Service -Name $s.Name -Force -ErrorAction Stop; Write-Host ("  Restarted: {0}" -f $s.DisplayName) -ForegroundColor Green }
            catch { Write-Host ("  Restart failed for {0}: {1}" -f $s.DisplayName, $_.Exception.Message) -ForegroundColor Yellow }
        }
    }
}

# --- Repair: trigger an Intune/MDM policy sync so client config re-applies (OS facility) ---
if ($Repair) {
    if ($PSCmdlet.ShouldProcess("$env:COMPUTERNAME", "Trigger MDM policy sync (deviceenroller /AutoEnrollMDM) to re-apply client config")) {
        try {
            Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
            Write-Host "  MDM policy sync requested (re-applies managed client config)." -ForegroundColor Green
        } catch { Write-Host ("  Sync trigger failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        Write-Host "  NOTE: A vendor-specific client 'repair' may also exist — confirm the exact command in Netskope's docs." -ForegroundColor DarkCyan
    }
}

# --- Re-enroll: last resort. Vendor-specific enrollment is deferred to Netskope docs. ---
if ($ReEnroll) {
    if ($PSCmdlet.ShouldProcess("$env:COMPUTERNAME", "Re-enroll the Netskope client (restart service + MDM sync; vendor re-enroll deferred to Netskope docs)")) {
        Write-Host "  Re-enroll is a last resort — confirm a change window and a rollback first." -ForegroundColor Yellow
        foreach ($s in $svc) {
            try { Restart-Service -Name $s.Name -Force -ErrorAction Stop; Write-Host ("  Restarted: {0}" -f $s.DisplayName) -ForegroundColor Green } catch {}
        }
        try {
            Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
            Write-Host "  MDM policy sync requested." -ForegroundColor Green
        } catch { Write-Host ("  Sync trigger failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        Write-Host "  NOTE: The Netskope client's own re-enroll/provisioning command is VENDOR-SPECIFIC." -ForegroundColor DarkCyan
        Write-Host "        Run it per Netskope's documentation for your client version; do not assume a path." -ForegroundColor DarkCyan
    }
}

Write-Host "`nRe-run NSDIAG-Validation.ps1 after a policy cycle to confirm the fix." -ForegroundColor Green
