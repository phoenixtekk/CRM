<#
.SYNOPSIS
    PURVASSESS-Discovery.ps1 — Inventory every enabled Purview capability's configuration (read-only).
.DESCRIPTION
    PURPOSE
        Reads, with no changes, the current configuration of each Purview capability and tags it
        enabled / not enabled / not licensed / portal-only: Information Protection (labels, label
        policies, auto-labeling mode), DLP (policies, workloads, mode), Data Lifecycle & Records
        (retention policies/labels + enabled state), Audit (ingestion, retention), eDiscovery
        (cases, holds), Sensitive Info Types, and a manual-review pointer for the portal-only
        capabilities (Insider Risk, Communication Compliance, DSPM, Compliance Manager, Unified
        Catalog). Optionally writes the inventory to JSON for PURVASSESS-Report.ps1.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVASSESS-Discovery.ps1 -OutFile .\inventory.json
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline).
        Interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A per-capability inventory printed to the console and (with -OutFile) saved as JSON. Each
        capability shows a state and its key objects; unreadable/portal-only items are flagged, not
        asserted.
.NOTES
    Purview category — Tenant Assessment. Read-only. Availability is licensing-/tenant-dependent and
    evolving; portal-only capabilities are flagged "review manually," never invented.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$OutFile                      # optional: path to save the inventory as JSON for the report tool
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  $m" -ForegroundColor Yellow }

$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
$inv = [ordered]@{}

function Read-Capability {
    param([string]$Name, [scriptblock]$Reader)
    try {
        $data = & $Reader
        $inv[$Name] = @{ state = 'enabled'; data = $data }
        return $data
    } catch {
        $msg = $_.Exception.Message
        $state = if ($msg -match 'not recognized|term') { 'not-available-cmdlet' }
                 elseif ($msg -match 'access|denied|permission|role') { 'read-denied (role?)' }
                 else { 'error' }
        $inv[$Name] = @{ state = $state; error = $msg }
        Warn "$Name : $state — $msg"
        return $null
    }
}

# --- Connect S&C + Exchange Online ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
try { Connect-ExchangeOnline @connectParams } catch { Warn "Connect-ExchangeOnline failed: $($_.Exception.Message)" }
try { Connect-IPPSSession @connectParams | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }

# --- 1. Information Protection ---
Write-Section "1. Information Protection (sensitivity labels)"
$labels = Read-Capability 'InformationProtection.Labels' { Get-Label -ErrorAction Stop }
if ($labels) { Ok ("Sensitivity labels: {0}" -f @($labels).Count) } elseif ($inv['InformationProtection.Labels'].state -eq 'enabled') { Warn "No sensitivity labels defined (licensed-but-empty?)" }
$labelPols = Read-Capability 'InformationProtection.LabelPolicies' { Get-LabelPolicy -ErrorAction Stop }
if ($labelPols) { Ok ("Label policies (publication): {0}" -f @($labelPols).Count) }
$auto = Read-Capability 'InformationProtection.AutoLabeling' { Get-AutoSensitivityLabelPolicy -ErrorAction Stop }
if ($auto) { $auto | ForEach-Object { Ok ("Auto-label policy '{0}' mode={1}" -f $_.Name, $_.Mode) } }

# --- 2. DLP ---
Write-Section "2. Data Loss Prevention"
$dlp = Read-Capability 'DLP.Policies' { Get-DlpCompliancePolicy -ErrorAction Stop }
if ($dlp) {
    foreach ($p in $dlp) {
        $locs = @()
        foreach ($w in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
            if ($p.PSObject.Properties.Name -contains $w -and $p.$w) { $locs += ($w -replace 'Location','') }
        }
        Ok ("DLP '{0}' mode={1} workloads=[{2}]" -f $p.Name, $p.Mode, ($locs -join ','))
    }
}

# --- 3. Data Lifecycle & Records ---
Write-Section "3. Data Lifecycle & Records Management (retention)"
$ret = Read-Capability 'Retention.Policies' { Get-RetentionCompliancePolicy -ErrorAction Stop }
if ($ret) { $ret | ForEach-Object { Ok ("Retention policy '{0}' Enabled={1} Mode={2}" -f $_.Name, $_.Enabled, $_.Mode) } }
$tags = Read-Capability 'Retention.Labels' { Get-ComplianceTag -ErrorAction Stop }
if ($tags) { Ok ("Retention labels: {0}" -f @($tags).Count) }

# --- 4. Audit ---
Write-Section "4. Audit (Standard/Premium)"
$audit = Read-Capability 'Audit.Ingestion' { Get-AdminAuditLogConfig -ErrorAction Stop }
if ($audit) {
    if ($audit.UnifiedAuditLogIngestionEnabled) { Ok "UnifiedAuditLogIngestionEnabled = True" }
    else { Warn "UnifiedAuditLogIngestionEnabled = False (unified audit OFF — not retroactive)" }
}
Read-Capability 'Audit.RetentionPolicies' { Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop } | Out-Null

# --- 5. eDiscovery ---
Write-Section "5. eDiscovery (Standard/Premium)"
$cases = Read-Capability 'eDiscovery.Cases' { Get-ComplianceCase -ErrorAction Stop }
if ($cases) { Ok ("Compliance/eDiscovery cases: {0}" -f @($cases).Count) }
Read-Capability 'eDiscovery.Holds' { Get-CaseHoldPolicy -ErrorAction Stop } | Out-Null

# --- 6. Classifiers & SITs ---
Write-Section "6. Classifiers & Sensitive Information Types"
$sits = Read-Capability 'Classifiers.SITs' { Get-DlpSensitiveInformationType -ErrorAction Stop }
if ($sits) {
    $custom = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' })
    Ok ("Sensitive info types total={0}, custom={1}" -f @($sits).Count, $custom.Count)
}

# --- 7. Portal-only capabilities (record for manual review, do not invent readings) ---
Write-Section "7. Portal-only capabilities — REVIEW MANUALLY"
$portalOnly = [ordered]@{
    'InsiderRiskManagement'   = 'Purview portal > Insider Risk Management > Policies (check policies exist, are scoped, and have reviewers; privacy-by-design)'
    'CommunicationCompliance' = 'Purview portal > Communication Compliance > Policies (check policies, reviewer groups, scope)'
    'DSPM'                    = 'Purview portal > Data Security Posture Management (and DSPM for AI — preview; verify your licensing/tenant)'
    'ComplianceManager'       = 'Purview portal > Compliance Manager (overall score + improvement actions)'
    'UnifiedCatalog'          = 'Purview portal > Unified Catalog / Data Map (enablement + coverage; evolving — verify your licensing/tenant)'
}
foreach ($k in $portalOnly.Keys) {
    $inv[$k] = @{ state = 'portal-only'; review = $portalOnly[$k] }
    Warn ("{0}: portal-only — {1}" -f $k, $portalOnly[$k])
}

# --- Save inventory ---
if ($OutFile) {
    $inv | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutFile -Encoding UTF8
    Write-Host "`nInventory saved to $OutFile (feed to PURVASSESS-Report.ps1)" -ForegroundColor White
}
Write-Host "`nInventory complete. 'not licensed / not enabled / portal-only' are legitimate results." -ForegroundColor White
