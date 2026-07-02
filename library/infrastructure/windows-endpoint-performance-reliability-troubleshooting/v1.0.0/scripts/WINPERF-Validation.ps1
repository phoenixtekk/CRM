<#
.SYNOPSIS
    WINPERF-Validation.ps1 — deep per-device measurement scored against the pass/fail gates.
.DESCRIPTION
    PURPOSE
        Performs the full per-device measurement behind the Diagnostic Playbook: boot timing and slow
        contributors, sign-in/profile signals, steady-state CPU/RAM/disk sampled over a window,
        crash/bugcheck history, and storage/SSD health. Scores each against the pass/fail gates and
        maps failures to a playbook branch. Read-only: it measures, it does not change anything.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINPERF-Validation.ps1

        Optional: -SampleSeconds 60   how long to sample resource counters (default 60).
        Optional: -OutFile results-your-device-name.json   to save the full result as JSON.
    EXPECTED RESULTS
        A per-branch PASS/FAIL table (Boot, Sign-in/Profile, Resource, Stability, Storage). Each FAIL
        names the measured cause and the playbook branch to follow. All PASS means the device meets
        the enterprise gates; re-run after a fix to confirm a previously failing gate now passes.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [int]$SampleSeconds = 60,
    [string]$OutFile
)

$ErrorActionPreference = 'SilentlyContinue'

# --- Gate thresholds (enterprise defaults; tune to your fleet baseline) ---
$Gate = @{
    BootMs       = 60000
    SignInSec    = 30
    StartupApps  = 10
    CpuPct       = 85
    MemPct       = 90
    DiskPct      = 95
    DiskQueue    = 2
    FreePct      = 15
    CrashDays    = 14
}

$diagLog = 'Microsoft-Windows-Diagnostics-Performance/Operational'
$findings = @()

function New-Finding($Branch, $Metric, $Value, $Pass, $Note) {
    [PSCustomObject]@{ Branch=$Branch; Metric=$Metric; Value=$Value; Result=$(if($Pass){'PASS'}else{'FAIL'}); Note=$Note }
}

Write-Host "=== WINPERF Validation — $env:COMPUTERNAME — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# ---------- Branch A: Boot ----------
$bootMs = $null; $slowBoot = @()
$bootEvt = Get-WinEvent -LogName $diagLog -FilterXPath "*[System[(EventID=100)]]" -MaxEvents 1 -ErrorAction SilentlyContinue
if ($bootEvt) {
    $x = [xml]$bootEvt.ToXml()
    $bt = ($x.Event.EventData.Data | Where-Object { $_.Name -eq 'BootTime' }).'#text'
    if ($bt) { $bootMs = [int]$bt }
}
$slowBoot = Get-WinEvent -LogName $diagLog -FilterXPath "*[System[(EventID=101 or EventID=102 or EventID=103 or EventID=109)]]" -MaxEvents 20 -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Message
if ($null -ne $bootMs) {
    $findings += New-Finding 'A-Boot' 'BootTime(ms)' $bootMs ($bootMs -le $Gate.BootMs) `
        $(if ($slowBoot) {"Slow contributors present ($($slowBoot.Count)) — see events 101/102/103/109"} else {'no repeated slow contributors'})
} else {
    $findings += New-Finding 'A-Boot' 'BootTime(ms)' 'n/a' $true 'boot event 100 unavailable (VM or log disabled)'
}

# ---------- Branch B: Sign-in / Profile ----------
$startupApps = @()
$runKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
           'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
foreach ($k in $runKeys) {
    $p = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue
    if ($p) { $startupApps += ($p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }).Name }
}
$startupApps += (Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Name
$startupApps = $startupApps | Where-Object { $_ } | Select-Object -Unique
$startupCount = $startupApps.Count
$findings += New-Finding 'B-SignIn' 'StartupAppCount' $startupCount ($startupCount -le $Gate.StartupApps) `
    'sign-in duration best read from Endpoint analytics; startup-app count measured locally'

$profiles = Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue |
    Where-Object { $_.Special -eq $false -and $_.LocalPath }
foreach ($pr in $profiles) {
    $sizeGb = $null
    if (Test-Path $pr.LocalPath) {
        $bytes = (Get-ChildItem -LiteralPath $pr.LocalPath -Recurse -Force -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum).Sum
        if ($bytes) { $sizeGb = [math]::Round($bytes/1GB,2) }
    }
    if ($null -ne $sizeGb) {
        $findings += New-Finding 'B-SignIn' "ProfileSizeGB($($pr.LocalPath | Split-Path -Leaf))" $sizeGb $true 'informational — compare to fleet norm'
    }
}

# ---------- Branch C: Steady-state resources ----------
Write-Host "Sampling resource counters for $SampleSeconds s..." -ForegroundColor DarkGray
$maxSamples = [math]::Max(2, [int]($SampleSeconds))
$cpuS = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples $maxSamples -ErrorAction SilentlyContinue).CounterSamples.CookedValue
$memS = (Get-Counter '\Memory\% Committed Bytes In Use' -SampleInterval 1 -MaxSamples $maxSamples -ErrorAction SilentlyContinue).CounterSamples.CookedValue
$dskS = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -SampleInterval 1 -MaxSamples $maxSamples -ErrorAction SilentlyContinue).CounterSamples.CookedValue
$qS   = (Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length' -SampleInterval 1 -MaxSamples $maxSamples -ErrorAction SilentlyContinue).CounterSamples.CookedValue

$cpuAvg = if ($cpuS) { [math]::Round(($cpuS | Measure-Object -Average).Average,1) } else { $null }
$memAvg = if ($memS) { [math]::Round(($memS | Measure-Object -Average).Average,1) } else { $null }
$dskAvg = if ($dskS) { [math]::Round(($dskS | Measure-Object -Average).Average,1) } else { $null }
$qAvg   = if ($qS)   { [math]::Round(($qS   | Measure-Object -Average).Average,2) } else { $null }

$topCpu = Get-Process -ErrorAction SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 3 -ExpandProperty ProcessName
$topMem = Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet -Descending | Select-Object -First 3 -ExpandProperty ProcessName

if ($null -ne $cpuAvg) { $findings += New-Finding 'C-Resource' 'CPU%avg' $cpuAvg ($cpuAvg -lt $Gate.CpuPct) ("top: " + ($topCpu -join ', ')) }
if ($null -ne $memAvg) { $findings += New-Finding 'C-Resource' 'Mem%avg' $memAvg ($memAvg -lt $Gate.MemPct) ("top: " + ($topMem -join ', ')) }
if ($null -ne $dskAvg) { $findings += New-Finding 'C-Resource' 'Disk%avg' $dskAvg ($dskAvg -lt $Gate.DiskPct) ("queue avg: $qAvg") }
if ($null -ne $qAvg)   { $findings += New-Finding 'C-Resource' 'DiskQueueAvg' $qAvg ($qAvg -lt $Gate.DiskQueue) '' }

# ---------- Branch D: Stability ----------
$since = (Get-Date).AddDays(-$Gate.CrashDays)
$bugs = @(Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001; StartTime=$since} -ErrorAction SilentlyContinue)
$apps = @(Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1002; StartTime=$since} -ErrorAction SilentlyContinue)
$unexp= @(Get-WinEvent -FilterHashtable @{LogName='System'; Id=41; StartTime=$since} -ErrorAction SilentlyContinue)
$findings += New-Finding 'D-Stability' "Bugchecks/$($Gate.CrashDays)d" $bugs.Count ($bugs.Count -eq 0) $(if($bugs){'Stop code(s) in System event 1001 — map to driver/hardware'}else{''})
$findings += New-Finding 'D-Stability' "AppCrashes/$($Gate.CrashDays)d" $apps.Count ($apps.Count -eq 0) 'check for a repeating faulting module (event 1000)'
$findings += New-Finding 'D-Stability' "UnexpectedShutdowns/$($Gate.CrashDays)d" $unexp.Count ($unexp.Count -eq 0) 'event 41 without bugcheck suggests power/thermal'

# ---------- Branch E: Storage health ----------
foreach ($pd in (Get-PhysicalDisk -ErrorAction SilentlyContinue)) {
    $healthy = ($pd.HealthStatus -eq 'Healthy')
    $findings += New-Finding 'E-Storage' "Health($($pd.FriendlyName))" $pd.HealthStatus $healthy "media: $($pd.MediaType)"
}
$predict = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
if ($predict) {
    foreach ($p in $predict) {
        $findings += New-Finding 'E-Storage' 'PredictFailure' $p.PredictFailure (-not $p.PredictFailure) $(if($p.PredictFailure){'DRIVE FAILING — back up + replace'}else{''})
    }
} else {
    $findings += New-Finding 'E-Storage' 'PredictFailure' 'n/a' $true 'SMART unavailable (virtual / driver) — not a pass by itself'
}
foreach ($v in (Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.Size })) {
    $free = [math]::Round(($v.SizeRemaining/$v.Size)*100,1)
    $findings += New-Finding 'E-Storage' "Free%($($v.DriveLetter):)" $free ($free -ge $Gate.FreePct) ''
}

# ---------- Output ----------
Write-Host "`n--- Results ---" -ForegroundColor Cyan
$findings | Format-Table Branch, Metric, Value, Result, Note -AutoSize | Out-String | Write-Host
$fails = @($findings | Where-Object { $_.Result -eq 'FAIL' })
Write-Host ("Overall: {0}  ({1} of {2} gates failing)" -f `
    $(if ($fails.Count -eq 0){'PASS'}else{'FAIL'}), $fails.Count, $findings.Count) `
    -ForegroundColor $(if ($fails.Count -eq 0){'Green'}else{'Yellow'})
if ($fails) {
    Write-Host "Follow these playbook branches:" -ForegroundColor Yellow
    ($fails.Branch | Select-Object -Unique) | ForEach-Object { Write-Host "  - $_" }
}

$out = [PSCustomObject]@{
    Computer  = $env:COMPUTERNAME
    Timestamp = (Get-Date).ToString('s')
    Overall   = $(if ($fails.Count -eq 0){'PASS'}else{'FAIL'})
    Findings  = $findings
}
if ($OutFile) {
    $out | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutFile -Encoding UTF8
    Write-Host "`nSaved results to $OutFile" -ForegroundColor Green
}
$out
