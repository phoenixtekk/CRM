<#
.SYNOPSIS
    OPSTRAIN-LabBaseline.ps1 — snapshot the current Purview configuration as the known-good "before" state (read-only).
.DESCRIPTION
    PURPOSE
        Discovery for the training curriculum. Enumerates the Purview objects the labs will add to —
        sensitivity labels, label policies, DLP policies and rules, retention policies, and auto-labeling
        policies — and writes them to a baseline CSV. This is the known-good state each lab teardown
        returns to, and the reference OPSTRAIN-LabValidate.ps1 diffs against to confirm only TRAIN- objects
        were added. Run it BEFORE Lab 1 and again after teardown. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\OPSTRAIN-LabBaseline.ps1
          .\OPSTRAIN-LabBaseline.ps1 -OutPath ".\OPSTRAIN-Baseline-before.csv"
    EXPECTED RESULTS
        The full inventory to .\OPSTRAIN-Baseline.csv (ArtifactType,Name,Detail). Compare a post-teardown
        run against the pre-training run: the only difference should be TRAIN- objects added then removed.
.NOTES
    White-label Microsoft Purview training tooling. Read-only. No credentials stored. Cmdlets are standard
    Security & Compliance PowerShell; none are invented. Feature availability is licensing-dependent — the
    script WARNS where an area is not readable rather than assuming it exists.
#>
[CmdletBinding()]
param(
    [string]$OutPath = ".\OPSTRAIN-Baseline.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== OPSTRAIN LabBaseline — current Purview config snapshot (read-only) ===" -ForegroundColor Cyan

try { Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}
function Probe($label, $script) {
    try { $items = & $script; Write-Host ("  {0}: {1}" -f $label, @($items).Count) -ForegroundColor Green; return $items }
    catch { Write-Host ("  WARN: {0} not readable (may be unlicensed): {1}" -f $label, $_.Exception.Message) -ForegroundColor Yellow; return @() }
}

foreach ($l in (Probe "Sensitivity labels" { Get-Label -ErrorAction Stop })) {
    Add-Row "SensitivityLabel" $l.DisplayName ("Priority={0}; Enabled={1}" -f $l.Priority, $l.Enabled)
}
foreach ($p in (Probe "Label policies" { Get-LabelPolicy -ErrorAction Stop })) {
    Add-Row "LabelPolicy" $p.Name ("Labels={0}" -f ($p.Labels -join "; "))
}
foreach ($d in (Probe "DLP policies" { Get-DlpCompliancePolicy -ErrorAction Stop })) {
    Add-Row "DlpPolicy" $d.Name ("Mode={0}; Workload={1}" -f $d.Mode, $d.Workload)
}
foreach ($r in (Probe "DLP rules" { Get-DlpComplianceRule -ErrorAction Stop })) {
    Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled)
}
foreach ($rp in (Probe "Retention policies" { Get-RetentionCompliancePolicy -ErrorAction Stop })) {
    Add-Row "RetentionPolicy" $rp.Name ("Enabled={0}; Mode={1}" -f $rp.Enabled, $rp.Mode)
}
foreach ($a in (Probe "Auto-labeling policies" { Get-AutoSensitivityLabelPolicy -ErrorAction Stop })) {
    Add-Row "AutoLabelPolicy" $a.Name ("Mode={0}; Label={1}" -f $a.Mode, $a.ApplySensitivityLabel)
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
$trainCount = @($rows | Where-Object { $_.Name -like "TRAIN-*" }).Count
Write-Host ("`nBaseline written to {0}  ({1} object(s); {2} already named TRAIN-)" -f $OutPath, $rows.Count, $trainCount) -ForegroundColor Green
if ($trainCount -gt 0) { Write-Host "  Note: TRAIN- objects already exist — a prior training run may not have been torn down." -ForegroundColor Yellow }
Write-Host "Next: run the labs, then OPSTRAIN-LabValidate.ps1 -Lab All to check each pass/fail gate." -ForegroundColor Cyan
