<#
.SYNOPSIS
    WS1WIN-Remediation.ps1 — safely resolve dual or failed enrollment on a migrated device.
.DESCRIPTION
    PURPOSE
        Helps a device end up managed by Intune ONLY. It (1) reports the current MDM enrollment(s)
        and flags a remaining Workspace ONE provider, (2) triggers an Entra/MDM auto-enroll + sync
        so a clean Intune enrollment can complete or re-apply, and (3) kicks the MDM sync scheduled
        task so policy re-evaluates. Defaults to -WhatIf: it shows what it WOULD do and changes
        nothing until you re-run with -WhatIf:$false.

        IMPORTANT — Workspace ONE removal is a VMware-owned action. This script does NOT unenroll
        from Workspace ONE; if a Workspace ONE enrollment is detected it STOPS and tells you to
        remove it per the official VMware Workspace ONE documentation first.
    HOW TO RUN
        Preview (safe, default):   powershell -ExecutionPolicy Bypass -File .\WS1WIN-Remediation.ps1
        Apply:                     powershell -ExecutionPolicy Bypass -File .\WS1WIN-Remediation.ps1 -WhatIf:$false
        Run elevated on the affected device.
    EXPECTED RESULTS
        In -WhatIf: a report of enrollments and the actions that would run. Applied: an MDM
        auto-enroll + sync requested; re-run WS1WIN-Validation.ps1 after a policy cycle.
.NOTES
    Workplace Marketplace — Migrations. Defaults to -WhatIf. Workspace ONE unenroll deferred to VMware.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param()
# Default to WhatIf unless the caller explicitly turns it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "`n=== WS1->Intune migration remediation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  MODE: -WhatIf (preview only — nothing will be changed). Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }

# 1. Inspect enrollments
$enrollRoot = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
$enr = @()
if (Test-Path $enrollRoot) {
    Get-ChildItem $enrollRoot -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.ProviderID -or $p.DiscoveryServiceFullURL) { $enr += $p }
    }
}
$isWs1    = @($enr | Where-Object { ($_.ProviderID -match 'AirWatch') -or ($_.DiscoveryServiceFullURL -match 'awmdm|airwatch|workspaceone') }).Count -gt 0
$isIntune = @($enr | Where-Object { ($_.ProviderID -match 'MS DM Server') -or ($_.DiscoveryServiceFullURL -match 'manage.microsoft.com|enrollment.manage') }).Count -gt 0
Write-Host ("  Enrollments: Intune={0}  WorkspaceONE={1}" -f $isIntune, $isWs1)

# 2. Guard: Workspace ONE present -> defer to VMware, do not auto-enroll into a dual state
if ($isWs1) {
    Write-Host "  STOP: Workspace ONE enrollment detected. Remove it per the official VMware Workspace ONE" -ForegroundColor Red
    Write-Host "        documentation (unenroll/retire) BEFORE remediating, to avoid dual management." -ForegroundColor Red
    Write-Host "        Re-run this script after the Workspace ONE enrollment is gone." -ForegroundColor Red
    return
}

# 3. Trigger a clean MDM auto-enroll + sync
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Trigger MDM auto-enroll (deviceenroller /AutoEnrollMDM)")) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM auto-enroll requested." -ForegroundColor Green
}

# 4. Kick the MDM sync scheduled task so policy re-applies
$syncTasks = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue |
             Where-Object { $_.TaskName -match 'Schedule.*createdby|PushLaunch|Sync' }
if ($syncTasks) {
    foreach ($t in $syncTasks) {
        if ($PSCmdlet.ShouldProcess("$($t.TaskPath)$($t.TaskName)", "Start MDM sync task")) {
            try { $t | Start-ScheduledTask -ErrorAction Stop; Write-Host ("  Started sync task: {0}" -f $t.TaskName) -ForegroundColor Green }
            catch { Write-Host ("  Could not start {0}: {1}" -f $t.TaskName, $_.Exception.Message) -ForegroundColor Yellow }
        }
    }
} else {
    Write-Host "  No MDM EnterpriseMgmt sync task found yet (expected before first successful enrollment)." -ForegroundColor Yellow
}

Write-Host "`n  Re-run WS1WIN-Validation.ps1 after a policy cycle to confirm single-MDM, parity, compliance." -ForegroundColor Green
