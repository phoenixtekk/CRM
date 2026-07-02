<#
.SYNOPSIS
    WINPERF-Discovery.ps1 — quick read-only sweep of Windows performance and reliability signals.
.DESCRIPTION
    PURPOSE
        Collects a fast snapshot of the key performance and reliability signals on a Windows
        endpoint (boot timing, resource pressure, recent crashes, storage health) and confirms the
        prerequisites needed to measure deeper. Read-only: it changes nothing. Use it first to see
        who is slow or unstable and where to look next.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINPERF-Discovery.ps1

        Optional: -OutFile results-your-device-name.json  to save the snapshot as JSON.
    EXPECTED RESULTS
        A READY / NOT READY prerequisite line, then a signal summary. The technician sees boot time,
        current CPU/RAM/disk, recent bugcheck/app-crash counts, and disk health at a glance.
        NOT READY means fix prerequisites (run as admin, enable logs) before trusting the numbers.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [string]$OutFile
)

$ErrorActionPreference = 'SilentlyContinue'

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "=== WINPERF Discovery — $env:COMPUTERNAME — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# --- Prerequisite readiness (T1) ---
$ready = $true
$isAdmin = Test-IsAdmin
if (-not $isAdmin) { $ready = $false }

$diagLog = 'Microsoft-Windows-Diagnostics-Performance/Operational'
$diagOk  = [bool](Get-WinEvent -LogName $diagLog -MaxEvents 1 -ErrorAction SilentlyContinue)
$sysOk   = [bool](Get-WinEvent -LogName System -MaxEvents 1 -ErrorAction SilentlyContinue)
$ctrOk   = [bool](Get-Counter '\Processor(_Total)\% Processor Time' -MaxSamples 1 -ErrorAction SilentlyContinue)
$diskOk  = [bool](Get-PhysicalDisk -ErrorAction SilentlyContinue)
if (-not ($diagOk -and $sysOk -and $ctrOk -and $diskOk)) { $ready = $false }

Write-Host ("Prerequisites: {0}" -f ($(if ($ready) {'READY'} else {'NOT READY'}))) `
    -ForegroundColor $(if ($ready) {'Green'} else {'Yellow'})
Write-Host ("  Admin={0}  DiagLog={1}  SysLog={2}  Counters={3}  Storage={4}" -f `
    $isAdmin, $diagOk, $sysOk, $ctrOk, $diskOk)

# --- Boot time (event 100) ---
$bootMs = $null
$boot = Get-WinEvent -LogName $diagLog -FilterXPath "*[System[(EventID=100)]]" -MaxEvents 1 -ErrorAction SilentlyContinue
if ($boot) {
    $x = [xml]$boot.ToXml()
    $bt = ($x.Event.EventData.Data | Where-Object { $_.Name -eq 'BootTime' }).'#text'
    if ($bt) { $bootMs = [int]$bt }
}

# --- Resource snapshot (single quick sample) ---
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -MaxSamples 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue
$memC = (Get-Counter '\Memory\% Committed Bytes In Use' -MaxSamples 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue
$disk = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -MaxSamples 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue

# --- Stability (last 14 days) ---
$since = (Get-Date).AddDays(-14)
$bugchecks = @(Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001; StartTime=$since} -ErrorAction SilentlyContinue).Count
$appCrash  = @(Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1002; StartTime=$since} -ErrorAction SilentlyContinue).Count
$unexpected= @(Get-WinEvent -FilterHashtable @{LogName='System'; Id=41; StartTime=$since} -ErrorAction SilentlyContinue).Count

# --- Storage health ---
$disks = Get-PhysicalDisk -ErrorAction SilentlyContinue |
    Select-Object FriendlyName, MediaType, HealthStatus
$sysVol = Get-Volume -DriveLetter $env:SystemDrive.TrimEnd(':') -ErrorAction SilentlyContinue
$freePct = if ($sysVol -and $sysVol.Size) { [math]::Round(($sysVol.SizeRemaining / $sysVol.Size) * 100, 1) } else { $null }

Write-Host "`n--- Signals ---" -ForegroundColor Cyan
Write-Host ("Boot time (ms) : {0}" -f $(if ($bootMs) {$bootMs} else {'n/a'}))
Write-Host ("CPU %          : {0}" -f $(if ($null -ne $cpu) {[math]::Round($cpu,1)} else {'n/a'}))
Write-Host ("Mem committed %: {0}" -f $(if ($null -ne $memC){[math]::Round($memC,1)} else {'n/a'}))
Write-Host ("Disk % time    : {0}" -f $(if ($null -ne $disk){[math]::Round($disk,1)} else {'n/a'}))
Write-Host ("Bugchecks/14d  : {0}   AppCrashes/14d: {1}   UnexpectedShutdowns/14d: {2}" -f $bugchecks,$appCrash,$unexpected)
Write-Host ("System free %  : {0}" -f $(if ($null -ne $freePct){$freePct} else {'n/a'}))
foreach ($d in $disks) { Write-Host ("Disk           : {0} [{1}] Health={2}" -f $d.FriendlyName,$d.MediaType,$d.HealthStatus) }

$result = [PSCustomObject]@{
    Computer            = $env:COMPUTERNAME
    Timestamp           = (Get-Date).ToString('s')
    Ready               = $ready
    IsAdmin             = $isAdmin
    BootTimeMs          = $bootMs
    CpuPct              = if ($null -ne $cpu)  {[math]::Round($cpu,1)}  else {$null}
    MemCommittedPct     = if ($null -ne $memC) {[math]::Round($memC,1)} else {$null}
    DiskPct             = if ($null -ne $disk) {[math]::Round($disk,1)} else {$null}
    Bugchecks14d        = $bugchecks
    AppCrashes14d       = $appCrash
    UnexpectedShutdowns = $unexpected
    SystemFreePct       = $freePct
    Disks               = $disks
}

if ($OutFile) {
    $result | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutFile -Encoding UTF8
    Write-Host "`nSaved snapshot to $OutFile" -ForegroundColor Green
}

$result
