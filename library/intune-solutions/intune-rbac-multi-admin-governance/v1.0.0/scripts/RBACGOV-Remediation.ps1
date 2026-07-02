<#
.SYNOPSIS
    RBACGOV-Remediation.ps1 — safely tighten over-privileged Intune role assignments (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Tightens over-privileged role assignments by applying a target scope tag to assignments that
        currently have none (the most common over-privilege: an assignment with unbounded reach).
        Defaults to -WhatIf so it only previews changes; pass -Apply to actually write.
    HOW TO RUN
        Preview (safe, default):  powershell -ExecutionPolicy Bypass -File .\RBACGOV-Remediation.ps1 -ScopeTagId 5
        Apply changes:            powershell -ExecutionPolicy Bypass -File .\RBACGOV-Remediation.ps1 -ScopeTagId 5 -Apply
        Requires the Microsoft Graph SDK and consent to DeviceManagementRBAC.ReadWrite.All (write
        only happens with -Apply; preview needs read only).
    EXPECTED RESULTS
        In preview: a WHATIF line per assignment that would be tightened. With -Apply: each
        no-scope-tag assignment receives $ScopeTagId. Always run RBACGOV-Validation.ps1 afterward.
        Keep a break-glass admin excluded from the gate so you never lock yourself out.
.NOTES
    White-label — Intune Solutions. Defaults to -WhatIf (no changes).
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$ScopeTagId,   # the roleScopeTag id to apply to unbounded assignments
    [switch]$Apply                                # omit for -WhatIf preview (default)
)
$whatIf = -not $Apply
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Apply) { @('DeviceManagementRBAC.ReadWrite.All') } else { @('DeviceManagementRBAC.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host ("=== RBACGOV Remediation ({0}) ===" -f ($(if ($whatIf) { 'WhatIf preview — no changes' } else { 'APPLY' }))) -ForegroundColor Cyan
$roles = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions').value
$count = 0
foreach ($r in $roles) {
    if ($r.isBuiltIn) { continue }
    try { $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($r.id)/roleAssignments").value } catch { $asg = @() }
    foreach ($a in $asg) {
        if (-not $a.scopeTags) {
            $count++
            if ($whatIf) {
                Write-Host ("  WHATIF: would add scope tag {0} to assignment '{1}' (role '{2}')." -f $ScopeTagId, $a.displayName, $r.displayName) -ForegroundColor Yellow
            } else {
                $body = @{ scopeTags = @($ScopeTagId) } | ConvertTo-Json
                try {
                    Invoke-MgGraphRequest -Method PATCH -Uri "/beta/deviceManagement/roleAssignments/$($a.id)" -Body $body -ContentType 'application/json'
                    Write-Host ("  APPLIED: scope tag {0} added to assignment '{1}'." -f $ScopeTagId, $a.displayName) -ForegroundColor Green
                } catch { Write-Host ("  ERROR on '{0}': {1}" -f $a.displayName, $_.Exception.Message) -ForegroundColor Red }
            }
        }
    }
}
if ($count -eq 0) { Write-Host "  No unbounded assignments found — nothing to tighten." -ForegroundColor Green }
Write-Host "`nRe-run RBACGOV-Validation.ps1 to confirm. Keep a break-glass admin excluded from the gate." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
