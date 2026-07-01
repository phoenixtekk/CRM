<#
.SYNOPSIS
    BACKUPVAL-Discovery - Inventory backup coverage across Azure Recovery Services
    vaults and identify protected vs. unprotected resources.

.DESCRIPTION
    Read-only discovery for the Backup Validation & Recoverability Assurance Program.
    Enumerates Recovery Services vault backup items (Azure VMs and Azure Files),
    then cross-checks the live estate (VMs and Storage file shares) to flag in-scope
    resources that are NOT protected. Produces the raw data for the
    'Coverage Baseline - Backup Estate - Assessment'.

    Makes no changes. Requires the Az PowerShell module and at least Reader access
    to the subscription and the Recovery Services vault(s).

.PARAMETER SubscriptionId
    Optional. The Azure subscription to inspect. Defaults to the current context.

.PARAMETER VaultName
    Optional. Limit discovery to a single Recovery Services vault by name.

.PARAMETER OutputPath
    Optional. CSV path for the discovery results. Defaults to a timestamped file
    in the current directory.

.EXAMPLE
    .\BACKUPVAL-Discovery.ps1

.EXAMPLE
    .\BACKUPVAL-Discovery.ps1 -SubscriptionId 00000000-0000-0000-0000-000000000000 -VaultName rsv-prod

.NOTES
    Backup & DR Solutions - read-only.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$VaultName,
    [string]$OutputPath = ".\BACKUPVAL-Discovery-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

function Connect-Context {
    if (-not (Get-AzContext)) {
        Write-Host "No Azure context found. Connecting..." -ForegroundColor Yellow
        Connect-AzAccount | Out-Null
    }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
}

try {
    Connect-Context

    $results = New-Object System.Collections.Generic.List[object]

    # --- Protected items from Recovery Services vaults ---
    $vaults = if ($VaultName) {
        Get-AzRecoveryServicesVault -Name $VaultName
    } else {
        Get-AzRecoveryServicesVault
    }

    if (-not $vaults) {
        Write-Warning "No Recovery Services vaults found in the current context."
    }

    $protectedVmNames    = @{}
    $protectedShareNames = @{}

    foreach ($vault in $vaults) {
        Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop

        foreach ($type in @('AzureVM', 'AzureFiles')) {
            $containers = Get-AzRecoveryServicesBackupContainer -ContainerType `
                ($type -eq 'AzureVM' ? 'AzureVM' : 'AzureStorage') `
                -BackupManagementType ($type -eq 'AzureVM' ? 'AzureVM' : 'AzureStorage') `
                -ErrorAction SilentlyContinue

            foreach ($container in $containers) {
                $items = Get-AzRecoveryServicesBackupItem -Container $container `
                    -WorkloadType $type -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    if ($type -eq 'AzureVM')    { $protectedVmNames[$item.Name]    = $true }
                    if ($type -eq 'AzureFiles') { $protectedShareNames[$item.Name] = $true }

                    $results.Add([pscustomobject]@{
                        Vault            = $vault.Name
                        WorkloadClass    = $type
                        ObjectName       = $item.Name
                        Protected        = 'Y'
                        LastBackupStatus = $item.LastBackupStatus
                        LastBackupTime   = $item.LastBackupTime
                        LatestRecovery   = $item.LatestRecoveryPoint
                        ProtectionState  = $item.ProtectionState
                    })
                }
            }
        }
    }

    # --- Live estate cross-check: unprotected VMs ---
    foreach ($vm in (Get-AzVM -ErrorAction SilentlyContinue)) {
        $isProtected = $protectedVmNames.Keys -contains $vm.Name
        if (-not $isProtected) {
            $results.Add([pscustomobject]@{
                Vault            = ''
                WorkloadClass    = 'AzureVM'
                ObjectName       = $vm.Name
                Protected        = 'N'
                LastBackupStatus = ''
                LastBackupTime   = ''
                LatestRecovery   = ''
                ProtectionState  = 'UNPROTECTED'
            })
        }
    }

    # --- Live estate cross-check: file shares (best-effort) ---
    foreach ($sa in (Get-AzStorageAccount -ErrorAction SilentlyContinue)) {
        try {
            $ctx = $sa.Context
            $shares = Get-AzStorageShare -Context $ctx -ErrorAction SilentlyContinue |
                Where-Object { -not $_.IsSnapshot }
            foreach ($share in $shares) {
                if ($protectedShareNames.Keys -notcontains $share.Name) {
                    $results.Add([pscustomobject]@{
                        Vault            = ''
                        WorkloadClass    = 'AzureFiles'
                        ObjectName       = "$($sa.StorageAccountName)/$($share.Name)"
                        Protected        = 'N'
                        LastBackupStatus = ''
                        LastBackupTime   = ''
                        LatestRecovery   = ''
                        ProtectionState  = 'UNPROTECTED'
                    })
                }
            }
        } catch {
            Write-Verbose "Skipped storage account $($sa.StorageAccountName): $($_.Exception.Message)"
        }
    }

    $results | Sort-Object WorkloadClass, Protected, ObjectName |
        Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    $protected   = ($results | Where-Object Protected -eq 'Y').Count
    $unprotected = ($results | Where-Object Protected -eq 'N').Count
    Write-Host ""
    Write-Host "Discovery complete." -ForegroundColor Green
    Write-Host "  Protected items   : $protected"
    Write-Host "  Unprotected items : $unprotected"
    Write-Host "  Results written to: $OutputPath"
}
catch {
    Write-Error "Discovery failed: $($_.Exception.Message)"
    exit 1
}
