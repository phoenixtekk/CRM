<#
.SYNOPSIS
    TUNMAM-Remediation.ps1 — safely remediate an unassigned Tunnel (MAM) configuration (Graph).
.DESCRIPTION
    PURPOSE
        Detects Tunnel (MAM) app-configuration policies that have no group assignment (a common cause
        of "the app never prompts to tunnel") and can assign a specified group to fix it. Runs in
        preview mode by default (-WhatIf); it only writes when you pass -WhatIf:$false.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\TUNMAM-Remediation.ps1 -GroupId <entra-group-guid>
        Apply the fix:      powershell -ExecutionPolicy Bypass -File .\TUNMAM-Remediation.ps1 -GroupId <entra-group-guid> -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.ReadWrite.All to apply.
    EXPECTED RESULTS
        Lists each unassigned Tunnel (MAM) configuration. In preview it reports what it would do; with
        -WhatIf:$false it assigns the given group to each unassigned configuration.
.NOTES
    Intune Solutions — Microsoft Tunnel for MAM. Read-only unless -WhatIf:$false is set.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$GroupId,
    [switch]$WhatIf = $true
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$scopes = if ($WhatIf) { @('DeviceManagementApps.Read.All') } else { @('DeviceManagementApps.ReadWrite.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

$appcfg = @()
try { $appcfg = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/targetedManagedAppConfigurations').value } catch {}

$fixed = 0
foreach ($a in $appcfg) {
    $grp = @()
    try { $grp = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/targetedManagedAppConfigurations/$($a.id)/assignments").value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch {}
    if ($grp.Count -gt 0) { continue }

    Write-Host ("UNASSIGNED: {0}" -f $a.displayName) -ForegroundColor Yellow
    if ($WhatIf) {
        Write-Host ("  [WhatIf] would assign group {0} to '{1}'." -f $GroupId, $a.displayName) -ForegroundColor Cyan
    } else {
        $body = @{
            assignments = @(
                @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId } }
            )
        }
        try {
            Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceAppManagement/targetedManagedAppConfigurations/$($a.id)/assign" -Body ($body | ConvertTo-Json -Depth 6)
            Write-Host ("  Assigned group {0} to '{1}'." -f $GroupId, $a.displayName) -ForegroundColor Green
            $fixed++
        } catch {
            Write-Host ("  Failed to assign: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
}

if ($WhatIf) { Write-Host "`nPreview only. Re-run with -WhatIf:`$false to apply." -ForegroundColor Cyan }
else { Write-Host ("`nRemediation complete. Configurations fixed: {0}" -f $fixed) -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
