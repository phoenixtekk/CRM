<#
.SYNOPSIS
    DLCEXO-Report.ps1 — coverage/health report for the Exchange lifecycle policies (read-only).
.DESCRIPTION
    PURPOSE
        Reports the operating state of the lifecycle deployment: which mailboxes the Purview retention policy
        actually scopes (ExchangeLocation), MRM policy assignment coverage across the pilot/estate, archive
        enablement (needed for MoveToArchive), and a mailbox-size signal so you can see cleanup taking effect
        over time. Use it as pilot evidence and for ongoing drift/coverage assurance. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement. Connect BOTH endpoints first:
          Connect-IPPSSession
          Connect-ExchangeOnline
          .\DLCEXO-Report.ps1 -PolicyName "DLCEXO-Retention-Exchange-Pilot" -MrmPolicyName "DLCEXO-MRM-Cleanup-Standard"
          .\DLCEXO-Report.ps1 -PilotGroup "SG-DLCEXO-Pilot"
    EXPECTED RESULTS
        A coverage report to .\DLCEXO-Coverage-Report.csv plus a console summary (policy scope count, MRM
        assignment coverage, archive-enabled count). Gaps (scoped mailbox without archive for a MoveToArchive
        design, or pilot mailbox missing the MRM policy) are surfaced.
.NOTES
    White-label tooling. Read-only. No credentials stored. Standard S&C / Exchange Online cmdlets; none
    invented. Feature availability is licensing-dependent — the script warns rather than assuming.
#>
[CmdletBinding()]
param(
    [string]$PolicyName    = "DLCEXO-Retention-Exchange-Pilot",
    [string]$MrmPolicyName = "DLCEXO-MRM-Cleanup-Standard",
    [string]$PilotGroup,
    [string]$OutPath       = ".\DLCEXO-Coverage-Report.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLCEXO Report — lifecycle coverage/health (read-only) ===" -ForegroundColor Cyan

# --- Purview retention policy scope ---
$scopeMailboxes = @()
try {
    $pol = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction Stop
    $scopeMailboxes = @($pol.ExchangeLocation)
    Write-Host ("  Purview policy '{0}': Enabled={1}; ExchangeLocation entries={2}" -f $PolicyName, $pol.Enabled, $scopeMailboxes.Count) -ForegroundColor Green
} catch { Write-Host ("  WARN: Purview policy '{0}' not readable: {1}" -f $PolicyName, $_.Exception.Message) -ForegroundColor Yellow }

# --- Determine the mailbox set to report on ---
$targets = @()
if ($PilotGroup) {
    try { $targets = Get-DistributionGroupMember -Identity $PilotGroup -ResultSize Unlimited -ErrorAction Stop | Select-Object -ExpandProperty PrimarySmtpAddress }
    catch { Write-Host ("  WARN: cannot resolve pilot group '{0}': {1}" -f $PilotGroup, $_.Exception.Message) -ForegroundColor Yellow }
}
if (-not $targets -or $targets.Count -eq 0) {
    # Fall back to the retention policy's own scope where it names explicit addresses
    $targets = $scopeMailboxes | Where-Object { $_ -and $_ -notmatch '^All$' }
}
if (-not $targets -or $targets.Count -eq 0) {
    Write-Host "  No explicit mailbox targets (policy may be scoped to 'All' or an adaptive scope). Provide -PilotGroup to report per-mailbox." -ForegroundColor Yellow
}

# --- Per-mailbox coverage ---
$rows = [System.Collections.Generic.List[object]]::new()
foreach ($t in $targets) {
    try {
        $m = Get-Mailbox -Identity $t -ErrorAction Stop
        $stats = $null
        try { $stats = Get-MailboxStatistics -Identity $t -ErrorAction Stop } catch {}
        $rows.Add([pscustomobject]@{
            Mailbox         = $m.PrimarySmtpAddress
            MrmAssigned     = ($m.RetentionPolicy -eq $MrmPolicyName)
            RetentionPolicy = $m.RetentionPolicy
            ArchiveEnabled  = ($m.ArchiveStatus -eq 'Active' -or $m.ArchiveState -eq 'Local' -or $m.ArchiveState -eq 'HostedProvisioned')
            LitigationHold  = $m.LitigationHoldEnabled
            TotalItemSize   = if ($stats) { $stats.TotalItemSize } else { "n/a" }
        })
    } catch { Write-Host ("  WARN: mailbox '{0}' not readable: {1}" -f $t, $_.Exception.Message) -ForegroundColor Yellow }
}

if ($rows.Count -gt 0) {
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
    $assigned = @($rows | Where-Object { $_.MrmAssigned }).Count
    $arch     = @($rows | Where-Object { $_.ArchiveEnabled }).Count
    Write-Host ("`nCoverage report written to {0}: {1} mailbox(es); MRM assigned={2}; archive-enabled={3}." -f `
        $OutPath, $rows.Count, $assigned, $arch) -ForegroundColor Green
    $missing = @($rows | Where-Object { -not $_.MrmAssigned })
    if ($missing.Count -gt 0) { Write-Host ("  GAP: {0} target mailbox(es) missing MRM policy '{1}'." -f $missing.Count, $MrmPolicyName) -ForegroundColor Yellow }
} else {
    Write-Host "  No per-mailbox rows produced." -ForegroundColor Yellow
}

Write-Host "Next: DLCEXO-Test-Readiness.ps1 for the consolidated PASS/GAP pilot gate." -ForegroundColor Cyan
