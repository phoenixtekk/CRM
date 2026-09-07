<#
.SYNOPSIS
    List Conditional Access policies that target the enrollment cloud apps — Microsoft Intune Enrollment
    and Microsoft Intune — and could block or gate the enrollment sign-in (Phase 2D).

.DESCRIPTION
    Reads Get-MgIdentityConditionalAccessPolicy and reports every enabled policy whose included
    applications contain the Microsoft Intune Enrollment app (d4ebce55-015a-49b5-a083-c84d1797ae8c),
    the Microsoft Intune app (0000000a-0000-0000-c000-000000000000), or All, with its grant controls —
    so you can spot a block, or a "require compliant device" grant a not-yet-enrolled device cannot meet.

.HOW TO RUN
    .\ENRLDX-Get-EnrollmentCA.ps1
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    A table of CA policies affecting enrollment, their state, grant controls, and whether they block.

.NOTES
    Intune Solutions — read-only diagnostic (Microsoft Graph). Scope: Policy.Read.All. The failed
    sign-in's Conditional Access tab is the definitive per-attempt evidence.
#>
[CmdletBinding()]
param(
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes 'Policy.Read.All' -Environment $Environment -NoWelcome

$enrollApp = 'd4ebce55-015a-49b5-a083-c84d1797ae8c'  # Microsoft Intune Enrollment
$intuneApp = '0000000a-0000-0000-c000-000000000000'  # Microsoft Intune
$targets   = @($enrollApp, $intuneApp, 'All')

$policies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
$hits = foreach ($p in $policies) {
    $inc = @($p.Conditions.Applications.IncludeApplications)
    $match = $inc | Where-Object { $targets -contains $_ }
    if (-not $match) { continue }
    $grants = @($p.GrantControls.BuiltInControls)
    [pscustomobject]@{
        Name     = $p.DisplayName
        State    = $p.State
        Includes = ($inc -join ',')
        Grants   = ($grants -join ';')
        Blocks   = [bool]($grants -contains 'block')
    }
}
if (-not $hits) { Write-Host "No CA policy targets the enrollment apps (or 'All'). CA is not the cause (Phase 2D clear)." -ForegroundColor Green; return }

$hits | Format-Table Name,State,Grants,Blocks,Includes -AutoSize
$risky = $hits | Where-Object { $_.State -eq 'enabled' -and ($_.Blocks -or $_.Grants -match 'compliantDevice|domainJoinedDevice') }
if ($risky) {
    Write-Host "`nPolicies that can block enrollment (block, or require compliant/hybrid device a new device can't meet):" -ForegroundColor Yellow
    $risky | ForEach-Object { Write-Host "  - $($_.Name)  [$($_.Grants)]" -ForegroundColor Yellow }
    Write-Host "Exclude the enrollment apps/user rather than disabling the policy (Phase 2D)." -ForegroundColor Yellow
}
