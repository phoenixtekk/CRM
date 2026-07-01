<#
.SYNOPSIS
    EXOMIG-Discovery.ps1 - Inventory a SOURCE Microsoft 365 / Exchange Online tenant
    ahead of a tenant-to-tenant migration. READ-ONLY.

    PURPOSE:
        Build the assessment baseline for an Exchange Online tenant-to-tenant
        migration. Exports CSVs covering mailboxes (user/shared/room/equipment),
        sizes, item counts, aliases, accepted domains, distribution groups,
        Microsoft 365 groups, and mailbox permissions/delegation. These exports
        drive the source->target mapping and the remediation scripts.

    HOW TO RUN:
        1. Install the Exchange Online module (once):
               Install-Module ExchangeOnlineManagement -Scope CurrentUser
        2. Run against the SOURCE tenant:
               .\EXOMIG-Discovery.ps1 -OutputFolder .\discovery
        3. Sign in as a source-tenant administrator when prompted (or pass -UserPrincipalName).

    EXPECTED RESULTS:
        A set of timestamped CSV files in -OutputFolder:
            mailboxes.csv, accepted-domains.csv, distribution-groups.csv,
            m365-groups.csv, mailbox-permissions.csv
        plus a console summary. No changes are made to the tenant.

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding()]
param(
    [string] $OutputFolder = ".\discovery",
    [string] $UserPrincipalName,
    [switch] $SkipItemCounts   # item-count statistics are slower on large tenants
)

$ErrorActionPreference = 'Stop'

function Connect-Source {
    param([string] $Upn)
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module not found. Run: Install-Module ExchangeOnlineManagement"
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        Write-Host "Connecting to Exchange Online (source tenant)..." -ForegroundColor Cyan
        if ($Upn) { Connect-ExchangeOnline -UserPrincipalName $Upn -ShowBanner:$false }
        else      { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

try {
    Connect-Source -Upn $UserPrincipalName

    if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    # ---- Mailboxes -----------------------------------------------------------
    Write-Host "Enumerating mailboxes..." -ForegroundColor Cyan
    $mailboxes = Get-EXOMailbox -ResultSize Unlimited -PropertySets All
    $mbRows = foreach ($mb in $mailboxes) {
        $sizeMB = $null; $items = $null
        if (-not $SkipItemCounts) {
            try {
                $stat   = Get-EXOMailboxStatistics -Identity $mb.PrimarySmtpAddress -ErrorAction Stop
                $items  = $stat.ItemCount
                if ($stat.TotalItemSize -and $stat.TotalItemSize.Value) {
                    $sizeMB = [math]::Round($stat.TotalItemSize.Value.ToBytes() / 1MB, 2)
                }
            } catch { Write-Warning "Stats failed for $($mb.PrimarySmtpAddress): $_" }
        }
        [pscustomobject]@{
            DisplayName       = $mb.DisplayName
            UserPrincipalName = $mb.UserPrincipalName
            PrimarySMTP       = $mb.PrimarySmtpAddress
            MailboxType       = $mb.RecipientTypeDetails
            Aliases           = (($mb.EmailAddresses | Where-Object { $_ -clike 'smtp:*' }) -join ';')
            SizeMB            = $sizeMB
            ItemCount         = $items
            ArchiveEnabled    = $mb.ArchiveStatus
            LitigationHold    = $mb.LitigationHoldEnabled
        }
    }
    $mbPath = Join-Path $OutputFolder "mailboxes-$stamp.csv"
    $mbRows | Sort-Object MailboxType, PrimarySMTP | Export-Csv $mbPath -NoTypeInformation -Encoding UTF8

    # ---- Accepted domains ----------------------------------------------------
    Write-Host "Enumerating accepted domains..." -ForegroundColor Cyan
    $domPath = Join-Path $OutputFolder "accepted-domains-$stamp.csv"
    Get-AcceptedDomain | Select-Object DomainName, DomainType, Default |
        Export-Csv $domPath -NoTypeInformation -Encoding UTF8

    # ---- Distribution groups -------------------------------------------------
    Write-Host "Enumerating distribution groups..." -ForegroundColor Cyan
    $dgPath = Join-Path $OutputFolder "distribution-groups-$stamp.csv"
    Get-DistributionGroup -ResultSize Unlimited |
        Select-Object DisplayName, PrimarySmtpAddress, GroupType, RecipientTypeDetails |
        Export-Csv $dgPath -NoTypeInformation -Encoding UTF8

    # ---- Microsoft 365 groups ------------------------------------------------
    Write-Host "Enumerating Microsoft 365 groups..." -ForegroundColor Cyan
    $ugPath = Join-Path $OutputFolder "m365-groups-$stamp.csv"
    Get-UnifiedGroup -ResultSize Unlimited |
        Select-Object DisplayName, PrimarySmtpAddress, AccessType, ManagedBy |
        Export-Csv $ugPath -NoTypeInformation -Encoding UTF8

    # ---- Mailbox permissions / delegation ------------------------------------
    Write-Host "Enumerating mailbox permissions (FullAccess / SendAs / SendOnBehalf)..." -ForegroundColor Cyan
    $permRows = foreach ($mb in $mailboxes) {
        $id = $mb.PrimarySmtpAddress
        try {
            Get-EXOMailboxPermission -Identity $id |
                Where-Object { $_.AccessRights -contains 'FullAccess' -and -not $_.IsInherited -and $_.User -notlike 'NT AUTHORITY\*' } |
                ForEach-Object { [pscustomobject]@{ TargetMailbox=$id; Trustee=$_.User; AccessRight='FullAccess' } }
        } catch {}
        try {
            Get-EXORecipientPermission -Identity $id |
                Where-Object { $_.AccessRights -contains 'SendAs' -and $_.Trustee -notlike 'NT AUTHORITY\*' } |
                ForEach-Object { [pscustomobject]@{ TargetMailbox=$id; Trustee=$_.Trustee; AccessRight='SendAs' } }
        } catch {}
        if ($mb.GrantSendOnBehalfTo) {
            foreach ($t in $mb.GrantSendOnBehalfTo) {
                [pscustomobject]@{ TargetMailbox=$id; Trustee=$t; AccessRight='SendOnBehalf' }
            }
        }
    }
    $permPath = Join-Path $OutputFolder "mailbox-permissions-$stamp.csv"
    $permRows | Export-Csv $permPath -NoTypeInformation -Encoding UTF8

    # ---- Summary -------------------------------------------------------------
    Write-Host ""
    Write-Host "==== DISCOVERY SUMMARY ====" -ForegroundColor Green
    Write-Host ("Mailboxes total      : {0}" -f $mbRows.Count)
    $mbRows | Group-Object MailboxType | ForEach-Object { Write-Host ("  {0,-28}: {1}" -f $_.Name, $_.Count) }
    if (-not $SkipItemCounts) {
        $totalGB = [math]::Round((($mbRows | Measure-Object SizeMB -Sum).Sum) / 1024, 2)
        Write-Host ("Total mailbox data   : {0} GB" -f $totalGB)
    }
    Write-Host ("Permission entries   : {0}" -f ($permRows | Measure-Object).Count)
    Write-Host ""
    Write-Host "CSV files written to: $OutputFolder" -ForegroundColor Green
}
finally {
    if (Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    }
}
