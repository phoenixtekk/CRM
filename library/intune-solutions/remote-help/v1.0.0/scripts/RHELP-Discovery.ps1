<#
.SYNOPSIS
    RHELP-Discovery.ps1 — Remote Help readiness check on the device.
.DESCRIPTION
    PURPOSE
        Reports OS support, whether the Remote Help app is installed, and reachability to sign-in,
        so you can confirm a device is ready to give/receive Remote Help.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELP-Discovery.ps1
    EXPECTED RESULTS
        PASS/FAIL per facet and a readiness verdict.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
function R($n,$p,$d){ [pscustomobject]@{Check=$n;Result=if($p){'PASS'}else{'FAIL'};Detail=$d} }
$res = New-Object System.Collections.Generic.List[object]
$os = Get-CimInstance Win32_OperatingSystem
$res.Add( (R 'OS supported (Win10/11)' ([version]$os.Version -ge [version]'10.0.19044') "$($os.Caption) $($os.Version)") )
$paths = @("$env:ProgramFiles\Remote help\remotehelp.exe", "${env:ProgramFiles(x86)}\Remote help\remotehelp.exe")
$app = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
$ver = if ($app) { (Get-Item $app).VersionInfo.ProductVersion } else { $null }
$res.Add( (R 'Remote Help app installed' ([bool]$app) ($(if($app){"v$ver"}else{'not found'}))) )
$net = Test-NetConnection -ComputerName login.microsoftonline.com -Port 443 -WarningAction SilentlyContinue
$res.Add( (R 'Reaches Entra sign-in (443)' ($net.TcpTestSucceeded) "$($net.RemoteAddress)") )
$dsreg = (dsregcmd /status) 2>$null
$res.Add( (R 'Entra joined' (($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null) '') )
Write-Host "`n=== Remote Help Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$blk = $res | Where-Object { $_.Result -eq 'FAIL' -and $_.Check -notmatch 'app installed' }
Write-Host ("Overall: {0}" -f ($(if($blk){'NOT READY'}else{'READY' + $(if(-not $app){' (deploy the Remote Help app)'}else{''})}))) -ForegroundColor ($(if($blk){'Yellow'}else{'Green'}))
