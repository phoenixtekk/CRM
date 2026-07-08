<#
.SYNOPSIS
    OPSREPORT-Configuration.ps1 — provision export storage, the Power BI workspace, and the scheduled refresh. -WhatIf by default.
.DESCRIPTION
    PURPOSE
        The only write-path in the framework, and it is gated. -CreateStorage provisions the dated export
        set folder Purview Exports - <yyyyMM> - Report under a secured path; -CreateWorkspace creates a
        Power BI workspace (New-PowerBIWorkspace via MicrosoftPowerBIMgmt); -ScheduleRefresh registers a
        local scheduled task Purview Refresh - Daily - Recurring that re-runs OPSREPORT-Report.ps1 to
        refresh the export set. SAFE BY DEFAULT: every action runs in -WhatIf and prints the exact planned
        change; -Commit is required to apply. It never reads or writes Purview/Graph data itself.
    HOW TO RUN
        # Export storage (dry-run then commit):
        .\OPSREPORT-Configuration.ps1 -CreateStorage -StoragePath 'D:\PurviewExports' -WhatIf
        .\OPSREPORT-Configuration.ps1 -CreateStorage -StoragePath 'D:\PurviewExports' -Commit
        # Power BI workspace (needs MicrosoftPowerBIMgmt + Connect-PowerBIServiceAccount):
        .\OPSREPORT-Configuration.ps1 -CreateWorkspace -WorkspaceName 'Purview Reporting - Pilot - Stage1' -Commit
        # Daily refresh task that runs OPSREPORT-Report.ps1:
        .\OPSREPORT-Configuration.ps1 -ScheduleRefresh -Cadence Daily -StoragePath 'D:\PurviewExports' -ReportScript '.\OPSREPORT-Report.ps1' -Commit
    EXPECTED RESULTS
        -WhatIf: the planned folder / workspace / scheduled-task is printed; nothing created. -Commit: the
        dated export folder exists, and/or the workspace is created, and/or the scheduled task is
        registered. Rollback: delete the folder/workspace or Unregister-ScheduledTask (all additive).
.NOTES
    Purview — Reporting & Power BI Framework. -WhatIf by default. Power BI workspace creation uses
    MicrosoftPowerBIMgmt; if absent, create the workspace in the Power BI service and skip -CreateWorkspace.
    The scheduled task runs under the account you register it with — grant least privilege. No secrets in
    code. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [switch]$CreateStorage,
    [switch]$CreateWorkspace,
    [switch]$ScheduleRefresh,

    [string]$StoragePath,
    [string]$WorkspaceName = 'Purview Reporting - Pilot - Stage1',
    [ValidateSet('Daily','Weekly')][string]$Cadence = 'Daily',
    [string]$RunAt = '05:00',
    [string]$ReportScript = '.\OPSREPORT-Report.ps1',
    [string]$TaskName = 'Purview Refresh - Daily - Recurring',

    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
$WhatIf = -not $Commit
Write-Host ("=== OPSREPORT Configuration [{0}] ===" -f ($(if ($WhatIf) { 'DRY-RUN (-WhatIf)' } else { 'COMMIT' }))) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

if (-not ($CreateStorage -or $CreateWorkspace -or $ScheduleRefresh)) {
    Write-Host 'No action specified. Provide -CreateStorage, -CreateWorkspace, and/or -ScheduleRefresh.' -ForegroundColor Yellow
    return
}

# ---- Export storage --------------------------------------------------------------------------------
if ($CreateStorage) {
    if (-not $StoragePath) { throw '-CreateStorage requires -StoragePath (a secured local path or mapped library).' }
    $stamp  = (Get-Date).ToString('yyyyMM')
    $setDir = Join-Path $StoragePath ("Purview Exports - {0} - Report" -f $stamp)
    Write-Host ("--- Export storage: {0} ---" -f $setDir) -ForegroundColor Cyan
    if (Test-Path $setDir) { Write-Host '  Export set folder already exists (kept).' -ForegroundColor DarkGray }
    elseif ($WhatIf)       { Write-Host '  WHATIF: would create the dated export-set folder under least-privilege access.' -ForegroundColor DarkYellow }
    else {
        New-Item -ItemType Directory -Path $setDir -Force | Out-Null
        Write-Host ("  Created: {0}" -f $setDir) -ForegroundColor Green
        Write-Host '  Restrict access to the reporting identity + least-privilege readers (Requirement 2.4).' -ForegroundColor Yellow
    }
}

# ---- Power BI workspace ----------------------------------------------------------------------------
if ($CreateWorkspace) {
    Write-Host ("--- Power BI workspace: {0} ---" -f $WorkspaceName) -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
        Write-Host '  MicrosoftPowerBIMgmt not installed. Install-Module MicrosoftPowerBIMgmt, or create the workspace in the Power BI service and skip -CreateWorkspace.' -ForegroundColor Yellow
    } else {
        if ($WhatIf) {
            Write-Host ("  WHATIF: would run New-PowerBIWorkspace -Name '{0}' (after Connect-PowerBIServiceAccount)." -f $WorkspaceName) -ForegroundColor DarkYellow
        } else {
            try {
                if (-not (Get-PowerBIAccessToken -ErrorAction SilentlyContinue)) { Connect-PowerBIServiceAccount | Out-Null }
                $existing = Get-PowerBIWorkspace -Name $WorkspaceName -ErrorAction SilentlyContinue
                if ($existing) { Write-Host '  Workspace already exists (kept).' -ForegroundColor DarkGray }
                else { New-PowerBIWorkspace -Name $WorkspaceName | Out-Null; Write-Host ("  Created workspace '{0}'." -f $WorkspaceName) -ForegroundColor Green }
                Write-Host '  Assign least-privilege roles: Viewer for the leadership audience; Member/Admin only for report authors.' -ForegroundColor Yellow
            } catch { Write-Warning ("  Workspace creation failed: {0}" -f $_.Exception.Message) }
        }
    }
}

# ---- Scheduled refresh -----------------------------------------------------------------------------
if ($ScheduleRefresh) {
    Write-Host ("--- Scheduled refresh: {0} ({1} at {2}) ---" -f $TaskName, $Cadence, $RunAt) -ForegroundColor Cyan
    $scriptFull = (Resolve-Path $ReportScript -ErrorAction SilentlyContinue)
    if (-not $scriptFull) { Write-Host ("  Report script not found: {0} — provide -ReportScript path." -f $ReportScript) -ForegroundColor Yellow }
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File', ("`"{0}`"" -f ($scriptFull.Path)))
    if ($StoragePath) { $args += @('-StoragePath', ("`"{0}`"" -f $StoragePath)) }
    Write-Host ("  Action: powershell.exe {0}" -f ($args -join ' ')) -ForegroundColor DarkGray

    if ($WhatIf) {
        Write-Host ("  WHATIF: would Register-ScheduledTask '{0}' ({1} {2}) running the report script to refresh the export set." -f $TaskName, $Cadence, $RunAt) -ForegroundColor DarkYellow
    } elseif (-not (Get-Command Register-ScheduledTask -ErrorAction SilentlyContinue)) {
        Write-Host '  ScheduledTasks module unavailable on this host — schedule the export via your platform scheduler instead.' -ForegroundColor Yellow
    } else {
        try {
            $action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ($args -join ' ')
            $trigger = if ($Cadence -eq 'Weekly') { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $RunAt } else { New-ScheduledTaskTrigger -Daily -At $RunAt }
            if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
                Write-Host '  Scheduled task already exists (kept). Update it deliberately if the schedule changed.' -ForegroundColor DarkGray
            } else {
                Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description 'Refresh the Purview reporting export set (OPSREPORT-Report.ps1).' | Out-Null
                Write-Host ("  Registered scheduled task '{0}'. The Power BI service then refreshes the dataset from the export set." -f $TaskName) -ForegroundColor Green
            }
        } catch { Write-Warning ("  Could not register scheduled task: {0}" -f $_.Exception.Message) }
    }
}

Write-Host ("=== Configuration complete [{0}] ===" -f ($(if ($WhatIf) { 'DRY-RUN' } else { 'COMMIT' }))) -ForegroundColor Cyan
if ($WhatIf) { Write-Host 'Re-run with -Commit to apply. Nothing was changed. Rollback is additive: delete the folder/workspace or Unregister-ScheduledTask.' -ForegroundColor Yellow }
