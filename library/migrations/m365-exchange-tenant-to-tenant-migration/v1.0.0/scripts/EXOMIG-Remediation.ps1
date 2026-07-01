<#
.SYNOPSIS
    EXOMIG-Remediation.ps1 - Safe post-migration remediation in the TARGET tenant:
    re-stamp primary SMTP addresses at cutover and re-grant mailbox permissions.
    READ-ONLY / -WhatIf by DEFAULT; changes require an explicit -Apply switch.

    PURPOSE:
        After the migrating domain is verified in the target tenant, this script:
          1. Stamps each migrated mailbox's FINAL primary SMTP (e.g. @contoso.com)
             from mapping.csv, keeping prior addresses as secondary aliases.
          2. Re-grants FullAccess and SendAs permissions from permissions.csv
             (inter-mailbox permissions do NOT migrate cross-tenant).

    HOW TO RUN:
        Preview (default, no changes):
            .\EXOMIG-Remediation.ps1 -MappingCsv .\mapping.csv -PermissionsCsv .\permissions.csv `
                -TargetUpn admin@target.onmicrosoft.com
        Apply changes:
            .\EXOMIG-Remediation.ps1 -MappingCsv .\mapping.csv -PermissionsCsv .\permissions.csv `
                -TargetUpn admin@target.onmicrosoft.com -Apply

        Run only one task with -Task StampSmtp or -Task Permissions (default: Both).

        mapping.csv columns       : TargetUPN, FinalPrimarySMTP
        permissions.csv columns   : TargetMailbox, Trustee, AccessRight  (FullAccess|SendAs)

    EXPECTED RESULTS:
        Without -Apply: a preview of every change that WOULD be made.
        With -Apply   : addresses stamped and permissions granted, with a result log.

.NOTES
    Azure Solutions - read-only / -WhatIf by default; mutations gated behind -Apply.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][string] $MappingCsv,
    [string] $PermissionsCsv,
    [string] $TargetUpn,
    [ValidateSet('StampSmtp','Permissions','Both')][string] $Task = 'Both',
    [switch] $Apply
)

$ErrorActionPreference = 'Stop'
# When -Apply is not passed, force WhatIf behaviour for all state-changing cmdlets.
if (-not $Apply) { $WhatIfPreference = $true; Write-Host "PREVIEW MODE (no -Apply): no changes will be made." -ForegroundColor Yellow }

Import-Module ExchangeOnlineManagement -ErrorAction Stop
Write-Host "Connecting to TARGET tenant..." -ForegroundColor Cyan
if ($TargetUpn) { Connect-ExchangeOnline -UserPrincipalName $TargetUpn -ShowBanner:$false }
else            { Connect-ExchangeOnline -ShowBanner:$false }

$log = New-Object System.Collections.Generic.List[object]

try {
    # ---- Task 1: stamp final primary SMTP ------------------------------------
    if ($Task -in 'StampSmtp','Both') {
        if (-not (Test-Path $MappingCsv)) { throw "Mapping CSV not found: $MappingCsv" }
        Write-Host "`n== Stamping final primary SMTP addresses ==" -ForegroundColor Cyan
        foreach ($row in Import-Csv $MappingCsv) {
            if (-not $row.TargetUPN -or -not $row.FinalPrimarySMTP) { continue }
            try {
                $mb = Get-Mailbox -Identity $row.TargetUPN -ErrorAction Stop
                if ($mb.PrimarySmtpAddress -eq $row.FinalPrimarySMTP) {
                    $log.Add([pscustomobject]@{ Action='StampSMTP'; Target=$row.TargetUPN; Result='AlreadySet'; Detail=$row.FinalPrimarySMTP })
                    continue
                }
                # Add the final address as primary (EmailAddressPolicyEnabled must be off, which it is for migrated mbx)
                if ($PSCmdlet.ShouldProcess($row.TargetUPN, "Set primary SMTP to $($row.FinalPrimarySMTP)")) {
                    Set-Mailbox -Identity $row.TargetUPN -EmailAddresses @{ Add = "SMTP:$($row.FinalPrimarySMTP)" } -ErrorAction Stop
                    $log.Add([pscustomobject]@{ Action='StampSMTP'; Target=$row.TargetUPN; Result='Stamped'; Detail=$row.FinalPrimarySMTP })
                } else {
                    $log.Add([pscustomobject]@{ Action='StampSMTP'; Target=$row.TargetUPN; Result='WouldStamp'; Detail=$row.FinalPrimarySMTP })
                }
            } catch {
                $log.Add([pscustomobject]@{ Action='StampSMTP'; Target=$row.TargetUPN; Result='Error'; Detail=$_.Exception.Message })
            }
        }
    }

    # ---- Task 2: re-grant permissions ----------------------------------------
    if ($Task -in 'Permissions','Both') {
        if (-not $PermissionsCsv) { Write-Warning "No -PermissionsCsv supplied; skipping permission remediation." }
        elseif (-not (Test-Path $PermissionsCsv)) { throw "Permissions CSV not found: $PermissionsCsv" }
        else {
            Write-Host "`n== Re-granting mailbox permissions ==" -ForegroundColor Cyan
            foreach ($p in Import-Csv $PermissionsCsv) {
                if (-not $p.TargetMailbox -or -not $p.Trustee) { continue }
                try {
                    switch ($p.AccessRight) {
                        'FullAccess' {
                            if ($PSCmdlet.ShouldProcess($p.TargetMailbox, "Grant FullAccess to $($p.Trustee)")) {
                                Add-MailboxPermission -Identity $p.TargetMailbox -User $p.Trustee -AccessRights FullAccess -AutoMapping $true -ErrorAction Stop | Out-Null
                                $log.Add([pscustomobject]@{ Action='FullAccess'; Target=$p.TargetMailbox; Result='Granted'; Detail=$p.Trustee })
                            } else {
                                $log.Add([pscustomobject]@{ Action='FullAccess'; Target=$p.TargetMailbox; Result='WouldGrant'; Detail=$p.Trustee })
                            }
                        }
                        'SendAs' {
                            if ($PSCmdlet.ShouldProcess($p.TargetMailbox, "Grant SendAs to $($p.Trustee)")) {
                                Add-RecipientPermission -Identity $p.TargetMailbox -Trustee $p.Trustee -AccessRights SendAs -Confirm:$false -ErrorAction Stop | Out-Null
                                $log.Add([pscustomobject]@{ Action='SendAs'; Target=$p.TargetMailbox; Result='Granted'; Detail=$p.Trustee })
                            } else {
                                $log.Add([pscustomobject]@{ Action='SendAs'; Target=$p.TargetMailbox; Result='WouldGrant'; Detail=$p.Trustee })
                            }
                        }
                        default { $log.Add([pscustomobject]@{ Action=$p.AccessRight; Target=$p.TargetMailbox; Result='Skipped'; Detail='Unsupported here (e.g. SendOnBehalf - set manually)' }) }
                    }
                } catch {
                    $log.Add([pscustomobject]@{ Action=$p.AccessRight; Target=$p.TargetMailbox; Result='Error'; Detail=$_.Exception.Message })
                }
            }
        }
    }

    Write-Host ""
    $log | Format-Table -AutoSize
    $errs = ($log | Where-Object Result -eq 'Error').Count
    if (-not $Apply) { Write-Host "`nPREVIEW complete. Re-run with -Apply to make changes." -ForegroundColor Yellow }
    elseif ($errs -gt 0) { Write-Host "`nApplied with $errs error(s) - review the log above." -ForegroundColor Red }
    else { Write-Host "`nRemediation applied successfully." -ForegroundColor Green }
}
finally {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}
