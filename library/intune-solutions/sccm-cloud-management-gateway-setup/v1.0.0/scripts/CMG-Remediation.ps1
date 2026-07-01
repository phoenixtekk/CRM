<#
.SYNOPSIS
    CMG-Remediation.ps1 - Safe remediation of a misconfigured Configuration Manager client so it can
    use the Cloud Management Gateway (CMG). DEFAULTS TO -WhatIf (no changes unless you opt in).

.DESCRIPTION
    Purpose:
        On a managed client that should be using the CMG but is not, this triggers the standard,
        non-destructive client recovery actions: a Machine Policy Retrieval & Evaluation cycle, a
        Hardware Inventory cycle, and a software-update scan. It changes nothing on the server side.
        It does NOT reissue certificates, re-enroll, or alter site configuration.

    How to run:
        - Preview only (default, recommended first):
              .\CMG-Remediation.ps1
          Shows exactly what it WOULD do; makes no changes (-WhatIf is on by default).
        - Apply the safe client triggers (run elevated on the client):
              .\CMG-Remediation.ps1 -Apply

    Expected results:
        In preview mode, a list of the client actions that would run. With -Apply, the ConfigMgr
        client schedules a policy retrieval/evaluation, a hardware inventory, and an update scan; the
        client should then pick up the internet/CMG management point. Re-run CMG-Validation.ps1 to
        confirm.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    # Default posture is preview-only. Pass -Apply to actually trigger the (safe) client cycles.
    [Parameter(Mandatory = $false)]
    [switch]$Apply
)

# Enforce -WhatIf by default unless -Apply is explicitly supplied.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
    Write-Host "Running in preview mode (-WhatIf). Pass -Apply to perform the safe client actions." -ForegroundColor Yellow
}

# ConfigMgr client scheduled-action GUIDs (documented client trigger IDs)
$actions = [ordered]@{
    'Machine Policy Retrieval & Evaluation Cycle' = '{00000000-0000-0000-0000-000000000021}'
    'Machine Policy Evaluation Cycle'             = '{00000000-0000-0000-0000-000000000022}'
    'Hardware Inventory Cycle'                    = '{00000000-0000-0000-0000-000000000001}'
    'Software Updates Scan Cycle'                 = '{00000000-0000-0000-0000-000000000113}'
    'Software Updates Deployment Evaluation'      = '{00000000-0000-0000-0000-000000000108}'
}

# Confirm the ConfigMgr client is present
$ccm = Get-CimInstance -Namespace "root\ccm" -ClassName "SMS_Client" -ErrorAction SilentlyContinue
if (-not $ccm) {
    Write-Warning "ConfigMgr client (root\ccm) not found. Run this on a managed client."
    return
}

foreach ($name in $actions.Keys) {
    $guid = $actions[$name]
    if ($PSCmdlet.ShouldProcess("ConfigMgr client", "Trigger '$name' ($guid)")) {
        try {
            Invoke-CimMethod -Namespace "root\ccm" -ClassName "SMS_Client" `
                -MethodName "TriggerSchedule" -Arguments @{ sScheduleID = $guid } -ErrorAction Stop | Out-Null
            Write-Host "Triggered: $name" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to trigger '$name': $($_.Exception.Message)"
        }
    }
}

if ($WhatIfPreference) {
    Write-Host "`nPreview complete. No changes were made. Re-run with -Apply to execute." -ForegroundColor Yellow
} else {
    Write-Host "`nSafe client cycles triggered. Allow time, then run CMG-Validation.ps1 to confirm CMG reach." -ForegroundColor Green
}
