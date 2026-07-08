<#
.SYNOPSIS
    CMPNIST-Report.ps1 — produce the NIST 800-53 – Control Evidence – Report (family→Purview artifact map) (read-only).
.DESCRIPTION
    PURPOSE
        Read-only reporting. Assembles the control-evidence report for the assessment package: a row per
        in-scope NIST family with the Purview capability that implements it, the concrete artifact that
        evidences it, and the current status read live from the tenant (audit on, AU retention present,
        DLP policy + mode, labels published, retention present). Exports CSV and a simple HTML for the
        package. It reports state; it does not change anything and it does not authorize.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPNIST-Report.ps1
        .\CMPNIST-Report.ps1 -CsvPath .\nist-evidence.csv -HtmlPath .\nist-evidence.html
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). Interactive
        modern-auth / MFA admin; no secrets in code.
    EXPECTED RESULTS
        NIST 800-53 – Control Evidence – Report generated with one row per family and a live status.
        Attach the concrete artifacts to the matching Compliance Manager improvement actions in the portal.
.NOTES
    Purview category — NIST 800-53 program. Read-only. Evidence SUFFICIENCY and the AUTHORIZATION (ATO)
    are the assessor's / AO's determinations — DEFERRED. Compliance Manager scoring/attachment are portal
    operations. Feature availability is licensing-/tenant-dependent and evolving. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$AuditRetentionName = 'Control Evidence – NIST AU – Audit Retention',
    [string]$DlpPolicyName       = 'Control Evidence – NIST SC-MP – DLP (Simulation)',
    [string]$CsvPath,
    [string]$HtmlPath
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

# --- Gather live status -----------------------------------------------------------------------------
$auditOn = $false; $auRet = $false; $dlpFound = $false; $dlpMode = 'n/a'; $labelEnc = $false; $retFound = $false
try { Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null; $auditOn = [bool](Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled }
catch { Warn "Exchange Online read failed: $($_.Exception.Message)" }

try {
    Connect-IPPSSession @cp -ErrorAction Stop | Out-Null
    try { $auRet = [bool](Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditRetentionName }) } catch {}
    try { $d = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicyName }; if ($d) { $dlpFound = $true; $dlpMode = "$($d.Mode)" } } catch {}
    try { $labelEnc = [bool](Get-Label -ErrorAction Stop | Where-Object { $_.EncryptionEnabled }) } catch {}
    try { $retFound = [bool](Get-RetentionCompliancePolicy -ErrorAction Stop) } catch {}
} catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }

function Status([bool]$ok,[string]$note=''){ if ($ok) { "PRESENT $note".Trim() } else { "GAP $note".Trim() } }

# --- Build the family→artifact rows -----------------------------------------------------------------
$rows = @(
    [pscustomobject]@{ Family='AU';        PurviewCapability='Purview Audit + audit-log retention';           Artifact=$AuditRetentionName;                                 Status=Status ($auditOn -and $auRet) }
    [pscustomobject]@{ Family='SC-8/SC-28'; PurviewCapability='Sensitivity-label encryption + message encryption + DLP'; Artifact=$DlpPolicyName;                            Status=Status $dlpFound "(Mode=$dlpMode)" }
    [pscustomobject]@{ Family='MP-7';       PurviewCapability='Endpoint / removable-media DLP';               Artifact=$DlpPolicyName;                                       Status=Status $dlpFound "(Mode=$dlpMode)" }
    [pscustomobject]@{ Family='AC-3/AC-6';  PurviewCapability='Label-based encryption/usage rights + DLP sharing restrictions'; Artifact='Published encryption label';        Status=Status $labelEnc }
    [pscustomobject]@{ Family='SI-4';       PurviewCapability='DLP alerts + DSPM posture';                    Artifact=$DlpPolicyName;                                       Status=Status $dlpFound "(Mode=$dlpMode)" }
    [pscustomobject]@{ Family='Retention';  PurviewCapability='Retention policies/labels';                    Artifact='Retention policy';                                   Status=Status $retFound }
    [pscustomobject]@{ Family='CA/RA';      PurviewCapability='Compliance Manager assessment + DSPM (visibility)'; Artifact='NIST 800-53 – Rev5 – Assessment (portal)';       Status='PORTAL — confirm in Compliance Manager' }
    [pscustomobject]@{ Family='PE/PS/AT/IR'; PurviewCapability='Not Purview-covered';                          Artifact='Inherited / program-owned';                          Status='DEFERRED' }
)

Write-Section 'NIST 800-53 – Control Evidence – Report'
$rows | Format-Table Family, PurviewCapability, Artifact, Status -AutoSize | Out-String | Write-Host

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Ok "CSV written: $CsvPath" }
    catch { Warn "Could not write CSV: $($_.Exception.Message)" }
}

if ($HtmlPath) {
    try {
        $head = '<style>body{font-family:Segoe UI,Arial,sans-serif}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px 10px;font-size:13px}th{background:#f2f2f2;text-align:left}</style>'
        $pre  = "<h2>NIST 800-53 &ndash; Control Evidence &ndash; Report</h2><p>Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Live tenant status. Evidence sufficiency and the authorization (ATO) are the assessor's / AO's determinations &mdash; deferred.</p>"
        $rows | ConvertTo-Html -Head $head -PreContent $pre -Property Family, PurviewCapability, Artifact, Status | Out-File -FilePath $HtmlPath -Encoding UTF8
        Ok "HTML written: $HtmlPath"
    } catch { Warn "Could not write HTML: $($_.Exception.Message)" }
}

Write-Section 'Next'
Write-Host 'Attach the concrete artifacts (Discovery exports, audit-config snapshot, DLP definition, label list)' -ForegroundColor White
Write-Host 'to the matching Compliance Manager improvement actions in the portal. The AO judges sufficiency — deferred.' -ForegroundColor White
