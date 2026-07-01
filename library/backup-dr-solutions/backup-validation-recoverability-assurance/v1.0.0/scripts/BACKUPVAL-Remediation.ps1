<#
.SYNOPSIS
    BACKUPVAL-Remediation - Flag unprotected Azure resources and (optionally)
    trigger an on-demand backup for a named protected item.

.DESCRIPTION
    Remediation helper for the Backup Validation & Recoverability Assurance Program.
    Defaults to read-only / preview: it lists unprotected in-scope resources and
    shows which on-demand backup WOULD be triggered (-WhatIf semantics). It only
    triggers an on-demand backup when -Apply is supplied and a target item is named,
    and even then respects -WhatIf for a dry run.

    Triggering an on-demand backup is the one state-changing action and is gated
    behind -Apply plus change-control authorization. Flagging is always read-only.

    Requires the Az PowerShell module. Reader access is enough for flagging;
    Backup Operator (or Contributor) on the vault is required for -Apply.

.PARAMETER VaultName
    Optional. Limit to a single Recovery Services vault.

.PARAMETER ItemName
    Optional. The protected backup item to trigger an on-demand backup for (with -Apply).

.PARAMETER WorkloadType
    Workload type of -ItemName: AzureVM or AzureFiles. Default AzureVM.

.PARAMETER RetentionDays
    Retention for the on-demand recovery point. Default 30.

.PARAMETER Apply
    Switch. Required to actually trigger an on-demand backup. Without it, the
    script only flags and previews.

.EXAMPLE
    .\BACKUPVAL-Remediation.ps1                       # flag unprotected + preview only

.EXAMPLE
    .\BACKUPVAL-Remediation.ps1 -ItemName vm-app01 -WorkloadType AzureVM -Apply -WhatIf

.EXAMPLE
    .\BACKUPVAL-Remediation.ps1 -ItemName vm-app01 -WorkloadType AzureVM -Apply

.NOTES
    Backup & DR Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$VaultName,
    [string]$ItemName,
    [ValidateSet('AzureVM', 'AzureFiles')]
    [string]$WorkloadType = 'AzureVM',
    [int]$RetentionDays = 30,
    [switch]$Apply
)

try {
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

    # --- Always-on: flag unprotected VMs (read-only) ---
    $protectedVmNames = @{}
    $vaults = if ($VaultName) { Get-AzRecoveryServicesVault -Name $VaultName } else { Get-AzRecoveryServicesVault }
    foreach ($vault in $vaults) {
        Set-AzRecoveryServicesVaultContext -Vault $vault
        $containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM `
            -BackupManagementType AzureVM -ErrorAction SilentlyContinue
        foreach ($c in $containers) {
            Get-AzRecoveryServicesBackupItem -Container $c -WorkloadType AzureVM -ErrorAction SilentlyContinue |
                ForEach-Object { $protectedVmNames[$_.Name] = $true }
        }
    }

    Write-Host "Unprotected Azure VMs (coverage gaps):" -ForegroundColor Cyan
    $gaps = Get-AzVM -ErrorAction SilentlyContinue | Where-Object { $protectedVmNames.Keys -notcontains $_.Name }
    if ($gaps) {
        $gaps | ForEach-Object { Write-Host "  [GAP] $($_.Name)  (RG: $($_.ResourceGroupName))" -ForegroundColor Yellow }
    } else {
        Write-Host "  None found." -ForegroundColor Green
    }

    # --- Optional: on-demand backup for a named item (state-changing, gated) ---
    if (-not $ItemName) {
        Write-Host ""
        Write-Host "No -ItemName supplied; flagging only. Re-run with -ItemName and -Apply to trigger a backup." -ForegroundColor Gray
        return
    }

    if (-not $Apply) {
        Write-Host ""
        Write-Host "[PREVIEW] Would trigger on-demand backup for '$ItemName' ($WorkloadType), retention $RetentionDays days." -ForegroundColor Yellow
        Write-Host "          Re-run with -Apply (and change-control authorization) to execute." -ForegroundColor Yellow
        return
    }

    # Locate the item across vaults
    $target = $null; $targetVault = $null
    $ctype = ($WorkloadType -eq 'AzureVM') ? 'AzureVM' : 'AzureStorage'
    foreach ($vault in $vaults) {
        Set-AzRecoveryServicesVaultContext -Vault $vault
        $containers = Get-AzRecoveryServicesBackupContainer -ContainerType $ctype `
            -BackupManagementType $ctype -ErrorAction SilentlyContinue
        foreach ($c in $containers) {
            $item = Get-AzRecoveryServicesBackupItem -Container $c -WorkloadType $WorkloadType `
                -Name $ItemName -ErrorAction SilentlyContinue
            if ($item) { $target = $item; $targetVault = $vault; break }
        }
        if ($target) { break }
    }

    if (-not $target) { throw "Backup item '$ItemName' ($WorkloadType) not found in scoped vault(s)." }

    Set-AzRecoveryServicesVaultContext -Vault $targetVault
    $expiry = (Get-Date).AddDays($RetentionDays)

    if ($PSCmdlet.ShouldProcess("$ItemName in vault $($targetVault.Name)", "Trigger on-demand backup (retain until $($expiry.ToString('yyyy-MM-dd')))")) {
        $job = Backup-AzRecoveryServicesBackupItem -Item $target -ExpiryDateTimeUTC $expiry.ToUniversalTime()
        Write-Host "On-demand backup started for '$ItemName'. Job: $($job.JobId)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Remediation failed: $($_.Exception.Message)"
    exit 1
}
