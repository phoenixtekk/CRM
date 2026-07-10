<#
.SYNOPSIS
    SENTSOAR-SimulateResponse.ps1 — simulate-only dry run of the containment response logic.
.DESCRIPTION
    PURPOSE
        Mirrors what the 'Response - Contain - Pilot' playbook would do, but as a SAFE, read-only dry
        run: given an incident's entities (a user UPN, a device id, an IP), it prints exactly which
        disable-user / isolate-device / block-IP action WOULD run, checks the target exists, and makes
        NO change. Use it to rehearse containment and to demonstrate simulate-first behaviour.
    HOW TO RUN
        Connect-AzAccount (and Connect-MgGraph for the user check) first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTSOAR-SimulateResponse.ps1 -UserUpn user@contoso.com -DeviceId <mde-machine-id> -IpAddress 203.0.113.10
        Any parameter may be omitted; only the provided targets are simulated.
        Requires modules: Az.Accounts, Microsoft.Graph.Users (for the optional user lookup).
    EXPECTED RESULTS
        For each provided target: a "WOULD ..." line describing the enforced action, a lookup result
        confirming the target resolves, and an explicit "NO CHANGE MADE (simulate)" note. Never mutates.
.NOTES
    Sentinel Solutions. Read-only / simulate-only by design — this script contains no enforcing calls.
#>
[CmdletBinding()]
param(
    [string]$UserUpn,
    [string]$DeviceId,
    [string]$IpAddress
)

Write-Host "=== SENTSOAR Simulate Response — DRY RUN (no changes) ===" -ForegroundColor Cyan
Write-Host "This script never enforces. It only reports what the response playbook WOULD do." -ForegroundColor Yellow

if (-not ($UserUpn -or $DeviceId -or $IpAddress)) {
    Write-Host "Provide at least one of -UserUpn, -DeviceId, -IpAddress to simulate." -ForegroundColor Yellow
    return
}

# --- Disable user (simulate) ---
if ($UserUpn) {
    Write-Host "`n[Disable user]" -ForegroundColor Cyan
    Write-Host ("  WOULD disable Entra ID account : {0}  (set accountEnabled = false)" -f $UserUpn)
    try {
        $u = Get-MgUser -UserId $UserUpn -Property Id,DisplayName,AccountEnabled -ErrorAction Stop
        Write-Host ("  Target resolves : {0}  (currently AccountEnabled = {1})" -f $u.DisplayName, $u.AccountEnabled) -ForegroundColor Green
    } catch {
        Write-Host ("  Target lookup skipped/failed ({0}). Connect-MgGraph with User.Read.All to verify." -f $_.Exception.Message) -ForegroundColor Yellow
    }
    Write-Host "  NO CHANGE MADE (simulate). Enforcing requires the playbook with SimulateMode=false + approval." -ForegroundColor Green
}

# --- Isolate device (simulate) ---
if ($DeviceId) {
    Write-Host "`n[Isolate device]" -ForegroundColor Cyan
    Write-Host ("  WOULD isolate Defender for Endpoint machine : {0}  (Isolate machine action)" -f $DeviceId)
    Write-Host "  Verify the machine is onboarded at security.microsoft.com before enforcing (Requirement 2.6)."
    Write-Host "  NO CHANGE MADE (simulate)." -ForegroundColor Green
}

# --- Block IP (simulate) ---
if ($IpAddress) {
    Write-Host "`n[Block IP]" -ForegroundColor Cyan
    if ($IpAddress -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
        Write-Host ("  '{0}' does not look like an IPv4 address — check the entity." -f $IpAddress) -ForegroundColor Yellow
    } else {
        Write-Host ("  WOULD block IP : {0}  (firewall/NSG rule or Sentinel threat-intel indicator, per your architecture)" -f $IpAddress)
    }
    Write-Host "  NO CHANGE MADE (simulate)." -ForegroundColor Green
}

Write-Host "`nSimulation complete. Nothing was changed." -ForegroundColor Cyan
