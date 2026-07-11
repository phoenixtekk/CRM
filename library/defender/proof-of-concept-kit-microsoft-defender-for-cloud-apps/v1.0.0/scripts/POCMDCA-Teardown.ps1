<#
.SYNOPSIS
    POCMDCA-Teardown.ps1 — clean rollback of the MDCA proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Returns the tenant to its pre-PoC state. It guides removal of:
          - the audit-mode activity policy 'MDCA PoC Activity Policy - Pilot Users - Audit',
          - the Cloud Discovery snapshot report 'MDCA PoC Discovery - Pilot - Report',
          - the optional app connector,
        and reminds you to resolve the MDCA-PoC-TESTSIGNAL alerts. MDCA policy/report objects are
        removed in the portal; this script marks intent behind -WhatIf. Nothing was ever enforced,
        so there is no blocking to undo.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-Teardown.ps1 -WhatIf
        # Apply (prints the guided steps and marks intent):
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-Teardown.ps1
    EXPECTED RESULTS
        The audit policy, discovery report, and connector removed, and test alerts resolved.
.NOTES
    White-label. Reversible teardown. Audit-mode only — no enforcement to roll back.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PolicyName = 'MDCA PoC Activity Policy - Pilot Users - Audit',
    [string]$ReportName = 'MDCA PoC Discovery - Pilot - Report',
    [string]$ConnectorName = 'MDCA PoC Connector - Microsoft365 - Pilot',
    [string]$Tag = 'MDCA-PoC-TESTSIGNAL'
)

Write-Host "`n=== POCMDCA — teardown (preview by default) ===" -ForegroundColor Cyan

# 1) Delete the audit policy.
Write-Host "`n[1] Delete the audit-mode activity policy:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess($PolicyName, "Delete activity policy")) {
    Write-Host "  security.microsoft.com -> Cloud apps -> Policies -> Policy management -> delete '$PolicyName'." -ForegroundColor Green
} else { Write-Host "  [WhatIf] Would delete policy '$PolicyName'." -ForegroundColor Yellow }

# 2) Delete the discovery report.
Write-Host "`n[2] Delete the Cloud Discovery snapshot report:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess($ReportName, "Delete Cloud Discovery report")) {
    Write-Host "  Cloud apps -> Cloud discovery -> Snapshot reports -> delete '$ReportName'." -ForegroundColor Green
} else { Write-Host "  [WhatIf] Would delete discovery report '$ReportName'." -ForegroundColor Yellow }

# 3) Remove the optional connector.
Write-Host "`n[3] Remove the optional app connector (if added):" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess($ConnectorName, "Disconnect app connector")) {
    Write-Host "  Cloud apps -> Connected apps -> App connectors -> disconnect '$ConnectorName'." -ForegroundColor Green
} else { Write-Host "  [WhatIf] Would disconnect connector '$ConnectorName'." -ForegroundColor Yellow }

# 4) Resolve test alerts.
Write-Host "`n[4] Resolve the benign test alerts:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess("$Tag alerts", "Resolve test alerts")) {
    Write-Host "  Incidents & alerts (or Cloud apps -> Alerts) -> resolve '$Tag' items as 'Not a threat / test'." -ForegroundColor Green
} else { Write-Host "  [WhatIf] Would resolve '$Tag' alerts." -ForegroundColor Yellow }

Write-Host "`nConfirm with: POCMDCA-Validate.ps1  (policy and report should be gone)." -ForegroundColor Cyan
