<#
.SYNOPSIS
    CMPFERPA-Report.ps1 — control → object → configuration → proof evidence binder export (read-only).
.DESCRIPTION
    PURPOSE
        Produces the 'Evidence – FERPA Controls – Binder' with no changes: for each FERPA control domain
        (classify & label, prevent disclosure via DLP, records lifecycle/retention, access evidence via
        audit) it reads the configured Purview object, records its key configuration, and marks whether
        the proof is PRESENT — a control → object → configuration → proof mapping cross-referenced to the
        'Control Map – FERPA – Purview' register. Exports CSV + JSON for the compliance/audit file.
        Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFERPA-Report.ps1 -OutDir .\ferpa-evidence
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin;
        no secrets. Writes only the evidence export files to -OutDir; makes NO tenant change.
    EXPECTED RESULTS
        Two files in -OutDir: 'Evidence – FERPA Controls – Binder.csv' and '.json'. PASS = every in-scope
        control maps to a present Purview object with its configuration and a proof reference; FAIL = a
        control with no evidence (fill the gap and re-run). Adequacy of the configuration vs FERPA is a
        compliance/registrar/records/legal determination, not asserted here.
.NOTES
    Purview category — FERPA Compliance Program. Read-only (writes only local evidence files). Does not
    certify FERPA compliance; it evidences that the technical controls are configured. Verify cmdlet/plan
    names for your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutDir          = '.',
    [string]$LabelName       = 'Protect – FERPA Education Records – Confidential',
    [string]$LabelPolicy     = 'Protect – FERPA Education Records – Publish',
    [string]$DlpPolicy       = 'DLP – FERPA Education Records – Simulate',
    [string]$RetentionPolicy = 'Retention – FERPA Records – Publish',
    [string]$AuditPolicy     = 'Audit Retention – FERPA Evidence – LongTerm'
)

$ErrorActionPreference = 'Stop'
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Info($m){ Write-Host $m -ForegroundColor Cyan }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

$rows = @()
function Add-Evidence($domain,$control,$object,$config,$present){
    $script:rows += [pscustomobject]@{
        ControlDomain = $domain
        Control       = $control
        PurviewObject = $object
        Configuration = $config
        ProofPresent  = if ($present) { 'PRESENT' } else { 'MISSING' }
        CapturedUtc   = (Get-Date).ToUniversalTime().ToString('o')
    }
}

Info "Collecting FERPA control evidence (read-only) ..."

# Classify & label — sensitivity label + publish policy
try {
    $lbl = Get-Label -ErrorAction Stop | Where-Object { $_.DisplayName -eq $LabelName -or $_.Name -match 'FERPA' } | Select-Object -First 1
    $lp  = Get-LabelPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $LabelPolicy } | Select-Object -First 1
    $cfg = if ($lbl) { "DisplayName='$($lbl.DisplayName)'; Published=$([bool]$lp); PolicyEnabled=$($lp.Enabled)" } else { 'none' }
    Add-Evidence 'Classification & Labeling' 'Identify + protect education records' $LabelName $cfg ([bool]$lbl)
} catch { Add-Evidence 'Classification & Labeling' 'Identify + protect education records' $LabelName "read error: $($_.Exception.Message)" $false }

# Prevent disclosure — DLP policy (mode matters)
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicy } | Select-Object -First 1
    $cfg = if ($dlp) { "Mode='$($dlp.Mode)' (should be SIMULATION until sign-off); Workloads per policy" } else { 'none' }
    Add-Evidence 'Disclosure Prevention (DLP)' 'Prevent unauthorized disclosure' $DlpPolicy $cfg ([bool]$dlp)
    if ($dlp -and "$($dlp.Mode)" -match 'Enforce') { Warn "DLP '$DlpPolicy' is ENFORCING — confirm this was signed off (record the sign-off with the binder)." }
} catch { Add-Evidence 'Disclosure Prevention (DLP)' 'Prevent unauthorized disclosure' $DlpPolicy "read error: $($_.Exception.Message)" $false }

# Records lifecycle — retention policy
try {
    $rp = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionPolicy } | Select-Object -First 1
    $cfg = if ($rp) { "Enabled=$($rp.Enabled); Mode='$($rp.Mode)'; Workload='$($rp.Workload)'" } else { 'none' }
    Add-Evidence 'Records Lifecycle' 'Retain/dispose education records' $RetentionPolicy $cfg ([bool]$rp)
} catch { Add-Evidence 'Records Lifecycle' 'Retain/dispose education records' $RetentionPolicy "read error: $($_.Exception.Message)" $false }

# Access evidence — unified audit + retention policy
try {
    $cfgObj = $null
    try { $cfgObj = Get-AdminAuditLogConfig -ErrorAction Stop } catch {
        try { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null; $cfgObj = Get-AdminAuditLogConfig -ErrorAction Stop } catch {}
    }
    $ingest = if ($cfgObj) { [bool]$cfgObj.UnifiedAuditLogIngestionEnabled } else { $false }
    Add-Evidence 'Access Evidence (Audit)' 'Unified audit ingestion ON' 'UnifiedAuditLogIngestionEnabled' "Ingestion=$ingest" $ingest
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditPolicy } | Select-Object -First 1
    $cfg = if ($arp) { "Duration='$($arp.RetentionDuration)'; Priority=$($arp.Priority)" } else { 'none' }
    Add-Evidence 'Access Evidence (Audit)' 'Retain access evidence' $AuditPolicy $cfg ([bool]$arp)
} catch { Add-Evidence 'Access Evidence (Audit)' 'Retain access evidence' $AuditPolicy "read error: $($_.Exception.Message)" $false }

# --- Export ---
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
$csvPath  = Join-Path $OutDir 'Evidence – FERPA Controls – Binder.csv'
$jsonPath = Join-Path $OutDir 'Evidence – FERPA Controls – Binder.json'
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath -Encoding UTF8

Write-Host "`n=== Evidence – FERPA Controls – Binder ===" -ForegroundColor Cyan
$rows | ForEach-Object {
    $c = if ($_.ProofPresent -eq 'PRESENT') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} → {2}" -f $_.ProofPresent, $_.Control, $_.PurviewObject) -ForegroundColor $c
    Write-Host ("         {0}" -f $_.Configuration) -ForegroundColor DarkGray
}
$missing = @($rows | Where-Object { $_.ProofPresent -eq 'MISSING' }).Count
Ok "Exported: $csvPath"
Ok "Exported: $jsonPath"
if ($missing -eq 0) { Write-Host "`nEvery in-scope control has evidence — cross-reference to 'Control Map – FERPA – Purview' and retain with sign-offs." -ForegroundColor Green }
else { Write-Host "`n$missing control(s) MISSING evidence — a control with no evidence fails an audit. Fill the gap (Implementation Guide) and re-run." -ForegroundColor Yellow }
Write-Host "NOTE: this binder evidences that controls are configured; whether the configuration satisfies FERPA is a compliance/registrar/records/legal determination." -ForegroundColor White
