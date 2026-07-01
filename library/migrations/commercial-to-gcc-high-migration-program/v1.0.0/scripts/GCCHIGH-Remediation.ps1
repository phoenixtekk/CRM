<#
.SYNOPSIS
    GCCHIGH-Remediation.ps1 - Safe remediation helpers for a Commercial-to-GCC High migration.

    PURPOSE:
        Provides post-migration fix-up helpers for common cross-cloud issues:
          - ReStampAddresses : re-stamp / correct proxy (SMTP) addresses on GCC High mailboxes.
          - RePermission     : re-apply SharePoint Online (GCC High) permissions to target principals.
          - RetriggerASR     : re-trigger Azure Site Recovery (Azure Gov) replication for failed items.
        Every mode is SAFE BY DEFAULT: it runs read-only / -WhatIf and only reports what it WOULD do.
        Pass -Apply to actually make changes (you will still be asked to confirm).

    HOW TO RUN:
        # Preview (default, no changes):
        .\GCCHIGH-Remediation.ps1 -Mode ReStampAddresses -InputCsv ".\address-fixes.csv"
        # Apply changes:
        .\GCCHIGH-Remediation.ps1 -Mode ReStampAddresses -InputCsv ".\address-fixes.csv" -Apply

        Input CSV columns by mode:
          ReStampAddresses : Identity, PrimarySmtp, AddProxy(optional, ;-separated)
          RePermission     : SiteUrl, PrincipalUpn, Role   (Role: Read|Edit|FullControl)
          RetriggerASR     : VaultName, VaultResourceGroup, ProtectedItemName

    EXPECTED RESULTS:
        Without -Apply: a per-row "WOULD ..." report and no changes. With -Apply: the change is made
        (with confirmation) and the result reported per row. A summary of changed/skipped/failed rows
        is printed at the end.

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateSet('ReStampAddresses','RePermission','RetriggerASR')]
    [string]$Mode,
    [Parameter(Mandatory)][string]$InputCsv,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
$rows = Import-Csv $InputCsv
$changed = 0; $skipped = 0; $failed = 0

# WhatIfPreference is honored automatically by ShouldProcess; force preview unless -Apply.
if (-not $Apply) { $WhatIfPreference = $true }

function Do-Action {
    param([string]$Target, [string]$Op, [scriptblock]$Action)
    try {
        if ($PSCmdlet.ShouldProcess($Target, $Op)) {
            & $Action
            Write-Host ("CHANGED: {0} - {1}" -f $Op, $Target) -ForegroundColor Green
            $script:changed++
        } else {
            Write-Host ("WOULD {0}: {1}" -f $Op, $Target) -ForegroundColor Yellow
            $script:skipped++
        }
    } catch {
        Write-Host ("FAILED: {0} - {1} :: {2}" -f $Op, $Target, $_.Exception.Message) -ForegroundColor Red
        $script:failed++
    }
}

switch ($Mode) {

    'ReStampAddresses' {
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -ShowBanner:$false
        foreach ($r in $rows) {
            $op = "Set primary SMTP to $($r.PrimarySmtp)"
            Do-Action -Target $r.Identity -Op $op -Action {
                Set-Mailbox -Identity $r.Identity -WindowsEmailAddress $r.PrimarySmtp -ErrorAction Stop
                if ($r.AddProxy) {
                    foreach ($p in ($r.AddProxy -split ';' | Where-Object { $_ })) {
                        Set-Mailbox -Identity $r.Identity -EmailAddresses @{ Add = "smtp:$p" } -ErrorAction Stop
                    }
                }
            }
        }
        Disconnect-ExchangeOnline -Confirm:$false
    }

    'RePermission' {
        Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
        # Connect to the GCC High SharePoint admin endpoint; -Region ITAR targets GCC High.
        $adminUrl = ($rows[0].SiteUrl -replace '(https://[^/.]+)\.sharepoint\.us.*', '$1-admin.sharepoint.us')
        Connect-SPOService -Url $adminUrl -Region ITAR
        foreach ($r in $rows) {
            $op = "Grant $($r.Role) to $($r.PrincipalUpn) on $($r.SiteUrl)"
            Do-Action -Target $r.SiteUrl -Op $op -Action {
                $grp = switch ($r.Role) {
                    'Read'        { 'Members' }
                    'Edit'        { 'Members' }
                    'FullControl' { 'Owners'  }
                    default       { 'Members' }
                }
                Add-SPOUser -Site $r.SiteUrl -LoginName $r.PrincipalUpn -Group "$grp" -ErrorAction Stop
            }
        }
        Disconnect-SPOService
    }

    'RetriggerASR' {
        Import-Module Az.Accounts, Az.RecoveryServices -ErrorAction Stop
        Connect-AzAccount -Environment AzureUSGovernment | Out-Null
        foreach ($r in $rows) {
            $op = "Re-trigger ASR replication for $($r.ProtectedItemName)"
            Do-Action -Target $r.ProtectedItemName -Op $op -Action {
                $vault = Get-AzRecoveryServicesVault -Name $r.VaultName -ResourceGroupName $r.VaultResourceGroup
                Set-AzRecoveryServicesAsrVaultContext -Vault $vault | Out-Null
                $fabric = Get-AzRecoveryServicesAsrFabric | Select-Object -First 1
                $cont   = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric | Select-Object -First 1
                $item   = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $cont |
                          Where-Object FriendlyName -eq $r.ProtectedItemName
                if (-not $item) { throw "Protected item not found: $($r.ProtectedItemName)" }
                Update-AzRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $item `
                    -Direction PrimaryToRecovery -ErrorAction Stop | Out-Null
            }
        }
    }
}

Write-Host ("`nSummary [{0}] - Changed: {1}  WouldChange/Skipped: {2}  Failed: {3}" -f $Mode, $changed, $skipped, $failed) -ForegroundColor Cyan
if (-not $Apply) { Write-Host "Preview only. Re-run with -Apply to make changes." -ForegroundColor Yellow }
