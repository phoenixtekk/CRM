<#
.SYNOPSIS
    CMPNIST-Validate.ps1 — check each Purview-covered NIST 800-53 family has its evidence present (read-only).
.DESCRIPTION
    PURPOSE
        Read-only validation against NIST 800-53 – Control-to-Purview – Map. For each Purview-covered
        family it confirms the evidence exists: AU = unified audit on + the AU retention policy present;
        SC/MP/SI = the control-support DLP policy present (and its mode reported); AC/SC = a published
        sensitivity label with encryption; retention = a retention policy present. Emits a per-family
        PASS / FAIL / DEFERRED line with the missing item named. Changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPNIST-Validate.ps1
        .\CMPNIST-Validate.ps1 -CsvPath .\nist-validation.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). Interactive
        modern-auth / MFA admin; no secrets in code.
    EXPECTED RESULTS
        Every Purview-covered family reports PASS with its evidence; deferred families are marked DEFERRED.
        A FAIL names the missing artifact so you can return to the matching Implementation step.
.NOTES
    Purview category — NIST 800-53 program. Read-only. Whether the evidence is SUFFICIENT and whether the
    system is AUTHORIZED (ATO) are the assessor's / Authorizing Official's determinations — DEFERRED. This
    validates that the technical control is configured and evidenced, not that the control set is complete.
    Feature availability is licensing-/tenant-dependent and evolving. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$AuditRetentionName = 'Control Evidence – NIST AU – Audit Retention',
    [string]$DlpPolicyName       = 'Control Evidence – NIST SC-MP – DLP (Simulation)',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$Family,[string]$Status,[string]$Detail){
    $results.Add([pscustomobject]@{ Family = $Family; Status = $Status; Detail = $Detail })
}

# --- AU: unified audit + retention ------------------------------------------------------------------
Write-Section 'AU — unified audit + audit-log retention'
try {
    Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null
    $cfg = Get-AdminAuditLogConfig
    if ($cfg.UnifiedAuditLogIngestionEnabled) { Ok 'Unified audit ingestion: ON' }
    else { Warn 'Unified audit ingestion: OFF' }
    $auditOk = [bool]$cfg.UnifiedAuditLogIngestionEnabled
} catch { Warn "Could not read audit config: $($_.Exception.Message)"; $auditOk = $false }

$ippsOk = $false
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; $ippsOk = $true } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }

$auRetOk = $false
if ($ippsOk) {
    try {
        $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditRetentionName }
        if ($arp) { Ok "AU retention policy present: $AuditRetentionName"; $auRetOk = $true }
        else { Warn "AU retention policy MISSING: $AuditRetentionName" }
    } catch { Warn "Could not read audit-retention policies: $($_.Exception.Message)" }
}
if ($auditOk -and $auRetOk) { Add-Result 'AU' 'PASS' 'Unified audit ON + AU retention policy present' }
else { Add-Result 'AU' 'FAIL' ("Missing: " + (@(if(-not $auditOk){'unified audit'}; if(-not $auRetOk){"retention '$AuditRetentionName'"}) -join '; ')) }

# --- SC/MP/SI: DLP control-support policy -----------------------------------------------------------
Write-Section 'SC/MP/SI — control-support DLP policy'
$dlpOk = $false; $dlpMode = ''
if ($ippsOk) {
    try {
        $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicyName }
        if ($dlp) { $dlpMode = "$($dlp.Mode)"; Ok "DLP policy present: $DlpPolicyName (Mode=$dlpMode)"; $dlpOk = $true }
        else { Warn "DLP policy MISSING: $DlpPolicyName" }
    } catch { Warn "Could not read DLP policies: $($_.Exception.Message)" }
}
if ($dlpOk) { Add-Result 'SC/MP/SI' 'PASS' "DLP policy present (Mode=$dlpMode)" }
else { Add-Result 'SC/MP/SI' 'FAIL' "DLP policy '$DlpPolicyName' not found (create in simulation — Step 5)" }

# --- AC/SC: label with encryption -------------------------------------------------------------------
Write-Section 'AC/SC — sensitivity label with encryption'
$labelOk = $false
if ($ippsOk) {
    try {
        $enc = Get-Label -ErrorAction Stop | Where-Object { $_.EncryptionEnabled }
        if ($enc) { Ok ("Encryption-bearing label(s) present: {0}" -f @($enc).Count); $labelOk = $true }
        else { Warn 'No sensitivity label with encryption/usage rights found (AC-3/SC-28 evidence gap).' }
        $lp = Get-LabelPolicy -ErrorAction SilentlyContinue
        if (-not $lp) { Warn 'No label policy published — labels not surfaced to users.' }
    } catch { Warn "Could not read labels: $($_.Exception.Message)" }
}
if ($labelOk) { Add-Result 'AC/SC' 'PASS' 'Encryption-bearing sensitivity label published' }
else { Add-Result 'AC/SC' 'FAIL' 'No encryption label published (assign to labeling workstream or record gap)' }

# --- Retention family -------------------------------------------------------------------------------
Write-Section 'Retention — retention policy present'
$retOk = $false
if ($ippsOk) {
    try {
        $rp = Get-RetentionCompliancePolicy -ErrorAction Stop
        if ($rp) { Ok ("Retention policies present: {0}" -f @($rp).Count); $retOk = $true }
        else { Warn 'No retention policies found (record in map if the boundary requires retention).' }
    } catch { Warn "Could not read retention policies: $($_.Exception.Message)" }
}
Add-Result 'Retention' ($(if($retOk){'PASS'}else{'REVIEW'})) ($(if($retOk){'Retention policy present'}else{'No retention policy — confirm boundary requirement'}))

# --- Deferred families (Purview does not technically cover) ------------------------------------------
Write-Section 'Deferred families (recorded as inherited/deferred in the map)'
foreach ($f in @('PE','PS','AT','IR (most)')) { Add-Result $f 'DEFERRED' 'Not Purview-covered — inherited/deferred to program' }
Warn 'Identity/Conditional Access (parts of AC/IA) is Entra — recorded as inherited, not Purview evidence.'

# --- Scorecard --------------------------------------------------------------------------------------
Write-Section 'Per-family validation scorecard'
$results | Format-Table Family, Status, Detail -AutoSize | Out-String | Write-Host
$fails = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
if ($fails -eq 0) { Ok 'All Purview-covered families are evidenced for the pilot scope.' }
else { Warn ("$fails family(ies) FAIL — resolve the named item and re-run. Authorization remains the AO's decision — deferred.") }

if ($CsvPath) {
    try { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Ok "Scorecard exported: $CsvPath" }
    catch { Warn "Could not export scorecard: $($_.Exception.Message)" }
}
