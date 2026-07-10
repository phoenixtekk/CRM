<#
.SYNOPSIS
    AVDDEP-Report.ps1 — Produce an inventory/cost-posture report of the AVD deployment estate (images, hosts, drain status, scaling schedules, VM sizing).
.DESCRIPTION
    PURPOSE
        Generates a concise report for review or handover: the gallery image versions in use, session
        hosts with their VM size, drain/allow-new-session state and active session count, and the
        scaling plan schedules that govern cost. Optionally exports to CSV. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVDDEP-Report.ps1 `
            -ResourceGroupName 'AVD - Resource Group - Core' `
            -HostPoolName 'AVD - Host Pool - Pilot' `
            -CsvPath .\AVDDEP-report.csv        # optional
        Requires Az.Accounts, Az.Compute, Az.DesktopVirtualization. Read-only.
    EXPECTED RESULTS
        A per-host table (size, drain state, sessions), the gallery versions referenced, and the scaling
        schedule summary. If -CsvPath is given, the host table is also written to CSV.
.NOTES
    Azure Solutions — Azure Virtual Desktop (deployment/image/FSLogix/scaling). Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$HostPoolName,
    [string]$CsvPath = ''
)

foreach ($m in 'Az.Accounts','Az.Compute','Az.DesktopVirtualization') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

Write-Host "`n=== AVD deployment report: $HostPoolName ===" -ForegroundColor Cyan
$hp = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction Stop
Write-Host ("Host pool type: {0}   load-balancer: {1}   max session limit: {2}" -f $hp.HostPoolType, $hp.LoadBalancerType, $hp.MaxSessionLimit)

$hosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue)
$rows = foreach ($h in $hosts) {
    $vmName = ($h.Name -split '/')[-1] -replace '\..*$',''
    $vm = Get-AzVM -Name $vmName -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Host            = $vmName
        VmSize          = $vm.HardwareProfile.VmSize
        ImageExactVer   = $vm.StorageProfile.ImageReference.ExactVersion
        Status          = $h.Status
        AllowNewSession = $h.AllowNewSession      # $false == drain mode
        Sessions        = $h.Session
        AgentVersion    = $h.AgentVersion
    }
}
if ($rows) {
    $rows | Format-Table -AutoSize
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("CSV written: {0}" -f $CsvPath) -ForegroundColor Green }
    $drained = @($rows | Where-Object { -not $_.AllowNewSession })
    $drainColor = if ($drained.Count) { 'Yellow' } else { 'Green' }
    Write-Host ("Hosts in drain mode (AllowNewSession=false): {0}" -f $drained.Count) -ForegroundColor $drainColor
} else {
    Write-Host "  (no session hosts found)" -ForegroundColor Yellow
}

Write-Host "`n=== Gallery image versions referenced by this pool ===" -ForegroundColor Cyan
$rows.ImageExactVer | Sort-Object -Unique | ForEach-Object { Write-Host ("  {0}" -f $_) }

Write-Host "`n=== Scaling plan schedules (cost control) ===" -ForegroundColor Cyan
$plans = @(Get-AzWvdScalingPlan -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
           Where-Object { $_.HostPoolReference.HostPoolArmPath -like "*$HostPoolName*" })
if (-not $plans) { Write-Host "  (no scaling plan assigned — idle hosts will not deallocate)" -ForegroundColor Yellow }
foreach ($p in $plans) {
    Write-Host ("  Plan: {0}  enabled-for-this-pool: {1}" -f $p.Name, ($p.HostPoolReference | Where-Object { $_.HostPoolArmPath -like "*$HostPoolName*" }).ScalingPlanEnabled) -ForegroundColor Green
    foreach ($s in $p.Schedule) {
        Write-Host ("    schedule: {0}  ramp-up: {1}  peak-start: {2}  ramp-down: {3}  off-peak: {4}" -f `
            $s.Name, $s.RampUpStartTime, $s.PeakStartTime, $s.RampDownStartTime, $s.OffPeakStartTime)
    }
}

Write-Host "`nReport complete." -ForegroundColor Green
