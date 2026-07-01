<#
.SYNOPSIS
    COMGMT-Discovery.ps1 — Co-management readiness discovery (READ-ONLY).

PURPOSE
    Reports whether a Windows device is ready for Configuration Manager + Intune
    co-management: Configuration Manager client presence/health, OS build, and
    Microsoft Entra join state. Makes no changes.

HOW TO RUN
    Run locally on a candidate device in an elevated PowerShell session:
        .\COMGMT-Discovery.ps1
    Optionally write a CSV summary:
        .\COMGMT-Discovery.ps1 -OutputCsv .\comgmt-readiness.csv

EXPECTED RESULTS
    A readiness summary: ConfigMgr client installed/active, supported OS build,
    AzureAdJoined / DomainJoined state, and an overall Ready = True/False flag.
    Read-only — safe to run anytime.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv
)

$ErrorActionPreference = 'SilentlyContinue'

function Get-EntraJoinState {
    $raw = & dsregcmd /status 2>$null
    [pscustomobject]@{
        AzureAdJoined = [bool]($raw | Select-String -Pattern 'AzureAdJoined\s*:\s*YES')
        DomainJoined  = [bool]($raw | Select-String -Pattern 'DomainJoined\s*:\s*YES')
        MdmUrlPresent = [bool]($raw | Select-String -Pattern 'MdmUrl\s*:\s*http')
    }
}

$os = Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion

$ccmService = Get-Service -Name 'CcmExec' -ErrorAction SilentlyContinue
$ccmInstalled = $null -ne $ccmService
$ccmRunning = $ccmInstalled -and $ccmService.Status -eq 'Running'

$entra = Get-EntraJoinState

# A supported build is Windows 10/11 with a modern build number.
$buildNum = 0
[int]::TryParse($os.OsBuildNumber, [ref]$buildNum) | Out-Null
$supportedOs = $buildNum -ge 19044   # Windows 10 21H2 baseline or later

$ready = $ccmRunning -and $supportedOs -and $entra.AzureAdJoined

$result = [pscustomobject]@{
    ComputerName        = $env:COMPUTERNAME
    OS                  = $os.WindowsProductName
    OsBuild             = $os.OsBuildNumber
    OsVersion           = $os.WindowsVersion
    SupportedOs         = $supportedOs
    ConfigMgrClient     = $ccmInstalled
    ConfigMgrRunning    = $ccmRunning
    AzureAdJoined       = $entra.AzureAdJoined
    DomainJoined        = $entra.DomainJoined
    MdmUrlPresent       = $entra.MdmUrlPresent
    Ready               = $ready
}

$result | Format-List

if ($OutputCsv) {
    $result | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Saved readiness summary to $OutputCsv"
}

if (-not $ready) {
    Write-Warning 'Device is NOT ready for co-management. Address the False fields above (see Requirements Guide 2.1, 2.2, 2.4, 2.7).'
}
