<#
.SYNOPSIS
    BACKUPVAL-Validation - Verify last-backup recency against RPO and last
    successful restore-test recency against the test cadence; emit PASS/FAIL.

.DESCRIPTION
    Read-only validation for the Backup Validation & Recoverability Assurance Program.
    For each protected Azure Recovery Services vault backup item, checks whether the
    latest recovery point is within the workload's RPO. Optionally checks each
    workload's last successful test restore against the required cadence using a
    restore-test log (the 'Test-Restore Record - Per-Workload - Evidence' export).
    Emits a PASS/FAIL line per item and a non-zero exit code if any FAIL.

    Makes no changes. Requires the Az PowerShell module and Reader access.

.PARAMETER VaultName
    Optional. Limit validation to a single Recovery Services vault.

.PARAMETER RpoHours
    RPO threshold in hours for last-backup recency. Default 24.

.PARAMETER CadenceDays
    Maximum days since the last successful test restore. Default 90.

.PARAMETER RestoreTestLog
    Optional. CSV path of the restore-test evidence log with columns
    'ObjectName' and 'LastTestRestore' (date). Enables cadence checking.

.PARAMETER OutputPath
    Optional. CSV path for results. Defaults to a timestamped file.

.EXAMPLE
    .\BACKUPVAL-Validation.ps1 -RpoHours 24 -CadenceDays 90

.EXAMPLE
    .\BACKUPVAL-Validation.ps1 -RestoreTestLog .\restore-test-log.csv

.NOTES
    Backup & DR Solutions - read-only.
#>

[CmdletBinding()]
param(
    [string]$VaultName,
    [int]$RpoHours = 24,
    [int]$CadenceDays = 90,
    [string]$RestoreTestLog,
    [string]$OutputPath = ".\BACKUPVAL-Validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

try {
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

    $testLog = @{}
    if ($RestoreTestLog -and (Test-Path $RestoreTestLog)) {
        Import-Csv $RestoreTestLog | ForEach-Object {
            if ($_.ObjectName) { $testLog[$_.ObjectName] = $_.LastTestRestore }
        }
    }

    $now      = Get-Date
    $results  = New-Object System.Collections.Generic.List[object]
    $anyFail  = $false

    $vaults = if ($VaultName) { Get-AzRecoveryServicesVault -Name $VaultName } else { Get-AzRecoveryServicesVault }

    foreach ($vault in $vaults) {
        Set-AzRecoveryServicesVaultContext -Vault $vault

        foreach ($type in @('AzureVM', 'AzureFiles')) {
            $ctype = ($type -eq 'AzureVM') ? 'AzureVM' : 'AzureStorage'
            $containers = Get-AzRecoveryServicesBackupContainer -ContainerType $ctype `
                -BackupManagementType $ctype -ErrorAction SilentlyContinue
            foreach ($container in $containers) {
                $items = Get-AzRecoveryServicesBackupItem -Container $container `
                    -WorkloadType $type -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    # --- RPO check ---
                    $rpoResult = 'FAIL'
                    $ageHours  = $null
                    if ($item.LatestRecoveryPoint) {
                        $ageHours = [math]::Round(($now - $item.LatestRecoveryPoint).TotalHours, 1)
                        $rpoResult = ($ageHours -le $RpoHours) ? 'PASS' : 'FAIL'
                    }

                    # --- Cadence check ---
                    $cadenceResult = 'N/A'
                    $daysSinceTest = $null
                    if ($testLog.ContainsKey($item.Name) -and $testLog[$item.Name]) {
                        try {
                            $last = [datetime]$testLog[$item.Name]
                            $daysSinceTest = [math]::Round(($now - $last).TotalDays, 0)
                            $cadenceResult = ($daysSinceTest -le $CadenceDays) ? 'PASS' : 'FAIL'
                        } catch { $cadenceResult = 'FAIL' }
                    } elseif ($testLog.Count -gt 0) {
                        $cadenceResult = 'FAIL'   # no recorded test for a workload we expected to test
                    }

                    if ($rpoResult -eq 'FAIL' -or $cadenceResult -eq 'FAIL') { $anyFail = $true }

                    $results.Add([pscustomobject]@{
                        Vault             = $vault.Name
                        WorkloadClass     = $type
                        ObjectName        = $item.Name
                        LatestRecovery    = $item.LatestRecoveryPoint
                        AgeHours          = $ageHours
                        RpoHours          = $RpoHours
                        RpoResult         = $rpoResult
                        DaysSinceTest     = $daysSinceTest
                        CadenceDays       = $CadenceDays
                        CadenceResult     = $cadenceResult
                    })
                }
            }
        }
    }

    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    $results | Format-Table WorkloadClass, ObjectName, RpoResult, AgeHours, CadenceResult, DaysSinceTest -AutoSize

    Write-Host ""
    Write-Host "Validation written to: $OutputPath"
    if ($anyFail) {
        Write-Warning "One or more items FAILED RPO or cadence validation."
        exit 2
    } else {
        Write-Host "All validated items PASSED." -ForegroundColor Green
    }
}
catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
}
