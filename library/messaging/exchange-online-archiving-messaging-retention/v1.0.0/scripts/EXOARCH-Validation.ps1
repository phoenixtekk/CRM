<#
.SYNOPSIS
  EXOARCH-Validation.ps1 — read-only pass/fail validation of archives, move-to-archive, and holds; emits the "Archive Validation - EXO - Report". Makes NO changes.
.DESCRIPTION
  Validates the solution against its Stage-3 pass gates for the given mailboxes and reports PASS/FAIL
  per check: (1) archive Active, (2) auto-expanding archive (if expected), (3) retention policy =
  "Archive Retention Policy - EXO - Prod", (4) archive has received items (move-to-archive working /
  PST ingested), (5) expected hold present. Read-only — it only runs Get-* cmdlets. Optionally triggers
  the Managed Folder Assistant first (opt-in) so a freshly-assigned policy has a chance to process.
.EXAMPLE
  .\EXOARCH-Validation.ps1 -Identities (Get-Content .\pilot.txt)
  # Validate the pilot scope; console PASS/FAIL table.
.EXAMPLE
  .\EXOARCH-Validation.ps1 -Identities (Get-Content .\pilot.txt) -ExpectAutoExpand -ExpectHold -TriggerMfa -CsvPath .\Archive-Validation-Report.csv
  # Full validation including auto-expand + hold expectations, trigger MFA first, export the report.
  # (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline.)
.NOTES
  Expected results: all applicable checks PASS before expanding to "Archive Scope - Broad - Stage2".
  Move-to-archive is not instant — allow the MFA to process large mailboxes. Messaging — Exchange
  Online Archiving & Messaging Retention.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Identities,
    [string]$ExpectedPolicy = 'Archive Retention Policy - EXO - Prod',
    [switch]$ExpectAutoExpand,
    [switch]$ExpectHold,
    [switch]$TriggerMfa,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
    Connect-ExchangeOnline -ShowBanner:$false   # -ExchangeEnvironmentName for Gov clouds
}

Write-Host '=== Archive Validation - EXO - Report (read-only) ===' -ForegroundColor Cyan

if ($TriggerMfa) {
    Write-Host 'Triggering Managed Folder Assistant on the scope (processing is not instant)...' -ForegroundColor Yellow
    foreach ($id in $Identities) { Start-ManagedFolderAssistant -Identity $id -ErrorAction SilentlyContinue }
}

$results = foreach ($id in $Identities) {
    $mbx = try { Get-Mailbox -Identity $id -ErrorAction Stop } catch { Write-Warning ("Skip '{0}': {1}" -f $id, $_.Exception.Message); continue }

    $archiveActive = ($mbx.ArchiveStatus -eq 'Active')
    $policyOk      = ($mbx.RetentionPolicy -eq $ExpectedPolicy)
    $autoExpandOk  = (-not $ExpectAutoExpand) -or [bool]$mbx.AutoExpandingArchiveEnabled
    $holdOk        = (-not $ExpectHold) -or ($mbx.LitigationHoldEnabled -or ($mbx.InPlaceHolds -and $mbx.InPlaceHolds.Count -gt 0))

    $archiveItems = 0
    if ($archiveActive) {
        $as = Get-MailboxStatistics -Identity $mbx.Identity -Archive -ErrorAction SilentlyContinue
        if ($as) { $archiveItems = [int]$as.ItemCount }
    }
    $archiveHasItems = ($archiveItems -gt 0)   # move-to-archive working and/or PST ingested

    $checks = @{
        'Archive Active'   = $archiveActive
        'AutoExpand'       = $autoExpandOk
        'Retention Policy' = $policyOk
        'Archive HasItems' = $archiveHasItems
        'Hold'             = $holdOk
    }
    $overall = -not ($checks.Values -contains $false)

    [pscustomobject]@{
        UserPrincipalName = $mbx.UserPrincipalName
        ArchiveActive     = if ($archiveActive) { 'PASS' } else { 'FAIL' }
        AutoExpand        = if ($autoExpandOk)  { 'PASS' } else { 'FAIL' }
        RetentionPolicy   = if ($policyOk)      { 'PASS' } else { 'FAIL' }
        ArchiveHasItems   = if ($archiveHasItems) { 'PASS' } else { 'WARN' }   # may be pending MFA
        Hold              = if ($holdOk)        { 'PASS' } else { 'FAIL' }
        ArchiveItems      = $archiveItems
        Overall           = if ($overall)       { 'PASS' } else { 'FAIL' }
    }
}

$results | Format-Table UserPrincipalName,ArchiveActive,AutoExpand,RetentionPolicy,ArchiveHasItems,Hold,Overall -AutoSize

$pass = @($results | Where-Object { $_.Overall -eq 'PASS' }).Count
Write-Host ("Validation: {0}/{1} mailboxes PASS all applicable gates." -f $pass, @($results).Count) -ForegroundColor Cyan
Write-Host 'Note: "Archive HasItems = WARN" can mean the Managed Folder Assistant has not finished moving aged mail yet — re-run after it processes.' -ForegroundColor DarkGray

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved 'Archive Validation - EXO - Report' to {0}" -f $CsvPath) -ForegroundColor Green
}
