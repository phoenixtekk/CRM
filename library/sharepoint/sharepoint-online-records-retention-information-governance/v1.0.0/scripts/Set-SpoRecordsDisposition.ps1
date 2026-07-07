<#
.SYNOPSIS
  Configure/validate record + regulatory-record labels and disposition-review wiring (dry-run default).
.DESCRIPTION
  For a named retention label, sets records declaration (-IsRecordLabel), optional regulatory-record
  status, and disposition-review reviewers (-ReviewerEmail) via Set-ComplianceTag, and validates the
  reviewer accounts are in the Disposition Management role group. Dry-run by default; writes only with
  -Commit. Refuses to set the irreversible -Regulatory flag unless -ConfirmRegulatory is also passed.
.EXAMPLE
  .\Set-SpoRecordsDisposition.ps1 -LabelName "Record Label - Contracts - Pilot" -Reviewers dispo@contoso.com
  .\Set-SpoRecordsDisposition.ps1 -LabelName "Record Label - Contracts - Pilot" -Reviewers dispo@contoso.com -Commit
  # (PowerShell 5.1+/7+; ExchangeOnlineManagement; Connect-IPPSSession)
.NOTES
  Expected results: without -Commit, the planned record/disposition settings are printed (no change).
  With -Commit, the label is a record with the named reviewers and end-of-retention disposition review.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$LabelName,

    # Disposition reviewers (must be in the Disposition Management role group).
    [string[]]$Reviewers = @(),

    # Mark as a regulatory record - IRREVERSIBLE. Requires -ConfirmRegulatory.
    [switch]$Regulatory,
    [switch]$ConfirmRegulatory,

    [switch]$Commit
)

$ErrorActionPreference = 'Stop'

if ($Regulatory -and -not $ConfirmRegulatory) {
    throw "Refusing to set -Regulatory (a regulatory record is IRREVERSIBLE). Re-run with -ConfirmRegulatory to proceed under records/legal sign-off."
}

$tag = Get-ComplianceTag -Identity $LabelName -ErrorAction Stop
Write-Host "Label: $($tag.Name)  (currently IsRecordLabel=$($tag.IsRecordLabel), Regulatory=$($tag.Regulatory))" -ForegroundColor Cyan

# --- Validate reviewer accounts are in Disposition Management (best-effort, read-only) ---
if ($Reviewers.Count -gt 0) {
    try {
        $dm = Get-RoleGroupMember -Identity "Disposition Management" -ErrorAction Stop |
              Select-Object -ExpandProperty PrimarySmtpAddress
        foreach ($r in $Reviewers) {
            if ($dm -contains $r) { Write-Host "  reviewer OK (in Disposition Management): $r" -ForegroundColor Green }
            else { Write-Warning "  reviewer NOT in Disposition Management role group: $r" }
        }
    }
    catch {
        Write-Warning "Could not read the Disposition Management role group membership: $_"
    }
}

# --- Build the change set ---
$set = @{ Identity = $LabelName; IsRecordLabel = $true }
if ($Reviewers.Count -gt 0) { $set['ReviewerEmail'] = $Reviewers }
if ($Regulatory) { $set['Regulatory'] = $true }

$plan = ($set.GetEnumerator() | Where-Object Key -ne 'Identity' | ForEach-Object { "$($_.Key)=$($_.Value -join ';')" }) -join ", "
if ($Commit) {
    if ($PSCmdlet.ShouldProcess($LabelName, "Set-ComplianceTag ($plan)")) {
        Set-ComplianceTag @set | Out-Null
        Write-Host "COMMITTED: $LabelName -> $plan" -ForegroundColor Green
    }
}
else {
    Write-Host "WOULD SET: $LabelName -> $plan" -ForegroundColor Yellow
    Write-Host "Dry-run complete. Re-run with -Commit (under change control) to apply." -ForegroundColor Cyan
}
