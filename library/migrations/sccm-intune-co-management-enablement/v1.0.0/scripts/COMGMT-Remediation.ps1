<#
.SYNOPSIS
    COMGMT-Remediation.ps1 — Safe remediation for un-enrolled co-management clients.

PURPOSE
    For a Configuration Manager client that is co-management-enabled but has not
    yet enrolled into Intune, this safely retries the path: triggers the client
    machine-policy retrieval/evaluation cycles so the co-management policy and
    auto-enrollment are re-applied. It does NOT force-unenroll, reinstall, or
    change any workload slider. Defaults to -WhatIf (no action) — you must pass
    -WhatIf:$false (or -Confirm) to actually trigger the cycles.

HOW TO RUN
    Preview (default, makes no changes):
        .\COMGMT-Remediation.ps1
    Execute the policy-retrieval triggers:
        .\COMGMT-Remediation.ps1 -WhatIf:$false

EXPECTED RESULTS
    With -WhatIf (default): prints what it WOULD trigger, changes nothing.
    Executed: triggers Machine Policy Retrieval + Evaluation and a co-management
    re-evaluation on the local ConfigMgr client, prompting a fresh enrollment
    attempt. Re-run COMGMT-Validation.ps1 afterward to confirm.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param()

# Default to WhatIf unless the caller explicitly turns it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
}

$ErrorActionPreference = 'Stop'

$ccm = Get-Service -Name 'CcmExec' -ErrorAction SilentlyContinue
if (-not $ccm) {
    Write-Warning 'Configuration Manager client (CcmExec) not found. Nothing to remediate; deploy the client first.'
    return
}

# ConfigMgr client action schedule IDs (read-only triggers, no data loss):
#   Machine Policy Retrieval Cycle      {00000000-0000-0000-0000-000000000021}
#   Machine Policy Evaluation Cycle     {00000000-0000-0000-0000-000000000022}
$actions = @(
    @{ Name = 'Machine Policy Retrieval Cycle';  Id = '{00000000-0000-0000-0000-000000000021}' }
    @{ Name = 'Machine Policy Evaluation Cycle'; Id = '{00000000-0000-0000-0000-000000000022}' }
)

foreach ($a in $actions) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Trigger $($a.Name)")) {
        Invoke-CimMethod -Namespace 'root\ccm' -ClassName 'SMS_Client' `
            -MethodName 'TriggerSchedule' -Arguments @{ sScheduleID = $a.Id } | Out-Null
        Write-Host "Triggered: $($a.Name)"
    }
    else {
        Write-Host "WhatIf: would trigger $($a.Name)"
    }
}

Write-Host ''
Write-Host 'Done. Allow a few minutes, then run COMGMT-Validation.ps1 to confirm enrollment.'
