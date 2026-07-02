<#
.SYNOPSIS
    SCCMTS-Validation.ps1 — validate the task-sequence deployment state for a device or collection.
.DESCRIPTION
    PURPOSE
        Read-only check of where a task-sequence deployment currently stands. For a device it reports
        the last deployment/execution status; for a collection it summarizes Success / In Progress /
        Error / Failed counts. Use after a fix + re-run to confirm success (status 11127 / exit 0).
    HOW TO RUN
        From a ConfigurationManager PowerShell session (site drive PS XYZ:\>):
          .\SCCMTS-Validation.ps1 -SiteCode ABC -SmsProvider cm01.contoso.com -DeviceName PC123
          .\SCCMTS-Validation.ps1 -SiteCode ABC -SmsProvider cm01.contoso.com -CollectionName "OSD - Pilot"
        Requires the ConfigurationManager module and RBAC read on deployments/status messages.
    EXPECTED RESULTS
        "DEPLOYMENT SUCCEEDED" (exit 0) when the device's latest result is success (11127),
        or a collection status breakdown; "NOT SUCCEEDED" (exit 1) if a failure is still present.
.NOTES
    White-label — Infrastructure Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SiteCode,
    [Parameter(Mandatory)][string]$SmsProvider,
    [string]$DeviceName,
    [string]$CollectionName
)

$ns = "root\SMS\site_$SiteCode"
Write-Host "=== TS deployment validation ($SiteCode) ===" -ForegroundColor Cyan

if ($DeviceName) {
    # Latest task-sequence execution message for the device: 11127 = success, 11124/11170 = failure.
    $filter = "MachineName='$DeviceName' AND (MessageID=11127 OR MessageID=11124 OR MessageID=11170)"
    $latest = Get-CimInstance -Namespace $ns -ComputerName $SmsProvider -ClassName SMS_StatusMessage `
        -Filter $filter -ErrorAction SilentlyContinue |
        Sort-Object Time -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-Host "No task-sequence execution messages for $DeviceName." -ForegroundColor Yellow
        exit 1
    }
    Write-Host ("Device   : {0}" -f $DeviceName)
    Write-Host ("Latest   : MessageID {0} at {1}" -f $latest.MessageID, $latest.Time)
    if ($latest.MessageID -eq 11127) {
        Write-Host "`nResult: DEPLOYMENT SUCCEEDED (11127)" -ForegroundColor Green; exit 0
    } else {
        Write-Host "`nResult: NOT SUCCEEDED — latest message is a failure ($($latest.MessageID)). Run the runbook." -ForegroundColor Yellow; exit 1
    }
}
elseif ($CollectionName) {
    if (-not (Get-Module ConfigurationManager)) {
        Import-Module "$($env:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction Stop
    }
    if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SmsProvider -ErrorAction Stop | Out-Null
    }
    Push-Location "$($SiteCode):"
    $dep = Get-CMTaskSequenceDeployment | Where-Object { $_.CollectionName -eq $CollectionName } | Select-Object -First 1
    Pop-Location
    if (-not $dep) { Write-Host "No TS deployment found on collection '$CollectionName'." -ForegroundColor Yellow; exit 1 }

    # Summarize per-device state from deployment status summary.
    $summ = Get-CimInstance -Namespace $ns -ComputerName $SmsProvider `
        -ClassName SMS_DeploymentSummary -Filter "CollectionID='$($dep.CollectionID)'" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($summ) {
        Write-Host ("Collection : {0}" -f $CollectionName)
        Write-Host ("Success    : {0}" -f $summ.NumberSuccess)
        Write-Host ("In Progress: {0}" -f $summ.NumberInProgress)
        Write-Host ("Errors     : {0}" -f $summ.NumberErrors)
        Write-Host ("Other      : {0}" -f $summ.NumberOther)
        if ($summ.NumberErrors -gt 0) { Write-Host "`nResult: FAILURES PRESENT — run the runbook on the error devices." -ForegroundColor Yellow; exit 1 }
        else { Write-Host "`nResult: NO FAILURES on this collection." -ForegroundColor Green; exit 0 }
    } else {
        Write-Host "No deployment summary available for collection $($dep.CollectionID)." -ForegroundColor Yellow; exit 1
    }
}
else {
    Write-Host "Provide -DeviceName or -CollectionName." -ForegroundColor Yellow; exit 1
}
