<#
.SYNOPSIS
    APPUNIN-LogParser.ps1 — parse the Intune Management Extension logs for a Win32 app's uninstall sequence.
.DESCRIPTION
    PURPOSE
        Runs LOCALLY on the device. Reads the IME logs and extracts, for the target app,
        the uninstall pipeline in order: the intent the IME resolved (watch for Required
        beating Uninstall -> Branch A), the pre-uninstall detection result, the uninstall
        command line that ran, the returned EXIT CODE, and the post-uninstall detection
        result. This is the definitive evidence for which branch you are in; Graph reports
        the state, these logs report the reason.
    HOW TO RUN
          powershell -ExecutionPolicy Bypass -File .\APPUNIN-LogParser.ps1 -AppNameLike "Contoso LOB"
        Optional:
          -LogPath  'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'  (default)
          -AppId    '<application GUID>'   (match by id instead of/as well as name)
          -OutFile  'C:\ProgramData\APPUNIN\Evidence\log-extract.txt'
        No Microsoft Graph and no external modules are required.
    EXPECTED RESULTS
        The matched log lines (with timestamps and highlighted exit codes) in pipeline
        order, and a one-line verdict pointing at the likely branch. Pass = intent
        Uninstall -> detection detected -> command -> exit 0 -> detection notDetected.
        Fail = the sequence breaks (e.g. exit 1605 -> Branch D; detection detected after
        exit 0 -> Branch C; no command after 'not detected' -> Branch B).
.NOTES
    Intune Solutions — read-only, local. The repeatable way. Reads log files only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $AppNameLike,
    [string] $AppId,
    [string] $LogPath = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs',
    [string] $OutFile
)

$ErrorActionPreference = 'Stop'

$logNames = 'IntuneManagementExtension.log','AppWorkload.log','AgentExecutor.log'
$files = foreach ($n in $logNames) {
    Get-ChildItem -Path $LogPath -Filter ($n -replace '\.log$','*') -ErrorAction SilentlyContinue
}
$files = $files | Sort-Object LastWriteTime
if (-not $files) { throw "No IME logs found under $LogPath. Confirm the Intune Management Extension is installed (R5)." }

# Keywords that indicate the uninstall pipeline stages / exit codes.
$stageRegex = 'uninstall|Uninstall|EnforceUninstall|detection|Detection|Applicability|intent|Intent|Required|ExitCode|exit code|return code|MSI.*\d{3,5}|1603|1605|1614|1618|1639|1641|3010'

$matches = foreach ($f in $files) {
    $ln = 0
    foreach ($line in [System.IO.File]::ReadLines($f.FullName)) {
        $ln++
        $hit = ($line -like "*$AppNameLike*") -or ($AppId -and $line -like "*$AppId*")
        # Also keep pipeline-stage lines near the app context (heuristic: any stage keyword).
        if ($hit -and ($line -match $stageRegex)) {
            [pscustomobject]@{ File = $f.Name; Line = $ln; Text = $line.Trim() }
        }
    }
}

if (-not $matches) {
    Write-Host "No matching uninstall pipeline lines for '*$AppNameLike*'. Try -AppId <GUID>, or the app never reached this device (Branch A/I)." -ForegroundColor Yellow
    return
}

$matches | ForEach-Object {
    $color = 'Gray'
    if ($_.Text -match '1605')                 { $color = 'Red'    }   # wrong ProductCode
    elseif ($_.Text -match '1603|1639')        { $color = 'Red'    }   # fatal / bad command
    elseif ($_.Text -match '1618')             { $color = 'Yellow' }   # installer busy (retry)
    elseif ($_.Text -match '3010|1641')        { $color = 'Cyan'   }   # reboot codes (success)
    elseif ($_.Text -match 'exit code 0|ExitCode:0|return code 0') { $color = 'Green' }
    elseif ($_.Text -match 'Required')         { $color = 'Magenta'}   # possible intent conflict
    Write-Host ("[{0}:{1}] {2}" -f $_.File, $_.Line, $_.Text) -ForegroundColor $color
}

# Simple verdict heuristic.
$text = ($matches.Text -join "`n")
Write-Host "`n--- Verdict ---" -ForegroundColor Cyan
if     ($text -match '1605')                       { Write-Host "Exit 1605 seen -> wrong/stale MSI ProductCode. Go to Branch D." -ForegroundColor Red }
elseif ($text -match '1618')                       { Write-Host "Exit 1618 seen -> Windows Installer busy. Map as Retry. Go to Branch G." -ForegroundColor Yellow }
elseif ($text -match '1603|1639')                  { Write-Host "Exit 1603/1639 seen -> wrong uninstall command/switches or fatal MSI. Go to Branch E." -ForegroundColor Red }
elseif ($text -match 'Required')                   { Write-Host "Intent resolved to Required where Uninstall was expected -> intent conflict. Go to Branch A." -ForegroundColor Magenta }
elseif ($text -match 'exit code 0|return code 0')  { Write-Host "Uninstall exited 0. If Intune still shows failed, post-detection is matching a remnant -> Branch C. If the app is still present, pre-detection skipped removal -> Branch B." -ForegroundColor Yellow }
else   { Write-Host "No decisive exit code found; read the lines above in order and match against the playbook." -ForegroundColor Gray }

if ($OutFile) {
    $dir = Split-Path -Parent $OutFile
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $matches | ForEach-Object { "[{0}:{1}] {2}" -f $_.File, $_.Line, $_.Text } | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "`nSaved extract to $OutFile" -ForegroundColor Green
}
