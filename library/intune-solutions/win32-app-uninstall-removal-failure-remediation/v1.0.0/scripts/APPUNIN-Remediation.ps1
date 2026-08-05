<#
.SYNOPSIS
    APPUNIN-Remediation.ps1 — guarded fixes for a Win32 app's uninstall failure (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Applies one targeted, reviewed fix to correct a removal failure, per the
        Diagnostic Playbook. Every action defaults to PREVIEW (-WhatIf): it prints exactly
        what it WOULD change and makes no modification unless you re-run with -WhatIf:$false.
        Supported actions:
          SetUninstallCommand  - set Properties>Program>Uninstall command to a known-good
                                 string (Branch D/E). Use -GenerateProductCodeWrapper to
                                 emit a run-time ProductCode-resolving wrapper for fleets
                                 spanning multiple versions (Branch D).
          Resync               - trigger a device sync so the IME re-attempts the pipeline
                                 for devices reporting uninstallFailed (post-fix).
        NOTE: detection-rule and assignment edits are structurally destructive and are
        intentionally left to the console with the exact click path (printed by this
        script) so you review them yourself; this tool only writes the uninstall command
        and triggers re-syncs.
    HOW TO RUN
        Preview a corrected uninstall command:
          .\APPUNIN-Remediation.ps1 -AppNameLike "Contoso LOB" -Action SetUninstallCommand -UninstallCommand 'msiexec /x {NEW-GUID} /qn /norestart'
        Apply it:
          ... same line ... -WhatIf:$false
        Emit + set a ProductCode-resolving wrapper (multi-version fleet):
          .\APPUNIN-Remediation.ps1 -AppNameLike "Contoso LOB" -Action SetUninstallCommand -GenerateProductCodeWrapper -DisplayNamePattern "Contoso LOB Suite*"
        Re-attempt failed devices:
          .\APPUNIN-Remediation.ps1 -AppNameLike "Contoso LOB" -Action Resync -WhatIf:$false
        US Gov: add -GraphEnvironment USGov (GCC High) or -GraphEnvironment USGovDoD (DoD)

        Required Graph scopes: DeviceManagementApps.ReadWrite.All
                               (Resync also uses DeviceManagementManagedDevices.ReadWrite.All)
    EXPECTED RESULTS
        In preview, the exact planned change. When applied, the app's uninstall command is
        updated (or failed devices are synced). Re-run APPUNIN-Validation.ps1 after a cycle
        to confirm the state reaches notInstalled across the affected versions.
.NOTES
    Intune Solutions — WRITE-CAPABLE but defaults to -WhatIf. The repeatable way.
    Review every planned change before re-running with -WhatIf:$false.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string] $AppNameLike,
    [Parameter(Mandatory)][ValidateSet('SetUninstallCommand','Resync')][string] $Action,
    [string] $UninstallCommand,
    [switch] $GenerateProductCodeWrapper,
    [string] $DisplayNamePattern,
    [switch] $WhatIf = $true,
    [ValidateSet('Global','USGov','USGovDoD')][string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'
if ($WhatIf) { $WhatIfPreference = $true }

function Connect-Graph {
    param([string[]] $Scopes, [string] $Environment)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        if ($Environment -eq 'Global') { Connect-MgGraph -Scopes $Scopes | Out-Null }
        else { Connect-MgGraph -Scopes $Scopes -Environment $Environment | Out-Null }
    }
}

$graphHost = switch ($GraphEnvironment) {
    'USGov'    { 'https://graph.microsoft.us' }
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    default    { 'https://graph.microsoft.com' }
}
$base = "$graphHost/beta"

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

$scopes = @('DeviceManagementApps.ReadWrite.All')
if ($Action -eq 'Resync') { $scopes += 'DeviceManagementManagedDevices.ReadWrite.All' }
Connect-Graph -Scopes $scopes -Environment $GraphEnvironment

$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100" |
        Where-Object { $_.displayName -like "*$AppNameLike*" -and $_.'@odata.type' -match 'win32' }
if (-not $apps) { throw "No Win32 app found matching '$AppNameLike'." }

switch ($Action) {

    'SetUninstallCommand' {
        if ($GenerateProductCodeWrapper) {
            if (-not $DisplayNamePattern) { throw "-GenerateProductCodeWrapper requires -DisplayNamePattern (e.g. 'Contoso LOB Suite*')." }
            # A robust uninstall command that resolves the installed ProductCode at run time,
            # then uninstalls silently. Packaged as a one-line powershell call.
            $inner = @"
`$k='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*';
`$a=Get-ItemProperty `$k -EA SilentlyContinue|?{`$_.DisplayName -like '$DisplayNamePattern'}|select -First 1;
if(`$a.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$'){Start-Process msiexec.exe -ArgumentList ('/x '+`$a.PSChildName+' /qn /norestart') -Wait}
"@
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
            $UninstallCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
            Write-Host "Generated ProductCode-resolving uninstall wrapper (matches DisplayName like '$DisplayNamePattern')." -ForegroundColor Cyan
        }
        if (-not $UninstallCommand) { throw "Provide -UninstallCommand '<string>' or use -GenerateProductCodeWrapper -DisplayNamePattern '<pattern>'." }

        foreach ($app in $apps) {
            Write-Host "`nApp: $($app.displayName) [$($app.id)]" -ForegroundColor Cyan
            Write-Host "  Current uninstall command: $($app.uninstallCommandLine)" -ForegroundColor Gray
            Write-Host "  New uninstall command:     $UninstallCommand" -ForegroundColor Yellow
            $body = @{ '@odata.type' = $app.'@odata.type'; uninstallCommandLine = $UninstallCommand } | ConvertTo-Json
            if ($WhatIfPreference) {
                Write-Host "  PREVIEW (-WhatIf): would PATCH the uninstall command. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
            } elseif ($PSCmdlet.ShouldProcess($app.displayName, "Set uninstall command")) {
                Invoke-MgGraphRequest -Method PATCH -Uri "$base/deviceAppManagement/mobileApps/$($app.id)" -Body $body -ContentType 'application/json'
                Write-Host "  Applied." -ForegroundColor Green
            }
        }
        Write-Host "`nReminder: also confirm the DETECTION RULE points at an artifact the uninstaller REMOVES (Branch B/C), and that no Required assignment overlaps the Uninstall assignment (Branch A). Edit those in the console:" -ForegroundColor Cyan
        Write-Host "  Detection: Apps > All apps > <app> > Properties > Detection rules > Edit" -ForegroundColor Gray
        Write-Host "  Assignments: Apps > All apps > <app> > Properties > Assignments > Edit" -ForegroundColor Gray
    }

    'Resync' {
        foreach ($app in $apps) {
            $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses" |
                        Where-Object installState -eq 'uninstallFailed'
            if (-not $statuses) { Write-Host "No devices in 'uninstallFailed' for $($app.displayName)." -ForegroundColor Green; continue }
            Write-Host "`nApp: $($app.displayName) — devices to re-sync:" -ForegroundColor Cyan
            $statuses | Format-Table -AutoSize deviceName, installState, errorCode
            foreach ($s in $statuses) {
                if (-not $s.deviceId) { continue }
                if ($WhatIfPreference) {
                    Write-Host "  PREVIEW (-WhatIf): would sync $($s.deviceName). Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
                } elseif ($PSCmdlet.ShouldProcess($s.deviceName, "Trigger device sync")) {
                    try {
                        Invoke-MgGraphRequest -Method POST -Uri "$base/deviceManagement/managedDevices/$($s.deviceId)/syncDevice" | Out-Null
                        Write-Host "  Sync triggered: $($s.deviceName)" -ForegroundColor Green
                    } catch { Write-Host "  Failed to sync $($s.deviceName): $($_.Exception.Message)" -ForegroundColor Red }
                }
            }
        }
        Write-Host "`nAllow a sync cycle, then run APPUNIN-Validation.ps1 to confirm the app reaches notInstalled." -ForegroundColor Cyan
    }
}
