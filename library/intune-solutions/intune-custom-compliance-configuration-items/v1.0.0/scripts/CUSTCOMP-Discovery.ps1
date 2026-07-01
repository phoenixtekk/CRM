<#
.SYNOPSIS
    CUSTCOMP-Discovery.ps1 — read the device-side values a custom-compliance detection script checks.
.DESCRIPTION
    PURPOSE
        Reports the OS build and the sample device-side values a custom-compliance detection script
        would read (a registry hardening value and an installed app version), returned as the same
        compact JSON a detection script emits — so you can confirm what Intune will evaluate.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\CUSTCOMP-Discovery.ps1
        Optional: -RegPath / -RegName / -AppName to target your own value.
    EXPECTED RESULTS
        OS build, the discovered values, and a single-line JSON object mirroring the detection script.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param(
    [string]$RegPath = 'HKLM:\SOFTWARE\Contoso\Security',
    [string]$RegName = 'HardeningLevel',
    [string]$AppName = 'Contoso Agent'
)
Write-Host "`n=== Custom Compliance — device posture ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS               : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)
Write-Host ("64-bit PowerShell: {0}" -f ([Environment]::Is64BitProcess))
$reg = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue).$RegName
$app = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq $AppName } | Select-Object -First 1).DisplayVersion
Write-Host ("Registry value   : {0}\{1} = {2}" -f $RegPath, $RegName, ($(if($null -ne $reg){$reg}else{'not set'})))
Write-Host ("App version      : {0} = {1}" -f $AppName, ($(if($app){$app}else{'not installed'})))
$out = @{
    HardeningLevel = $(if ($null -ne $reg) { [int]$reg } else { 0 })
    AgentVersion   = [string]$app
}
Write-Host "`nDetection-script JSON (what Intune evaluates):" -ForegroundColor Cyan
$out | ConvertTo-Json -Compress
