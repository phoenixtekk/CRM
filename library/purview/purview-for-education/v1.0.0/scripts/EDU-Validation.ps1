<#
.SYNOPSIS
    EDU-Validation.ps1 — education/FERPA program readiness scorecard: DLP in TEST, labels published to pilot, retention period set (read-only).
.DESCRIPTION
    PURPOSE
        Scores the education program with no changes: the FERPA DLP policy exists and is in TEST (flags
        any policy that is ENFORCING), the label policy targets the pilot, the student-record retention
        label exists with a non-zero approved period, and the DLP rule references the education-record
        signal (the 'EDU - Student ID' SIT and/or the 'EDU - Student Record (FERPA)' label). Emits a
        PASS/FAIL per gate mirroring the Testing Guide. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDU-Validation.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin; no
        secrets. Override the checked names with -DlpName / -RetentionLabel / -LabelPolicy if you renamed.
    EXPECTED RESULTS
        A scorecard: each gate GREEN (pass) or RED (fail) with a remediation pointer. PASS overall =
        every in-scope gate green for the pilot AND no DLP policy enforcing before sign-off. Adequacy of
        the retention period / FERPA scope is NOT scored — that is records/legal's.
.NOTES
    Purview category — Microsoft Purview for Education (FERPA). Read-only. Proves the technical controls
    are present and SAFE (DLP not enforcing); does not certify FERPA compliance. Verify cmdlet/plan names
    for your tenant.
#>
[CmdletBinding()]
param(
    [string]$DlpName        = 'EDU - FERPA Student Records - DLP - Pilot',
    [string]$RetentionLabel = 'EDU - Student Education Record',
    [string]$LabelPolicy    = 'EDU - Label Policy - Pilot',
    [string]$StudentIdSit   = 'EDU - Student ID',
    [string]$RecordLabel    = 'EDU - Student Record (FERPA)'
)

$ErrorActionPreference = 'Stop'
$results = @()
function Gate($name,$pass,$detail){ $script:results += [pscustomobject]@{ Gate=$name; Status = if($pass){'GREEN'}else{'RED'}; Detail=$detail } }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# Gate: FERPA DLP policy exists and is in TEST (not enforcing)
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    $p   = $dlp | Where-Object { $_.Name -eq $DlpName }
    if (-not $p) { Gate 'DLP: FERPA policy present (in Test)' $false "'$DlpName' not found — Implementation Step 5." }
    elseif ($p.Mode -eq 'Enable') { Gate 'DLP: FERPA policy present (in Test)' $false "'$DlpName' is ENFORCING (Mode=Enable) — must be Test until sign-off (Step 9)." }
    else { Gate 'DLP: FERPA policy present (in Test)' $true "'$DlpName' present, Mode=$($p.Mode) (not enforcing)." }
    # Safety gate: NO education DLP policy should be enforcing before the expand phase
    $enforcing = $dlp | Where-Object { $_.Mode -eq 'Enable' -and $_.Name -like 'EDU*' }
    if ($enforcing) { Gate 'DLP: no education policy enforcing pre-sign-off' $false ("Enforcing: {0}" -f (($enforcing.Name) -join ', ')) }
    else { Gate 'DLP: no education policy enforcing pre-sign-off' $true "No EDU DLP policy is enforcing." }
} catch { Gate 'DLP: FERPA policy present (in Test)' $false "Get-DlpCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: DLP rule references the education-record signal
try {
    $rules = Get-DlpComplianceRule -Policy $DlpName -ErrorAction Stop
    $refsSignal = $false
    foreach ($r in $rules) {
        $blob = ($r | Out-String)
        if ($blob -match [regex]::Escape($StudentIdSit) -or $blob -match [regex]::Escape($RecordLabel)) { $refsSignal = $true }
    }
    if ($refsSignal) { Gate 'DLP: rule references education-record signal' $true "Rule references '$StudentIdSit' and/or '$RecordLabel'." }
    else { Gate 'DLP: rule references education-record signal' $false "No rule references the SIT/label — add the education-record condition (Step 5)." }
} catch { Gate 'DLP: rule references education-record signal' $false "Get-DlpComplianceRule failed (policy present?): $($_.Exception.Message)" }

# Gate: label policy targets the pilot
try {
    $lp = Get-LabelPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $LabelPolicy }
    if ($lp) { Gate 'Labels: pilot label policy present' $true "'$LabelPolicy' present (confirm it targets the PILOT group, not All)." }
    else { Gate 'Labels: pilot label policy present' $false "'$LabelPolicy' not found — publish labels to the pilot (Step 4)." }
} catch { Gate 'Labels: pilot label policy present' $false "Get-LabelPolicy failed: $($_.Exception.Message)" }

# Gate: student-record retention label with a non-zero approved period
try {
    $tag = Get-ComplianceTag -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionLabel }
    if (-not $tag) { Gate 'Retention: student-record label present' $false "'$RetentionLabel' not found — Implementation Step 7 (only after sign-off)." }
    elseif (-not $tag.RetentionDuration -or "$($tag.RetentionDuration)" -eq '0') { Gate 'Retention: student-record label present' $false "'$RetentionLabel' has no/zero duration — set the records owner's approved period." }
    else { Gate 'Retention: student-record label present' $true "'$RetentionLabel' present (duration $($tag.RetentionDuration), action $($tag.RetentionAction)). Adequacy is records/legal's determination." }
} catch { Gate 'Retention: student-record label present' $false "Get-ComplianceTag failed: $($_.Exception.Message)" }

# Gate: education Student-ID SIT present
try {
    $sit = Get-DlpSensitiveInformationType -ErrorAction Stop | Where-Object { $_.Name -eq $StudentIdSit }
    if ($sit) { Gate 'Classification: Student-ID SIT present' $true "'$StudentIdSit' present." }
    else { Gate 'Classification: Student-ID SIT present' $false "'$StudentIdSit' not found — build the custom SIT (Step 3); there is no built-in FERPA SIT." }
} catch { Gate 'Classification: Student-ID SIT present' $false "Get-DlpSensitiveInformationType failed: $($_.Exception.Message)" }

Write-Host "`n=== Education / FERPA Program Scorecard ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $c = if ($_.Status -eq 'GREEN') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $_.Status, $_.Gate) -ForegroundColor $c
    Write-Host ("         {0}" -f $_.Detail) -ForegroundColor DarkGray
}
$red = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($red -eq 0) { Write-Host "`nAll in-scope gates GREEN — controls present and SAFE (DLP not enforcing). Proceed per Testing Guide." -ForegroundColor Green }
else { Write-Host "`n$red gate(s) RED — remediate before expanding/enforcing." -ForegroundColor Yellow }
Write-Host "NOTE: FERPA applicability and retention-period adequacy are records/legal determinations, not scored here." -ForegroundColor White
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
