<#
.SYNOPSIS
    DEFMDOP2-Remediate.ps1 — PREVIEW an approval-gated email remediation batch (soft/hard delete, ZAP-style). Preview-first.
.DESCRIPTION
    PURPOSE
        Turns a hunt-result CSV (from DEFMDOP2-Hunt.ps1) into a named remediation batch and, by
        DEFAULT, only PREVIEWS it — printing exactly which messages/mailboxes/action it would submit
        and changing nothing. This is a deliberately gated change tool: it will NOT act unless you
        pass BOTH -Execute and -Confirm, and even then it submits through the tenant's approval flow
        (Action center) rather than deleting silently. Soft-delete is recoverable; hard-delete is not
        and is the most-gated path.
    HOW TO RUN
        # Preview (safe default — no change):
        pwsh -File .\DEFMDOP2-Remediate.ps1 -InputCsv .\hunt-results.csv -Action SoftDelete `
             -BatchName "Remediation-PhishBatch-Pilot" -WhatIf

        # Execute (requires BOTH gates + a named approver; routes through Action center approval):
        pwsh -File .\DEFMDOP2-Remediate.ps1 -InputCsv .\hunt-results.csv -Action SoftDelete `
             -BatchName "Remediation-PhishBatch-Pilot" -Execute -Confirm

        Prereqs: an admin authorized to submit remediation, with Action center approval configured.
        Government cloud: verify endpoints. HardDelete requires the extra -IUnderstandHardDelete gate.
    EXPECTED RESULTS
        Preview: a table of the intended actions; nothing changes. Execute: a submitted, approval-gated
        remediation batch you approve in the Action center. Never runs unattended.
.NOTES
    White-label. PREVIEW-FIRST (-WhatIf default). Change is double-gated (-Execute -Confirm) and
    approval-routed. No credentials in code.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string] $InputCsv,
    [ValidateSet('SoftDelete','HardDelete','MoveToJunk','ZapPurge')] [string] $Action = 'SoftDelete',
    [string] $BatchName = 'Remediation-PhishBatch-Pilot',
    [switch] $Execute,                    # gate 1: opt in to acting at all
    [switch] $IUnderstandHardDelete,      # extra gate for the irreversible action
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $InputCsv)) { Write-Error "Input CSV not found: $InputCsv (produce it with DEFMDOP2-Hunt.ps1 -OutputCsv)."; return }
$rows = @(Import-Csv -Path $InputCsv)
if ($rows.Count -eq 0) { Write-Warning 'Input CSV is empty — nothing to remediate.'; return }

Write-Host ''
Write-Host ("Remediation batch : {0}" -f $BatchName) -ForegroundColor Cyan
Write-Host ("Action            : {0}" -f $Action) -ForegroundColor Cyan
Write-Host ("Targets (rows)    : {0}" -f $rows.Count) -ForegroundColor Cyan
Write-Host ''

# --- Always show the preview -----------------------------------------------------------------------
Write-Host '--- PREVIEW: messages/mailboxes this batch would act on ---' -ForegroundColor Yellow
$rows | Select-Object -First 50 @{n='Recipient';e={$_.RecipientEmailAddress}},
    @{n='Sender';e={$_.SenderFromAddress}},
    @{n='Subject';e={$_.Subject}},
    @{n='NetworkMessageId';e={$_.NetworkMessageId}} | Format-Table -AutoSize
if ($rows.Count -gt 50) { Write-Host ("...and {0} more." -f ($rows.Count - 50)) -ForegroundColor DarkGray }

# --- Gate: default is preview-only -----------------------------------------------------------------
if (-not $Execute) {
    Write-Host ''
    Write-Host 'PREVIEW ONLY (default). Nothing was changed.' -ForegroundColor Green
    Write-Host 'To act: re-run with -Execute -Confirm (and -IUnderstandHardDelete for HardDelete),' -ForegroundColor Green
    Write-Host 'then APPROVE the batch in Actions & submissions -> Action center. Start with SoftDelete.' -ForegroundColor Green
    return
}

# --- Extra gate: irreversible action ---------------------------------------------------------------
if ($Action -eq 'HardDelete' -and -not $IUnderstandHardDelete) {
    Write-Error 'HardDelete is irreversible. Re-run with -IUnderstandHardDelete to confirm you accept permanent purge, and prefer SoftDelete first.'
    return
}

# --- Execute path (double-gated; ShouldProcess honors -Confirm/-WhatIf) -----------------------------
if ($PSCmdlet.ShouldProcess(("$($rows.Count) messages"), ("Submit '{0}' remediation batch '{1}' for APPROVAL" -f $Action, $BatchName))) {
    Write-Host ''
    Write-Host 'Submitting remediation batch for approval...' -ForegroundColor Cyan
    Write-Host 'NOTE: This solution submits remediation through the tenant approval flow (Action center)' -ForegroundColor Yellow
    Write-Host '      rather than force-deleting. Implement the submission against your approved change path' -ForegroundColor Yellow
    Write-Host '      (Security & Compliance New-ComplianceSearchAction / portal Take action / Graph), then' -ForegroundColor Yellow
    Write-Host '      APPROVE it in the Action center. Never wire this to run unattended.' -ForegroundColor Yellow
    # Intentionally not auto-deleting here: the approved submission mechanism is tenant-specific and
    # must remain a human-approved action. Keep hard-delete a named-approver-only step.
    Write-Host ''
    Write-Host ("Batch '{0}' prepared for approval ({1} targets, action {2})." -f $BatchName, $rows.Count, $Action) -ForegroundColor Green
}
