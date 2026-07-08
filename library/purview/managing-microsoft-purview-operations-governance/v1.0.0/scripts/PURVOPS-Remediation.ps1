<#
.SYNOPSIS
    PURVOPS-Remediation.ps1 — change-controlled Purview ops/config helper: promote a piloted policy to enforce, or roll it back. -WhatIf by DEFAULT; writes only with -Commit.
.DESCRIPTION
    PURPOSE
        The one write-capable operating tool, safe by default. Performs the routine lifecycle transitions
        under change control: PromotePolicy (move a DLP or auto-labeling policy from test/simulation to
        enforce, Mode=Enable) and RollbackPolicy (return it to a test/disabled mode). With no -Commit it
        PREVIEWS the change and makes NONE. On -Commit it applies the change and appends a row to the change
        record CSV (who/when/what/from/to). No credentials or secrets in code.
    HOW TO RUN
        Connect-IPPSSession                                  # modern-auth admin sign-in (no secrets in code)
        # Preview (default, no change):
        .\PURVOPS-Remediation.ps1 -Action PromotePolicy -PolicyName "Finance DLP - Pilot" -WhatIf
        # Apply inside a change window:
        .\PURVOPS-Remediation.ps1 -Action PromotePolicy -PolicyName "Finance DLP - Pilot" -Commit
        .\PURVOPS-Remediation.ps1 -Action RollbackPolicy -PolicyName "Finance DLP - Pilot" -RollbackMode TestWithNotifications -Commit
        PowerShell 5.1+/7+; requires Security & Compliance PowerShell (Set-DlpCompliancePolicy / Set-AutoSensitivityLabelPolicy).
    EXPECTED RESULTS
        -WhatIf: prints the intended From->To mode and confirms NO change was made.
        -Commit: mode changes as previewed AND a row is written to the change record CSV.
.NOTES
    Purview — Operations & Governance. HIGH-IMPACT: only promote a policy whose simulation/test results are
    clean, only in a change window, with approval. Retention/records changes and any legal-hold action are
    DEFERRED to records/legal and are intentionally NOT automated here. Verify licensing/tenant.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][ValidateSet('PromotePolicy','RollbackPolicy')][string]$Action,
    [Parameter(Mandatory=$true)][string]$PolicyName,
    [ValidateSet('DLP','AutoLabeling')][string]$PolicyType = 'DLP',
    [ValidateSet('TestWithNotifications','TestWithoutNotifications','Disable')][string]$RollbackMode = 'TestWithNotifications',
    [switch]$Commit,
    [string]$ChangeRecordCsv = '.\Change-Record-Purview.csv'
)

# Safe by default: unless -Commit is passed, force -WhatIf behavior (no writes).
if (-not $Commit) { $WhatIfPreference = $true }

if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Error "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first."
    return
}

# Resolve the current policy + mode.
$getCmd = if ($PolicyType -eq 'DLP') { 'Get-DlpCompliancePolicy' } else { 'Get-AutoSensitivityLabelPolicy' }
$setCmd = if ($PolicyType -eq 'DLP') { 'Set-DlpCompliancePolicy' } else { 'Set-AutoSensitivityLabelPolicy' }

$policy = & $getCmd -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $policy) {
    Write-Error "Policy '$PolicyName' ($PolicyType) not found. Check the name with PURVOPS-Discovery.ps1."
    return
}
$fromMode = [string]$policy.Mode
$toMode   = if ($Action -eq 'PromotePolicy') { 'Enable' } else { $RollbackMode }

Write-Host ("=== {0}: '{1}' ({2}) ===" -f $Action, $PolicyName, $PolicyType) -ForegroundColor Cyan
Write-Host ("Current mode: {0}   -->   target mode: {1}" -f $fromMode, $toMode) -ForegroundColor Cyan

if ($fromMode -eq $toMode) {
    Write-Host "Policy already in the target mode. Nothing to do." -ForegroundColor Green
    return
}

if ($Action -eq 'PromotePolicy' -and $fromMode -notmatch 'Test|Disable') {
    Write-Warning "Policy is not currently in a test/disabled mode — confirm this is an intended re-enforce."
}

# ShouldProcess honors -WhatIf; with the safe default above, no -Commit = no change.
if ($PSCmdlet.ShouldProcess("$PolicyType policy '$PolicyName'", "set Mode $fromMode -> $toMode")) {
    try {
        & $setCmd -Identity $PolicyName -Mode $toMode -ErrorAction Stop
        Write-Host ("APPLIED: '{0}' is now Mode={1}." -f $PolicyName, $toMode) -ForegroundColor Green

        # Append change record (idempotent create).
        $record = [pscustomobject]@{
            TimestampUtc = (Get-Date).ToUniversalTime().ToString('s')
            Operator     = $(try { (Get-ConnectionInformation | Select-Object -First 1).UserPrincipalName } catch { $env:USERNAME })
            Action       = $Action
            PolicyType   = $PolicyType
            PolicyName   = $PolicyName
            FromMode     = $fromMode
            ToMode       = $toMode
        }
        $record | Export-Csv -Path $ChangeRecordCsv -NoTypeInformation -Append
        Write-Host ("Change recorded in {0}." -f $ChangeRecordCsv) -ForegroundColor Green
    } catch {
        Write-Error ("Change FAILED: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "WHATIF (default): no change made. Re-run with -Commit inside a change window to apply." -ForegroundColor Yellow
}
