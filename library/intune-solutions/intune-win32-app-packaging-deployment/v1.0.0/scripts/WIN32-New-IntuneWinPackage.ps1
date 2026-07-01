<#
.SYNOPSIS
    WIN32-New-IntuneWinPackage.ps1 — wrap an app source folder into a .intunewin package.
.DESCRIPTION
    PURPOSE
        Builds an Intune Win32 .intunewin package from a source folder and a setup file using the
        Microsoft Win32 Content Prep Tool (IntuneWinAppUtil.exe). This script does NOT embed the tool;
        download it from Microsoft's official repository:
            https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool  (Releases)
        Place IntuneWinAppUtil.exe in a known folder (default: C:\Tools\IntuneWinAppUtil) or pass
        its path with -ContentPrepTool.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIN32-New-IntuneWinPackage.ps1 `
            -SourceFolder C:\Packaging\ContosoLOB -SetupFile ContosoLOB.msi `
            -OutputFolder C:\Packaging\Output
    EXPECTED RESULTS
        A single .intunewin file (e.g. ContosoLOB.intunewin) in the output folder, ready to upload
        in Intune (Apps > Windows > Add > Windows app (Win32)).
.NOTES
    Workplace Marketplace — Intune Solutions. Packaging helper; does not change Intune state.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SourceFolder,
    [Parameter(Mandatory)] [string]$SetupFile,
    [Parameter(Mandatory)] [string]$OutputFolder,
    [string]$ContentPrepTool = 'C:\Tools\IntuneWinAppUtil\IntuneWinAppUtil.exe'
)

Write-Host "=== Win32 Content Prep — package builder ===" -ForegroundColor Cyan

if (-not (Test-Path $SourceFolder))                 { throw "Source folder not found: $SourceFolder" }
if (-not (Test-Path (Join-Path $SourceFolder $SetupFile))) { throw "Setup file not found in source: $SetupFile" }
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }

if (-not (Test-Path $ContentPrepTool)) {
    Write-Host "  IntuneWinAppUtil.exe not found at: $ContentPrepTool" -ForegroundColor Yellow
    Write-Host "  Download it from Microsoft: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool" -ForegroundColor Yellow
    $ContentPrepTool = Read-Host "Enter the full path to IntuneWinAppUtil.exe"
    if (-not (Test-Path $ContentPrepTool)) { throw "Content Prep Tool not found. Obtain it from Microsoft and retry." }
}

Write-Host ("  Source : {0}" -f $SourceFolder)
Write-Host ("  Setup  : {0}" -f $SetupFile)
Write-Host ("  Output : {0}" -f $OutputFolder)

& $ContentPrepTool -c $SourceFolder -s $SetupFile -o $OutputFolder -q
if ($LASTEXITCODE -ne 0) { throw "IntuneWinAppUtil.exe returned exit code $LASTEXITCODE." }

$pkg = Get-ChildItem -Path $OutputFolder -Filter *.intunewin -Recurse |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($pkg) { Write-Host ("  Created: {0}" -f $pkg.FullName) -ForegroundColor Green }
else      { Write-Host "  WARNING: no .intunewin found in output." -ForegroundColor Yellow }

Write-Host "`nUpload this .intunewin in Intune: Apps > Windows > Add > Windows app (Win32)." -ForegroundColor Green
