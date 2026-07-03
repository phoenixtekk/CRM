<#
.SYNOPSIS
    MAMAPPG-Remediation.ps1 — safely assign a MAM App Protection Policy to the BYOD scope group on GCC High. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Closes the most common coverage gap on a GCC High tenant: an App Protection Policy exists but is
        not assigned to the BYOD scope group. This script adds the target group to the named iOS/Android
        App Protection Policy's assignments. It is SAFE BY DEFAULT (-WhatIf) and only writes when you
        pass -Apply. Supply names/ids like 'BYOD - App Protection - iOS (Gov)' and your-entra-group-id
        (no angle brackets).
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\MAMAPPG-Remediation.ps1 -PolicyName 'BYOD - App Protection - iOS (Gov)' -Platform iOS -GroupId your-entra-group-id
        Apply:  add  -Apply
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementApps.ReadWrite.All'
    EXPECTED RESULTS
        With -WhatIf (default): prints the assignment it WOULD add. With -Apply: adds the group to the
        policy's target assignments and confirms.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless -Apply is passed.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$PolicyName,
    [Parameter(Mandatory)][ValidateSet('iOS','Android')][string]$Platform,
    [Parameter(Mandatory)][string]$GroupId,
    [switch]$Apply,
    [switch]$WhatIf = $true
)
if ($Apply) { $WhatIf = $false }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementApps.ReadWrite.All' -NoWelcome

if ((Get-MgContext).Environment -ne 'USGov') {
    Write-Host "WRONG CLOUD: not USGov (graph.microsoft.us). Reconnect with -Environment USGov." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}

$base = if ($Platform -eq 'iOS') { 'iosManagedAppProtections' } else { 'androidManagedAppProtections' }
$policy = ((Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/$base").value | Where-Object { $_.displayName -eq $PolicyName })
if (-not $policy) { Write-Host ("Policy '{0}' not found for {1}." -f $PolicyName, $Platform) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

$body = @{ assignments = @(@{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId } }) } | ConvertTo-Json -Depth 6
if ($WhatIf) {
    Write-Host ("[WhatIf] Would assign group {0} to '{1}' ({2}) on GCC High." -f $GroupId, $PolicyName, $Platform) -ForegroundColor Cyan
    Write-Host "         Re-run with -Apply to commit." -ForegroundColor Cyan
} else {
    Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceAppManagement/$base/$($policy.id)/assign" -Body $body -ContentType 'application/json' | Out-Null
    Write-Host ("Assigned group {0} to '{1}' ({2})." -f $GroupId, $PolicyName, $Platform) -ForegroundColor Green
    Write-Host "Re-run MAMAPPG-Report.ps1 to confirm coverage." -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
