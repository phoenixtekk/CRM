<#
.SYNOPSIS
    Autopilot-Discovery.ps1 — Windows Autopilot device readiness check.
.DESCRIPTION
    PURPOSE
        Reports whether a device is ready for Autopilot: OS version, TPM, network reachability to
        Microsoft endpoints, and current Entra/MDM join state.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\Autopilot-Discovery.ps1
    EXPECTED RESULTS
        PASS/FAIL summary and an overall verdict. READY = supported OS, TPM present, endpoints reachable.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
function R($n,$p,$d){ [pscustomobject]@{Check=$n;Result=if($p){'PASS'}else{'FAIL'};Detail=$d} }
$res = New-Object System.Collections.Generic.List[object]
$os = Get-CimInstance Win32_OperatingSystem
$res.Add( (R 'OS supported (Win10 1809+/Win11)' ([version]$os.Version -ge [version]'10.0.17763') "$($os.Caption) $($os.Version)") )
try { $tpm = Get-Tpm; $res.Add( (R 'TPM present' ($tpm.TpmPresent) "Present=$($tpm.TpmPresent)") ) } catch { $res.Add((R 'TPM present' $false 'Get-Tpm failed')) }
$net = Test-NetConnection -ComputerName login.microsoftonline.com -Port 443 -WarningAction SilentlyContinue
$res.Add( (R 'Reaches login.microsoftonline.com:443' ($net.TcpTestSucceeded) "$($net.RemoteAddress)") )
$dsreg = (dsregcmd /status) 2>$null
$res.Add( (R 'Entra/MDM state' $true (($dsreg | Select-String 'AzureAdJoined|MdmUrl' | ForEach-Object { $_.Line.Trim() }) -join '; ')) )
Write-Host "`n=== Autopilot Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$overall = if ($res | Where-Object { $_.Result -eq 'FAIL' -and $_.Check -notmatch 'state' }) { 'NOT READY' } else { 'READY' }
Write-Host "Overall: $overall" -ForegroundColor ($(if($overall -eq 'READY'){'Green'}else{'Yellow'}))
