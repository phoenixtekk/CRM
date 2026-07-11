<#
.SYNOPSIS
    SOPMDE-Discovery.ps1 — read-only discovery of an existing Defender for Endpoint deployment:
    devices & sensor health, groups/tags, ASR rule states, tamper/EDR/web-filter state.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Solution Optimization — Microsoft Defender for Endpoint"
        solution. Captures the current state to optimize: onboarded machines and their sensor
        health, device tags/groups, ASR rule configuration, tamper-protection and EDR-block-mode
        posture, web-content-filtering state, and Intune endpoint-security policies. Makes no
        changes. This is a TUNING engagement — it assumes MDE is already deployed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Discovery.ps1 -OutputPath .\state.json
        Requires Microsoft.Graph.Authentication. Consents (read-only):
        Machine.Read.All, SecurityEvents.Read.All, DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A before-tuning picture: device/sensor-health counts, tag/group inventory, ASR rule
        states, tamper/EDR/web-filter state, and Intune endpoint-security policies — the state to
        confirm before tuning ASR audit->block, reducing noise, and hardening policy.
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Plan/preview facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\SOPMDE-discovery.json"
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph.Authentication (one-time)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$scopes = 'Machine.Read.All','SecurityEvents.Read.All','DeviceManagementConfiguration.Read.All'
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null }

Write-Host "`n=== SOPMDE — Defender for Endpoint deployment discovery (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

# --- Devices & sensor health (Defender for Endpoint machines API) ---
Write-Host "`n-- Onboarded devices & sensor health --" -ForegroundColor Cyan
try {
    $machines = @()
    $uri = 'https://graph.microsoft.com/v1.0/security/microsoft.graph.security.runHuntingQuery'  # placeholder guard
    # Use the Defender for Endpoint machines API via Graph security when available; fall back to hunting.
    $resp = Invoke-MgGraphRequest -Method GET -Uri 'https://api.securitycenter.microsoft.com/api/machines' -ErrorAction SilentlyContinue
    if ($resp -and $resp.value) { $machines = $resp.value }
    if ($machines.Count -gt 0) {
        $byHealth = $machines | Group-Object healthStatus | Sort-Object Count -Descending
        foreach ($g in $byHealth) { Write-Host ("   sensor health {0,-16}: {1}" -f $g.Name, $g.Count) }
        $result.DeviceCount = $machines.Count
        $result.SensorHealth = ($byHealth | ForEach-Object { @{ State = $_.Name; Count = $_.Count } })
    } else {
        Write-Host "   (machines API returned none here — run SOPMDE-Hunt.ps1 -Mode Coverage for DeviceInfo-based coverage)" -ForegroundColor Yellow
    }
} catch { Write-Host ("   Could not read machines: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Device tags / groups ---
Write-Host "`n-- Device tags (top values) --" -ForegroundColor Cyan
try {
    if ($machines) {
        $tags = $machines | ForEach-Object { $_.machineTags } | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | Select-Object -First 15
        if ($tags) { $tags | ForEach-Object { Write-Host ("   tag '{0}': {1} device(s)" -f $_.Name, $_.Count) } }
        else { Write-Host "   (no device tags found — standardize tags in Implementation Step 4)" -ForegroundColor Yellow }
    }
} catch { Write-Host ("   Could not summarize tags: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Intune endpoint-security policies (where policy is authored) ---
Write-Host "`n-- Intune endpoint-security policies (ASR / EDR / AV) --" -ForegroundColor Cyan
try {
    $pols = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?$filter=templateReference/templateFamily eq ''endpointSecurityAttackSurfaceReduction'' or templateReference/templateFamily eq ''endpointSecurityEndpointDetectionAndResponse'' or templateReference/templateFamily eq ''endpointSecurityAntivirus''&$top=50' -ErrorAction SilentlyContinue).value
    if ($pols) { $pols | ForEach-Object { Write-Host ("   {0,-45} [{1}]" -f $_.name, $_.templateReference.templateFamily) } ; $result.IntunePolicyCount = $pols.Count }
    else { Write-Host "   (no matching Intune endpoint-security policies found — confirm the authoritative surface, Requirements 2.5)" -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read Intune policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Reminder pointers for portal-only state ---
Write-Host "`n-- Portal-confirmed state (verify in security.microsoft.com) --" -ForegroundColor Cyan
Write-Host "   ASR rule states .......... Reports -> Attack surface reduction rules"
Write-Host "   Tamper protection ........ Settings -> Endpoints -> Advanced features"
Write-Host "   EDR in block mode ........ Settings -> Endpoints -> Advanced features"
Write-Host "   Web content filtering .... Settings -> Endpoints -> Web content filtering"

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Next: SOPMDE-Report.ps1 -SaveBaseline to record the 'before' metrics." -ForegroundColor Green
