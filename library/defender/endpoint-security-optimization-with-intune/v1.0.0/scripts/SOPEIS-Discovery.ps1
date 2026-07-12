<#
.SYNOPSIS
    SOPEIS-Discovery.ps1 — read-only discovery of an existing Intune endpoint-security estate:
    policies, assignments, security-baseline versions, compliance policies, and coverage.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Solution Optimization — Endpoint Security with Microsoft
        Intune" solution. Inventories the endpoint-security and compliance policies, their
        assignments, applied security-baseline versions, and per-policy assignment coverage so you
        can see what to tune before migrating baselines, resolving conflicts, and expanding
        coverage. Makes no changes. This is a TUNING engagement — it assumes Intune endpoint
        security is already deployed and applying.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Discovery.ps1 -OutputPath .\state.json
        Requires Microsoft.Graph.Authentication. Consents (read-only):
        DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A before-tuning inventory: endpoint-security policies + assignments, security-baseline
        versions (and whether newer exist), compliance policies + assignments, and groups — the
        state to confirm before tuning.
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Plan/baseline-version facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\SOPEIS-discovery.json"
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph.Authentication (one-time)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome | Out-Null }

Write-Host "`n=== SOPEIS — Intune endpoint-security estate discovery (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

function Get-All($uri) {
    $items = @()
    while ($uri) {
        $r = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        if ($r.value) { $items += $r.value }
        $uri = $r.'@odata.nextLink'
    }
    return $items
}

# --- Endpoint-security / configuration policies (settings-catalog + intents) ---
Write-Host "`n-- Endpoint-security & configuration policies --" -ForegroundColor Cyan
try {
    $confPols = Get-All 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?$expand=assignments&$top=100'
    foreach ($p in $confPols) {
        $asn = if ($p.assignments) { $p.assignments.Count } else { 0 }
        Write-Host ("   {0,-48} assignments: {1}" -f $p.name, $asn)
    }
    $result.ConfigurationPolicyCount = $confPols.Count
    $result.UnassignedConfigPolicies = ($confPols | Where-Object { -not $_.assignments -or $_.assignments.Count -eq 0 }).name
} catch { Write-Host ("   Could not read configuration policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Security baselines (intents) and their versions ---
Write-Host "`n-- Security baselines (versions) --" -ForegroundColor Cyan
try {
    $templates = Get-All 'https://graph.microsoft.com/beta/deviceManagement/templates?$filter=(templateType eq ''securityBaseline'') or (templateType eq ''advancedThreatProtectionSecurityBaseline'')'
    $intents = Get-All 'https://graph.microsoft.com/beta/deviceManagement/intents?$top=100'
    foreach ($i in $intents) {
        $tmpl = $templates | Where-Object { $_.id -eq $i.templateId } | Select-Object -First 1
        if ($tmpl) { Write-Host ("   {0,-40} baseline v{1}" -f $i.displayName, $tmpl.versionInfo) }
    }
    $result.BaselineIntentCount = $intents.Count
    Write-Host "   (Compare each applied version to the latest in Endpoint security -> Security baselines. Verify current.)" -ForegroundColor DarkGray
} catch { Write-Host ("   Could not read baselines: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Compliance policies ---
Write-Host "`n-- Device compliance policies --" -ForegroundColor Cyan
try {
    $comp = Get-All 'https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies?$expand=assignments&$top=100'
    foreach ($c in $comp) {
        $asn = if ($c.assignments) { $c.assignments.Count } else { 0 }
        Write-Host ("   {0,-48} assignments: {1}" -f $c.displayName, $asn)
    }
    $result.CompliancePolicyCount = $comp.Count
    $result.UnassignedCompliancePolicies = ($comp | Where-Object { -not $_.assignments -or $_.assignments.Count -eq 0 }).displayName
} catch { Write-Host ("   Could not read compliance policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Managed device count (coverage denominator) ---
Write-Host "`n-- Managed devices (coverage denominator) --" -ForegroundColor Cyan
try {
    $devCount = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/managedDevices/$count' -Headers @{ ConsistencyLevel = 'eventual' } -ErrorAction SilentlyContinue)
    Write-Host ("   Managed devices: {0}" -f $devCount)
    $result.ManagedDeviceCount = $devCount
} catch { Write-Host ("   Could not read device count: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Next: SOPEIS-ConflictReport.ps1 and SOPEIS-Report.ps1 -SaveBaseline for the 'before' state." -ForegroundColor Green
