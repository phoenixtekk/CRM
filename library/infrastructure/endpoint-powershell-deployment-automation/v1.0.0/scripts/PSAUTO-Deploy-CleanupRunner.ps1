<#
.SYNOPSIS
    PSAUTO-Deploy-CleanupRunner.ps1 — software deploy / remove / post-failure cleanup runner. Safe by default.
.DESCRIPTION
    PURPOSE
        Runs a parameterized deployment or cleanup action on a device: install or uninstall an app
        (via its installer or product code) and remove leftover folders/files after a failed install.
        SAFE BY DEFAULT: runs in -WhatIf mode and only reports the actions it would take. Re-run with
        -WhatIf:$false to apply. Use -Action to choose Install, Uninstall, or Cleanup.
    HOW TO RUN
        Report-only (default):
          powershell -ExecutionPolicy Bypass -File .\PSAUTO-Deploy-CleanupRunner.ps1 -Action Install -InstallerPath "C:\Pkg\app.msi" -InstallArgs "/qn"
        Apply:
          powershell -ExecutionPolicy Bypass -File .\PSAUTO-Deploy-CleanupRunner.ps1 -Action Uninstall -ProductCode "{GUID}" -WhatIf:$false -LogPath "\\srv\share\psauto"
          powershell -ExecutionPolicy Bypass -File .\PSAUTO-Deploy-CleanupRunner.ps1 -Action Cleanup -CleanupPaths "C:\ProgramData\App\tmp","C:\Temp\App" -WhatIf:$false
    EXPECTED RESULTS
        -WhatIf (default): "WOULD: ..." lines, nothing changed, exit 0.
        Applied: "DID: ..." lines, the action performed, a log written to -LogPath if set, exit 0 on
        success / 1 on failure.
.NOTES
    Endpoint automation toolkit — the repeatable way. Run as SYSTEM for machine-wide actions.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [ValidateSet('Install','Uninstall','Cleanup')][string]$Action = 'Cleanup',
    [string]$InstallerPath,
    [string]$InstallArgs = '/qn',
    [string]$ProductCode,
    [string[]]$CleanupPaths,
    [string]$LogPath
)

# Default to report-only unless the caller explicitly asks to apply.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$log = New-Object System.Collections.Generic.List[string]
function Note($msg) { $line = ("{0}  {1}" -f (Get-Date -Format s), $msg); Write-Output $msg; $log.Add($line) }

$exitCode = 0
try {
    switch ($Action) {
        'Install' {
            if (-not $InstallerPath -or -not (Test-Path $InstallerPath)) { throw "InstallerPath '$InstallerPath' not found" }
            if ($PSCmdlet.ShouldProcess($InstallerPath, "Install with args '$InstallArgs'")) {
                if ($InstallerPath -match '\.msi$') { $p = Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" $InstallArgs" -Wait -PassThru }
                else { $p = Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait -PassThru }
                Note ("DID: install exit code {0}" -f $p.ExitCode)
                if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { $exitCode = 1 }
            } else { Note "WOULD: install $InstallerPath $InstallArgs" }
        }
        'Uninstall' {
            if (-not $ProductCode) { throw "Uninstall requires -ProductCode '{GUID}'" }
            if ($PSCmdlet.ShouldProcess($ProductCode, "Uninstall product")) {
                $p = Start-Process msiexec.exe -ArgumentList "/x $ProductCode /qn" -Wait -PassThru
                Note ("DID: uninstall exit code {0}" -f $p.ExitCode)
                if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { $exitCode = 1 }
            } else { Note "WOULD: uninstall $ProductCode" }
        }
        'Cleanup' {
            if (-not $CleanupPaths) { throw "Cleanup requires -CleanupPaths" }
            foreach ($path in $CleanupPaths) {
                if (Test-Path $path) {
                    if ($PSCmdlet.ShouldProcess($path, "Remove leftover path")) { Remove-Item -Path $path -Recurse -Force -ErrorAction Stop; Note "DID: removed $path" }
                    else { Note "WOULD: remove $path" }
                } else { Note "SKIP: $path not present" }
            }
        }
    }
}
catch {
    Note ("ERROR: " + $_.Exception.Message)
    $exitCode = 1
}

if ($LogPath) {
    try {
        if (-not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null }
        $file = Join-Path $LogPath ("PSAUTO-{0}-{1:yyyyMMdd-HHmmss}.log" -f $env:COMPUTERNAME, (Get-Date))
        $log | Set-Content -Path $file -Encoding UTF8
        Write-Output "Log written: $file"
    } catch { Write-Output "WARN: could not write log to $LogPath ($($_.Exception.Message))" }
}

exit $exitCode
