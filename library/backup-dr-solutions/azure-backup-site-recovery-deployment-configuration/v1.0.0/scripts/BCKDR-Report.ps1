<#
.SYNOPSIS
    BCKDR-Report.ps1 - Compile estate-wide Azure Backup + Site Recovery posture.

.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Azure Backup & Site Recovery - Deployment &
        Configuration" solution (Stage 5 - Expand / handover). Produces a single
        CSV summarizing, per subscription: protected vs. unprotected resources,
        which policy protects each item, last recovery point and status, ASR
        replication health, and vault hardening state - suitable for the handover
        pack and periodic posture review.

    HOW TO RUN
        Connect-AzAccount
        .\BCKDR-Report.ps1
        .\BCKDR-Report.ps1 -SubscriptionId <sub-id> -OutputPath .\posture.csv

    EXPECTED RESULTS
        A timestamped CSV plus a console summary (coverage %, replicated count,
        vault hardening state). Makes NO changes.

.NOTES
    White-label. Read-only. Requires Az.Accounts, Az.RecoveryServices,
    Az.DataProtection, Az.Compute, Az.Storage with Reader access.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\BCKDR-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

try {
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

    $rows = New-Object System.Collections.Generic.List[object]
    $protectedVm = @{}

    foreach ($vault in (Get-AzRecoveryServicesVault -ErrorAction SilentlyContinue)) {
        $sec = $vault.Properties.securitySettings
        $hardening = "softDelete=$($sec.softDeleteSettings.softDeleteState); immutability=$($sec.immutabilitySettings.state)"
        Set-AzRecoveryServicesVaultContext -Vault $vault

        foreach ($it in (Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -ErrorAction SilentlyContinue)) {
            $protectedVm[$it.Name] = $true
            $rows.Add([pscustomobject]@{
                Vault=$vault.Name; VaultHardening=$hardening; Type='AzureVM'; Object=$it.Name
                Protected='Y'; Policy=$it.ProtectionPolicyName; LastStatus=$it.LastBackupStatus
                LastBackup=$it.LastBackupTime; Replication='' })
        }
        foreach ($it in (Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -ErrorAction SilentlyContinue)) {
            $rows.Add([pscustomobject]@{
                Vault=$vault.Name; VaultHardening=$hardening; Type='AzureFiles'; Object=$it.Name
                Protected='Y'; Policy=$it.ProtectionPolicyName; LastStatus=$it.LastBackupStatus
                LastBackup=$it.LastBackupTime; Replication='' })
        }
        try {
            foreach ($f in (Get-AzRecoveryServicesAsrFabric -ErrorAction SilentlyContinue)) {
                foreach ($pc in (Get-AzRecoveryServicesAsrProtectionContainer -Fabric $f -ErrorAction SilentlyContinue)) {
                    foreach ($r in (Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -ErrorAction SilentlyContinue)) {
                        $rows.Add([pscustomobject]@{
                            Vault=$vault.Name; VaultHardening=$hardening; Type='ASR'; Object=$r.FriendlyName
                            Protected='Y'; Policy=''; LastStatus=''; LastBackup=''
                            Replication="$($r.ProtectionState)/$($r.ReplicationHealth)" })
                    }
                }
            }
        } catch { Write-Verbose "ASR read skipped on $($vault.Name)" }
    }

    # Unprotected VMs
    foreach ($vm in (Get-AzVM -ErrorAction SilentlyContinue)) {
        if (-not $protectedVm.ContainsKey($vm.Name)) {
            $rows.Add([pscustomobject]@{
                Vault=''; VaultHardening=''; Type='AzureVM'; Object=$vm.Name
                Protected='N'; Policy=''; LastStatus='UNPROTECTED'; LastBackup=''; Replication='' })
        }
    }

    $rows | Sort-Object Type, Protected, Object | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    $total = ($rows | Where-Object Type -in @('AzureVM','AzureFiles')).Count
    $prot  = ($rows | Where-Object { $_.Type -in @('AzureVM','AzureFiles') -and $_.Protected -eq 'Y' }).Count
    $cov   = if ($total) { [math]::Round(($prot / $total) * 100, 1) } else { 0 }
    $repl  = ($rows | Where-Object Type -eq 'ASR').Count
    Write-Host ""
    Write-Host "Posture report complete." -ForegroundColor Green
    Write-Host "  Backup coverage : $prot / $total  ($cov`%)"
    Write-Host "  ASR replicated  : $repl"
    Write-Host "  Written to      : $OutputPath"
}
catch {
    Write-Error "Report failed: $($_.Exception.Message)"
    exit 1
}
