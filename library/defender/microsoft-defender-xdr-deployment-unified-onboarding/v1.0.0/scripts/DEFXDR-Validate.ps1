<#
.SYNOPSIS
    DEFXDR-Validate.ps1 — per-pillar validation that each Defender XDR pillar is onboarded and
    unified RBAC is in place. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Microsoft Defender XDR Deployment & Unified Onboarding"
        solution. For the pillar you name, confirms the onboarding signal:
          Endpoint   — devices reporting in advanced hunting (DeviceInfo)
          Identity   — identity signal present (IdentityInfo)
          Office365  — email signal present (EmailEvents)
          CloudApps  — cloud-app signal present (CloudAppEvents)
          RBAC       — unified role assignments discoverable (informational)
        Uses the Microsoft 365 Defender advanced-hunting API via Microsoft Graph Security.
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFXDR-Validate.ps1 -Pillar Endpoint
        powershell -ExecutionPolicy Bypass -File .\DEFXDR-Validate.ps1 -Pillar Identity
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A pass/fail line per pillar: whether recent signal exists in the corresponding hunting
        table (or, for RBAC, guidance to confirm unified roles in the portal).
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Endpoint','Identity','Office365','CloudApps','RBAC')]
    [string]$Pillar,
    [int]$LookbackHours = 24
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}

Write-Host "`n=== DEFXDR validation — pillar: $Pillar (read-only) ===" -ForegroundColor Cyan

if ($Pillar -eq 'RBAC') {
    Write-Host "Unified RBAC check (informational):" -ForegroundColor Cyan
    Write-Host "  In security.microsoft.com -> System -> Permissions and roles, confirm the role assignments" -ForegroundColor Gray
    Write-Host "  'XDR Security Reader - Tenant - Prod' and 'XDR Security Operator - Tenant - Prod' exist and" -ForegroundColor Gray
    Write-Host "  that per-pillar permissions are consolidated under unified RBAC." -ForegroundColor Gray
    Write-Host "PASS criteria: one unified role model governs all four pillars." -ForegroundColor Green
    return
}

$table = switch ($Pillar) {
    'Endpoint'  { 'DeviceInfo' }
    'Identity'  { 'IdentityInfo' }
    'Office365' { 'EmailEvents' }
    'CloudApps' { 'CloudAppEvents' }
}

# KQL: count rows in the pillar's table over the lookback window.
$kql = @"
$table
| where Timestamp > ago(${LookbackHours}h)
| summarize Rows = count()
"@

try {
    $resp = Invoke-Hunt $kql
    $rows = 0
    if ($resp.results -and $resp.results.Count -gt 0) { $rows = [int]$resp.results[0].Rows }
    Write-Host ("Table {0}: {1} row(s) in the last {2}h" -f $table, $rows, $LookbackHours)
    if ($rows -gt 0) {
        Write-Host ("PASS — {0} pillar is streaming signal." -f $Pillar) -ForegroundColor Green
    } else {
        Write-Host ("FAIL — no recent {0} signal. Confirm onboarding and allow warm-up time." -f $Pillar) -ForegroundColor Yellow
        Write-Host "See Troubleshooting for this pillar." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("Could not run hunting query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm ThreatHunting.Read.All consent and that the pillar is activated." -ForegroundColor Yellow
}
