<#
.SYNOPSIS
    MACBYOD-Set-ScopeTargeting.ps1 — move BYOD compliance + CA scope from pilot to production. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Expands the macOS BYOD gate from the pilot group to a production group by (a) assigning the macOS
        BYOD compliance policy to the target group and (b) setting the require-compliant-Mac Conditional
        Access policy's included group to the target group while KEEPING break-glass exclusions. Change-
        making — so it DEFAULTS TO -WhatIf and only writes when you pass -Apply. Break-glass accounts are
        always re-asserted so scope expansion never drops the lockout safeguard. Use placeholder values
        like 'your-tenant.onmicrosoft.com', never real secrets.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\MACBYOD-Set-ScopeTargeting.ps1 -TargetGroup BYOD-Mac-Users -CompliancePolicyName "macOS BYOD Compliance - Pilot" -CaPolicyName "CA - Require Compliant Mac - Pilot" -BreakGlassUpns bg1@your-tenant.onmicrosoft.com,bg2@your-tenant.onmicrosoft.com
        Apply the scope change:
          powershell -ExecutionPolicy Bypass -File .\MACBYOD-Set-ScopeTargeting.ps1 -TargetGroup BYOD-Mac-Users -CompliancePolicyName "macOS BYOD Compliance - Pilot" -CaPolicyName "CA - Require Compliant Mac - Pilot" -BreakGlassUpns bg1@your-tenant.onmicrosoft.com,bg2@your-tenant.onmicrosoft.com -Apply
        Requires the Microsoft Graph PowerShell SDK. Graph scopes:
        read  — DeviceManagementConfiguration.Read.All, Policy.Read.All, Group.Read.All, User.Read.All
        write — DeviceManagementConfiguration.ReadWrite.All, Policy.ReadWrite.ConditionalAccess (with -Apply).
    EXPECTED RESULTS
        Without -Apply: prints the intended assignments (compliance policy -> target group; CA include ->
        target group; break-glass still excluded) and makes no change. With -Apply: both assignments are
        updated and confirmed.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -Apply. Break-glass always excluded.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetGroup,
    [string]$CompliancePolicyName = 'macOS BYOD Compliance - Pilot',
    [string]$CaPolicyName         = 'CA - Require Compliant Mac - Pilot',
    [string[]]$BreakGlassUpns,
    [switch]$Apply,
    [switch]$WhatIf = $true
)
if ($Apply) { $WhatIf = $false }

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Apply) { 'DeviceManagementConfiguration.ReadWrite.All','Policy.ReadWrite.ConditionalAccess','Group.Read.All','User.Read.All' }
          else        { 'DeviceManagementConfiguration.Read.All','Policy.Read.All','Group.Read.All','User.Read.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

$mode = $(if ($WhatIf) { '[WHATIF] ' } else { '[APPLY] ' })

# --- Resolve target group ---
$g = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$TargetGroup'&`$select=id,displayName").value | Select-Object -First 1
if (-not $g) { Write-Host "Target group not found: $TargetGroup" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# --- (1) Compliance policy assignment ---
$comp = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies').value |
        Where-Object displayName -eq $CompliancePolicyName | Select-Object -First 1
if (-not $comp) { Write-Host "Compliance policy not found: $CompliancePolicyName" -ForegroundColor Red }
else {
    Write-Host ("{0}Assign compliance '{1}' -> group '{2}'" -f $mode, $CompliancePolicyName, $g.displayName) -ForegroundColor Cyan
    if (-not $WhatIf) {
        $assign = @{ assignments = @(@{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $g.id } }) }
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$($comp.id)/assign" -Body ($assign | ConvertTo-Json -Depth 8) -ContentType 'application/json' | Out-Null
        Write-Host '  Compliance policy assigned.' -ForegroundColor Green
    }
}

# --- (2) CA policy include scope (keep break-glass excluded) ---
$ca = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies').value |
      Where-Object displayName -eq $CaPolicyName | Select-Object -First 1
if (-not $ca) { Write-Host "CA policy not found: $CaPolicyName" -ForegroundColor Red }
else {
    $exUsers = @($ca.conditions.users.excludeUsers)
    foreach ($u in $BreakGlassUpns) {
        try { $id = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$u").id; if ($exUsers -notcontains $id) { $exUsers += $id } }
        catch { Write-Host "  Break-glass user not found: $u" -ForegroundColor Red }
    }
    if ($exUsers.Count -eq 0) { Write-Host '  WARNING: no break-glass exclusions present or resolved — refusing to widen CA scope.' -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

    Write-Host ("{0}CA '{1}': include -> group '{2}'; keep {3} break-glass excluded" -f $mode, $CaPolicyName, $g.displayName, $exUsers.Count) -ForegroundColor Cyan
    if (-not $WhatIf) {
        $body = @{ conditions = @{ users = @{ includeGroups = @($g.id); excludeUsers = @($exUsers | Select-Object -Unique) } } } | ConvertTo-Json -Depth 8
        Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/$($ca.id)" -Body $body -ContentType 'application/json' | Out-Null
        Write-Host '  CA scope updated (break-glass still excluded).' -ForegroundColor Green
    }
}

if ($WhatIf) { Write-Host "`nNo changes made (WhatIf). Re-run with -Apply to commit." -ForegroundColor Yellow }
else { Write-Host "`nScope targeting complete. Re-run MACBYOD-Report.ps1 to confirm the new posture." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
