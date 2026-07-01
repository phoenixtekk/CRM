<#
.SYNOPSIS
    EXOMIG-Validation.ps1 - Pre-flight and post-migration validation for an
    Exchange Online tenant-to-tenant migration. READ-ONLY.

    PURPOSE:
        Pre-flight  : confirm the TARGET tenant is ready - mapped users have an
                      Exchange Online plan / provisioned mailbox, and the migrating
                      / routing domains are accepted/verified.
        Post-migration: confirm item-count parity (mail/calendar/contacts) between
                      a source mailbox and its target counterpart for a sample of
                      users, and that the final primary SMTP is stamped correctly.

    HOW TO RUN:
        Pre-flight (run while connected to TARGET):
            .\EXOMIG-Validation.ps1 -Mode PreFlight -MappingCsv .\mapping.csv `
                -MigratingDomain contoso.com
        Post-migration parity (connects to BOTH tenants):
            .\EXOMIG-Validation.ps1 -Mode PostMigration -MappingCsv .\mapping.csv `
                -SourceUpn admin@source.onmicrosoft.com -TargetUpn admin@target.onmicrosoft.com `
                -SampleCount 10

        mapping.csv columns:
            SourceUPN,SourcePrimarySMTP,MailboxType,TargetUPN,TargetRoutingAddress,FinalPrimarySMTP,Wave

    EXPECTED RESULTS:
        A per-check PASS/FAIL table and an overall PASS/FAIL summary. No changes made.

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('PreFlight','PostMigration')][string] $Mode,
    [Parameter(Mandatory)][string] $MappingCsv,
    [string] $MigratingDomain,
    [string] $SourceUpn,
    [string] $TargetUpn,
    [int]    $SampleCount = 10
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Result { param($Check,$Status,$Detail)
    $results.Add([pscustomobject]@{ Check=$Check; Status=$Status; Detail=$Detail })
}

if (-not (Test-Path $MappingCsv)) { throw "Mapping CSV not found: $MappingCsv" }
$map = Import-Csv $MappingCsv
Import-Module ExchangeOnlineManagement -ErrorAction Stop

try {
    if ($Mode -eq 'PreFlight') {
        Write-Host "Connecting to TARGET tenant for pre-flight..." -ForegroundColor Cyan
        if ($TargetUpn) { Connect-ExchangeOnline -UserPrincipalName $TargetUpn -ShowBanner:$false }
        else            { Connect-ExchangeOnline -ShowBanner:$false }

        # Accepted/verified domains
        $accepted = (Get-AcceptedDomain).DomainName
        if ($MigratingDomain) {
            if ($accepted -contains $MigratingDomain) {
                Add-Result "Migrating domain accepted in target" "PASS" $MigratingDomain
            } else {
                Add-Result "Migrating domain accepted in target" "INFO" "$MigratingDomain not yet in target (expected until cutover)"
            }
        }

        # Per-mapped-user provisioning check
        foreach ($row in $map) {
            $target = $row.TargetUPN
            if ([string]::IsNullOrWhiteSpace($target)) {
                Add-Result "Target mailbox provisioned" "FAIL" "No TargetUPN for source $($row.SourceUPN)"
                continue
            }
            try {
                $mb = Get-EXOMailbox -Identity $target -ErrorAction Stop
                Add-Result "Target mailbox provisioned" "PASS" $target
                # routing address present?
                if ($row.TargetRoutingAddress -and ($mb.EmailAddresses -notmatch [regex]::Escape($row.TargetRoutingAddress))) {
                    Add-Result "Routing address present" "WARN" "$target missing $($row.TargetRoutingAddress)"
                }
            } catch {
                Add-Result "Target mailbox provisioned" "FAIL" "$target not found / not licensed"
            }
        }
    }
    else {
        # PostMigration parity - connect to both, compare a sample
        $sample = $map | Where-Object { $_.SourcePrimarySMTP -and $_.TargetUPN } | Get-Random -Count ([Math]::Min($SampleCount, $map.Count))

        Write-Host "Connecting to SOURCE tenant..." -ForegroundColor Cyan
        Connect-ExchangeOnline -UserPrincipalName $SourceUpn -ShowBanner:$false -Prefix Src
        Write-Host "Connecting to TARGET tenant..." -ForegroundColor Cyan
        Connect-ExchangeOnline -UserPrincipalName $TargetUpn -ShowBanner:$false -Prefix Tgt

        foreach ($row in $sample) {
            try {
                $srcFolders = Get-SrcMailboxFolderStatistics -Identity $row.SourcePrimarySMTP -ErrorAction Stop
                $tgtFolders = Get-TgtMailboxFolderStatistics -Identity $row.TargetUPN -ErrorAction Stop

                foreach ($type in 'Inbox','Calendar','Contacts') {
                    $s = ($srcFolders | Where-Object { $_.FolderType -eq $type } | Measure-Object ItemsInFolder -Sum).Sum
                    $t = ($tgtFolders | Where-Object { $_.FolderType -eq $type } | Measure-Object ItemsInFolder -Sum).Sum
                    $s = [int]($s); $t = [int]($t)
                    if ($t -ge $s) {
                        Add-Result "Parity[$type] $($row.SourcePrimarySMTP)" "PASS" "src=$s tgt=$t"
                    } else {
                        Add-Result "Parity[$type] $($row.SourcePrimarySMTP)" "FAIL" "src=$s tgt=$t (target short)"
                    }
                }

                # Final primary SMTP stamped?
                if ($row.FinalPrimarySMTP) {
                    $tmb = Get-TgtMailbox -Identity $row.TargetUPN
                    if ($tmb.PrimarySmtpAddress -eq $row.FinalPrimarySMTP) {
                        Add-Result "Primary SMTP stamped $($row.TargetUPN)" "PASS" $row.FinalPrimarySMTP
                    } else {
                        Add-Result "Primary SMTP stamped $($row.TargetUPN)" "WARN" "is $($tmb.PrimarySmtpAddress), expected $($row.FinalPrimarySMTP)"
                    }
                }
            } catch {
                Add-Result "Parity $($row.SourcePrimarySMTP)" "FAIL" $_.Exception.Message
            }
        }
    }

    # ---- Report --------------------------------------------------------------
    Write-Host ""
    $results | Format-Table -AutoSize
    $fail = ($results | Where-Object Status -eq 'FAIL').Count
    $warn = ($results | Where-Object Status -eq 'WARN').Count
    Write-Host ""
    if ($fail -eq 0) {
        Write-Host "OVERALL: PASS  (warnings: $warn)" -ForegroundColor Green
    } else {
        Write-Host "OVERALL: FAIL  ($fail failed, $warn warnings)" -ForegroundColor Red
    }
}
finally {
    Get-ConnectionInformation -ErrorAction SilentlyContinue | ForEach-Object {}
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}
