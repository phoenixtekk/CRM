<#
.SYNOPSIS
    CLSFINGER-Discovery.ps1 — inventory document-fingerprint SITs and the DLP policies that reference them (read-only).
.DESCRIPTION
    PURPOSE
        Read-only posture assessment for Document Fingerprinting. Lists the sensitive information types in
        the tenant (flagging likely document-fingerprint SITs), the DLP policies and rules and their MODE
        (simulation vs enforced), and highlights which fingerprint SITs are — and are not — referenced by a
        DLP policy. Establishes the "what fingerprinting exists today" baseline before you build. Changes
        nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession -UserPrincipalName admin@contoso.com
          .\CLSFINGER-Discovery.ps1
          .\CLSFINGER-Discovery.ps1 -CsvPath .\CLSFINGER-Posture.csv
    EXPECTED RESULTS
        A console summary plus (with -CsvPath) a CSV of SITs, DLP policies/rules, and their modes. A
        fingerprint SIT not referenced by any DLP policy, or a policy left in a non-simulation mode without
        a pilot, is itself an early finding.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell; none are invented. Feature/label availability is licensing-dependent — the script
    warns where something is not readable rather than assuming.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

$ErrorActionPreference = "Stop"
Write-Host "=== CLSFINGER Discovery — document-fingerprint posture (read-only) ===" -ForegroundColor Cyan

try { Get-DlpSensitiveInformationType -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red
    return
}

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}

# --- Sensitive information types (flag custom/likely-fingerprint ones) ---
$fingerprintCandidates = @()
try {
    $sits = Get-DlpSensitiveInformationType -ErrorAction Stop
    foreach ($s in $sits) {
        $isCustom = ($s.Publisher -and $s.Publisher -notmatch 'Microsoft')
        Add-Row "SensitiveInfoType" $s.Name ("Publisher={0}; Custom={1}" -f $s.Publisher, $isCustom)
        if ($isCustom) { $fingerprintCandidates += $s.Name }
    }
    Write-Host ("  Sensitive info types: {0} (custom/likely-fingerprint: {1})" -f @($sits).Count, $fingerprintCandidates.Count) -ForegroundColor Green
    Write-Host "  NOTE: custom SITs may be document-fingerprint or regex/keyword — confirm each in the portal." -ForegroundColor DarkGray
} catch { Write-Host "  WARN: could not read sensitive info types: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP policies + their mode (simulation vs enforce) ---
$referencedSits = @()
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($d in $dlp) { Add-Row "DlpPolicy" $d.Name ("Mode={0}; Workloads={1}" -f $d.Mode, $d.Workload) }
    Write-Host ("  DLP policies: {0}" -f @($dlp).Count) -ForegroundColor Green

    try {
        $rules = Get-DlpComplianceRule -ErrorAction Stop
        foreach ($r in $rules) {
            $sitNames = @()
            try {
                foreach ($c in @($r.ContentContainsSensitiveInformation)) {
                    if ($c -and $c.Name) { $sitNames += $c.Name }
                }
            } catch { }
            $referencedSits += $sitNames
            Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}; SITs={2}" -f $r.Policy, $r.Disabled, ($sitNames -join ' | '))
        }
        Write-Host ("  DLP rules: {0}" -f @($rules).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Cross-reference: custom SITs not referenced by any DLP rule ---
$referencedSits = $referencedSits | Sort-Object -Unique
if ($fingerprintCandidates.Count -gt 0) {
    $unref = $fingerprintCandidates | Where-Object { $referencedSits -notcontains $_ }
    if ($unref) {
        Write-Host "`n  FINDING: custom SIT(s) NOT referenced by any DLP policy (inert until wired to DLP):" -ForegroundColor Yellow
        $unref | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow; Add-Row "Finding" $_ "Custom SIT not referenced by any DLP rule" }
    } else {
        Write-Host "`n  All custom SITs are referenced by at least one DLP rule." -ForegroundColor Green
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nPosture written to {0}" -f $CsvPath) -ForegroundColor Green
}
Write-Host "Next: CLSFINGER-CreateFingerprint.ps1 to fingerprint a form, then CLSFINGER-Validation.ps1 to confirm the wiring." -ForegroundColor Cyan
