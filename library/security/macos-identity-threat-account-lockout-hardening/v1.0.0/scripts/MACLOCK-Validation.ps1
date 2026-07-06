<#
.SYNOPSIS
    MACLOCK-Validation.ps1 — do Smart Lockout + the MFA policy match the register, and did Mac failures drop? (Graph).
.DESCRIPTION
    PURPOSE
        Confirms the tenant matches the desired hardening state recorded in the register 'MACLOCK
        Lockout & Spray Register - Mac Fleet - Baseline': the Smart Lockout threshold/duration and an
        MFA-enforcing Conditional Access policy for the Mac pilot. Then re-reads the Entra sign-in
        logs for macOS-originated failures so you can confirm they dropped after remediation. Reports
        each item as MATCH or GAP. Read-only. Use 'your-tenant-id' style values, not bracketed
        placeholders.
    HOW TO RUN
        Default (uses bundled desired values):
            powershell -ExecutionPolicy Bypass -File .\MACLOCK-Validation.ps1
        With your own desired state (JSON: { lockoutThreshold; lockoutDurationSeconds; mfaPolicyName }):
            ... .\MACLOCK-Validation.ps1 -RegisterPath .\maclock-register.json -Days 7
        Requires the Microsoft Graph PowerShell SDK and consent to:
        AuditLog.Read.All, Policy.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        A per-item MATCH / GAP list for Smart Lockout and the MFA policy, plus the current count of
        macOS-originated sign-in failures in the window. GAP lines are the backlog to work through in
        the Implementation Guide (safely via MACLOCK-Remediation.ps1).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    The desired state is intentionally external (a JSON file you own); the bundled sample lets the
    script run out-of-the-box.
#>
[CmdletBinding()]
param(
    [string]$RegisterPath,
    [int]$Days = 7
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

if ($RegisterPath -and (Test-Path $RegisterPath)) {
    $desired = Get-Content -Raw -Path $RegisterPath | ConvertFrom-Json
    Write-Host ("Register: {0}" -f $RegisterPath) -ForegroundColor DarkGray
} else {
    Write-Host "No -RegisterPath supplied; using bundled sample desired state." -ForegroundColor Yellow
    $desired = [pscustomobject]@{
        lockoutThreshold       = 10
        lockoutDurationSeconds = 60
        mfaPolicyName          = 'MACLOCK CA - Require MFA - Mac Pilot'
    }
}

Connect-MgGraph -Scopes 'AuditLog.Read.All','Policy.Read.All','Directory.Read.All' -NoWelcome
$gaps = 0

Write-Host "`n=== Smart Lockout ===" -ForegroundColor Cyan
try {
    $settings = Invoke-MgGraphRequest -Method GET -Uri "/beta/settings"
    $pp = $settings.value | Where-Object { $_.displayName -eq 'Password Rule Settings' }
    $threshold = if ($pp) { ($pp.values | Where-Object { $_.name -eq 'LockoutThreshold' }).value } else { $null }
    $duration  = if ($pp) { ($pp.values | Where-Object { $_.name -eq 'LockoutDurationInSeconds' }).value } else { $null }

    if ("$threshold" -eq "$($desired.lockoutThreshold)") {
        Write-Host ("  MATCH  Lockout threshold = {0}" -f $threshold) -ForegroundColor Green
    } else {
        Write-Host ("  GAP    Lockout threshold: desired {0}, current {1}" -f $desired.lockoutThreshold, $threshold) -ForegroundColor Red; $gaps++
    }
    if ("$duration" -eq "$($desired.lockoutDurationSeconds)") {
        Write-Host ("  MATCH  Lockout duration (s) = {0}" -f $duration) -ForegroundColor Green
    } else {
        Write-Host ("  GAP    Lockout duration (s): desired {0}, current {1}" -f $desired.lockoutDurationSeconds, $duration) -ForegroundColor Red; $gaps++
    }
} catch {
    Write-Host ("  GAP    Could not read Smart Lockout: {0}" -f $_.Exception.Message) -ForegroundColor Red; $gaps++
}

Write-Host "`n=== MFA Conditional Access policy ===" -ForegroundColor Cyan
try {
    $caps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identity/conditionalAccess/policies").value
    $p = $caps | Where-Object { $_.displayName -eq $desired.mfaPolicyName }
    if ($p -and $p.state -eq 'enabled') {
        Write-Host ("  MATCH  '{0}' is enabled" -f $desired.mfaPolicyName) -ForegroundColor Green
    } elseif ($p) {
        Write-Host ("  GAP    '{0}' exists but state = {1} (want enabled)" -f $desired.mfaPolicyName, $p.state) -ForegroundColor Red; $gaps++
    } else {
        Write-Host ("  GAP    '{0}' not found" -f $desired.mfaPolicyName) -ForegroundColor Red; $gaps++
    }
} catch {
    Write-Host ("  GAP    Could not read Conditional Access: {0}" -f $_.Exception.Message) -ForegroundColor Red; $gaps++
}

Write-Host "`n=== Mac-originated failures (last $Days day[s]) ===" -ForegroundColor Cyan
try {
    $since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $uri = "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since and status/errorCode ne 0&`$top=1000"
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $signIns = @($page.value)
    while ($page.'@odata.nextLink') { $page = Invoke-MgGraphRequest -Method GET -Uri $page.'@odata.nextLink'; $signIns += $page.value }
    $mac = $signIns | Where-Object { $_.deviceDetail.operatingSystem -and ($_.deviceDetail.operatingSystem -match 'mac|os ?x') }
    Write-Host ("  macOS-originated failures in window: {0}" -f @($mac).Count)
    Write-Host "  Compare against the pre-remediation baseline recorded in Implementation Step 2." -ForegroundColor DarkGray
} catch {
    Write-Host ("  Could not read sign-in logs: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host ("`nSummary: {0} configuration gap(s)." -f $gaps) -ForegroundColor Cyan
if ($gaps -gt 0) {
    Write-Host "Work the gaps via the Implementation Guide; preview safe fixes with MACLOCK-Remediation.ps1 -WhatIf." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
