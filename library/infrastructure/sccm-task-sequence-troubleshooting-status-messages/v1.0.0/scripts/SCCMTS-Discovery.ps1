<#
.SYNOPSIS
    SCCMTS-Discovery.ps1 — discover task sequences, their deployments, recent deployment states,
    and task-sequence execution status messages.
.DESCRIPTION
    PURPOSE
        Read-only triage inventory: lists task sequences and their deployments (Get-CM* cmdlets),
        the most recent per-device deployment states for a task sequence, and the task-sequence
        engine status messages (IDs 11123/11124/11127/11170/11171) from the SMS provider via CIM.
        This is Step 1-2 of the runbook — see where the failure is and pull the failing message.
    HOW TO RUN
        From a ConfigurationManager PowerShell session (site drive PS XYZ:\>):
          .\SCCMTS-Discovery.ps1 -SiteCode ABC -SmsProvider cm01.contoso.com
          .\SCCMTS-Discovery.ps1 -SiteCode ABC -SmsProvider cm01.contoso.com -DeviceName PC123 -Hours 24
        Requires the ConfigurationManager module (console) and RBAC read on TS/deployments/messages.
    EXPECTED RESULTS
        A list of task sequences + deployments, and (if -DeviceName given) the recent 11124/11170
        failure messages for that device, newest first, with the exit/error code text.
.NOTES
    Phoenixtekk Workplace Marketplace — Infrastructure Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SiteCode,
    [Parameter(Mandatory)][string]$SmsProvider,
    [string]$DeviceName,
    [int]$Hours = 24
)

# Import the ConfigurationManager module if not already loaded, then use the site drive.
if (-not (Get-Module ConfigurationManager)) {
    Import-Module "$($env:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction Stop
}
if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SmsProvider -ErrorAction Stop | Out-Null
}
Push-Location "$($SiteCode):"

Write-Host "`n=== Task sequences ===" -ForegroundColor Cyan
Get-CMTaskSequence -Fast | Select-Object Name, PackageID, LastRefreshTime | Format-Table -AutoSize

Write-Host "=== Task-sequence deployments ===" -ForegroundColor Cyan
Get-CMTaskSequenceDeployment |
    Select-Object ApplicationName, PackageID, CollectionName, CollectionID |
    Format-Table -AutoSize

Pop-Location

# Task-sequence execution status messages via the SMS provider (CIM).
$ns = "root\SMS\site_$SiteCode"
$since = (Get-Date).AddHours(-$Hours)
$filter = "MessageID=11124 OR MessageID=11170"
if ($DeviceName) { $filter = "($filter) AND MachineName='$DeviceName'" }

Write-Host "=== Task-sequence FAILURE messages (last $Hours h) ===" -ForegroundColor Cyan
try {
    $msgs = Get-CimInstance -Namespace $ns -ComputerName $SmsProvider -ClassName SMS_StatusMessage `
        -Filter $filter -ErrorAction Stop |
        Where-Object { $_.Time -ge $since } |
        Sort-Object Time -Descending | Select-Object -First 50
    if ($msgs) {
        $msgs | Select-Object MachineName, Time, MessageID, SiteCode, Component | Format-Table -AutoSize
        Write-Host ("Failure messages found: {0}" -f $msgs.Count) -ForegroundColor Yellow
    } else {
        Write-Host "No 11124/11170 failure messages in the window (widen -Hours or check the device name)." -ForegroundColor Green
    }
} catch {
    Write-Host "Status message query failed: $($_.Exception.Message)" -ForegroundColor Yellow
}
