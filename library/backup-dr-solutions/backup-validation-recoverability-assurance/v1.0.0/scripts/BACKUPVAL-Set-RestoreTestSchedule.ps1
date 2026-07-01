<#
.SYNOPSIS
    BACKUPVAL-Set-RestoreTestSchedule - Scaffold and track the restore-test
    schedule rotation ('Restore-Test Schedule - Backup Estate - Cadence').

.DESCRIPTION
    Builds (or updates) a restore-test schedule rotation for the Backup Validation &
    Recoverability Assurance Program. Takes an inventory of in-scope workloads (from a
    BACKUPVAL-Discovery.ps1 CSV, or live from Recovery Services vaults) and a cadence
    per workload class, then computes a 'Next due' date for each object and writes the
    schedule to CSV. Defaults to -WhatIf preview: it shows the schedule it WOULD write
    without writing unless run normally (no -WhatIf) or with -Force.

    Read-only against Azure (inventory query only); the only output is the schedule CSV.

.PARAMETER DiscoveryCsv
    Optional. BACKUPVAL-Discovery.ps1 output CSV providing the in-scope inventory.
    If omitted, protected items are queried live from the vault(s).

.PARAMETER ExistingSchedule
    Optional. An existing schedule CSV to update (preserves 'Last tested' dates).

.PARAMETER CadenceDaysByClass
    Hashtable of workload class -> cadence in days. Defaults:
    AzureVM=30, AzureFiles=90, Exchange=30, SharePoint=90, OneDrive=90, Teams=90.

.PARAMETER OutputPath
    Output schedule CSV path. Defaults to .\Restore-Test-Schedule.csv.

.PARAMETER Force
    Write the schedule even under -WhatIf preview semantics.

.EXAMPLE
    .\BACKUPVAL-Set-RestoreTestSchedule.ps1 -DiscoveryCsv .\BACKUPVAL-Discovery.csv -WhatIf

.EXAMPLE
    .\BACKUPVAL-Set-RestoreTestSchedule.ps1 -DiscoveryCsv .\BACKUPVAL-Discovery.csv

.NOTES
    Backup & DR Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$DiscoveryCsv,
    [string]$ExistingSchedule,
    [hashtable]$CadenceDaysByClass = @{
        AzureVM = 30; AzureFiles = 90; Exchange = 30; SharePoint = 90; OneDrive = 90; Teams = 90
    },
    [string]$OutputPath = ".\Restore-Test-Schedule.csv",
    [switch]$Force
)

function Get-Cadence([string]$class) {
    if ($CadenceDaysByClass.ContainsKey($class)) { return [int]$CadenceDaysByClass[$class] }
    return 90  # default cadence
}

try {
    $today = Get-Date

    # --- Preserve last-tested from an existing schedule ---
    $lastTested = @{}
    if ($ExistingSchedule -and (Test-Path $ExistingSchedule)) {
        Import-Csv $ExistingSchedule | ForEach-Object {
            if ($_.ObjectToTest) { $lastTested[$_.ObjectToTest] = $_.LastTested }
        }
    }

    # --- Inventory ---
    $inventory = New-Object System.Collections.Generic.List[object]
    if ($DiscoveryCsv -and (Test-Path $DiscoveryCsv)) {
        Import-Csv $DiscoveryCsv | Where-Object { $_.Protected -eq 'Y' } | ForEach-Object {
            $inventory.Add([pscustomobject]@{ WorkloadClass = $_.WorkloadClass; ObjectName = $_.ObjectName })
        }
    } else {
        if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
        foreach ($vault in (Get-AzRecoveryServicesVault)) {
            Set-AzRecoveryServicesVaultContext -Vault $vault
            foreach ($type in @('AzureVM', 'AzureFiles')) {
                $ctype = ($type -eq 'AzureVM') ? 'AzureVM' : 'AzureStorage'
                Get-AzRecoveryServicesBackupContainer -ContainerType $ctype -BackupManagementType $ctype -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        Get-AzRecoveryServicesBackupItem -Container $_ -WorkloadType $type -ErrorAction SilentlyContinue |
                            ForEach-Object { $inventory.Add([pscustomobject]@{ WorkloadClass = $type; ObjectName = $_.Name }) }
                    }
            }
        }
    }

    if (-not $inventory) { Write-Warning "No in-scope objects found to schedule."; return }

    # --- Build schedule with staggered next-due dates ---
    $schedule = New-Object System.Collections.Generic.List[object]
    $stagger = @{}  # per-class running offset so objects spread across the cadence window

    foreach ($obj in ($inventory | Sort-Object WorkloadClass, ObjectName)) {
        $class   = $obj.WorkloadClass
        $cadence = Get-Cadence $class
        $last    = $lastTested[$obj.ObjectName]

        if (-not $stagger.ContainsKey($class)) { $stagger[$class] = 0 }
        $countInClass = ($inventory | Where-Object WorkloadClass -eq $class).Count
        $step = if ($countInClass -gt 0) { [math]::Max([math]::Floor($cadence / $countInClass), 1) } else { $cadence }

        if ($last) {
            try { $nextDue = ([datetime]$last).AddDays($cadence) } catch { $nextDue = $today.AddDays($stagger[$class]) }
        } else {
            $nextDue = $today.AddDays($stagger[$class])
        }
        $stagger[$class] += $step

        $schedule.Add([pscustomobject]@{
            WorkloadClass   = $class
            ObjectToTest    = $obj.ObjectName
            CadenceDays     = $cadence
            LastTested      = if ($last) { $last } else { '' }
            NextDue         = $nextDue.ToString('yyyy-MM-dd')
            Owner           = ''
            RestoreTarget   = ''
            ChangeReference = ''
        })
    }

    Write-Host "Proposed Restore-Test Schedule - Backup Estate - Cadence:" -ForegroundColor Cyan
    $schedule | Format-Table WorkloadClass, ObjectToTest, CadenceDays, NextDue, LastTested -AutoSize

    $doWrite = $Force -or $PSCmdlet.ShouldProcess($OutputPath, "Write restore-test schedule ($($schedule.Count) entries)")
    if ($doWrite) {
        $schedule | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Schedule written to: $OutputPath" -ForegroundColor Green
    } else {
        Write-Host "[WhatIf] Schedule not written. Re-run without -WhatIf (or with -Force) to commit." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Schedule scaffolding failed: $($_.Exception.Message)"
    exit 1
}
