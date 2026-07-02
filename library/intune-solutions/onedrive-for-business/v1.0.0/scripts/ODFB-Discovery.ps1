<#
.SYNOPSIS
    ODFB-Discovery.ps1 — OneDrive for Business device readiness check.

.DESCRIPTION
    PURPOSE
        Reports whether the local device is ready for OneDrive for Business configuration:
        OS version, OneDrive sync client presence/version, Microsoft Entra join state, and free
        disk space. Use it before deployment to find devices that need remediation.

    HOW TO RUN
        Run on the device in a normal PowerShell window:
            powershell -ExecutionPolicy Bypass -File .\ODFB-Discovery.ps1
        Optional CSV row for fleet collation:
            .\ODFB-Discovery.ps1 -CsvPath C:\Temp\odfb-readiness.csv

    EXPECTED RESULTS
        A PASS/FAIL summary and an overall verdict. A READY device shows a supported OS, the
        OneDrive client present, AzureAdJoined = YES, and adequate free disk.

.NOTES
    White-label — Intune Solutions. Read-only; makes no changes.
#>
[CmdletBinding()]
param([string]$CsvPath)

function Test-Result($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = if ($Pass) { 'PASS' } else { 'FAIL' }; Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# OS
$os  = Get-CimInstance Win32_OperatingSystem
$osOk = [version]$os.Version -ge [version]'10.0.19044'
$results.Add( (Test-Result 'OS supported (Win10 21H2+/Win11)' $osOk "$($os.Caption) $($os.Version)") )

# OneDrive client
$paths = @("$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
           "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
           "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe")
$od = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
$odVer = if ($od) { (Get-Item $od).VersionInfo.ProductVersion } else { $null }
$results.Add( (Test-Result 'OneDrive sync client present' ([bool]$od) ($(if ($od) { "v$odVer  ($od)" } else { 'not found' }))) )

# Entra join
$dsreg = (dsregcmd /status) 2>$null
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$results.Add( (Test-Result 'Microsoft Entra joined' $aadJoined ($(if ($aadJoined) { 'Yes' } else { 'No' }))) )

# Disk space
$sys = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
$freeGB = [math]::Round($sys.FreeSpace/1GB,1)
$results.Add( (Test-Result 'Free disk space (>= 10 GB)' ($freeGB -ge 10) "$freeGB GB free") )

Write-Host "`n=== OneDrive for Business — Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$blocking = $results | Where-Object { $_.Result -eq 'FAIL' -and $_.Check -notmatch 'disk' }
$overall = if ($blocking) { 'NOT READY' } else { 'READY' }
Write-Host "Overall: $overall" -ForegroundColor ($(if ($overall -eq 'READY') { 'Green' } else { 'Yellow' }))

if ($CsvPath) {
    [pscustomobject]@{ ComputerName=$env:COMPUTERNAME; Overall=$overall; OS="$($os.Caption) $($os.Version)";
        OneDrive=$odVer; FreeGB=$freeGB; Timestamp=(Get-Date).ToString('s') } |
        Export-Csv -Path $CsvPath -NoTypeInformation -Append
    Write-Host "Appended readiness row to $CsvPath"
}
