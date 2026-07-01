<#
.SYNOPSIS
    BACKUPVAL-Report - Produce the recoverability assurance report data:
    coverage %, RPO adherence, and last successful test-restore per workload.

.DESCRIPTION
    Read-only reporting for the Backup Validation & Recoverability Assurance Program.
    Combines Azure Recovery Services vault backup-item state with an optional
    restore-test evidence log to compute, per workload class and overall:
      - coverage % (protected vs. total in-scope)
      - RPO adherence (latest recovery point within RPO)
      - last successful test-restore date per workload
    Emits the 'Recoverability Assurance Report - Backup Estate - Reporting' data to CSV.

    Makes no changes. Requires the Az PowerShell module and Reader access.

.PARAMETER DiscoveryCsv
    Optional. Path to a BACKUPVAL-Discovery.ps1 output CSV to use as the in-scope
    inventory (provides Protected = Y/N rows). If omitted, queries vaults live for
    protected items only (unprotected resources will not be counted).

.PARAMETER RestoreTestLog
    Optional. CSV with columns 'ObjectName' and 'LastTestRestore'.

.PARAMETER RpoHours
    RPO threshold in hours for adherence. Default 24.

.PARAMETER OutputPath
    Optional. CSV path for the report. Defaults to a timestamped file.

.EXAMPLE
    .\BACKUPVAL-Report.ps1 -DiscoveryCsv .\BACKUPVAL-Discovery-20260628.csv -RestoreTestLog .\restore-test-log.csv

.NOTES
    Backup & DR Solutions - read-only.
#>

[CmdletBinding()]
param(
    [string]$DiscoveryCsv,
    [string]$RestoreTestLog,
    [int]$RpoHours = 24,
    [string]$OutputPath = ".\BACKUPVAL-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

try {
    $now = Get-Date

    # --- Source inventory ---
    $inventory = New-Object System.Collections.Generic.List[object]

    if ($DiscoveryCsv -and (Test-Path $DiscoveryCsv)) {
        Import-Csv $DiscoveryCsv | ForEach-Object { $inventory.Add($_) }
    } else {
        if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
        foreach ($vault in (Get-AzRecoveryServicesVault)) {
            Set-AzRecoveryServicesVaultContext -Vault $vault
            foreach ($type in @('AzureVM', 'AzureFiles')) {
                $ctype = ($type -eq 'AzureVM') ? 'AzureVM' : 'AzureStorage'
                $containers = Get-AzRecoveryServicesBackupContainer -ContainerType $ctype `
                    -BackupManagementType $ctype -ErrorAction SilentlyContinue
                foreach ($container in $containers) {
                    Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType $type `
                        -ErrorAction SilentlyContinue | ForEach-Object {
                        $inventory.Add([pscustomobject]@{
                            WorkloadClass  = $type
                            ObjectName     = $_.Name
                            Protected      = 'Y'
                            LatestRecovery = $_.LatestRecoveryPoint
                        })
                    }
                }
            }
        }
    }

    # --- Test-restore log ---
    $testLog = @{}
    if ($RestoreTestLog -and (Test-Path $RestoreTestLog)) {
        Import-Csv $RestoreTestLog | ForEach-Object {
            if ($_.ObjectName) { $testLog[$_.ObjectName] = $_.LastTestRestore }
        }
    }

    # --- Per-class rollup ---
    $report = New-Object System.Collections.Generic.List[object]
    $classes = $inventory | Group-Object WorkloadClass

    foreach ($class in $classes) {
        $total      = $class.Group.Count
        $protected  = ($class.Group | Where-Object { $_.Protected -eq 'Y' }).Count
        $coverage   = if ($total) { [math]::Round(($protected / $total) * 100, 1) } else { 0 }

        $rpoOk = 0; $rpoEval = 0
        foreach ($row in ($class.Group | Where-Object { $_.Protected -eq 'Y' })) {
            if ($row.LatestRecovery) {
                $rpoEval++
                if ((New-TimeSpan -Start ([datetime]$row.LatestRecovery) -End $now).TotalHours -le $RpoHours) { $rpoOk++ }
            }
        }
        $rpoAdherence = if ($rpoEval) { [math]::Round(($rpoOk / $rpoEval) * 100, 1) } else { 0 }

        $lastTest = ($class.Group |
            Where-Object { $testLog.ContainsKey($_.ObjectName) } |
            ForEach-Object { try { [datetime]$testLog[$_.ObjectName] } catch {} } |
            Sort-Object -Descending | Select-Object -First 1)

        $report.Add([pscustomobject]@{
            WorkloadClass        = $class.Name
            TotalInScope         = $total
            Protected            = $protected
            CoveragePct          = $coverage
            RpoAdherencePct      = $rpoAdherence
            LastTestRestore      = if ($lastTest) { $lastTest.ToString('yyyy-MM-dd') } else { 'NONE' }
        })
    }

    # --- Overall line ---
    $allTotal     = $inventory.Count
    $allProtected = ($inventory | Where-Object { $_.Protected -eq 'Y' }).Count
    $report.Add([pscustomobject]@{
        WorkloadClass   = 'OVERALL'
        TotalInScope    = $allTotal
        Protected       = $allProtected
        CoveragePct     = if ($allTotal) { [math]::Round(($allProtected / $allTotal) * 100, 1) } else { 0 }
        RpoAdherencePct = ''
        LastTestRestore = ''
    })

    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    $report | Format-Table -AutoSize

    Write-Host ""
    Write-Host "Recoverability Assurance Report written to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Report generation failed: $($_.Exception.Message)"
    exit 1
}
