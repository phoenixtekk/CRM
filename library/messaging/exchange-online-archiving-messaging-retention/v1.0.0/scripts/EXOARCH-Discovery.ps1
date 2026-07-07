<#
.SYNOPSIS
  EXOARCH-Discovery.ps1 — read-only Exchange Online archive/hold posture + mailbox-size assessment. Makes NO changes.
.DESCRIPTION
  Builds the "Archive Posture - EXO - Discovery" baseline for the Exchange Online Archiving solution:
  per mailbox it reports archive status, archive GUID, auto-expanding-archive flag, the assigned
  retention policy, primary + archive size/item counts, litigation-hold state, and any In-Place hold
  GUIDs. Read-only — it only runs Get-* cmdlets. Use it in Stage 0 (Assess) and to re-verify after
  changes.
.EXAMPLE
  .\EXOARCH-Discovery.ps1
  # Assess the whole tenant, console summary only.
.EXAMPLE
  .\EXOARCH-Discovery.ps1 -Identities (Get-Content .\pilot.txt) -CsvPath .\Archive-Posture-Discovery.csv
  # Assess a pilot set and export the "Archive Posture - EXO - Discovery" CSV.
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline.)
.NOTES
  Expected results: a per-mailbox table (ArchiveStatus, AutoExpand, RetentionPolicy, sizes, holds).
  Pass signal for later stages: licensed mailboxes show ArchiveStatus Active once enabled and holds
  match the legal determination. Messaging — Exchange Online Archiving & Messaging Retention.
#>
[CmdletBinding()]
param(
    [string[]]$Identities,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement (EXO V3) for current user...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    # Add -ExchangeEnvironmentName O365USGovGCCHigh / O365USGovDoD on Government clouds.
    Connect-ExchangeOnline -ShowBanner:$false
}

Write-Host '=== Archive Posture - EXO - Discovery (read-only) ===' -ForegroundColor Cyan

if ($Identities) {
    $mailboxes = foreach ($id in $Identities) {
        try { Get-Mailbox -Identity $id -ErrorAction Stop }
        catch { Write-Warning ("Cannot read mailbox '{0}': {1}" -f $id, $_.Exception.Message) }
    }
} else {
    $mailboxes = Get-Mailbox -ResultSize Unlimited
}

$rows = foreach ($mbx in $mailboxes) {
    $primaryStats = Get-MailboxStatistics -Identity $mbx.Identity -ErrorAction SilentlyContinue
    $archiveStats = $null
    if ($mbx.ArchiveStatus -eq 'Active') {
        $archiveStats = Get-MailboxStatistics -Identity $mbx.Identity -Archive -ErrorAction SilentlyContinue
    }
    [pscustomobject]@{
        UserPrincipalName        = $mbx.UserPrincipalName
        ArchiveStatus            = $mbx.ArchiveStatus
        ArchiveGuidSet           = ($mbx.ArchiveGuid -and $mbx.ArchiveGuid -ne [guid]::Empty)
        AutoExpandingArchive     = $mbx.AutoExpandingArchiveEnabled
        RetentionPolicy          = $mbx.RetentionPolicy
        PrimarySize              = if ($primaryStats) { $primaryStats.TotalItemSize } else { 'n/a' }
        PrimaryItems             = if ($primaryStats) { $primaryStats.ItemCount } else { 'n/a' }
        ArchiveSize              = if ($archiveStats) { $archiveStats.TotalItemSize } else { 'n/a' }
        ArchiveItems             = if ($archiveStats) { $archiveStats.ItemCount } else { 'n/a' }
        LitigationHoldEnabled    = $mbx.LitigationHoldEnabled
        LitigationHoldDuration   = $mbx.LitigationHoldDuration
        InPlaceHolds             = ($mbx.InPlaceHolds -join ';')
    }
}

$rows | Sort-Object UserPrincipalName | Format-Table UserPrincipalName,ArchiveStatus,AutoExpandingArchive,RetentionPolicy,LitigationHoldEnabled -AutoSize

$archiveOn = @($rows | Where-Object { $_.ArchiveStatus -eq 'Active' }).Count
$held      = @($rows | Where-Object { $_.LitigationHoldEnabled -or $_.InPlaceHolds }).Count
Write-Host ("Mailboxes assessed: {0} | archive Active: {1} | with a hold: {2}" -f $rows.Count, $archiveOn, $held) -ForegroundColor Cyan

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved 'Archive Posture - EXO - Discovery' to {0}" -f $CsvPath) -ForegroundColor Green
}
