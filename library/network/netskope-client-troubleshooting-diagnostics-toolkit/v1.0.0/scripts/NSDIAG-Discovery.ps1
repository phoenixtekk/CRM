<#
.SYNOPSIS
    NSDIAG-Discovery.ps1 — Netskope client state, services, processes, and certificate posture.
.DESCRIPTION
    PURPOSE
        Read-only. Collects the endpoint's observable Netskope client state: installed product,
        related services and processes, and whether a decryption (SSL inspection) certificate is
        present in the trust store. This is the first input to the Diagnostic Bundle - Endpoint - Collect.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSDIAG-Discovery.ps1
    EXPECTED RESULTS
        Installed-client summary, service status, running processes, and decryption-cert presence.
        Netskope-internal log paths are deferred to Netskope's documentation (flagged below).
.NOTES
    Network category — client troubleshooting toolkit. Read-only. Uses only standard OS facilities.
#>
[CmdletBinding()] param()

Write-Host "`n=== Netskope client discovery ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# Installed product (registry uninstall keys) — match on a name pattern, do not assume an exact path.
$paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$installed = Get-ItemProperty $paths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like '*Netskope*' } |
    Select-Object DisplayName, DisplayVersion, Publisher
if ($installed) {
    Write-Host "Installed client:" -ForegroundColor Green
    $installed | Format-Table -AutoSize
} else {
    Write-Host "No Netskope client found in installed programs." -ForegroundColor Yellow
}

# Services matching the vendor name (names can vary by client version — match, don't hard-code).
Write-Host "Services (name match 'Netskope' / 'stAgent'):"
$svc = Get-Service -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'netskope|stAgent' -or $_.DisplayName -match 'Netskope' } |
    Select-Object Name, DisplayName, Status
if ($svc) { $svc | Format-Table -AutoSize } else { Write-Host "  (none found)" -ForegroundColor Yellow }

# Processes matching the vendor name.
Write-Host "Processes (name match 'netskope' / 'stAgent'):"
$proc = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match 'netskope|stAgent' } |
    Select-Object ProcessName, Id, StartTime
if ($proc) { $proc | Format-Table -AutoSize } else { Write-Host "  (none running)" -ForegroundColor Yellow }

# Decryption / inspection certificate presence (subject/issuer contains the vendor name).
Write-Host "Decryption certificate in trust stores (subject/issuer match 'Netskope'):"
$certs = @()
foreach ($store in 'Cert:\LocalMachine\Root','Cert:\LocalMachine\CA','Cert:\CurrentUser\Root') {
    $certs += Get-ChildItem $store -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -match 'Netskope' -or $_.Issuer -match 'Netskope' } |
        Select-Object @{n='Store';e={$store}}, Subject, NotAfter, Thumbprint
}
if ($certs) { $certs | Format-Table -AutoSize } else { Write-Host "  (no Netskope decryption cert found)" -ForegroundColor Yellow }

Write-Host "`nNOTE: Netskope client-internal logs/config paths are vendor-specific and version-specific." -ForegroundColor DarkCyan
Write-Host "      Locate them via Netskope's official documentation for your client version before escalation." -ForegroundColor DarkCyan
