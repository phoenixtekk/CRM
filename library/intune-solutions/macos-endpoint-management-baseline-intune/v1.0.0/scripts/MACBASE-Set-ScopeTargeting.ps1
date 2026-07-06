<#
.SYNOPSIS
    MACBASE-Set-ScopeTargeting.ps1 — add a group assignment to the macOS baseline policies (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Assigns a target Entra group (your pilot or production Mac group) to the named macOS baseline
        settings-catalog policies the repeatable way, so you do not click each policy by hand when
        expanding. It resolves the group by display name, finds the baseline policies by name prefix,
        and adds an include-group assignment to each. Safe by default: it previews unless you pass
        -WhatIf:$false.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\MACBASE-Set-ScopeTargeting.ps1 -GroupName "macOS Baseline - Production Devices"
        Apply:              powershell -ExecutionPolicy Bypass -File .\MACBASE-Set-ScopeTargeting.ps1 -GroupName "macOS Baseline - Production Devices" -WhatIf:$false
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.ReadWrite.All +
        Group.Read.All. (Use the exact group display name from your tenant.)
    EXPECTED RESULTS
        With -WhatIf (default): lists the baseline policies and the assignment it WOULD add, no change.
        With -WhatIf:$false: adds the include-group assignment to each baseline policy.
        Pass = each baseline policy now lists the target group under Assignments in Intune.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf (no change unless -WhatIf:$false).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$GroupName,
    [string]$PolicyNameLike = 'macOS Baseline'
)

# Default to WhatIf unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All','Group.Read.All' -NoWelcome

Write-Host "=== macOS Baseline — scope targeting ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (WhatIf mode — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

# Resolve the target group by display name
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f ($GroupName -replace "'","''"))).value | Select-Object -First 1
if (-not $grp) { Write-Host "Group '$GroupName' not found. Check the display name (see Requirement 2.6)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
Write-Host ("Target group   : {0} ({1})" -f $grp.displayName, $grp.id) -ForegroundColor Green

# Find the baseline settings-catalog policies by name prefix
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$PolicyNameLike')").value
if (-not $cps) { Write-Host "No baseline policies found matching '$PolicyNameLike'. Build them first (Implementation Steps 5–7)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 0 }

foreach ($p in $cps) {
    # Read existing assignments so we do not drop them
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/assignments").value
    $already = $existing | Where-Object { $_.target.groupId -eq $grp.id }
    if ($already) { Write-Host ("  (skip) {0} already targets this group." -f $p.name) -ForegroundColor DarkGray; continue }

    $assignments = @()
    foreach ($e in $existing) { $assignments += @{ target = $e.target } }
    $assignments += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id } }
    $body = @{ assignments = $assignments } | ConvertTo-Json -Depth 8

    if ($PSCmdlet.ShouldProcess($p.name, "Add include-group assignment for '$($grp.displayName)'")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/assign" -Body $body -ContentType 'application/json' | Out-Null
            Write-Host ("  Assigned group to: {0}" -f $p.name) -ForegroundColor Green
        } catch { Write-Host ("  Assignment failed for {0}: {1}" -f $p.name, $_.Exception.Message) -ForegroundColor Yellow }
    } else {
        Write-Host ("  WOULD assign group to: {0}" -f $p.name) -ForegroundColor Yellow
    }
}

Write-Host "`nVerify each policy's Assignments in Intune, then run MACBASE-Report.ps1 to confirm posture." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
