<#
.SYNOPSIS
    CMPFINRA-Report.ps1 — export the control → object → configuration → proof evidence binder (read-only).
.DESCRIPTION
    PURPOSE
        Produces the "Evidence – FINRA/SEC Controls – Binder" export: for each FINRA/SEC control domain
        (records/regulatory-records retention, communications-store retention, audit evidence, and the
        communication-supervision policy) it records the implementing Purview object, its key
        configuration, and a proof reference, cross-referenced to the "Control Map – FINRA/SEC – Purview"
        register. Read-only — reads current state and writes only a local CSV/JSON evidence file.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFINRA-Report.ps1 -OutputDir .\evidence
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession). Interactive modern-auth / MFA
        admin sign-in; no secrets in code. Optionally pass a control-map CSV via -ControlMapPath to merge
        your compliance-owned rule→control mapping into the binder.
    EXPECTED RESULTS
        A timestamped evidence binder (CSV + JSON) listing each control, its Purview object, configuration,
        and proof reference. PASS = every in-scope control resolves to a present, correctly-typed object
        with a proof reference; FAIL = a control with no object or no evidence (surfaces the gap to fill
        before an exam). Adequacy of retention/scope and rule fit is NOT asserted — that is compliance's.
.NOTES
    Purview category — FINRA/SEC Compliance Program. Read-only (emits a local evidence file only). A
    control's presence is proven here; whether it SATISFIES a FINRA/SEC rule is a compliance/records/legal
    determination. Verify cmdlet/plan names against your entitlements and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$OutputDir       = '.\evidence',
    [string]$ControlMapPath,                                        # optional: compliance-owned rule→control CSV to merge
    [string]$RegulatoryLabel = 'Records – FINRA/SEC Regulated – Regulatory',
    [string]$PilotLabelMatch = 'FINRA/SEC',                          # substring identifying pilot/records labels
    [string]$CommsRetention  = 'Retention – FINRA/SEC Comms Store – Immutable',
    [string]$PublishPolicy   = 'Retention – FINRA/SEC Records – Publish',
    [string]$AuditPolicy     = 'Audit Retention – FINRA/SEC Evidence – LongTerm',
    [string]$Supervision     = 'Supervision – Registered Persons Comms – Test'
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($domain,$control,$object,$config,$proof,$present){
    $rows.Add([pscustomobject]@{
        ControlDomain = $domain
        Control       = $control
        PurviewObject = $object
        Configuration = $config
        ProofReference= $proof
        Present       = $present
        CapturedUtc   = (Get-Date).ToUniversalTime().ToString('u')
    })
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# --- Records: regulatory / pilot records labels ---
Write-Section "Records-preservation control"
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    $reg  = $tags | Where-Object { $_.Name -eq $RegulatoryLabel -and $_.RegulatoryRecord }
    if ($reg) {
        Add-Row 'Records' 'Books-and-records regulatory preservation' $reg.Name `
            ("type=regulatory-record; retention={0}; action={1}" -f $reg.RetentionDuration,$reg.RetentionAction) `
            'Get-ComplianceTag (RegulatoryRecord=True)' $true
        Ok "Regulatory-records label present: $($reg.Name)"
    } else {
        Add-Row 'Records' 'Books-and-records regulatory preservation' $RegulatoryLabel 'NOT FOUND' 'Get-ComplianceTag' $false
        Warn "Regulatory-records label '$RegulatoryLabel' not found (may still be piloting non-regulatory)."
    }
    foreach ($p in ($tags | Where-Object { $_.IsRecordLabel -and $_.Name -match $PilotLabelMatch -and -not $_.RegulatoryRecord })) {
        Add-Row 'Records' 'Pilot records label (non-regulatory)' $p.Name `
            ("type=record; retention={0}" -f $p.RetentionDuration) 'Get-ComplianceTag (IsRecordLabel=True)' $true
    }
} catch { Warn "Could not read retention labels: $($_.Exception.Message)" }

# --- Retention policies (publish + comms-store) ---
Write-Section "Retention policies"
try {
    $pols = Get-RetentionCompliancePolicy -ErrorAction Stop
    foreach ($n in @($PublishPolicy,$CommsRetention)) {
        $pol = $pols | Where-Object { $_.Name -eq $n }
        if ($pol) {
            Add-Row 'Records' 'Retention policy' $pol.Name `
                ("enabled={0}; mode={1}; workload={2}" -f $pol.Enabled,$pol.Mode,$pol.Workload) `
                'Get-RetentionCompliancePolicy' $true
            Ok "Retention policy present: $n (enabled=$($pol.Enabled))"
        } else {
            Add-Row 'Records' 'Retention policy' $n 'NOT FOUND' 'Get-RetentionCompliancePolicy' $false
            Warn "Retention policy '$n' not found."
        }
    }
} catch { Warn "Could not read retention policies: $($_.Exception.Message)" }

# --- Audit evidence: ingestion + retention policy ---
Write-Section "Audit-evidence control"
try {
    $cfg = $null
    try { $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {
        try { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null; $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {}
    }
    $ing = if ($cfg) { [bool]$cfg.UnifiedAuditLogIngestionEnabled } else { $null }
    Add-Row 'Audit' 'Unified audit ingestion' 'Tenant audit configuration' `
        ("UnifiedAuditLogIngestionEnabled={0}" -f ($ing)) 'Get-AdminAuditLogConfig' ($ing -eq $true)
    if ($ing) { Ok "Unified audit ingestion: True" } else { Warn "Unified audit ingestion not confirmed True (no evidence captured while off)." }
} catch { Warn "Could not read AdminAuditLogConfig: $($_.Exception.Message)" }
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditPolicy }
    if ($arp) {
        Add-Row 'Audit' 'Audit evidence retention' $arp.Name `
            ("duration={0}; priority={1}" -f $arp.RetentionDuration,$arp.Priority) 'Get-UnifiedAuditLogRetentionPolicy' $true
        Ok "Audit retention policy present: $($arp.Name)"
    } else {
        Add-Row 'Audit' 'Audit evidence retention' $AuditPolicy 'NOT FOUND' 'Get-UnifiedAuditLogRetentionPolicy' $false
        Warn "Audit retention policy '$AuditPolicy' not found."
    }
} catch { Warn "Could not read audit retention policies: $($_.Exception.Message)" }

# --- Supervision (communication compliance) ---
Write-Section "Communication-supervision control"
try {
    $sup = Get-SupervisoryReviewPolicyV2 -ErrorAction Stop | Where-Object { $_.Name -eq $Supervision }
    if ($sup) {
        Add-Row 'Supervision' 'Communication supervision (built in TEST)' $sup.Name `
            ("enabled={0}; note=verify test scope + reviewer separation + pseudonymization" -f $sup.Enabled) `
            'Get-SupervisoryReviewPolicyV2' $true
        Ok "Supervision policy present: $($sup.Name)"
        Warn "Supervision is HR/privacy-sensitive — confirm reviewer separation; outcomes/case actions are HR/legal's."
    } else {
        Add-Row 'Supervision' 'Communication supervision (built in TEST)' $Supervision 'NOT FOUND' 'Get-SupervisoryReviewPolicyV2' $false
        Warn "Supervision policy '$Supervision' not found (build in TEST — Implementation Step 5)."
    }
} catch { Warn "Could not read supervisory-review policies (verify cmdlet/feature for your tenant): $($_.Exception.Message)" }

# --- Merge compliance-owned control map (optional) ---
if ($ControlMapPath) {
    if (Test-Path $ControlMapPath) {
        try {
            $map = Import-Csv -Path $ControlMapPath
            Write-Section "Control map merged"
            Ok ("Merged {0} rule→control row(s) from {1} (compliance-owned mapping)." -f @($map).Count, $ControlMapPath)
            foreach ($m in $map) {
                $rows.Add([pscustomobject]@{
                    ControlDomain='RuleMap'; Control=($m.PSObject.Properties.Name -join '|')
                    PurviewObject=''; Configuration=(( $m.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" } ) -join '; ')
                    ProofReference=$ControlMapPath; Present=$true; CapturedUtc=(Get-Date).ToUniversalTime().ToString('u')
                })
            }
        } catch { Warn "Could not import control map '$ControlMapPath': $($_.Exception.Message)" }
    } else { Warn "ControlMapPath '$ControlMapPath' not found — skipping merge." }
}

# --- Write the binder ---
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$stamp   = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$csvPath = Join-Path $OutputDir "Evidence-FINRA-SEC-Controls-Binder-$stamp.csv"
$jsonPath= Join-Path $OutputDir "Evidence-FINRA-SEC-Controls-Binder-$stamp.json"
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8

Write-Section "Evidence binder written"
Ok "CSV : $csvPath"
Ok "JSON: $jsonPath"
$missing = @($rows | Where-Object { $_.Present -eq $false }).Count
if ($missing -eq 0) { Write-Host "All in-scope controls resolved to a present object with a proof reference." -ForegroundColor Green }
else { Warn "$missing control(s) missing an object/evidence — fill the gap before an exam (a control with no evidence fails)." }
Write-Host "NOTE: this proves the controls are PRESENT and configured; whether they SATISFY FINRA/SEC is a compliance/records/legal determination." -ForegroundColor White
