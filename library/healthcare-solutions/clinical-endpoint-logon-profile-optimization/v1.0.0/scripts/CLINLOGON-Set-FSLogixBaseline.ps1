<#
.SYNOPSIS
    Clinical Endpoint Logon & Profile Optimization (FSLogix) - capture the logon
    baseline (and re-run for before/after). -WhatIf supported.

    PURPOSE:
        Captures a repeatable LOGON / PROFILE-LOAD baseline on a clinical endpoint so
        the FSLogix + fast-logon improvement can be quantified (R6 in 02-requirements.md
        and the acceptance gate T1 in 05-testing.md). For the most recent interactive
        sign-in it reads:
          - User Profile Service load duration (profile load time)
          - Group Policy / logon total where available (usable-desktop logon time)
        and appends a timestamped row to a baseline CSV with a -Phase label
        ('Before' or 'After'), so a Before row and an After row can be compared
        directly. The default action only READS event logs and APPENDS to a CSV;
        -WhatIf previews the write without changing the file.

    HOW TO RUN:
        Before change : .\CLINLOGON-Set-FSLogixBaseline.ps1 -Phase Before -OutCsv "C:\Temp\clinlogon-baseline.csv"
        After change  : .\CLINLOGON-Set-FSLogixBaseline.ps1 -Phase After  -OutCsv "C:\Temp\clinlogon-baseline.csv"
        Preview only  : .\CLINLOGON-Set-FSLogixBaseline.ps1 -Phase Before -WhatIf
        (Run on the endpoint shortly after a representative interactive sign-in.)

    EXPECTED RESULTS:
        A console summary of the sampled logon/profile-load seconds and a row appended
        to the baseline CSV (Timestamp, Device, User, Phase, ProfileLoadSeconds,
        LogonTotalSeconds, FSLogixAttached). Compare the 'Before' and 'After' rows to
        report the reduction.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Before','After')] [string]$Phase = 'Before',
    [string]$OutCsv = (".\CLINLOGON-Baseline-{0}.csv" -f (Get-Date -Format 'yyyyMMdd'))
)

$ErrorActionPreference = 'Stop'

function Get-ProfileLoadSeconds {
    try {
        $evt = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-User Profile Service/Operational'; Id=1,2 } -MaxEvents 50 -ErrorAction Stop | Sort-Object TimeCreated
        $start = ($evt | Where-Object Id -eq 1 | Select-Object -Last 1).TimeCreated
        $end   = ($evt | Where-Object Id -eq 2 | Select-Object -Last 1).TimeCreated
        if ($start -and $end -and $end -gt $start) { return [math]::Round(($end - $start).TotalSeconds,1) }
    } catch { }
    return $null
}

function Get-LogonTotalSeconds {
    # Group Policy operational log start (4001) to end (8001) gives a good proxy for
    # the interactive logon-to-usable window where available.
    try {
        $gp = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-GroupPolicy/Operational'; Id=4001,8001 } -MaxEvents 50 -ErrorAction Stop | Sort-Object TimeCreated
        $start = ($gp | Where-Object Id -eq 4001 | Select-Object -Last 1).TimeCreated
        $end   = ($gp | Where-Object Id -eq 8001 | Select-Object -Last 1).TimeCreated
        if ($start -and $end -and $end -gt $start) { return [math]::Round(($end - $start).TotalSeconds,1) }
    } catch { }
    return $null
}

function Test-FSLogixAttached {
    $v = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.FileSystemLabel -like 'Profile-*' -or $_.FileSystemLabel -like 'O365-*' }
    return [bool]$v
}

$profileLoad = Get-ProfileLoadSeconds
$logonTotal  = Get-LogonTotalSeconds
$attached    = Test-FSLogixAttached

Write-Host ("Device              : {0}" -f $env:COMPUTERNAME)
Write-Host ("User                : {0}" -f $env:USERNAME)
Write-Host ("Phase               : {0}" -f $Phase)
Write-Host ("Profile load (s)    : {0}" -f ($(if ($profileLoad -ne $null) { $profileLoad } else { 'n/a' })))
Write-Host ("Logon total (s)     : {0}" -f ($(if ($logonTotal  -ne $null) { $logonTotal }  else { 'n/a' })))
Write-Host ("FSLogix attached    : {0}" -f $attached)

if ($profileLoad -eq $null -and $logonTotal -eq $null) {
    Write-Warning "Could not sample logon timings from event logs. Ensure the operational logs are enabled and run shortly after an interactive sign-in."
}

$row = [pscustomobject]@{
    Timestamp          = (Get-Date).ToString('s')
    Device             = $env:COMPUTERNAME
    User               = $env:USERNAME
    Phase              = $Phase
    ProfileLoadSeconds = $profileLoad
    LogonTotalSeconds  = $logonTotal
    FSLogixAttached    = $attached
}

if ($PSCmdlet.ShouldProcess($OutCsv, "Append baseline row (Phase=$Phase)")) {
    $exists = Test-Path $OutCsv
    if ($exists) { $row | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8 -Append }
    else         { $row | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8 }
    Write-Host ("`nAppended {0} row to: {1}" -f $Phase, (Resolve-Path $OutCsv))

    # If both phases now present for this device, print the reduction.
    try {
        $all = Import-Csv -Path $OutCsv | Where-Object { $_.Device -eq $env:COMPUTERNAME }
        $b = ($all | Where-Object Phase -eq 'Before' | Select-Object -Last 1)
        $a = ($all | Where-Object Phase -eq 'After'  | Select-Object -Last 1)
        if ($b -and $a -and $b.LogonTotalSeconds -and $a.LogonTotalSeconds) {
            $delta = [double]$b.LogonTotalSeconds - [double]$a.LogonTotalSeconds
            $pct = if ([double]$b.LogonTotalSeconds -gt 0) { [math]::Round($delta / [double]$b.LogonTotalSeconds * 100,1) } else { 0 }
            Write-Host ("Before/After logon : {0}s -> {1}s  ({2}s, {3}% reduction)" -f $b.LogonTotalSeconds, $a.LogonTotalSeconds, $delta, $pct)
        }
    } catch { }
} else {
    Write-Host ("`n[WhatIf] Would append {0} row to: {1}" -f $Phase, $OutCsv)
}
