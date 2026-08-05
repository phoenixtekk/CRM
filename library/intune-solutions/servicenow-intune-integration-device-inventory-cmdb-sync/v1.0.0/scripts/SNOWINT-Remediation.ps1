<#
.SYNOPSIS
    SNOWINT-Remediation.ps1 — guarded fix for a missing/expired app-registration secret or scope.
.DESCRIPTION
    PURPOSE
        The most common cause of a dead ServiceNow feed is the Entra app's client secret expiring or
        a required Graph scope not being consented. This script DIAGNOSES that (reports secrets near
        or past expiry and which expected app-role scopes are missing) and, only with -Apply, will
        create a fresh client secret so you can update the ServiceNow connection. It NEVER deletes an
        existing secret and NEVER grants consent silently.
    HOW TO RUN
        Diagnose (default, -WhatIf-safe, no changes):
          powershell -ExecutionPolicy Bypass -File .\SNOWINT-Remediation.ps1 -AppId <client-id> [-Cloud Global|USGov|USGovDoD]
        Create a new secret (explicit opt-in):
          .\SNOWINT-Remediation.ps1 -AppId <client-id> -Apply -SecretMonths 24
        Requires Microsoft.Graph SDK and Application.ReadWrite.All (for -Apply) — an admin action.
    EXPECTED RESULTS
        A report of secret expiry + missing scopes. With -Apply, a NEW client secret value printed
        once (store it, then paste into the ServiceNow connection). Consent for any missing scope is
        surfaced as a manual step (by design) — grant it in the Entra portal.
.NOTES
    Intune Solutions. Read-only by default; -Apply performs ONE additive change (new secret) with
    ShouldProcess. Cloud-aware. Grant consent is intentionally left to a human in the portal.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)][string]$AppId,
    [switch]$Apply,
    [int]$SecretMonths = 24,
    [int]$WarnDays = 30,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Cloud = 'Global'
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Apply) { @('Application.ReadWrite.All') } else { @('Application.Read.All') }
Connect-MgGraph -Scopes $scopes -Environment $Cloud -NoWelcome

$base = switch ($Cloud) {
    'USGov'    { 'https://graph.microsoft.us' }
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    default    { 'https://graph.microsoft.com' }
}

# locate the app object
$app = (Invoke-MgGraphRequest -Method GET -Uri "$base/v1.0/applications?`$filter=appId eq '$AppId'").value | Select-Object -First 1
if (-not $app) { Write-Host "App with appId $AppId not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; exit 1 }
Write-Host "=== SNOWINT Remediation — $($app.displayName) ($Cloud) ===" -ForegroundColor Cyan

# secret expiry check
$now = Get-Date
foreach ($pc in @($app.passwordCredentials)) {
    $end = [datetime]$pc.endDateTime
    $days = [int]($end - $now).TotalDays
    $color = if ($days -lt 0) {'Red'} elseif ($days -le $WarnDays) {'Yellow'} else {'Green'}
    Write-Host ("  Secret '{0}' expires {1:yyyy-MM-dd} ({2} days)" -f $pc.displayName,$end,$days) -ForegroundColor $color
}

# expected app-role scopes (Graph = resourceAppId 00000003-0000-0000-c000-000000000000)
$expected = 'DeviceManagementManagedDevices.Read.All','DeviceManagementApps.Read.All','DeviceManagementServiceConfig.Read.All','Directory.Read.All'
$graphRRA = @($app.requiredResourceAccess | Where-Object { $_.resourceAppId -eq '00000003-0000-0000-c000-000000000000' })
$sp = (Invoke-MgGraphRequest -Method GET -Uri "$base/v1.0/servicePrincipals?`$filter=appId eq '00000003-0000-0000-c000-000000000000'").value | Select-Object -First 1
$roleMap = @{}; foreach ($r in $sp.appRoles) { $roleMap[$r.id] = $r.value }
$declared = @()
foreach ($ra in $graphRRA.resourceAccess) { if ($ra.type -eq 'Role' -and $roleMap[$ra.id]) { $declared += $roleMap[$ra.id] } }
foreach ($s in $expected) {
    if ($declared -contains $s) { Write-Host "  PASS  scope declared: $s" -ForegroundColor Green }
    else { Write-Host "  MISSING scope: $s  -> add it in Entra > API permissions, then Grant admin consent" -ForegroundColor Yellow }
}

if ($Apply) {
    if ($PSCmdlet.ShouldProcess($app.displayName, "Add a new client secret ($SecretMonths months)")) {
        $body = @{ passwordCredential = @{ displayName = "ServiceNow CMDB feed (rotated $($now.ToString('yyyy-MM-dd')))"; endDateTime = $now.AddMonths($SecretMonths).ToString('o') } }
        $new = Invoke-MgGraphRequest -Method POST -Uri "$base/v1.0/applications/$($app.id)/addPassword" -Body ($body | ConvertTo-Json -Depth 5)
        Write-Host "`n  NEW SECRET (store now — shown once):" -ForegroundColor Green
        Write-Host "    $($new.secretText)" -ForegroundColor Green
        Write-Host "  Paste this into the ServiceNow Intune connection, then Test the connection." -ForegroundColor Cyan
        Write-Host "  The old secret was NOT deleted — remove it in Entra after ServiceNow is updated." -ForegroundColor Yellow
    }
} else {
    Write-Host "`n(Diagnose only. Re-run with -Apply to create a fresh secret. Consent for missing scopes is a manual portal step by design.)" -ForegroundColor Cyan
}
Disconnect-MgGraph | Out-Null
