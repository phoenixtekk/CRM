<#
.SYNOPSIS
  EXOARCH-Set-Holds.ps1 — report current holds, and (with -Commit) apply litigation hold from a legal determination. SAFE BY DEFAULT: report/-WhatIf.
.DESCRIPTION
  Two modes for the holds stage:
    REPORT (default): lists LitigationHoldEnabled / duration / InPlaceHolds for the given mailboxes —
      read-only, use it to inventory holds at any time.
    APPLY (-Commit):  enables LITIGATION HOLD on the mailboxes in -Identities, tagging owner/duration
      from the legal/records determination. In-Place/eDiscovery holds are created in a Purview
      eDiscovery case (portal), NOT by this script — this script reports them but does not create them.
  WHAT to hold, for whom, and for how long is a LEGAL/RECORDS DETERMINATION — pass only the
  legal-owner-provided identities. Without -Commit it changes nothing; -WhatIf is honored.
.EXAMPLE
  .\EXOARCH-Set-Holds.ps1 -Identities (Get-Content .\held.txt)
  # Report-only: current hold state for these mailboxes.
.EXAMPLE
  .\EXOARCH-Set-Holds.ps1 -Identities (Get-Content .\held.txt) -Matter "MAT-2026-014" -DurationDays 2555 -Commit
  # Apply litigation hold "Litigation Hold - MAT-2026-014 - Legal" (7 years) per the determination.
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline.)
.NOTES
  Expected results: held mailboxes report LitigationHoldEnabled True; released only on legal instruction.
  Never release a hold on your own initiative. Messaging — Exchange Online Archiving & Messaging Retention.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Identities,
    [string]$Matter,
    [int]$DurationDays,          # omit for an indefinite hold
    [string]$HoldOwner,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    Connect-ExchangeOnline -ShowBanner:$false   # -ExchangeEnvironmentName for Gov clouds
}

$applying = $Commit.IsPresent
if (-not $applying) { Write-Host 'REPORT MODE (read-only). Re-run with -Commit + -Matter to apply litigation hold.' -ForegroundColor Yellow }
else {
    if (-not $Matter) { throw 'Apply mode requires -Matter (the legal/records matter identifier). Aborting.' }
    Write-Host ("APPLY MODE — litigation hold 'Litigation Hold - {0} - Legal' per the legal/records determination." -f $Matter) -ForegroundColor Red
}

$report = foreach ($id in $Identities) {
    $mbx = try { Get-Mailbox -Identity $id -ErrorAction Stop } catch { Write-Warning ("Skip '{0}': {1}" -f $id, $_.Exception.Message); continue }

    if ($applying -and -not $mbx.LitigationHoldEnabled) {
        if ($PSCmdlet.ShouldProcess($mbx.UserPrincipalName, "Set-Mailbox -LitigationHoldEnabled `$true (Matter $Matter)")) {
            $params = @{ Identity = $mbx.Identity; LitigationHoldEnabled = $true; ErrorAction = 'Stop' }
            if ($DurationDays) { $params.LitigationHoldDuration = $DurationDays }
            if ($HoldOwner)    { $params.LitigationHoldOwner    = $HoldOwner }
            try {
                Set-Mailbox @params
                Write-Host ("[hold applied] {0} — Matter {1}" -f $mbx.UserPrincipalName, $Matter) -ForegroundColor Green
                $mbx = Get-Mailbox -Identity $mbx.Identity
            } catch {
                Write-Warning ("[fail] {0} — {1}" -f $mbx.UserPrincipalName, $_.Exception.Message)
            }
        }
    }

    [pscustomobject]@{
        UserPrincipalName      = $mbx.UserPrincipalName
        LitigationHoldEnabled  = $mbx.LitigationHoldEnabled
        LitigationHoldDuration = $mbx.LitigationHoldDuration
        LitigationHoldOwner    = $mbx.LitigationHoldOwner
        InPlaceHolds           = ($mbx.InPlaceHolds -join ';')   # eDiscovery holds are managed in the Purview case
    }
}

$report | Format-Table -AutoSize
Write-Host 'Note: In-Place / eDiscovery holds ("eDiscovery Hold - <Matter> - Legal") are created in the Microsoft Purview eDiscovery case, not here.' -ForegroundColor Cyan
