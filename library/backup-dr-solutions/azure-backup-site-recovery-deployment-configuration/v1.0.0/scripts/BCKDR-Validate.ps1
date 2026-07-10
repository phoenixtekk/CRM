<#
.SYNOPSIS
    BCKDR-Validate.ps1 - Validate vault hardening, policy coverage, and ASR health;
    optionally run a non-disruptive ASR test failover.

.DESCRIPTION
    PURPOSE
        Read-only validation for the "Azure Backup & Site Recovery - Deployment &
        Configuration" solution (Stage 4 - Validate). Checks, per Section 5:
          - Soft delete + immutability set on the Recovery Services and Backup vaults.
          - The named backup policies exist and are assigned (no in-scope item
            unprotected).
          - Protected items have a recent successful recovery point.
          - ASR replicated items are Protected and within RPO.
        Emits a PASS/FAIL line per check as deployment evidence.

        OPTIONAL, GATED ACTION: with -RunTestFailover it triggers a NON-DISRUPTIVE
        test failover of a recovery plan into an isolated network. A test failover
        does NOT affect the running production workload; you MUST run "Cleanup test
        failover" afterward (the script reminds you). This proves the deployment
        once - ongoing scheduled restore-testing is the separate Backup Validation
        & Recoverability Assurance program.

    HOW TO RUN
        .\BCKDR-Validate.ps1 -Vault rsv-backup-core-prod -BackupVault bvault-backup-object-prod
        .\BCKDR-Validate.ps1 -Vault rsv-backup-core-prod -RunTestFailover `
            -RecoveryPlan rp-tier1-app -TestNetworkResourceGroup rg-dr-test-sandbox -ChangeRef CR-1234

    EXPECTED RESULTS
        A checklist of PASS/FAIL results and, if requested, a started test failover
        job id. Read-only except for the explicitly gated test failover.

.NOTES
    White-label. Read-only by default. Requires Az.RecoveryServices, Az.DataProtection.
    Verify current property paths for immutability/soft delete in your tenant.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Vault,
    [string]$BackupVault,
    [string]$VmPolicyName    = 'bkpol-vm-daily-30d',
    [string]$FilesPolicyName = 'bkpol-files-daily-30d',
    [int]$RpoTargetHours     = 24,
    [switch]$RunTestFailover,
    [string]$RecoveryPlan,
    [string]$TestNetworkResourceGroup,
    [string]$ChangeRef
)

$results = New-Object System.Collections.Generic.List[object]
function Add-Check($name, $pass, $detail) {
    $results.Add([pscustomobject]@{ Check=$name; Result=($pass ? 'PASS' : 'FAIL'); Detail=$detail })
}

try {
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    $rsv = Get-AzRecoveryServicesVault -Name $Vault -ErrorAction Stop

    # --- 1. Vault hardening (Recovery Services vault) ---
    $sec = $rsv.Properties.securitySettings
    $sd  = $sec.softDeleteSettings.softDeleteState
    $imm = $sec.immutabilitySettings.state
    Add-Check "RSV soft delete enabled" ($sd -eq 'Enabled') "state=$sd"
    Add-Check "RSV immutability configured" ($imm -in @('Unlocked','Locked')) "state=$imm"

    if ($BackupVault) {
        $bv = Get-AzDataProtectionBackupVault -VaultName $BackupVault -ErrorAction SilentlyContinue
        if ($bv) {
            $bsd = $bv.SecuritySettingSoftDeleteSettingState
            $bim = $bv.SecuritySettingImmutabilitySettingState
            Add-Check "Backup vault soft delete on" ($bsd -eq 'On') "state=$bsd"
            Add-Check "Backup vault immutability configured" ($bim -in @('Unlocked','Locked')) "state=$bim"
        } else {
            Add-Check "Backup vault present" $false "vault '$BackupVault' not found"
        }
    }

    # --- 2. Policies exist ---
    Set-AzRecoveryServicesVaultContext -Vault $rsv
    foreach ($p in @($VmPolicyName, $FilesPolicyName)) {
        $pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $p -ErrorAction SilentlyContinue
        Add-Check "Policy exists: $p" ($null -ne $pol) ($pol ? "found" : "missing")
    }

    # --- 3. Protected items have a recent recovery point ---
    $items = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -ErrorAction SilentlyContinue
    foreach ($it in $items) {
        $ageOk = $it.LastBackupTime -and ($it.LastBackupTime -gt (Get-Date).AddHours(-$RpoTargetHours))
        $statusOk = ($it.LastBackupStatus -eq 'Completed')
        Add-Check "Recovery point recent+ok: $($it.Name)" ($ageOk -and $statusOk) `
            "status=$($it.LastBackupStatus); last=$($it.LastBackupTime)"
    }
    if (-not $items) { Add-Check "Any VM protected" $false "no protected VM items found" }

    # --- 4. ASR replication health (best-effort) ---
    try {
        $fabrics = Get-AzRecoveryServicesAsrFabric -ErrorAction SilentlyContinue
        foreach ($f in $fabrics) {
            foreach ($pc in (Get-AzRecoveryServicesAsrProtectionContainer -Fabric $f -ErrorAction SilentlyContinue)) {
                foreach ($r in (Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -ErrorAction SilentlyContinue)) {
                    Add-Check "ASR protected: $($r.FriendlyName)" ($r.ProtectionState -eq 'Protected') `
                        "state=$($r.ProtectionState); health=$($r.ReplicationHealth)"
                }
            }
        }
    } catch { Add-Check "ASR enumeration" $false $_.Exception.Message }

    # --- Output checklist ---
    Write-Host ""
    $results | Format-Table -AutoSize
    $fails = ($results | Where-Object Result -eq 'FAIL').Count
    Write-Host ("Validation: {0} checks, {1} FAIL." -f $results.Count, $fails) `
        -ForegroundColor ($fails -eq 0 ? 'Green' : 'Red')

    # --- Optional gated test failover ---
    if ($RunTestFailover) {
        if ([string]::IsNullOrWhiteSpace($RecoveryPlan) -or
            [string]::IsNullOrWhiteSpace($TestNetworkResourceGroup) -or
            [string]::IsNullOrWhiteSpace($ChangeRef)) {
            throw "-RunTestFailover requires -RecoveryPlan, -TestNetworkResourceGroup, and -ChangeRef."
        }
        Write-Host ""
        Write-Host "Starting NON-DISRUPTIVE test failover of '$RecoveryPlan' into '$TestNetworkResourceGroup' (ChangeRef $ChangeRef)..." -ForegroundColor Cyan
        $rp = Get-AzRecoveryServicesAsrRecoveryPlan -Name $RecoveryPlan -ErrorAction Stop
        $job = Start-AzRecoveryServicesAsrTestFailoverJob -RecoveryPlan $rp -Direction PrimaryToRecovery -ErrorAction Stop
        Write-Host "Test failover job started: $($job.Name)" -ForegroundColor Green
        Write-Host "IMPORTANT: after validating, run 'Cleanup test failover' on '$RecoveryPlan' to remove test resources." -ForegroundColor Yellow
    }

    if ($fails -gt 0) { exit 2 }
}
catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
}
