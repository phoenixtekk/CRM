<#
.SYNOPSIS
    ISEPOST-Remediation.ps1 — safely nudge non-compliant devices toward compliance (default -WhatIf; nothing changes until -Execute).
.DESCRIPTION
    PURPOSE
        Finds Intune managed devices that are non-compliant (the population ISE would deny)
        and nudges them toward compliance by triggering an Intune sync so they re-evaluate
        and re-report. Runs in preview by default: it lists what it WOULD do and changes
        nothing. Pass -Execute to actually send the sync action.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Remediation.ps1
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Remediation.ps1 -Execute

        Required Graph scopes: DeviceManagementManagedDevices.Read.All (preview),
        DeviceManagementManagedDevices.PrivilegedOperations.All (with -Execute)
    EXPECTED RESULTS
        Lists non-compliant devices and the sync action. Default -WhatIf makes no change;
        with -Execute it triggers a sync per device and reports success/failure per device.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph by default. Cisco ISE internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
# Default posture is preview/-WhatIf: only act when -Execute is explicitly passed.
$whatIf = -not $Execute

function Connect-GraphSafe {
    param([switch]$Privileged)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('DeviceManagementManagedDevices.Read.All')
    if ($Privileged) { $scopes += 'DeviceManagementManagedDevices.PrivilegedOperations.All' }
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null }
}

Write-Host "=== ISEPOST Remediation — nudge non-compliant devices ===" -ForegroundColor Cyan
if ($whatIf) {
    Write-Host "MODE: -WhatIf (preview). No changes will be made. Pass -Execute to act." -ForegroundColor Yellow
} else {
    Write-Host "MODE: -Execute. A sync action WILL be sent to each non-compliant device." -ForegroundColor Red
}

Connect-GraphSafe -Privileged:$Execute

$nonCompliant = Get-MgDeviceManagementManagedDevice -All -Filter "complianceState eq 'noncompliant'" -ErrorAction Stop
if (-not $nonCompliant -or $nonCompliant.Count -eq 0) {
    Write-Host "`nNo non-compliant devices found. Nothing to remediate." -ForegroundColor Green
    return
}

Write-Host "`nNon-compliant devices found: $($nonCompliant.Count)" -ForegroundColor Cyan
$ok = 0; $fail = 0
foreach ($d in $nonCompliant) {
    $label = "{0} ({1} {2})" -f $d.DeviceName, $d.OperatingSystem, $d.OsVersion
    if ($whatIf) {
        Write-Host "  WOULD sync -> $label" -ForegroundColor Yellow
    } else {
        try {
            Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $d.Id -ErrorAction Stop
            Write-Host "  SYNCED     -> $label" -ForegroundColor Green
            $ok++
        } catch {
            Write-Host "  FAILED     -> $label : $($_.Exception.Message)" -ForegroundColor Red
            $fail++
        }
    }
}

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
if ($whatIf) {
    Write-Host "  $($nonCompliant.Count) device(s) would be nudged. Re-run with -Execute to apply." -ForegroundColor Yellow
} else {
    Write-Host "  Synced: $ok   Failed: $fail" -ForegroundColor Cyan
}
Write-Host "`nA sync prompts re-evaluation only; the user must still fix the underlying issue (encryption, OS, etc.)."
Write-Host "Enforcement of the resulting state is performed by Cisco ISE (deferred to Cisco documentation)."
