<#
.SYNOPSIS
    APPCFG-Remediation.ps1 — guarded staging of a missing App Configuration Policy assignment (-WhatIf by default, Graph).
.DESCRIPTION
    PURPOSE
        Fixes the most common app-config gap: a policy that exists but is not assigned to the intended
        group. Resolves a managed-device App Configuration Policy by name and an Entra group by name,
        shows the assignment it WOULD add, and — only when you pass -Commit — adds the group to the
        policy's assignments (preserving existing assignments). Safe by default: with no -Commit it runs
        in preview (-WhatIf) and writes nothing.
    HOW TO RUN
        # Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Remediation.ps1 -PolicyName "APPCFG - Ariba - iOS - Pilot" -GroupName "APPCFG - Ariba - Pilot"
        # Apply (explicit):
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Remediation.ps1 -PolicyName "APPCFG - Ariba - iOS - Pilot" -GroupName "APPCFG - Ariba - Pilot" -Commit
        Requires the Microsoft Graph SDK and DeviceManagementApps.ReadWrite.All (write only used with -Commit).
    EXPECTED RESULTS
        Preview: prints the assignment that would be added. -Commit: adds it and confirms. Existing
        assignments are preserved (the full set is re-sent).
.NOTES
    Intune Solutions — guarded write (-WhatIf by default; writes only with -Commit). Cloud-aware. No credentials stored.
.EXAMPLE
    .\APPCFG-Remediation.ps1 -PolicyName "APPCFG - Ariba - iOS - Pilot" -GroupName "APPCFG - Ariba - Pilot" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [Parameter(Mandatory)][string]$GroupName,
    [switch]$Commit,
    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$scopes = if ($Commit) { 'DeviceManagementApps.ReadWrite.All' } else { 'DeviceManagementApps.Read.All' }
$scopes = @($scopes, 'Directory.Read.All')
Connect-MgGraph -Scopes $scopes -Environment $Environment -NoWelcome

$enc = [uri]::EscapeDataString($PolicyName)
$pol = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileAppConfigurations?`$filter=displayName eq '$enc'&`$expand=assignments").value | Select-Object -First 1
if (-not $pol) { Write-Host "FAIL: managed-device policy '$PolicyName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$([uri]::EscapeDataString($GroupName))'").value | Select-Object -First 1
if (-not $grp) { Write-Host "FAIL: group '$GroupName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$existing = @($pol.assignments | ForEach-Object { $_.target.groupId })
if ($existing -contains $grp.id) {
    Write-Host ("No change — '{0}' is already assigned to policy '{1}'." -f $GroupName, $PolicyName) -ForegroundColor Green
    Disconnect-MgGraph | Out-Null; return
}

# Build the full assignment set (existing + new) — the assign action replaces ALL assignments.
$assignments = @()
foreach ($gid in $existing) {
    $assignments += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $gid } }
}
$assignments += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id } }
$body = @{ assignments = $assignments } | ConvertTo-Json -Depth 6

Write-Host ("Policy   : {0}" -f $PolicyName)
Write-Host ("Add group: {0}  ({1})" -f $GroupName, $grp.id)
Write-Host ("Result   : {0} total assignment(s)" -f $assignments.Count)

$uri = "/v1.0/deviceAppManagement/mobileAppConfigurations/$($pol.id)/assign"
if ($Commit -and $PSCmdlet.ShouldProcess($PolicyName, "Add assignment to group '$GroupName'")) {
    Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType 'application/json'
    Write-Host "COMMITTED — assignment added." -ForegroundColor Green
} else {
    Write-Host "PREVIEW (no -Commit) — no change made. Re-run with -Commit to apply." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
