<#
.SYNOPSIS
    MAMAPP-Remediation.ps1 — safely assign a MAM App Protection Policy to the scope group.
.DESCRIPTION
    PURPOSE
        Closes the most common coverage gap: an App Protection Policy exists but is not assigned to the
        BYOD scope group. This script adds the target group to the named iOS/Android App Protection
        Policy's assignments. It is SAFE BY DEFAULT (-WhatIf) and only writes when you pass -Execute.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\MAMAPP-Remediation.ps1 -PolicyName "BYOD - App Protection - iOS" -Platform iOS -GroupId <entra-group-id>
        Apply:              add  -Execute
        Requires the Microsoft Graph SDK and scope DeviceManagementApps.ReadWrite.All.
    EXPECTED RESULTS
        With -WhatIf (default): prints the assignment it WOULD add. With -Execute: adds the group to the
        policy's target assignments and confirms.
.NOTES
    Intune Solutions — MAM App Protection Policies for BYOD. Write action gated behind -Execute.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$PolicyName,
    [Parameter(Mandatory)][ValidateSet('iOS','Android')][string]$Platform,
    [Parameter(Mandatory)][string]$GroupId,
    [switch]$Execute
)
$WhatIf = -not $Execute
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All' -NoWelcome

$base = if ($Platform -eq 'iOS') { 'iosManagedAppProtections' } else { 'androidManagedAppProtections' }
$policy = ((Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/$base").value | Where-Object { $_.displayName -eq $PolicyName })
if (-not $policy) { Write-Host ("Policy '{0}' not found for {1}." -f $PolicyName, $Platform) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

$body = @{ assignments = @(@{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId } }) } | ConvertTo-Json -Depth 6
if ($WhatIf) {
    Write-Host ("[WhatIf] Would assign group {0} to '{1}' ({2})." -f $GroupId, $PolicyName, $Platform) -ForegroundColor Cyan
    Write-Host "         Re-run with -Execute to apply." -ForegroundColor Cyan
} else {
    Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceAppManagement/$base/$($policy.id)/assign" -Body $body -ContentType 'application/json' | Out-Null
    Write-Host ("Assigned group {0} to '{1}' ({2})." -f $GroupId, $PolicyName, $Platform) -ForegroundColor Green
    Write-Host "Re-run MAMAPP-Report.ps1 to confirm coverage." -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
