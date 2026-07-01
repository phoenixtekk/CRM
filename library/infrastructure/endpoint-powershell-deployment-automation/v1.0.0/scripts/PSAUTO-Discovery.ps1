<#
.SYNOPSIS
    PSAUTO-Discovery.ps1 — endpoint automation readiness check.
.DESCRIPTION
    PURPOSE
        Reports whether this admin workstation / device is ready to build and run the toolkit:
        the Microsoft Graph PowerShell SDK, execution policy, 64-bit host, OS build, and whether the
        Intune Management Extension (which runs remediations) is present on the device.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\PSAUTO-Discovery.ps1
    EXPECTED RESULTS
        A readiness summary: Graph SDK present, execution policy, 64-bit confirmed, OS build, and an
        Intune Management Extension status line. Warnings (yellow) flag anything to fix first.
.NOTES
    Endpoint automation toolkit — the repeatable way. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== Endpoint automation readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# OS build
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS                 : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)

# 64-bit host
$is64 = [Environment]::Is64BitProcess
Write-Host ("64-bit PowerShell  : {0}" -f ($(if($is64){'YES'}else{'NO (run 64-bit; set remediation to 64-bit)'}))) -ForegroundColor ($(if($is64){'Green'}else{'Yellow'}))

# execution policy
$ep = Get-ExecutionPolicy
Write-Host ("Execution policy   : {0}" -f $ep) -ForegroundColor ($(if($ep -eq 'AllSigned'){'Yellow'}else{'Green'}))
if ($ep -eq 'AllSigned') { Write-Host "  Note: AllSigned requires signed scripts — sign the .ps1 files or adjust the remediation signature check." -ForegroundColor Yellow }

# Graph SDK
$graph = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication
Write-Host ("Graph SDK present  : {0}" -f ($(if($graph){'YES'}else{'NO (Install-Module Microsoft.Graph)'}))) -ForegroundColor ($(if($graph){'Green'}else{'Yellow'}))

# Intune Management Extension (runs remediations on devices)
$ime = Get-Service -Name 'IntuneManagementExtension' -ErrorAction SilentlyContinue
if ($ime) { Write-Host ("Intune Mgmt Ext.   : {0} ({1})" -f $ime.Status, 'remediations can run on this device') -ForegroundColor Green }
else { Write-Host "Intune Mgmt Ext.   : not found (remediations run only on Intune-enrolled devices)" -ForegroundColor Yellow }

Write-Host "`nReview any yellow lines before building remediations." -ForegroundColor Cyan
