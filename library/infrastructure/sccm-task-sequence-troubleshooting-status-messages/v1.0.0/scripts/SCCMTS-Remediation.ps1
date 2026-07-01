<#
.SYNOPSIS
    SCCMTS-Remediation.ps1 — safe remediation helpers: retry a task-sequence deployment and clear
    the client ccmcache. DEFAULTS TO -WhatIf (shows actions without executing).
.DESCRIPTION
    PURPOSE
        After a fix (runbook Step 6), help the device re-evaluate cleanly:
          - Retry: trigger a machine policy retrieval + evaluation cycle on the target device so the
            re-deployed task sequence is re-offered (via CIM SMS Client SDK / trigger schedule).
          - Clear ccmcache: remove stale/corrupt cached content so corrected content re-downloads.
        This script is SAFE BY DEFAULT: with -WhatIf (the default) it only prints what it would do.
        Re-run with -WhatIf:$false to actually perform the actions.
    HOW TO RUN
        Preview (default, no changes):
          .\SCCMTS-Remediation.ps1 -DeviceName PC123 -Retry
          .\SCCMTS-Remediation.ps1 -DeviceName PC123 -ClearCache
        Execute:
          .\SCCMTS-Remediation.ps1 -DeviceName PC123 -Retry -ClearCache -WhatIf:$false
        Requires remote CIM/WMI access to the target client (admin rights).
    EXPECTED RESULTS
        With -WhatIf: a list of the exact actions. Without: policy cycles triggered and/or ccmcache
        cleared; then re-run SCCMTS-Validation.ps1 after a policy cycle to confirm 11127 / exit 0.
.NOTES
    Phoenixtekk Workplace Marketplace — Infrastructure Solutions. Changes are gated behind -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$DeviceName,
    [switch]$Retry,
    [switch]$ClearCache
)

# SupportsShouldProcess makes -WhatIf available; force it ON unless the caller explicitly disables it.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not $Retry -and -not $ClearCache) {
    Write-Host "Specify -Retry and/or -ClearCache." -ForegroundColor Yellow; exit 1
}
Write-Host "=== SCCMTS Remediation — target $DeviceName (WhatIf=$WhatIfPreference) ===" -ForegroundColor Cyan

if ($Retry) {
    # Machine Policy Retrieval {00000000-0000-0000-0000-000000000021} and Evaluation {...022}.
    $schedules = '{00000000-0000-0000-0000-000000000021}', '{00000000-0000-0000-0000-000000000022}'
    foreach ($s in $schedules) {
        if ($PSCmdlet.ShouldProcess($DeviceName, "Trigger client schedule $s (machine policy)")) {
            try {
                Invoke-CimMethod -ComputerName $DeviceName -Namespace 'root\ccm' -ClassName SMS_Client `
                    -MethodName TriggerSchedule -Arguments @{ sScheduleID = $s } -ErrorAction Stop | Out-Null
                Write-Host "  Triggered $s" -ForegroundColor Green
            } catch { Write-Host "  Trigger $s failed: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
    }
}

if ($ClearCache) {
    if ($PSCmdlet.ShouldProcess($DeviceName, "Clear ccmcache (delete cached content elements)")) {
        try {
            $cache = New-CimSession -ComputerName $DeviceName -ErrorAction Stop
            $elements = Get-CimInstance -CimSession $cache -Namespace 'root\ccm\SoftMgmtAgent' -ClassName CacheInfoEx -ErrorAction Stop
            foreach ($e in $elements) {
                Remove-CimInstance -InputObject $e -ErrorAction SilentlyContinue
            }
            Write-Host ("  Cleared {0} cache elements." -f @($elements).Count) -ForegroundColor Green
            Remove-CimSession $cache
        } catch { Write-Host "  Clear cache failed: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

Write-Host "`nRe-run SCCMTS-Validation.ps1 after a policy cycle to confirm 11127 / exit 0." -ForegroundColor Green
