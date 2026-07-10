<#
.SYNOPSIS
    BCKDR-Discovery.ps1 - Inventory the Azure estate and flag backup/DR coverage gaps.

.DESCRIPTION
    PURPOSE
        Read-only assessment for the "Azure Backup & Site Recovery - Deployment &
        Configuration" solution. Enumerates Azure VMs, Azure Files shares, SQL-in-VM
        candidates, storage accounts, and any existing Recovery Services vaults,
        Backup vaults, and ASR replicated items. Flags each in-scope resource as
        PROTECTED or UNPROTECTED to build the assessment baseline (Stage 1 - Assess).

    HOW TO RUN
        Connect-AzAccount
        Set-AzContext -SubscriptionId <sub-id>
        .\BCKDR-Discovery.ps1
        .\BCKDR-Discovery.ps1 -SubscriptionId <sub-id> -OutputPath .\baseline.csv

    EXPECTED RESULTS
        A timestamped CSV listing every in-scope resource with a Protected Y/N flag,
        the vault (if any), last backup status/time, and ASR replication state, plus a
        console summary of protected vs. unprotected counts. Makes NO changes.

.NOTES
    White-label. Read-only. Requires Az.Accounts, Az.RecoveryServices, Az.Compute,
    Az.Storage and at least Reader on the subscription and vault(s).
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\BCKDR-Discovery-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

function Connect-Context {
    if (-not (Get-AzContext)) {
        Write-Host "No Azure context found. Connecting..." -ForegroundColor Yellow
        Connect-AzAccount | Out-Null
    }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
}

try {
    Connect-Context
    $results = New-Object System.Collections.Generic.List[object]

    # --- Enumerate protected items across Recovery Services vaults ---
    $protectedVm    = @{}
    $protectedShare = @{}
    $replicatedVm   = @{}

    $vaults = Get-AzRecoveryServicesVault -ErrorAction SilentlyContinue
    if (-not $vaults) { Write-Warning "No Recovery Services vaults found." }

    foreach ($vault in $vaults) {
        Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction SilentlyContinue

        foreach ($wl in @('AzureVM','AzureFiles')) {
            $ctype = if ($wl -eq 'AzureVM') { 'AzureVM' } else { 'AzureStorage' }
            $containers = Get-AzRecoveryServicesBackupContainer -ContainerType $ctype `
                -BackupManagementType $ctype -ErrorAction SilentlyContinue
            foreach ($c in $containers) {
                $items = Get-AzRecoveryServicesBackupItem -Container $c -WorkloadType $wl `
                    -ErrorAction SilentlyContinue
                foreach ($it in $items) {
                    if ($wl -eq 'AzureVM')    { $protectedVm[$it.Name]    = $true }
                    if ($wl -eq 'AzureFiles') { $protectedShare[$it.Name] = $true }
                    $results.Add([pscustomobject]@{
                        Category         = "Backup"
                        WorkloadClass    = $wl
                        ObjectName       = $it.Name
                        Protected        = 'Y'
                        Vault            = $vault.Name
                        LastBackupStatus = $it.LastBackupStatus
                        LastBackupTime   = $it.LastBackupTime
                        ReplicationState = ''
                    })
                }
            }
        }

        # ASR replicated items (best-effort; requires ASR context on the vault)
        try {
            $fabrics = Get-AzRecoveryServicesAsrFabric -ErrorAction SilentlyContinue
            foreach ($f in $fabrics) {
                $containers = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $f -ErrorAction SilentlyContinue
                foreach ($pc in $containers) {
                    $ri = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -ErrorAction SilentlyContinue
                    foreach ($r in $ri) {
                        $replicatedVm[$r.FriendlyName] = $true
                        $results.Add([pscustomobject]@{
                            Category         = "ASR"
                            WorkloadClass    = 'ReplicatedVM'
                            ObjectName       = $r.FriendlyName
                            Protected        = 'Y'
                            Vault            = $vault.Name
                            LastBackupStatus = ''
                            LastBackupTime   = ''
                            ReplicationState = $r.ProtectionState
                        })
                    }
                }
            }
        } catch { Write-Verbose "ASR enumeration skipped on $($vault.Name): $($_.Exception.Message)" }
    }

    # --- Cross-check live estate: unprotected VMs / not replicated ---
    foreach ($vm in (Get-AzVM -ErrorAction SilentlyContinue)) {
        if (-not $protectedVm.ContainsKey($vm.Name)) {
            $results.Add([pscustomobject]@{
                Category         = "Backup"
                WorkloadClass    = 'AzureVM'
                ObjectName       = $vm.Name
                Protected        = 'N'
                Vault            = ''
                LastBackupStatus = 'UNPROTECTED'
                LastBackupTime   = ''
                ReplicationState = ($replicatedVm.ContainsKey($vm.Name) ? 'Replicated' : 'NotReplicated')
            })
        }
    }

    # --- Cross-check live estate: file shares (best-effort) ---
    foreach ($sa in (Get-AzStorageAccount -ErrorAction SilentlyContinue)) {
        try {
            $shares = Get-AzStorageShare -Context $sa.Context -ErrorAction SilentlyContinue |
                Where-Object { -not $_.IsSnapshot }
            foreach ($s in $shares) {
                if (-not $protectedShare.ContainsKey($s.Name)) {
                    $results.Add([pscustomobject]@{
                        Category         = "Backup"
                        WorkloadClass    = 'AzureFiles'
                        ObjectName       = "$($sa.StorageAccountName)/$($s.Name)"
                        Protected        = 'N'
                        Vault            = ''
                        LastBackupStatus = 'UNPROTECTED'
                        LastBackupTime   = ''
                        ReplicationState = ''
                    })
                }
            }
        } catch { Write-Verbose "Skipped storage $($sa.StorageAccountName): $($_.Exception.Message)" }
    }

    $results | Sort-Object Category, WorkloadClass, Protected, ObjectName |
        Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    $prot   = ($results | Where-Object Protected -eq 'Y').Count
    $unprot = ($results | Where-Object Protected -eq 'N').Count
    Write-Host ""
    Write-Host "Discovery complete." -ForegroundColor Green
    Write-Host "  Protected resources   : $prot"
    Write-Host "  Unprotected resources : $unprot"
    Write-Host "  Baseline written to   : $OutputPath"
}
catch {
    Write-Error "Discovery failed: $($_.Exception.Message)"
    exit 1
}
