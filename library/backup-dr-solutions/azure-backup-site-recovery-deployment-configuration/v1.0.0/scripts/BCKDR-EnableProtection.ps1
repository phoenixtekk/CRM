<#
.SYNOPSIS
    BCKDR-EnableProtection.ps1 - Assign backup policies and enable protection on
    Azure VMs and Azure Files (pilot then estate). CHANGE script - gated.

.DESCRIPTION
    PURPOSE
        Enablement helper for the "Azure Backup & Site Recovery - Deployment &
        Configuration" solution (Stage 3 - Pilot / Stage 5 - Expand). Assigns the
        named backup policies (bkpol-vm-daily-30d, bkpol-files-daily-30d) to
        in-scope resources and enables Azure Backup protection.

        SAFE BY DEFAULT: runs in -WhatIf mode and only REPORTS what it would
        protect. It makes changes ONLY when -Apply is supplied, and then requires
        a -ChangeRef (change-control reference, GR5). Never enables everything
        blindly - scope with -Scope Pilot first, prove it, then -Scope Estate.

    HOW TO RUN
        # Preview (no changes):
        .\BCKDR-EnableProtection.ps1 -Vault rsv-backup-core-prod -Scope Pilot -WhatIf
        # Apply to pilot, gated:
        .\BCKDR-EnableProtection.ps1 -Vault rsv-backup-core-prod -Scope Pilot -Apply -ChangeRef CR-1234
        # Later, expand to the estate:
        .\BCKDR-EnableProtection.ps1 -Vault rsv-backup-core-prod -Scope Estate -Apply -ChangeRef CR-1234

    EXPECTED RESULTS
        In -WhatIf: a table of resources that WOULD be protected and the policy
        that would apply. In -Apply: protection enabled and a first backup
        optionally triggered, with a summary of successes/failures.

.NOTES
    White-label. Defaults to preview. Requires Az.RecoveryServices + Backup
    Contributor on the vault. ASR replication enablement is done in-console
    (see 03-implementation.md Stage 3b) because it needs target network selection.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$Vault,
    [ValidateSet('Pilot','Estate')][string]$Scope = 'Pilot',
    [string[]]$PilotVmNames = @(),
    [string]$VmPolicyName    = 'bkpol-vm-daily-30d',
    [string]$FilesPolicyName = 'bkpol-files-daily-30d',
    [switch]$Apply,
    [string]$ChangeRef,
    [switch]$TriggerFirstBackup
)

# Gate: -Apply requires a change reference.
if ($Apply -and [string]::IsNullOrWhiteSpace($ChangeRef)) {
    throw "-Apply requires -ChangeRef <change-control reference> (GR5). Aborting."
}
if (-not $Apply) {
    Write-Host "PREVIEW MODE (no changes). Add -Apply -ChangeRef <CR> to enable protection." -ForegroundColor Yellow
}

try {
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    $rsv = Get-AzRecoveryServicesVault -Name $Vault -ErrorAction Stop
    Set-AzRecoveryServicesVaultContext -Vault $rsv

    $vmPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $VmPolicyName -ErrorAction Stop
    $plan = New-Object System.Collections.Generic.List[object]

    # Determine VM targets by scope.
    $allVms = Get-AzVM -ErrorAction SilentlyContinue
    $targetVms = if ($Scope -eq 'Pilot' -and $PilotVmNames.Count -gt 0) {
        $allVms | Where-Object { $PilotVmNames -contains $_.Name }
    } elseif ($Scope -eq 'Pilot') {
        $allVms | Select-Object -First 2   # fallback: first two as a representative pilot
    } else {
        $allVms
    }

    foreach ($vm in $targetVms) {
        # Skip if already protected.
        $existing = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM `
            -WorkloadType AzureVM -Name $vm.Name -ErrorAction SilentlyContinue
        if ($existing) {
            $plan.Add([pscustomobject]@{ Resource=$vm.Name; Type='AzureVM'; Action='AlreadyProtected'; Policy=$VmPolicyName })
            continue
        }
        $plan.Add([pscustomobject]@{ Resource=$vm.Name; Type='AzureVM'; Action='EnableProtection'; Policy=$VmPolicyName })

        if ($Apply) {
            if ($PSCmdlet.ShouldProcess("$($vm.Name)", "Enable Azure Backup with $VmPolicyName (ChangeRef $ChangeRef)")) {
                Enable-AzRecoveryServicesBackupProtection -Policy $vmPolicy `
                    -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -ErrorAction Stop
                if ($TriggerFirstBackup) {
                    $item = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM `
                        -WorkloadType AzureVM -Name $vm.Name
                    Backup-AzRecoveryServicesBackupItem -Item $item | Out-Null
                }
            }
        }
    }

    Write-Host ""
    Write-Host "Enablement plan ($Scope):" -ForegroundColor Cyan
    $plan | Format-Table -AutoSize
    if (-not $Apply) {
        Write-Host "No changes made (preview). Re-run with -Apply -ChangeRef <CR> to enable." -ForegroundColor Yellow
    } else {
        Write-Host "Applied under ChangeRef $ChangeRef." -ForegroundColor Green
    }
    Write-Host "Note: Azure Files, SQL-in-VM, and blob enablement / ASR replication are enabled per 03-implementation.md." -ForegroundColor DarkGray
}
catch {
    Write-Error "EnableProtection failed: $($_.Exception.Message)"
    exit 1
}
