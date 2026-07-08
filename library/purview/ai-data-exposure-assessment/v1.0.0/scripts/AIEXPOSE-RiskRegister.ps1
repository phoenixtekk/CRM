<#
.SYNOPSIS
    AIEXPOSE-RiskRegister.ps1 — combine discovery + reachability into a scored, prioritized exposure risk register (read-only).
.DESCRIPTION
    PURPOSE
        Read-only reporting step. Reads the discovery inventory and the reachability exports and produces
        the ranked Exposure Risk Register — the assessment's core deliverable. Each finding gets a
        transparent, deterministic exposure score (reachability breadth x sensitivity signal) so the
        priority risks — broadly-shared sites/content most likely to hold sensitive data that Copilot can
        surface — sort to the top. The score is DECISION SUPPORT, not a determination: which risks to
        remediate and what exposure level is acceptable are deferred to compliance/records/privacy/legal.
        Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ (no live connection needed; reads the CSVs the prior scripts wrote):
          .\AIEXPOSE-RiskRegister.ps1
          .\AIEXPOSE-RiskRegister.ps1 -OversharingCsv .\AIEXPOSE-Oversharing-Sites-Assess.csv -DiscoveryCsv .\AIEXPOSE-AccessScope-Estate-Discovery.csv
    EXPECTED RESULTS
        The ranked register written to .\AIEXPOSE-RiskRegister-Estate-Rank.csv (Exposure Risk Register -
        Estate - Rank), highest exposure first, each row with a Score, a Rationale, and a suggested fix
        family (label / DLP-for-AI / restrict sharing) for stakeholder review. Empty inputs yield an empty
        register (a valid pre-adoption result), not an error.
.NOTES
    White-label Microsoft Purview tooling. Read-only; reads only local CSVs from the prior scripts. No
    credentials stored. The scoring weights are transparent parameters you can tune — they rank findings
    for human review; they do NOT decide remediation. No cmdlets are invented.
#>
[CmdletBinding()]
param(
    [string]$OversharingCsv = ".\AIEXPOSE-Oversharing-Sites-Assess.csv",
    [string]$DiscoveryCsv   = ".\AIEXPOSE-AccessScope-Estate-Discovery.csv",
    [string]$OutPath        = ".\AIEXPOSE-RiskRegister-Estate-Rank.csv",
    [int]$BroadShareWeight  = 5,     # weight per broad-share event (reachability breadth)
    [int]$NoDlpPenalty      = 20     # added exposure when no DLP lever exists to protect content
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIEXPOSE Risk Register — score & rank exposure (read-only) ===" -ForegroundColor Cyan

# Estate-level signal: does a DLP lever exist at all? (thin/absent DLP raises every finding's exposure)
$dlpCount = 0
if (Test-Path $DiscoveryCsv) {
    try { $dlpCount = @((Import-Csv $DiscoveryCsv) | Where-Object ArtifactType -eq "DlpPolicy").Count } catch {}
}
$noDlp = ($dlpCount -eq 0)
if ($noDlp) { Write-Host "  Note: no DLP policy found in discovery — every finding carries a +$NoDlpPenalty no-lever penalty." -ForegroundColor Yellow }

$register = [System.Collections.Generic.List[object]]::new()

if (Test-Path $OversharingCsv) {
    $over = Import-Csv $OversharingCsv
    foreach ($o in $over) {
        if (-not $o.Site) { continue }
        $events = 0; [int]::TryParse(("" + $o.BroadShareEvents), [ref]$events) | Out-Null
        $score = ($events * $BroadShareWeight) + $(if ($noDlp) { $NoDlpPenalty } else { 0 })
        $rationale = "Site broadly shared ($events broad-share event(s)) — content here is reachable by Copilot for anyone with access" +
                     $(if ($noDlp) { "; no DLP lever present to keep sensitive content out of AI." } else { "." })
        $register.Add([pscustomobject]@{
            RiskItem       = $o.Site
            RiskType       = "Oversharing (AI-reachable)"
            Score          = $score
            BroadShareEvents = $events
            SuggestedFix   = "Restrict site sharing/access; apply/extend sensitivity label; scope DLP-for-AI to labeled content"
            Rationale      = $rationale
            Determination  = "Deferred to compliance/records/privacy/legal"
        })
    }
} else {
    Write-Host "  WARN: oversharing export not found ($OversharingCsv) — run AIEXPOSE-Reachability.ps1 first." -ForegroundColor Yellow
}

$ranked = $register | Sort-Object Score -Descending
$ranked | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8

Write-Host ("`nRisk register written to {0}  (Exposure Risk Register - Estate - Rank): {1} item(s)" -f $OutPath, @($ranked).Count) -ForegroundColor Green
if (@($ranked).Count -gt 0) {
    Write-Host "  Top exposure risks (highest score first):" -ForegroundColor Cyan
    $ranked | Select-Object -First 5 | ForEach-Object { Write-Host ("    [{0,4}] {1}" -f $_.Score, $_.RiskItem) -ForegroundColor Yellow }
} else {
    Write-Host "  Empty register — a valid pre-adoption result (no broad-sharing signal in the window)." -ForegroundColor Yellow
}
Write-Host "Determinations (which to fix, acceptable exposure level) belong to compliance/records/privacy/legal (GR §5)." -ForegroundColor Cyan
Write-Host "Next: validate the recommended fix for a top risk in SIMULATION with AIEXPOSE-PilotRemediation.ps1." -ForegroundColor Cyan
