<#
.SYNOPSIS
    DLPMac-Discovery.ps1 — macOS Endpoint DLP readiness: endpoint-scoped DLP policies, their Mode, and rule egress restrictions (read-only).
.DESCRIPTION
    PURPOSE
        Assesses whether the tenant is ready for macOS Endpoint DLP: enumerates DLP compliance
        policies scoped to the DEVICES (Endpoint) location, reports each policy's Mode and FLAGS any
        that are already in Enable (enforcing) rather than a test/simulation mode, and lists each
        rule's endpoint egress restrictions (cloud/USB/network-share/clipboard/print/restricted-apps).
        Read-only against Security & Compliance PowerShell — makes no changes. macOS device onboarding
        status is verified in the Purview portal (no supported cmdlet enumerates onboarded devices).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPMac-Discovery.ps1
        PowerShell 5.1+ or 7+. Requires the ExchangeOnlineManagement module; connects with
        Connect-IPPSSession (interactive modern auth). No credentials are stored in this script.
    EXPECTED RESULTS
        A list of endpoint-scoped DLP policies with Mode (TestWithoutNotifications / TestWithNotifications
        / Enable), a WARNING on any policy already enforcing, and each rule's endpoint restrictions.
        Confirm macOS devices are onboarded in Purview -> Settings -> Device onboarding before relying
        on any endpoint policy.
.NOTES
    Purview category — macOS Endpoint DLP. Read-only. Endpoint DLP is E5/E5-Compliance and macOS support
    is version-dependent — verify your licensing/tenant/macOS version.
#>
[CmdletBinding()]
param(
    [string]$PolicyNameFilter = 'Endpoint DLP - macOS'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement module not found — installing for current user..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

Write-Host "`n=== macOS Endpoint DLP readiness ===" -ForegroundColor Cyan
try {
    Connect-IPPSSession -ErrorAction Stop | Out-Null
} catch {
    Write-Host ("Could not connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}

# 1) DLP policies scoped to the Devices (Endpoint) location
Write-Host "`n-- Endpoint-scoped DLP policies --" -ForegroundColor Cyan
try {
    $all = Get-DlpCompliancePolicy -ErrorAction Stop
    # An endpoint policy has an EndpointDlpLocation (Devices location) configured.
    $endpoint = $all | Where-Object {
        ($_.EndpointDlpLocation -and $_.EndpointDlpLocation.Count -gt 0) -or ($_.Name -like "*$PolicyNameFilter*")
    }
    if (-not $endpoint -or $endpoint.Count -eq 0) {
        Write-Host "Policies         : none scoped to Devices/Endpoint yet — create one in TestWithoutNotifications (Implementation Step 5)." -ForegroundColor Yellow
    } else {
        foreach ($p in $endpoint) {
            $mode = "$($p.Mode)"
            $enforcing = ($mode -eq 'Enable')
            $col = if ($enforcing) { 'Yellow' } else { 'Green' }
            Write-Host ("Policy           : {0}" -f $p.Name) -ForegroundColor $col
            Write-Host ("  Mode           : {0}{1}" -f $mode, $(if ($enforcing) { '   <-- ENFORCING (Block). Confirm this is intended and signed off.' } else { '   (test/simulation)' }))
            Write-Host ("  Enabled        : {0}" -f $p.Enabled)
            if ($p.EndpointDlpLocation) { Write-Host ("  Devices scope  : {0}" -f (($p.EndpointDlpLocation | ForEach-Object { $_.Name }) -join ', ')) }
        }
    }
} catch {
    Write-Host ("Policies         : unable to read DLP policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    $endpoint = @()
}

# 2) Rules and their endpoint egress restrictions
Write-Host "`n-- Endpoint DLP rules + egress restrictions --" -ForegroundColor Cyan
try {
    foreach ($p in $endpoint) {
        $rules = Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue
        if (-not $rules) { Write-Host ("  {0}: no rules — add 'macOS Egress - Sensitive Content' (Implementation Step 6)." -f $p.Name) -ForegroundColor Yellow; continue }
        foreach ($r in $rules) {
            Write-Host ("  Rule           : {0}  (policy: {1})" -f $r.Name, $p.Name) -ForegroundColor Green
            if ($r.EndpointDlpRestrictions) {
                foreach ($er in $r.EndpointDlpRestrictions) {
                    # EndpointDlpRestrictions entries expose Setting + Value (e.g. Print/Block, RemovableMedia/Audit)
                    Write-Host ("      egress     : {0,-22} -> {1}" -f "$($er.Setting)", "$($er.Value)")
                }
            } else {
                Write-Host "      egress     : (no endpoint restrictions on this rule — add the macOS channels at Audit)" -ForegroundColor DarkGray
            }
        }
    }
} catch {
    Write-Host ("  (unable to read DLP rules: {0})" -f $_.Exception.Message) -ForegroundColor DarkGray
}

Write-Host "`nmacOS device onboarding is NOT enumerable via cmdlet — confirm in Purview -> Settings -> Device onboarding -> Devices." -ForegroundColor DarkGray
Write-Host "Endpoint DLP requires E5/E5 Compliance; macOS support is limited to the three latest major macOS versions — verify your licensing/tenant/macOS version." -ForegroundColor DarkGray
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
