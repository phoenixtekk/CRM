<#
.SYNOPSIS
    MCAONB-ScopePolicy.ps1 — scope the Conditional Access App Control policy to the MDCA pilot
    user group. SAFE PREVIEW by default (-WhatIf); changes are applied only with -Apply.
.DESCRIPTION
    PURPOSE
        Change helper for the "Onboarding Accelerator — Microsoft Defender for Cloud Apps" solution.
        Ensures the Conditional Access policy 'MDCA Session Control - Pilot Users - Report' targets
        ONLY the pilot user group 'MDCA Pilot Users - Pilot Ring - Pilot' and is left in report-only
        (CA state = enabledForReportingButNotEnforced) during the pilot. This is the only script
        that can change configuration, and it defaults to a safe preview.
    HOW TO RUN
        # Preview (default — shows what WOULD change, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\MCAONB-ScopePolicy.ps1 `
            -PolicyName 'MDCA Session Control - Pilot Users - Report' -GroupName 'MDCA Pilot Users - Pilot Ring - Pilot'
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\MCAONB-ScopePolicy.ps1 `
            -PolicyName 'MDCA Session Control - Pilot Users - Report' -GroupName 'MDCA Pilot Users - Pilot Ring - Pilot' -Apply
        Requires Microsoft.Graph with Policy.ReadWrite.ConditionalAccess and Group.Read.All.
    EXPECTED RESULTS
        Preview: prints the resolved policy id, group id, and the scope it WOULD set (pilot only,
        report-only). Apply: updates the policy scope and leaves it report-only. Validate with
        MCAONB-Validate.ps1 -Check Policy.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. Keeps the policy report-only; enforcement is a
    separate, deliberate step after validation. Session controls are set in the MDCA portal.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PolicyName,
    [Parameter(Mandatory)] [string]$GroupName,
    [switch]$Apply
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.Read.All' -NoWelcome | Out-Null }

$whatIf = -not $Apply
Write-Host "`n=== MCAONB scope CA App Control policy to pilot ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will update policy scope' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

$grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)).value | Select-Object -First 1
if (-not $grp) { Write-Host ("Group '{0}' not found. Create it first (Implementation Step 1)." -f $GroupName) -ForegroundColor Red; return }
Write-Host ("Group : {0}  ({1})" -f $grp.displayName, $grp.id)

$pol = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?`$filter=displayName eq '{0}'" -f $PolicyName)).value | Select-Object -First 1
if (-not $pol) { Write-Host ("CA policy '{0}' not found. Create it per Implementation Step 5." -f $PolicyName) -ForegroundColor Yellow; return }
Write-Host ("Policy: {0}  ({1})  state={2}" -f $pol.displayName, $pol.id, $pol.state)

if ($whatIf) {
    Write-Host "`nWOULD set conditions.users.includeGroups = [pilot group] and state = enabledForReportingButNotEnforced." -ForegroundColor Yellow
    Write-Host "Re-run with -Apply to update the policy. Session controls are configured in the MDCA portal." -ForegroundColor Yellow
    return
}

$body = @{
    conditions = @{ users = @{ includeGroups = @($grp.id) } }
    state      = 'enabledForReportingButNotEnforced'
} | ConvertTo-Json -Depth 6
try {
    Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/{0}" -f $pol.id) -Body $body -ContentType 'application/json' | Out-Null
    Write-Host "`nAPPLIED — policy scoped to the pilot group and left report-only. Validate with MCAONB-Validate.ps1 -Check Policy." -ForegroundColor Green
} catch { Write-Host ("Update failed: {0}" -f $_.Exception.Message) -ForegroundColor Red }
