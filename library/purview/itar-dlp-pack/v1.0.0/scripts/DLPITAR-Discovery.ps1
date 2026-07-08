<#
.SYNOPSIS
    DLPITAR-Discovery.ps1 — inventory existing DLP policies/rules, available SITs, and any technical-data classification (read-only; optional baseline).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and inventories the tenant's current Data Loss
        Prevention estate for the ITAR technical-data DLP pack: existing DLP policies and their modes,
        DLP rules, the sensitive-information-types available, any custom technical-data / export-controlled
        SIT already present, and (where readable) sensitivity labels that could key the DLP rule. Read-only:
        it changes nothing. With -SaveBaseline it writes a JSON baseline of policy names+modes; with
        -CompareBaseline it diffs the live estate against that baseline and reports drift (e.g. a policy
        silently moved to Disable).
    HOW TO RUN
        Inventory (read-only, default):
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Discovery.ps1
        Save a drift baseline once the estate is known-good:
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Discovery.ps1 -SaveBaseline
        Detect drift against the baseline:
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Discovery.ps1 -CompareBaseline

        Prereqs: ExchangeOnlineManagement module (Connect-IPPSSession) and an MFA-capable admin with at
        least read access to compliance policies (Requirement 2.2/2.3). For a sovereign cloud pass the
        matching -ConnectionUri (Commercial / GCC High / DoD). No credentials in code.
    EXPECTED RESULTS
        A summary: DLP policies with Mode, a count of available SITs with any technical-data/export match
        highlighted, readable sensitivity labels, and connectivity confirmation. PASS = the inventory
        prints without error. With -CompareBaseline, PASS = no unexplained drift.
.NOTES
    White-label. Read-only (baseline write is a local JSON file only). Security & Compliance PowerShell.
    No credentials in code. Verify capability availability against your licensing/tenant.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/',
    [string] $BaselinePath  = (Join-Path -Path (Get-Location) -ChildPath 'ITAR-DLP-Baseline.json'),
    [switch] $SaveBaseline,
    [switch] $CompareBaseline
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Text fragments that suggest a SIT / label / rule relates to export-controlled technical data.
$itarHints = @('ITAR', 'export', 'technical data', 'USML', 'munitions', 'distribution statement', 'controlled')

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    Write-Host 'Install ExchangeOnlineManagement and sign in with an MFA-capable admin, then retry.'
    return
}

# --- DLP policies + rules ---------------------------------------------------------------------------
Write-Section 'Existing DLP policies (Name / Mode / Workloads)'
$dlpPolicies = @()
try {
    $dlpPolicies = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    if ($dlpPolicies.Count -eq 0) {
        Write-Host 'No DLP policies found. This tenant has no DLP configured yet.' -ForegroundColor Yellow
    } else {
        $dlpPolicies | Select-Object Name, Mode, Enabled | Sort-Object Name | Format-Table -AutoSize
        $itarPolicies = $dlpPolicies | Where-Object { $blob = ($_ | Out-String); $itarHints | Where-Object { $blob -match [regex]::Escape($_) } }
        if ($itarPolicies) {
            Write-Host 'Policies that look ITAR/export-related (avoid duplicating these):' -ForegroundColor Green
            $itarPolicies | Select-Object Name, Mode | Format-Table -AutoSize
        } else {
            Write-Host 'No existing ITAR/export-related DLP policy detected — expected object to create:'
            Write-Host '  ITAR Technical-Data Egress - AllWorkloads - Pilot (see 03-implementation.md).'
        }
    }
}
catch {
    Write-Warning ("Could not enumerate DLP policies: {0}" -f $_.Exception.Message)
}

try {
    $rules = @(Get-DlpComplianceRule -ErrorAction SilentlyContinue)
    if ($rules.Count -gt 0) {
        Write-Host ''
        Write-Host ("DLP rules found: {0}" -f $rules.Count)
        $rules | Select-Object Name, ParentPolicyName, Disabled | Sort-Object ParentPolicyName | Format-Table -AutoSize
    }
}
catch { Write-Warning ("Could not enumerate DLP rules: {0}" -f $_.Exception.Message) }

# --- Sensitive information types ---------------------------------------------------------------------
Write-Section 'Sensitive information types (and any technical-data / export custom SIT)'
try {
    $sits = @(Get-DlpSensitiveInformationType -ErrorAction Stop)
    Write-Host ("Total SITs available: {0}" -f $sits.Count)
    $custom = $sits | Where-Object { $_.Publisher -ne 'Microsoft Corporation' }
    if ($custom) {
        Write-Host 'Custom SITs present:' -ForegroundColor Green
        $custom | Select-Object Name, Publisher | Sort-Object Name | Format-Table -AutoSize
    }
    $itarSit = $sits | Where-Object { $n = "$($_.Name) $($_.Description)"; $itarHints | Where-Object { $n -match [regex]::Escape($_) } }
    if ($itarSit) {
        Write-Host 'SIT(s) that look technical-data/export-related:' -ForegroundColor Green
        $itarSit | Select-Object Name | Format-Table -AutoSize
    } else {
        Write-Host 'No technical-data/export SIT detected — expected object to create:'
        Write-Host '  Technical Data SIT - Export Markings - Custom (see 03-implementation.md Step 2).'
    }
}
catch { Write-Warning ("Could not enumerate sensitive information types: {0}" -f $_.Exception.Message) }

# --- Sensitivity labels (preferred DLP condition) ---------------------------------------------------
Write-Section 'Sensitivity labels (the preferred, most durable DLP condition)'
if (Get-Command Get-Label -ErrorAction SilentlyContinue) {
    try {
        $labels = @(Get-Label -ErrorAction Stop)
        if ($labels.Count -gt 0) {
            $labels | Select-Object DisplayName, Name | Sort-Object DisplayName | Format-Table -AutoSize
            $itarLabel = $labels | Where-Object { $d = "$($_.DisplayName)"; $itarHints | Where-Object { $d -match [regex]::Escape($_) } }
            if ($itarLabel) { Write-Host 'An export/ITAR-related label exists — prefer it as the DLP condition.' -ForegroundColor Green }
            else { Write-Host 'No export/ITAR label found. Consider "Export Controlled // ITAR" (see 03-implementation.md).' }
        } else { Write-Host 'No sensitivity labels published yet.' -ForegroundColor Yellow }
    }
    catch { Write-Warning ("Could not read sensitivity labels: {0}" -f $_.Exception.Message) }
} else {
    Write-Host 'Get-Label not available in this session. Confirm labels in the Purview portal.'
}

# --- Baseline / drift --------------------------------------------------------------------------------
$liveState = $dlpPolicies | Select-Object Name, Mode, Enabled | Sort-Object Name

if ($SaveBaseline) {
    Write-Section 'Saving policy baseline'
    try {
        $liveState | ConvertTo-Json -Depth 4 | Set-Content -Path $BaselinePath -Encoding UTF8
        Write-Host ("Baseline written: {0}" -f $BaselinePath) -ForegroundColor Green
        Write-Host 'This is the drift reference: Policy Baseline - ITAR DLP - <date>.'
    }
    catch { Write-Warning ("Could not write baseline: {0}" -f $_.Exception.Message) }
}

if ($CompareBaseline) {
    Write-Section 'Comparing live estate against baseline'
    if (-not (Test-Path $BaselinePath)) {
        Write-Host ("No baseline at {0}. Run -SaveBaseline first." -f $BaselinePath) -ForegroundColor Yellow
    } else {
        try {
            $base = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
            $baseMap = @{}; foreach ($b in $base) { $baseMap[$b.Name] = $b.Mode }
            $drift = @()
            foreach ($p in $liveState) {
                if (-not $baseMap.ContainsKey($p.Name)) { $drift += "ADDED: $($p.Name) (Mode=$($p.Mode))" }
                elseif ($baseMap[$p.Name] -ne $p.Mode)  { $drift += "ModeChanged: $($p.Name) $($baseMap[$p.Name]) -> $($p.Mode)" }
            }
            foreach ($name in $baseMap.Keys) { if (-not ($liveState.Name -contains $name)) { $drift += "REMOVED: $name" } }
            if ($drift.Count -eq 0) { Write-Host 'PASS: no drift from baseline.' -ForegroundColor Green }
            else { Write-Host 'DRIFT detected (treat unexplained changes as change-control incidents):' -ForegroundColor Red; $drift | ForEach-Object { Write-Host "  $_" } }
        }
        catch { Write-Warning ("Could not compare baseline: {0}" -f $_.Exception.Message) }
    }
}

Write-Section 'Discovery complete'
Write-Host 'Next: DLPITAR-Scope-Health.ps1 (coverage/licensing), then design the technical-data'
Write-Host 'classification (03-implementation.md Step 2). Verify availability against your licensing/tenant.'
