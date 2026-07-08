<#
.SYNOPSIS
    DLCEXO-Set-Scope.ps1 — record the pilot/expansion lifecycle scope as a read-only manifest (changes nothing).
.DESCRIPTION
    PURPOSE
        Captures the intended Exchange lifecycle scope — pilot group and its resolved mailboxes, the target
        retention duration + disposition, and the cleanup tag design — into a manifest you configure against.
        Resolving the pilot group's current members up front makes the blast radius explicit BEFORE any
        policy is created. Read-only: it records intent, it does not create or change any policy.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement (Connect-ExchangeOnline for group resolution):
          Connect-ExchangeOnline
          .\DLCEXO-Set-Scope.ps1 -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete
    EXPECTED RESULTS
        A scope manifest written to .\DLCEXO-Scope-Manifest.csv (resolved pilot mailboxes + intended
        settings) and a one-line summary. Use it as the source of truth for DLCEXO-Configure.ps1.
.NOTES
    White-label tooling. Read-only. No credentials stored. Group resolution uses standard Exchange Online
    cmdlets; none are invented. Durations/dispositions come from your records schedule (R4) — this script
    validates format only, not policy.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PilotGroup,
    [Parameter(Mandatory)][int]$RetainDays,
    [ValidateSet("Retain","Delete","KeepAndDelete")][string]$Disposition = "Retain",
    [string]$OutPath = ".\DLCEXO-Scope-Manifest.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLCEXO Set-Scope — record lifecycle scope manifest (read-only) ===" -ForegroundColor Cyan
if ($Disposition -ne "Retain") {
    Write-Host ("  NOTE: Disposition '{0}' includes a DELETE action. Retention delete has no simulation mode and is largely irreversible — pilot first, retain-first recommended (see 01-solution-overview)." -f $Disposition) -ForegroundColor Yellow
}

# --- Resolve pilot group members to mailboxes (makes the blast radius explicit) ---
$members = @()
try {
    $members = Get-DistributionGroupMember -Identity $PilotGroup -ResultSize Unlimited -ErrorAction Stop |
        Select-Object -ExpandProperty PrimarySmtpAddress
    Write-Host ("  Pilot group '{0}' resolves to {1} member(s)." -f $PilotGroup, @($members).Count) -ForegroundColor Green
} catch {
    Write-Host ("  WARN: could not resolve group '{0}' (is it a mail-enabled/distribution group?): {1}" -f $PilotGroup, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  Recording the group name only; resolve membership before -Commit." -ForegroundColor Yellow
    $members = @("<unresolved: $PilotGroup>")
}

$manifest = foreach ($m in $members) {
    [pscustomobject]@{
        PilotGroup       = $PilotGroup
        Mailbox          = $m
        RetainDays       = $RetainDays
        Disposition      = $Disposition
        MrmPolicy        = "DLCEXO-MRM-Cleanup-Standard"
        MrmTags          = "DLCEXO-Tag-DeletedItems-30d; DLCEXO-Tag-JunkEmail-30d; DLCEXO-Tag-Default-MoveToArchive-2yr"
        PurviewPolicy    = "DLCEXO-Retention-Exchange-Pilot"
        PurviewRule      = "DLCEXO-Rule-Exchange-Keep7yrThenDelete"
        Recorded         = (Get-Date).ToString("s")
    }
}
$manifest | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8

Write-Host ("`nScope manifest written to {0}  ({1} mailbox row(s); RetainDays={2}; Disposition={3})" -f `
    $OutPath, @($manifest).Count, $RetainDays, $Disposition) -ForegroundColor Green
Write-Host "This changed nothing. Next: DLCEXO-Configure.ps1 -WhatIf (preview) then -Commit." -ForegroundColor Cyan
