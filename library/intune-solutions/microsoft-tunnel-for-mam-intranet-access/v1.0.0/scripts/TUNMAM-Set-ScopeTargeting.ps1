<#
.SYNOPSIS
    TUNMAM-Set-ScopeTargeting.ps1 — set the pilot/broad group on the Tunnel (MAM) configuration (Graph).
.DESCRIPTION
    PURPOSE
        Adds or replaces the Entra group assignment on one or all Tunnel (MAM) app-configuration
        policies, so you can move a configuration from the pilot group to the broad group (or scope a
        new group) as part of Assess -> Configure -> Pilot -> Validate -> Expand.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\TUNMAM-Set-ScopeTargeting.ps1 -GroupId <guid> [-ConfigName '<display name>']
        Apply:
          powershell -ExecutionPolicy Bypass -File .\TUNMAM-Set-ScopeTargeting.ps1 -GroupId <guid> [-ConfigName '<name>'] [-Replace] -WhatIf:$false
        -Replace overwrites existing assignments; omit it to add the group to existing assignments.
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.ReadWrite.All to apply.
    EXPECTED RESULTS
        Shows the target configuration(s) and the intended assignment. In preview it changes nothing;
        with -WhatIf:$false it writes the assignment via the /assign action.
.NOTES
    Intune Solutions — Microsoft Tunnel for MAM. Read-only unless -WhatIf:$false is set.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$GroupId,
    [string]$ConfigName,
    [switch]$Replace,
    [switch]$WhatIf = $true
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$scopes = if ($WhatIf) { @('DeviceManagementApps.Read.All') } else { @('DeviceManagementApps.ReadWrite.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

$all = @()
try { $all = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/targetedManagedAppConfigurations').value } catch {}
$targets = if ($ConfigName) { $all | Where-Object { $_.displayName -eq $ConfigName } } else { $all }

if (-not $targets) { Write-Host "No matching Tunnel (MAM) configuration found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

foreach ($t in $targets) {
    $existing = @()
    try { $existing = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/targetedManagedAppConfigurations/$($t.id)/assignments").value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch {}

    $wanted = if ($Replace) { @($GroupId) } else { @($existing + $GroupId | Select-Object -Unique) }
    Write-Host ("Config: {0}" -f $t.displayName) -ForegroundColor Cyan
    Write-Host ("  current groups: {0}" -f (($existing -join ', ')))
    Write-Host ("  target groups : {0}" -f (($wanted  -join ', ')))

    if ($WhatIf) { Write-Host "  [WhatIf] no change made." -ForegroundColor Cyan; continue }

    $body = @{ assignments = @($wanted | ForEach-Object { @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $_ } } }) }
    try {
        Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceAppManagement/targetedManagedAppConfigurations/$($t.id)/assign" -Body ($body | ConvertTo-Json -Depth 6)
        Write-Host "  Assignment updated." -ForegroundColor Green
    } catch {
        Write-Host ("  Failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

if ($WhatIf) { Write-Host "`nPreview only. Re-run with -WhatIf:`$false to apply." -ForegroundColor Cyan }
Disconnect-MgGraph | Out-Null
