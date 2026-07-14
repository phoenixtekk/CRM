<#
.SYNOPSIS
    MDEPROXY-FeatureImpact.ps1 — read-only enumeration of the network-dependent Defender surface
    exposed to proxy-induced destination obfuscation (detections, hunts, TI indicators).
.DESCRIPTION
    PURPOSE
        Seeds the feature-impact matrix. Read-only, it enumerates: custom detection rules whose query
        references RemoteIP / RemoteUrl / RemotePort (directly exposed to obfuscation), and the custom
        threat-intelligence indicators of type IP / URL / Domain (whose endpoint-layer matching depends
        on true-remote visibility). It also prints the portal-only checks for Network Protection and
        SmartScreen state. It does NOT assert Microsoft's feature behavior — those cells stay
        'confirm with Microsoft' in the matrix. Changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEPROXY-FeatureImpact.ps1
        Needs ThreatHunting.Read.All (+ ThreatIndicators.Read.All / relevant read scope for indicators).
        Some inventories may require the Defender/Graph Security beta endpoint — verify current API.
        Government cloud: pass -Environment.
    EXPECTED RESULTS
        MDEPROXY-feature-impact.json — the list of exposed custom detections/hunts and IP/URL/domain
        indicators, plus the manual NP/SmartScreen checks, to paste into the feature-impact matrix.
.NOTES
    White-label. Read-only. Enumerates configuration only. Microsoft-authoritative feature behavior is
    obtained via the advisory case, not asserted here. Verify current indicator/detection API paths.
#>
[CmdletBinding()]
param(
    [string[]]$Sample,
    [string]$OutputPath = ".\MDEPROXY-feature-impact.json",
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('ThreatHunting.Read.All','ThreatIndicators.ReadWrite.OwnedBy','SecurityEvents.Read.All')
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -Environment $Environment -NoWelcome | Out-Null }

Write-Host "`n=== MDEPROXY — network-dependent feature/detection enumeration (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); ReadOnly = $true }

# --- Custom TI indicators of type IP / URL / Domain (endpoint-layer matching depends on true remote)
Write-Host "`n-- Custom TI indicators (IP / URL / Domain) exposed to obfuscation --" -ForegroundColor Cyan
$indUris = @(
    'https://graph.microsoft.com/beta/security/tiIndicators',
    'https://graph.microsoft.com/v1.0/security/tiIndicators'
)
$indicators = $null
foreach ($u in $indUris) {
    try { $indicators = Invoke-MgGraphRequest -Method GET -Uri $u -ErrorAction Stop; if ($indicators) { break } }
    catch { Write-Host ("   ({0} unavailable: {1})" -f $u, $_.Exception.Message) -ForegroundColor DarkGray }
}
if ($indicators -and $indicators.value) {
    $netInd = $indicators.value | Where-Object { $_.networkDestinationIPv4 -or $_.networkDestinationIPv6 -or $_.url -or $_.domainName -or $_.networkIPv4 }
    Write-Host ("   Network-type indicators (IP/URL/Domain): {0}" -f (@($netInd).Count)) -ForegroundColor Yellow
    $netInd | Select-Object -First 25 | ForEach-Object {
        $val = @($_.networkDestinationIPv4, $_.networkDestinationIPv6, $_.networkIPv4, $_.url, $_.domainName | Where-Object { $_ }) -join ' '
        Write-Host ("     [{0}] {1}" -f $_.action, $val)
    }
    $result.NetworkIndicatorCount = @($netInd).Count
    $result.NetworkIndicators = @($netInd | Select-Object action, url, domainName, networkDestinationIPv4, networkDestinationIPv6)
    Write-Host "   NOTE: endpoint-layer matching of these depends on true-remote visibility — confirm behavior with Microsoft." -ForegroundColor DarkGray
} else {
    Write-Host "   No indicators returned (or API path differs in your cloud) — verify via Settings > Endpoints > Indicators." -ForegroundColor Yellow
}

# --- Custom detection rules referencing remote-destination fields
Write-Host "`n-- Custom detection rules referencing RemoteIP / RemoteUrl / RemotePort --" -ForegroundColor Cyan
$detUris = @(
    'https://graph.microsoft.com/beta/security/rules/detectionRules',
    'https://graph.microsoft.com/v1.0/security/rules/detectionRules'
)
$rules = $null
foreach ($u in $detUris) {
    try { $rules = Invoke-MgGraphRequest -Method GET -Uri $u -ErrorAction Stop; if ($rules) { break } }
    catch { Write-Host ("   ({0} unavailable: {1})" -f $u, $_.Exception.Message) -ForegroundColor DarkGray }
}
if ($rules -and $rules.value) {
    $exposed = $rules.value | Where-Object { $_.queryCondition.queryText -match 'RemoteIP|RemoteUrl|RemotePort' }
    Write-Host ("   Detection rules pivoting on remote destination: {0}" -f (@($exposed).Count)) -ForegroundColor Yellow
    $exposed | ForEach-Object { Write-Host ("     {0}" -f $_.displayName) }
    $result.ExposedDetectionRules = @($exposed | Select-Object id, displayName)
} else {
    Write-Host "   No detection rules returned (or API path differs) — verify via Hunting > Custom detection rules." -ForegroundColor Yellow
    Write-Host "   Manually review any rule whose KQL uses RemoteIP/RemoteUrl/RemotePort — those inherit the obfuscation." -ForegroundColor DarkGray
}

# --- Portal-only feature state (read-only checks; NOT asserted as impacted here)
Write-Host "`n-- Portal-only feature checks (record state; impact = confirm with Microsoft) --" -ForegroundColor Cyan
Write-Host "   Network Protection : Settings > Endpoints > Advanced features (and Intune ASR/NP policy) — record On/Audit/Off" -ForegroundColor DarkGray
Write-Host "   SmartScreen        : Edge/Defender SmartScreen policy state — record configured/enforced" -ForegroundColor DarkGray
Write-Host "   Web content filter : Settings > Endpoints > Web content filtering — record active policies (P2)" -ForegroundColor DarkGray
Write-Host "   => For each, the QUESTION 'does loopback-forward steering change evaluation?' goes to the advisory case." -ForegroundColor DarkGray

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nFeature enumeration complete (read-only). Output: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host  "Paste into 'MDEPROXY Feature-Impact Matrix - Tenant - Validate'; keep the 'Confirm with Microsoft' column open." -ForegroundColor DarkGray
