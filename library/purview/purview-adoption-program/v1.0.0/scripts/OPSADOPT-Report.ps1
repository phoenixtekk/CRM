<#
.SYNOPSIS
    OPSADOPT-Report.ps1 — read-only adoption-signal report: reads the unified audit log for sensitivity-label activity and DLP match/override counts, optionally scoped to an adoption ring. Makes no changes.
.DESCRIPTION
    PURPOSE
        Turns "are people actually using it?" into numbers. Searches the unified audit log
        (Search-UnifiedAuditLog) over a window for LABELING activity (label applied / changed / removed) and
        DLP signal (rule matches and, where present, user overrides/justifications), then computes a labeling-
        coverage proxy and an override rate. Optionally scopes the signal to the members of an adoption ring
        (Microsoft Graph group). Read-only.
    HOW TO RUN
        Connect-IPPSSession                                  # audit-log search (Search-UnifiedAuditLog)
        Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'   # only needed for -RingGroup scoping
        .\OPSADOPT-Report.ps1 -Days 30
        .\OPSADOPT-Report.ps1 -Days 7 -RingGroup "Adoption Ring - Purview - Wave1" -CsvPath .\adoption-signal.csv
        PowerShell 5.1+/7+; ExchangeOnlineManagement (Connect-IPPSSession) + Microsoft.Graph (for -RingGroup).
    EXPECTED RESULTS
        Counts of label apply/change/remove events and DLP match/override events for the window (and ring),
        a labeling-coverage proxy, and a DLP override rate. Rising coverage + falling overrides = adoption.
        An empty window reports cleanly (valid pre-launch baseline).
.NOTES
    Purview — Adoption Program. Read-only. Audit-log OPERATION NAMES and record types vary by workload and
    evolve — the defaults are best-effort; verify/adjust for your tenant. Audit availability/retention is
    plan-gated. Report metrics AGGREGATE for coverage/coaching (privacy-by-design), not individual case action.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string]$RingGroup,
    [string]$CsvPath,
    # Best-effort operation sets; override for your tenant if names differ.
    [string[]]$LabelApplyOps  = @('SensitivityLabelApplied','FileSensitivityLabelApplied','SensitivityLabelUpdated','FileSensitivityLabelChanged','SensitivityLabelRemoved','FileSensitivityLabelRemoved'),
    [string[]]$DlpOps         = @('DLPRuleMatch','DLPRuleUndo','DLPInfo','DLPPolicyMatch')
)

if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    Write-Error "Search-UnifiedAuditLog not available. Run Connect-IPPSSession (or Connect-ExchangeOnline) with an Audit Reader role first."
    return
}

$start = (Get-Date).AddDays(-[math]::Abs($Days))
$end   = Get-Date

# Optional: resolve ring membership (UPNs) to scope the signal.
$ringUpns = $null
if ($RingGroup) {
    if (-not (Get-Command Get-MgGroup -ErrorAction SilentlyContinue)) {
        Write-Warning "Microsoft.Graph not available; ignoring -RingGroup and reporting tenant-wide."
    } else {
        try {
            $grp = Get-MgGroup -Filter "displayName eq '$RingGroup'" -ErrorAction Stop | Select-Object -First 1
            if (-not $grp) { Write-Warning "Ring group '$RingGroup' not found; reporting tenant-wide." }
            else {
                $ringUpns = @(Get-MgGroupMember -GroupId $grp.Id -All | ForEach-Object { $_.AdditionalProperties.userPrincipalName } | Where-Object { $_ })
                Write-Host ("Scoping signal to ring '{0}' ({1} members)." -f $RingGroup, $ringUpns.Count) -ForegroundColor Cyan
            }
        } catch { Write-Warning ("Could not resolve ring group ({0}); reporting tenant-wide." -f $_.Exception.Message) }
    }
}

function Search-Ops {
    param([string[]]$Operations, [string]$Label)
    $all = New-Object System.Collections.Generic.List[object]
    foreach ($op in $Operations) {
        try {
            $rows = Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations $op -ResultSize 5000 -ErrorAction Stop
            foreach ($r in $rows) { $all.Add($r) }
        } catch { Write-Warning ("{0}: search for '{1}' failed ({2})" -f $Label, $op, $_.Exception.Message) }
    }
    # Optional ring scoping by UserIds.
    if ($ringUpns) { $all = @($all | Where-Object { $ringUpns -contains $_.UserIds }) }
    ,$all
}

Write-Host ("=== Adoption Signal - Purview  ({0:d} .. {1:d}) ===" -f $start, $end) -ForegroundColor Cyan

$labelEvents = Search-Ops -Operations $LabelApplyOps -Label 'Labeling'
$dlpEvents   = Search-Ops -Operations $DlpOps        -Label 'DLP'

$labelApplied = @($labelEvents | Where-Object { $_.Operations -match 'Applied|Updated|Changed' }).Count
$labelRemoved = @($labelEvents | Where-Object { $_.Operations -match 'Removed' }).Count
$dlpMatch     = @($dlpEvents   | Where-Object { $_.Operations -match 'Match|Info' }).Count
$dlpOverride  = @($dlpEvents   | Where-Object { $_.Operations -match 'Undo|Override' }).Count

# Labeling-coverage proxy: applied vs (applied+removed) — a directional signal, not a document census.
$coverage = if (($labelApplied + $labelRemoved) -gt 0) { [math]::Round(100.0 * $labelApplied / ($labelApplied + $labelRemoved), 1) } else { $null }
$overrideRate = if ($dlpMatch -gt 0) { [math]::Round(100.0 * $dlpOverride / $dlpMatch, 1) } else { $null }

$summary = [pscustomobject]@{
    WindowDays        = $Days
    Scope             = if ($ringUpns) { "Ring: $RingGroup ($($ringUpns.Count))" } else { 'Tenant-wide' }
    LabelApplyEvents  = $labelApplied
    LabelRemoveEvents = $labelRemoved
    LabelingCoveragePct = if ($null -ne $coverage) { $coverage } else { 'n/a (no activity)' }
    DlpMatchEvents    = $dlpMatch
    DlpOverrideEvents = $dlpOverride
    DlpOverrideRatePct = if ($null -ne $overrideRate) { $overrideRate } else { 'n/a (no matches)' }
}
$summary | Format-List

if (($labelApplied + $labelRemoved + $dlpMatch) -eq 0) {
    Write-Host "No adoption activity in the window. (Valid as a pre-launch baseline; widen -Days or verify audit operation names for your tenant.)" -ForegroundColor Yellow
} else {
    Write-Host "Interpretation: rising label-apply + falling DLP-override = behavior is being adopted." -ForegroundColor Green
}

if ($CsvPath) { $summary | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved signal summary to {0}" -f $CsvPath) -ForegroundColor Green }
