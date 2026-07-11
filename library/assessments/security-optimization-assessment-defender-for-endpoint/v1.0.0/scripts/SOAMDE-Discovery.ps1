<#
.SYNOPSIS
    SOAMDE-Discovery.ps1 — read-only collection of the full Defender for Endpoint configuration into a dated run folder.
.DESCRIPTION
    PURPOSE
        Builds the raw evidence base the scoring and coverage passes consume. For the in-scope fleet it
        collects, read-only: device inventory with onboarding status and sensor health; next-generation
        protection settings and EDR block-mode state; attack surface reduction (ASR) rule states;
        tamper protection; web/network protection; the delivery policies (Intune endpoint security
        policies / baselines) that set these; and the exposure & endpoint Secure Score signals. Nothing
        is changed. Every area is written as JSON/CSV so the run is reproducible and auditable.
    HOW TO RUN
        pwsh -File .\SOAMDE-Discovery.ps1 -ScopeFile ".\SOAMDE-Scope - Fleet - Assess.json" -OutputDir ".\SOAMDE-Run - 2026-07-11 - Assess"
        Run SOAMDE-Validate.ps1 first. Requires read scopes (Security Reader / Global Reader + MDE read).
        Uses Microsoft Graph security + device management read APIs and advanced hunting (KQL).
        *Verify current API hosts, permission names, and RBAC model.*
    EXPECTED RESULTS
        A populated run folder with one file per area plus a discovery-manifest.json. Read-only — no changes.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ScopeFile,
    [Parameter(Mandatory = $true)] [string]$OutputDir,
    [string[]]$ReadScopes = @('SecurityEvents.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$scope = if (Test-Path $ScopeFile) { Get-Content $ScopeFile -Raw | ConvertFrom-Json } else { @{ description = 'unspecified'; expectedDeviceCount = 0; baseline = 'Microsoft security baseline + Secure Score (verify)' } }
Write-Host "SOAMDE discovery (read-only) -> $OutputDir`n" -ForegroundColor Cyan

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes $ReadScopes -NoWelcome -ErrorAction Stop

function Save-Area([string]$Name, [object]$Data) {
    $path = Join-Path $OutputDir "$Name.json"
    $Data | ConvertTo-Json -Depth 12 | Set-Content -Path $path -Encoding UTF8
    $count = if ($Data -is [System.Array]) { $Data.Count } elseif ($null -ne $Data) { 1 } else { 0 }
    Write-Host ("  {0,-28} {1,6} record(s) -> {2}" -f $Name, $count, (Split-Path $path -Leaf))
    return $count
}

function Invoke-GraphPaged([string]$Uri) {
    $items = @()
    $next = $Uri
    while ($next) {
        try { $resp = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop }
        catch { Write-Host "    (read failed for $next : $($_.Exception.Message))" -ForegroundColor Yellow; break }
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

function Invoke-Hunt([string]$Kql) {
    try {
        $body = @{ Query = $Kql } | ConvertTo-Json
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json' -ErrorAction Stop
        return $r.results
    } catch { Write-Host "    (hunting query failed: $($_.Exception.Message))" -ForegroundColor Yellow; return @() }
}

$manifest = [ordered]@{ tool = 'SOAMDE-Discovery'; runDate = (Get-Date).ToString('s'); scope = $scope; areas = @{} }

# --- 1. Devices, onboarding & sensor health ---------------------------------
# MDE machines carry onboardingStatus and health state. Cross-check with advanced hunting DeviceInfo.
$machines = Invoke-GraphPaged 'https://graph.microsoft.com/v1.0/security/microsoftDefenderForEndpoint/machines?$top=1000'
$manifest.areas['devices'] = Save-Area 'devices' $machines

$onboardKql = @'
DeviceInfo
| summarize arg_max(Timestamp, OnboardingStatus, SensorHealthState, OSPlatform) by DeviceId, DeviceName
| summarize DeviceCount = count() by OnboardingStatus, SensorHealthState
'@
$manifest.areas['onboarding-summary'] = Save-Area 'onboarding-summary' (Invoke-Hunt $onboardKql)

# --- 2. ASR rules state (per device) via secure configuration assessment -----
# DeviceTvmSecureConfigurationAssessment carries per-config compliance; ASR + tamper appear here.
$asrKql = @'
DeviceTvmSecureConfigurationAssessment
| where ConfigurationCategory in ("Attack Surface Reduction Rules","Network protection","Defender")
| summarize Devices = dcount(DeviceId) by ConfigurationId, ConfigurationName, IsCompliant, ConfigurationCategory
'@
$manifest.areas['asr-tamper-config'] = Save-Area 'asr-tamper-config' (Invoke-Hunt $asrKql)

# --- 3. ASR audit-vs-block signal from DeviceEvents (rules firing in audit) ---
$asrEventsKql = @'
DeviceEvents
| where ActionType startswith "Asr"
| where Timestamp > ago(30d)
| summarize Events = count(), Devices = dcount(DeviceId) by ActionType
'@
$manifest.areas['asr-events'] = Save-Area 'asr-events' (Invoke-Hunt $asrEventsKql)

# --- 4. Delivery policies (Intune endpoint security / config) ----------------
# Read-only enumeration of the configuration policies that deliver AV/ASR/tamper/EDR settings.
$intunePolicies = Invoke-GraphPaged 'https://graph.microsoft.com/v1.0/deviceManagement/configurationPolicies?$top=200'
$manifest.areas['delivery-policies'] = Save-Area 'delivery-policies' $intunePolicies

$intuneIntents = Invoke-GraphPaged 'https://graph.microsoft.com/v1.0/deviceManagement/intents?$top=200'
$manifest.areas['security-baselines'] = Save-Area 'security-baselines' $intuneIntents

# --- 5. Exposure score & endpoint security recommendations -------------------
try {
    $exposure = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/security/microsoftDefenderForEndpoint/exposureScore' -ErrorAction Stop
} catch { $exposure = @{ note = "exposureScore read failed: $($_.Exception.Message) *verify API path*" } }
$manifest.areas['exposure-score'] = Save-Area 'exposure-score' $exposure

$secureScore = Invoke-GraphPaged 'https://graph.microsoft.com/v1.0/security/secureScores?$top=1'
$manifest.areas['secure-score'] = Save-Area 'secure-score' $secureScore
$secureControls = Invoke-GraphPaged 'https://graph.microsoft.com/v1.0/security/secureScoreControlProfiles?$top=200'
$manifest.areas['secure-score-controls'] = Save-Area 'secure-score-controls' $secureControls

# --- Manifest ----------------------------------------------------------------
$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutputDir 'discovery-manifest.json') -Encoding UTF8
Write-Host "`nDiscovery complete — raw evidence in '$OutputDir'. Read-only; no changes made." -ForegroundColor Green
Write-Host "Next: SOAMDE-Coverage.ps1 then SOAMDE-Assess.ps1." -ForegroundColor Green
