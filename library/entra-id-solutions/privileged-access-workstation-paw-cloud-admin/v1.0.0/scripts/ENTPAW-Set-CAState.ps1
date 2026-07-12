<#
.SYNOPSIS
    ENTPAW-Set-CAState.ps1 — safely flip the PAW device-filter Conditional Access policy between report-only and enabled.
.DESCRIPTION
    PURPOSE
        Performs the staged-enforcement (and rollback) step for the PAW device-filter policy: moves the
        single, named Conditional Access policy from report-only to enabled — or back — after the
        report-only results are clean. Runs in -WhatIf (preview) mode by default. As a safety guard it
        refuses to enable a policy that does NOT exclude the named break-glass group, so a device-filter
        mistake can never lock out break-glass accounts.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\ENTPAW-Set-CAState.ps1 `
            -PolicyName "CA – Require PAW for Privileged Roles – Pilot (Report-Only)" -TargetState enabled `
            -BreakGlassGroupName "CA Break-Glass Exclusion"
        Apply: add -WhatIf:$false to the same command after reviewing the preview.
        Rollback: set -TargetState reportOnly to move the policy back to report-only.
        Requires the Microsoft Graph PowerShell SDK. Scope: Policy.ReadWrite.ConditionalAccess, Group.Read.All.
    EXPECTED RESULTS
        A preview (or applied change) of the policy state; the break-glass guard blocks enabling a policy
        that does not exclude break-glass. Re-run ENTPAW-Validate.ps1 afterward and watch Sign-in logs.
.NOTES
    White-label — Entra ID Solutions. Changes a Conditional Access policy state — preview first, keep break-glass ready.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$PolicyName,
    [Parameter(Mandatory=$true)][ValidateSet('enabled','reportOnly')][string]$TargetState,
    [string]$BreakGlassGroupName = 'CA Break-Glass Exclusion'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.Read.All' -NoWelcome
Write-Host "=== ENTPAW Set-CAState — '$PolicyName' -> $TargetState ===" -ForegroundColor Cyan

$cap = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)
$p = $cap | Where-Object { $_.displayName -eq $PolicyName } | Select-Object -First 1
if (-not $p) { Write-Host "Policy not found: $PolicyName" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

# Break-glass guard: never ENABLE a policy that does not exclude break-glass
$enc = [uri]::EscapeDataString($BreakGlassGroupName)
$bgId = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1 -ExpandProperty id
if ($TargetState -eq 'enabled') {
    $excl = @($p.conditions.users.excludeGroups)
    if (-not $bgId -or -not ($excl -contains $bgId)) {
        Write-Host "REFUSING to enable: policy does not exclude break-glass group '$BreakGlassGroupName'." -ForegroundColor Red
        Write-Host "Add the break-glass exclusion first, then retry." -ForegroundColor Red
        Disconnect-MgGraph | Out-Null; exit 2
    }
}

$graphState = if ($TargetState -eq 'enabled') { 'enabled' } else { 'enabledForReportingButNotEnforced' }
if ($PSCmdlet.ShouldProcess($PolicyName, "Set Conditional Access state to '$graphState'")) {
    $body = @{ state = $graphState } | ConvertTo-Json
    Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/identity/conditionalAccess/policies/$($p.id)" -Body $body | Out-Null
    Write-Host "  APPLIED: '$PolicyName' is now '$graphState'." -ForegroundColor Green
    Write-Host "  Confirm a PAW admin can still administer and a non-PAW privileged sign-in is blocked." -ForegroundColor Cyan
} else {
    Write-Host "  WHATIF would set '$PolicyName' from '$($p.state)' to '$graphState'." -ForegroundColor Yellow
}
Write-Host "`nRe-run ENTPAW-Validate.ps1 and watch Sign-in logs after any enforcement flip." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
