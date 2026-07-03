<#
.SYNOPSIS
    EXOMIGG-Report.ps1 — Read-only per-mailbox migration status and validation report for GCC High.
.DESCRIPTION
    PURPOSE
        Produces a per-mailbox report used at the Pilot, per-Wave, and Closeout gates: migration/move-request
        status, item and folder counts, mailbox size, and permission/delegation inventory. Point it at a set of
        mailboxes (a CSV of addresses, or all) in a GCC High tenant. Placeholders use plain text like
        your-admin-upn and your-mailboxes.csv (column: PrimarySmtpAddress).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EXOMIGG-Report.ps1 -AdminUpn your-admin-upn -MailboxCsv your-mailboxes.csv -OutputFolder .\EXOMIGG-baseline
        (Connects with -ExchangeEnvironmentName O365USGovGCCHigh)
    EXPECTED RESULTS
        A CSV report plus console summary. PASS at a gate = every listed mailbox shows completed status with item
        counts and permissions intact. FAIL = missing content/permissions (see 05-testing.md Gate 3 / 06-troubleshooting.md).
.NOTES
    White-label — the repeatable way. Read-only against EXO US Gov endpoints. No changes are made.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]  [string] $AdminUpn,
    [Parameter(Mandatory = $false)] [string] $MailboxCsv,
    [Parameter(Mandatory = $false)] [string] $OutputFolder = ".\EXOMIGG-baseline"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -UserPrincipalName $AdminUpn -ShowBanner:$false
} catch {
    Write-Host "FAIL: could not connect to GCC High Exchange Online. Verify -ExchangeEnvironmentName O365USGovGCCHigh (06-troubleshooting.md #1)." -ForegroundColor Red
    throw
}

# Determine target mailbox set
if ($MailboxCsv) {
    $targets = (Import-Csv $MailboxCsv).PrimarySmtpAddress
} else {
    $targets = (Get-Mailbox -ResultSize Unlimited).PrimarySmtpAddress
}

# Move-request status (native moves). Empty is fine for tool/PST paths.
$moveStatus = @{}
try {
    Get-MoveRequest -ErrorAction SilentlyContinue | ForEach-Object {
        $moveStatus[$_.DisplayName] = $_.Status
    }
} catch { }

$rows = foreach ($addr in $targets) {
    $mb = Get-Mailbox -Identity $addr -ErrorAction SilentlyContinue
    if (-not $mb) {
        [pscustomobject]@{ PrimarySmtpAddress = $addr; Found = $false }
        continue
    }
    $st  = Get-MailboxStatistics -Identity $addr -ErrorAction SilentlyContinue
    $fld = (Get-MailboxFolderStatistics -Identity $addr -ErrorAction SilentlyContinue | Measure-Object).Count
    $perms = (Get-MailboxPermission -Identity $addr -ErrorAction SilentlyContinue |
              Where-Object { $_.User -notlike 'NT AUTHORITY\SELF' -and -not $_.IsInherited } |
              ForEach-Object { $_.User } ) -join ';'
    $sendAs = (Get-RecipientPermission -Identity $addr -ErrorAction SilentlyContinue |
               Where-Object { $_.Trustee -ne 'NT AUTHORITY\SELF' } |
               ForEach-Object { $_.Trustee } ) -join ';'
    [pscustomobject]@{
        PrimarySmtpAddress = $addr
        Found              = $true
        Type               = $mb.RecipientTypeDetails
        ExchangeGuid       = $mb.ExchangeGuid
        MoveStatus         = ($moveStatus[$mb.DisplayName])
        ItemCount          = $st.ItemCount
        TotalItemSize      = $st.TotalItemSize
        FolderCount        = $fld
        FullAccessDelegates= $perms
        SendAsTrustees     = $sendAs
    }
}

$outFile = Join-Path $OutputFolder "report-$stamp.csv"
$rows | Export-Csv $outFile -NoTypeInformation
Write-Host "`n=== EXOMIGG Report ===" -ForegroundColor Cyan
$rows | Format-Table PrimarySmtpAddress, Found, MoveStatus, ItemCount, FolderCount -AutoSize
$missing = $rows | Where-Object { -not $_.Found -or ($_.ItemCount -eq 0) }
if ($missing) {
    Write-Host ("ATTENTION: {0} mailbox(es) missing or empty — investigate before passing the gate (05-testing.md Gate 3)." -f ($missing | Measure-Object).Count) -ForegroundColor Yellow
} else {
    Write-Host "All listed mailboxes present with content." -ForegroundColor Green
}
Write-Host "Report written to: $outFile"

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
