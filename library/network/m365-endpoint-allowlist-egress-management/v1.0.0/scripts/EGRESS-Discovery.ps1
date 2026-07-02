<#
.SYNOPSIS
    EGRESS-Discovery.ps1 — derive the current Microsoft required IP/Port/URL endpoint set and capture current filter state.
.DESCRIPTION
    PURPOSE
        Pulls the current required IP/Port/URL set from the Microsoft 365 IP Address and URL web
        service for your tenant instance, adds the documented Intune, Autopilot, and Defender
        endpoints, and writes one normalized required-set file. Optionally compares the web-service
        version against a saved baseline to detect drift. Read-only: it changes nothing on any device.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESS-Discovery.ps1 -Instance Worldwide -OutputPath .\EGRESS-Output
        Needs outbound HTTPS to the Microsoft 365 endpoints web service. No admin rights required.
        Add -BaselineVersionPath to detect drift; add -CurrentRulesetPath to summarize an exported ruleset.
    EXPECTED RESULTS
        Writes egress-required-set.json and egress-baseline-version.json to the output folder and
        prints a summary (endpoint-set count, required/Optimize/Allow counts, drift status). PASS =
        required-set file written for the correct instance; FAIL = web service unreachable or wrong instance.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [ValidateSet('Worldwide', 'USGOVGCCHigh', 'USGOVDoD', 'China')]
    [string]$Instance = 'Worldwide',

    [string]$OutputPath = '.\EGRESS-Output',

    [string]$BaselineVersionPath,

    [string]$CurrentRulesetPath
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Text)
    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 70) -ForegroundColor Cyan
}

# Stable client GUID for the web service (any GUID; identifies the caller session).
$clientRequestId = [guid]::NewGuid().ToString()
$svcRoot = 'https://endpoints.office.com'

if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Section "EGRESS Discovery — instance: $Instance"

# --- 1. Query the version operation (drift detection) ------------------------
Write-Host 'Querying Microsoft 365 endpoints web service version...' -ForegroundColor Gray
$versionUrl = "$svcRoot/version/$Instance`?clientRequestId=$clientRequestId"
try {
    $currentVersion = Invoke-RestMethod -Uri $versionUrl -Method Get -UseBasicParsing
}
catch {
    throw "Could not reach the Microsoft 365 endpoints web service version operation at $versionUrl. Confirm outbound HTTPS is permitted from this host (Requirement R2). Underlying error: $($_.Exception.Message)"
}

$currentVersionValue = $currentVersion.latest
Write-Host "  Current published version: $currentVersionValue" -ForegroundColor Green

$driftStatus = 'baseline-not-provided'
if ($BaselineVersionPath -and (Test-Path -LiteralPath $BaselineVersionPath)) {
    try {
        $baseline = Get-Content -LiteralPath $BaselineVersionPath -Raw | ConvertFrom-Json
        if ($baseline.version -eq $currentVersionValue) {
            $driftStatus = 'no-change'
            Write-Host "  Drift check: NO CHANGE since baseline ($($baseline.version))." -ForegroundColor Green
        }
        else {
            $driftStatus = 'changed'
            Write-Host "  Drift check: CHANGED. Baseline=$($baseline.version) Current=$currentVersionValue" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "Could not read baseline version file '$BaselineVersionPath': $($_.Exception.Message)"
    }
}

# --- 2. Query the endpoints operation ---------------------------------------
Write-Host 'Querying Microsoft 365 required endpoints...' -ForegroundColor Gray
$endpointsUrl = "$svcRoot/endpoints/$Instance`?clientRequestId=$clientRequestId"
try {
    $endpoints = Invoke-RestMethod -Uri $endpointsUrl -Method Get -UseBasicParsing
}
catch {
    throw "Could not reach the Microsoft 365 endpoints operation at $endpointsUrl. Underlying error: $($_.Exception.Message)"
}

# Normalize each endpoint set into a consistent shape.
$m365Sets = foreach ($e in $endpoints) {
    [pscustomobject]@{
        id           = $e.id
        serviceArea  = $e.serviceArea
        category     = $e.category
        required     = [bool]$e.required
        urls         = @($e.urls)
        ips          = @($e.ips)
        tcpPorts     = $e.tcpPorts
        udpPorts     = $e.udpPorts
        notes        = $e.notes
        source       = 'm365-web-service'
    }
}

$requiredCount  = ($m365Sets | Where-Object { $_.required }).Count
$optimizeCount  = ($m365Sets | Where-Object { $_.category -eq 'Optimize' }).Count
$allowCount     = ($m365Sets | Where-Object { $_.category -eq 'Allow' }).Count
$defaultCount   = ($m365Sets | Where-Object { $_.category -eq 'Default' }).Count

Write-Host "  Endpoint sets returned: $($m365Sets.Count)" -ForegroundColor Green
Write-Host "  required=$requiredCount  Optimize=$optimizeCount  Allow=$allowCount  Default=$defaultCount" -ForegroundColor Green

# --- 3. Documented Intune / Autopilot / Defender endpoints -------------------
# The M365 web service covers M365 (incl. the common/identity area Entra uses). The endpoints below
# are the documented host names/ports that complete the required set for device management and are
# not all returned by the web service. These are host names (NOT IP addresses) so nothing here is a
# hardcoded IP — confirm against Microsoft's current Intune/Defender endpoint documentation.
$deviceMgmtEndpoints = @(
    [pscustomobject]@{ area = 'Intune';    urls = @('*.manage.microsoft.com'); tcpPorts = '443'; notes = 'Intune device enrollment and management check-in.' }
    [pscustomobject]@{ area = 'Intune';    urls = @('enterpriseregistration.windows.net'); tcpPorts = '443'; notes = 'Device registration for enrollment.' }
    [pscustomobject]@{ area = 'Autopilot'; urls = @('ztd.dds.microsoft.com','cs.dds.microsoft.com'); tcpPorts = '443'; notes = 'Autopilot deployment service (depends also on Entra + Intune + Windows endpoints).' }
    [pscustomobject]@{ area = 'Defender';  urls = @('*.wdcp.microsoft.com','*.wdcpalt.microsoft.com','*.wd.microsoft.com','*.endpoint.security.microsoft.com'); tcpPorts = '443'; notes = 'Defender cloud-delivered protection, sample submission, telemetry.' }
    [pscustomobject]@{ area = 'Windows';   urls = @('*.update.microsoft.com','*.delivery.mp.microsoft.com','*.windowsupdate.com'); tcpPorts = '443,80'; notes = 'Windows Update / content delivery.' }
)
foreach ($d in $deviceMgmtEndpoints) { $d | Add-Member -NotePropertyName source -NotePropertyValue 'documented-device-management' -Force }

Write-Host "  Device-management endpoints (Intune/Autopilot/Defender/Windows): $($deviceMgmtEndpoints.Count) groups" -ForegroundColor Green

# --- 4. Optional: summarize an exported current ruleset ----------------------
$rulesetSummary = $null
if ($CurrentRulesetPath -and (Test-Path -LiteralPath $CurrentRulesetPath)) {
    $lines = Get-Content -LiteralPath $CurrentRulesetPath
    $rulesetSummary = [pscustomobject]@{
        path       = (Resolve-Path -LiteralPath $CurrentRulesetPath).Path
        lineCount  = $lines.Count
        capturedAt = (Get-Date).ToString('o')
    }
    Write-Host "  Current ruleset captured: $($rulesetSummary.lineCount) lines from $($rulesetSummary.path)" -ForegroundColor Green
}

# --- 5. Write outputs -------------------------------------------------------
$requiredSet = [pscustomobject]@{
    generatedAt              = (Get-Date).ToString('o')
    instance                 = $Instance
    webServiceVersion        = $currentVersionValue
    driftStatus              = $driftStatus
    counts                   = [pscustomobject]@{ endpointSets = $m365Sets.Count; required = $requiredCount; optimize = $optimizeCount; allow = $allowCount; default = $defaultCount }
    m365Endpoints            = $m365Sets
    deviceManagementEndpoints = $deviceMgmtEndpoints
    currentRulesetSummary    = $rulesetSummary
}

$requiredSetPath = Join-Path $OutputPath 'egress-required-set.json'
$requiredSet | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $requiredSetPath -Encoding UTF8
Write-Host "  Wrote required set: $requiredSetPath" -ForegroundColor Green

$baselineOut = [pscustomobject]@{ instance = $Instance; version = $currentVersionValue; capturedAt = (Get-Date).ToString('o') }
$baselineOutPath = Join-Path $OutputPath 'egress-baseline-version.json'
$baselineOut | ConvertTo-Json | Set-Content -LiteralPath $baselineOutPath -Encoding UTF8
Write-Host "  Wrote baseline version: $baselineOutPath" -ForegroundColor Green

Write-Section 'Discovery complete'
Write-Host "Instance     : $Instance"
Write-Host "Version      : $currentVersionValue"
Write-Host "Drift status : $driftStatus"
Write-Host "Required set : $requiredSetPath"
Write-Host ''
Write-Host 'Next: build the allow-list with EGRESS-Remediation.ps1 (preview), then validate with EGRESS-Validation.ps1.' -ForegroundColor Gray
