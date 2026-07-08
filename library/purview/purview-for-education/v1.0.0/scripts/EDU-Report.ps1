<#
.SYNOPSIS
    EDU-Report.ps1 — activity & coverage report for the education/FERPA program: DLP matches/incidents, label usage, retention coverage (read-only).
.DESCRIPTION
    PURPOSE
        Produces a coverage/activity snapshot with no changes: the education DLP policies with their mode
        (Test vs enforcing) and recent DLP match/incident counts where the reporting cmdlet is available,
        the education sensitivity labels and their publishing policies, and the student-record retention
        label/policy coverage. Writes only a local CSV/JSON report. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDU-Report.ps1 -OutputDir .\report -Days 30
        Requires ExchangeOnlineManagement (Connect-IPPSSession). DLP incident/match counts use the
        Security & Compliance reporting cmdlet where present (verify availability/latency for your
        tenant). Interactive modern-auth / MFA admin; no secrets in code.
    EXPECTED RESULTS
        A timestamped report (CSV + JSON) of DLP policies + mode + match counts, label/label-policy
        coverage, and retention coverage — evidence for the Compliance Manager 'EDU - FERPA Posture'
        assessment. Nothing is modified. Counts are indicative; reporting latency applies.
.NOTES
    Purview category — Microsoft Purview for Education (FERPA). Read-only (emits a local report only).
    Capability/report availability is licensing-/tenant-dependent and evolving — verify. FERPA
    applicability, retention adequacy, and holds are records/legal determinations.
#>
[CmdletBinding()]
param(
    [string]$OutputDir      = '.\report',
    [int]$Days              = 30,
    [string]$DlpFilter      = 'EDU',
    [string]$RetentionLabel = 'EDU - Student Education Record'
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($section,$name,$detail){
    $rows.Add([pscustomobject]@{ Section=$section; Name=$name; Detail=$detail; CapturedUtc=(Get-Date).ToUniversalTime().ToString('u') })
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# --- DLP policies + mode ---
Write-Section "DLP policies (mode)"
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -like "*$DlpFilter*" }
    if (-not $dlp) { Warn "No education DLP policies found (filter '$DlpFilter')."; Add-Row 'DLP' '(none)' "No policy matching '$DlpFilter'." }
    foreach ($p in $dlp) {
        $tag = if ($p.Mode -eq 'Enable') { 'ENFORCING' } else { 'Test/safe' }
        Ok ("  {0}  [mode: {1} — {2}]" -f $p.Name, $p.Mode, $tag)
        Add-Row 'DLP' $p.Name ("mode={0} ({1})" -f $p.Mode, $tag)
    }
} catch { Warn "Could not read DLP policies: $($_.Exception.Message)" }

# --- DLP match / incident counts (best-effort; cmdlet availability varies) ---
Write-Section "DLP match/incident activity (last $Days days — indicative)"
$start = (Get-Date).AddDays(-$Days)
$gotCounts = $false
foreach ($cmd in @('Get-DlpDetailReport','Get-DlpDetectionsReport')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        try {
            $data = & $cmd -StartDate $start -EndDate (Get-Date) -ErrorAction Stop |
                    Where-Object { $_.DLPPolicy -like "*$DlpFilter*" -or $_.PolicyName -like "*$DlpFilter*" }
            $count = @($data).Count
            Ok "  $cmd : $count matching event(s) in the window."
            Add-Row 'DLP-Activity' $cmd ("$count matching event(s) over $Days days")
            $gotCounts = $true
            break
        } catch { Warn "  $cmd failed: $($_.Exception.Message)" }
    }
}
if (-not $gotCounts) {
    Warn "No DLP activity-report cmdlet available in this session — review DLP matches in Purview > Data loss prevention > Activity explorer / reports (verify for your tenant)."
    Add-Row 'DLP-Activity' '(unavailable)' 'Use Purview Activity explorer / DLP reports; report cmdlet not available in session.'
}

# --- Labels + label policies ---
Write-Section "Sensitivity labels + policies"
try {
    Get-Label -ErrorAction Stop | Where-Object { $_.DisplayName -like "*$DlpFilter*" -or $_.Name -like "*$DlpFilter*" } | ForEach-Object {
        Add-Row 'Labels' $_.DisplayName ("encryption={0}" -f $_.EncryptionEnabled)
        Write-Host ("  label: {0} (encryption={1})" -f $_.DisplayName, $_.EncryptionEnabled)
    }
} catch { Warn "Could not read labels: $($_.Exception.Message)" }
try {
    Get-LabelPolicy -ErrorAction Stop | Where-Object { $_.Name -like "*$DlpFilter*" } | ForEach-Object {
        Add-Row 'LabelPolicies' $_.Name ("labels={0}" -f (($_.Labels) -join ', '))
        Write-Host ("  label policy: {0}" -f $_.Name)
    }
} catch { Warn "Could not read label policies: $($_.Exception.Message)" }

# --- Retention coverage ---
Write-Section "Retention coverage"
try {
    $tag = Get-ComplianceTag -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionLabel }
    if ($tag) {
        Add-Row 'Retention' $tag.Name ("action={0}; duration={1}" -f $tag.RetentionAction, $tag.RetentionDuration)
        Ok ("  retention label: {0} (action={1}, duration={2})" -f $tag.Name, $tag.RetentionAction, $tag.RetentionDuration)
    } else { Warn "Retention label '$RetentionLabel' not found."; Add-Row 'Retention' $RetentionLabel 'NOT FOUND' }
    Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -like "*$DlpFilter*" -or $_.Name -like '*Student*' } | ForEach-Object {
        Add-Row 'Retention' $_.Name ("enabled={0}; workload={1}" -f $_.Enabled, $_.Workload)
        Write-Host ("  retention policy: {0} (enabled={1})" -f $_.Name, $_.Enabled)
    }
} catch { Warn "Could not read retention config: $($_.Exception.Message)" }

# --- Write report ---
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$stamp    = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$csvPath  = Join-Path $OutputDir "EDU-Coverage-Report-$stamp.csv"
$jsonPath = Join-Path $OutputDir "EDU-Coverage-Report-$stamp.json"
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8

Write-Section "Report written"
Ok "CSV : $csvPath"
Ok "JSON: $jsonPath"
Write-Host "Attach this as evidence to the 'EDU - FERPA Posture' Compliance Manager assessment. Counts are indicative (reporting latency applies)." -ForegroundColor White
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
