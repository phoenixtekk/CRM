<#
.SYNOPSIS
    WS1POL-Remediation.ps1 — find and (with confirmation) resolve conflicting policy assignments.
.DESCRIPTION
    PURPOSE
        Identifies devices reporting a configuration setting in conflict (the same setting set by more
        than one policy) and, when run without -WhatIf, removes the conflicting assignment you select
        from the policy you specify — the safe fix for the overlap that breaks parity. Defaults to
        -WhatIf so nothing changes until you confirm.
    HOW TO RUN
        Preview (default, no change):
          powershell -ExecutionPolicy Bypass -File .\WS1POL-Remediation.ps1
        Apply (remove a conflicting group assignment from a policy):
          powershell -ExecutionPolicy Bypass -File .\WS1POL-Remediation.ps1 -PolicyId <id> -RemoveGroupId <groupId> -WhatIf:$false
        Requires Microsoft Graph SDK with DeviceManagementConfiguration.ReadWrite.All.
    EXPECTED RESULTS
        -WhatIf (default): a list of configuration policies in a conflicting state and the requested
        assignment change, with NO change made.
        Applied: the named group assignment is removed from the named policy; re-run WS1POL-Validation.ps1.
.NOTES
    Workspace ONE to Intune migration — defaults to -WhatIf. Read-only unless -WhatIf:$false is set.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [string]$PolicyId,
    [string]$RemoveGroupId
)
# Default to -WhatIf unless the caller explicitly disabled it.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$scope = if ($WhatIfPreference) { 'DeviceManagementConfiguration.Read.All' } else { 'DeviceManagementConfiguration.ReadWrite.All' }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes $scope -NoWelcome

# Report configuration policies whose per-device status includes conflicts.
$cfg = @(); $uri = '/beta/deviceManagement/configurationPolicies?$select=id,name'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $cfg += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
Write-Host "`n=== Configuration policies with conflicting device status ===" -ForegroundColor Cyan
foreach ($c in $cfg) {
    try {
        $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($c.id)/deviceStatuses").value
        $conf = @($st | Where-Object { $_.status -match 'conflict' })
        if ($conf.Count -gt 0) { Write-Host ("  {0}  — {1} device(s) in conflict" -f $c.name, $conf.Count) -ForegroundColor Yellow }
    } catch { }
}

# Optional fix: remove a conflicting group assignment from a specified policy.
if ($PolicyId -and $RemoveGroupId) {
    $target = $cfg | Where-Object { $_.id -eq $PolicyId }
    $label = if ($target) { $target.name } else { $PolicyId }
    if ($PSCmdlet.ShouldProcess("$label", "Remove assignment of group $RemoveGroupId")) {
        $assigns = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$PolicyId/assignments").value
        $kept = $assigns | Where-Object { $_.target.groupId -ne $RemoveGroupId } | ForEach-Object { @{ target = $_.target } }
        $body = @{ assignments = @($kept) } | ConvertTo-Json -Depth 6
        Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/configurationPolicies/$PolicyId/assign" -Body $body -ContentType 'application/json'
        Write-Host "Removed group $RemoveGroupId from $label. Re-run WS1POL-Validation.ps1." -ForegroundColor Green
    }
} else {
    Write-Host "`nPreview only. To resolve a conflict, re-run with -PolicyId, -RemoveGroupId, and -WhatIf:`$false." -ForegroundColor Cyan
}
Disconnect-MgGraph | Out-Null
