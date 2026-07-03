<#
.SYNOPSIS
    HYBIDG-Remediation.ps1 — safely correct common hybrid-identity drift on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Detects and (when explicitly authorized) corrects common configuration drift for Hybrid
        Identity on a Microsoft 365 U.S. Government GCC High tenant — for example a paused
        Connect Sync scheduler, or a stale/disabled sync schedule on the local Connect host.
        Defaults to -WhatIf: it reports what it WOULD change and makes no change until you re-run
        with -WhatIf:$false. Run from the Connect host (for example your-connect-host).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HYBIDG-Remediation.ps1            (preview only)
        powershell -ExecutionPolicy Bypass -File .\HYBIDG-Remediation.ps1 -WhatIf:$false   (apply)
        (Graph scopes: Organization.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A list of detected drift items, each showing WOULD FIX (default) or FIXED (when applied).
        Items requiring portal changes are reported as guidance and never auto-applied.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints;
    local changes are gated behind -WhatIf.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',

    # Safety default: preview only. Set -WhatIf:$false to apply.
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
Write-Host "=== HYBIDG Remediation (Government / GCC High) — Environment: $Environment ===" -ForegroundColor Cyan
if ($WhatIf) { Write-Host "MODE: PREVIEW (-WhatIf). No changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }

$actions = New-Object System.Collections.Generic.List[object]
function Record {
    param([string]$Item,[string]$Finding,[string]$Action,[bool]$Applied)
    $actions.Add([pscustomobject]@{ Item=$Item; Finding=$Finding; Action=$Action; Applied=$Applied })
    Write-Host ("[{0}] {1}: {2} -> {3}" -f ($(if($Applied){'FIXED'}elseif($WhatIf){'WOULD FIX'}else{'SKIPPED'}), $Item, $Finding, $Action))
}

# --- Local Connect Sync scheduler drift (ADSync module) ---
try {
    if (Get-Module -ListAvailable -Name ADSync) {
        Import-Module ADSync -ErrorAction Stop
        $sched = Get-ADSyncScheduler
        if (-not $sched.SyncCycleEnabled) {
            if ($WhatIf) {
                Record 'ConnectSyncScheduler' 'SyncCycleEnabled = False' 'Enable sync cycle' $false
            } elseif ($PSCmdlet.ShouldProcess('ADSyncScheduler','Enable sync cycle')) {
                Set-ADSyncScheduler -SyncCycleEnabled $true
                Record 'ConnectSyncScheduler' 'SyncCycleEnabled = False' 'Enabled sync cycle' $true
            }
        } else {
            Write-Host "[OK] ConnectSyncScheduler: SyncCycleEnabled = True" -ForegroundColor Green
        }

        if ($sched.StagingModeEnabled) {
            Record 'ConnectStagingMode' 'StagingModeEnabled = True (host will not export)' `
                'Review — leave staging on for a passive host; disable only on the active host (manual)' $false
        }
    } else {
        Write-Host "[INFO] ADSync module not present — run remediation on the Connect Sync host." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Local scheduler check: $($_.Exception.Message)" -ForegroundColor Red
}

# --- Tenant-side read-only drift detection (guidance only; never auto-applied) ---
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Environment $Environment -Scopes 'Organization.Read.All' -NoWelcome
    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value[0]

    if (-not $org.onPremisesSyncEnabled) {
        Record 'DirectorySync' 'onPremisesSyncEnabled = False' `
            'Enable directory sync via Entra Connect setup on the host (manual — not auto-applied)' $false
    }
    if ($org.onPremisesLastSyncDateTime) {
        $age = (New-TimeSpan -Start ([datetime]$org.onPremisesLastSyncDateTime) -End (Get-Date)).TotalHours
        if ($age -gt 24) {
            Record 'SyncFreshness' "Last sync $([math]::Round($age,1))h ago" `
                'Start a sync cycle on the host (Start-ADSyncSyncCycle) and check Connect Health (manual)' $false
        }
    }
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Host "[ERROR] Tenant drift check: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Remediation summary ===" -ForegroundColor Cyan
if ($actions.Count -eq 0) { Write-Host "No drift detected." -ForegroundColor Green }
else { $actions | Format-Table -AutoSize }
if ($WhatIf) { Write-Host "`nPreview only. Re-run with -WhatIf:`$false to apply the auto-fixable items." -ForegroundColor Yellow }
exit 0
