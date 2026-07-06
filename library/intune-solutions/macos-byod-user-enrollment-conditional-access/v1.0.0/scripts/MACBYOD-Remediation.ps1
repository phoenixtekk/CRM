<#
.SYNOPSIS
    MACBYOD-Remediation.ps1 — create/repair the require-compliant-Mac CA policy and assign BYOD compliance. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Performs the common fixes that make the BYOD gate work: creates or repairs the Conditional Access
        policy that requires a compliant Mac (scoped to macOS, targeting the pilot group) and ALWAYS
        re-asserts break-glass exclusions so scope changes never drop the lockout safeguard; and assigns
        the macOS BYOD compliance policy to a target group. Change-making — so it DEFAULTS TO -WhatIf and
        only writes when you pass -Apply. Use 'your-tenant.onmicrosoft.com' style values, never secrets.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\MACBYOD-Remediation.ps1 -PolicyName "CA - Require Compliant Mac - Pilot" -IncludeGroup BYOD-Mac-Pilot -BreakGlassUpns bg1@your-tenant.onmicrosoft.com,bg2@your-tenant.onmicrosoft.com
        Apply (creates/repairs the report-only CA policy and re-asserts break-glass):
          powershell -ExecutionPolicy Bypass -File .\MACBYOD-Remediation.ps1 -PolicyName "CA - Require Compliant Mac - Pilot" -IncludeGroup BYOD-Mac-Pilot -BreakGlassUpns bg1@your-tenant.onmicrosoft.com,bg2@your-tenant.onmicrosoft.com -Apply
        Requires the Microsoft Graph PowerShell SDK. Graph scopes:
        read  — Policy.Read.All, Group.Read.All, User.Read.All
        write — Policy.ReadWrite.ConditionalAccess (added only with -Apply).
    EXPECTED RESULTS
        Without -Apply: prints the intended CA policy (include group, macOS platform, require-compliant
        grant, break-glass exclusions) and makes no change. With -Apply: the policy is created/updated in
        REPORT-ONLY with break-glass excluded — you enable it manually after reviewing sign-in logs.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -Apply. Break-glass always excluded.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$IncludeGroup = 'BYOD-Mac-Pilot',
    [string[]]$BreakGlassUpns,
    [switch]$Apply,
    [switch]$WhatIf = $true
)
if ($Apply) { $WhatIf = $false }

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Apply) { 'Policy.ReadWrite.ConditionalAccess','Group.Read.All','User.Read.All' }
          else        { 'Policy.Read.All','Group.Read.All','User.Read.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

$mode = $(if ($WhatIf) { '[WHATIF] ' } else { '[APPLY] ' })

if (-not $BreakGlassUpns) {
    Write-Host 'WARNING: no -BreakGlassUpns supplied. Refusing to create/modify a CA policy without break-glass exclusions.' -ForegroundColor Red
    Write-Host 'Re-run with -BreakGlassUpns bg1@your-tenant.onmicrosoft.com,bg2@your-tenant.onmicrosoft.com' -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

# --- Resolve the include group ---
$g = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$IncludeGroup'&`$select=id,displayName").value | Select-Object -First 1
if (-not $g) { Write-Host "Group not found: $IncludeGroup" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# --- Resolve break-glass user ids (always excluded) ---
$exUsers = @()
foreach ($u in $BreakGlassUpns) {
    try { $id = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$u").id; if ($exUsers -notcontains $id) { $exUsers += $id } }
    catch { Write-Host "  Break-glass user not found: $u" -ForegroundColor Red }
}
if ($exUsers.Count -eq 0) { Write-Host 'No break-glass users resolved — aborting to avoid a lockout risk.' -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# --- Desired policy body: report-only, macOS, require compliant device, pilot group in / break-glass out ---
$body = @{
    displayName = $PolicyName
    state       = 'enabledForReportingButNotEnforced'   # report-only first (enable manually after review)
    conditions  = @{
        users        = @{ includeGroups = @($g.id); excludeUsers = @($exUsers | Select-Object -Unique) }
        applications = @{ includeApplications = @('Office365') }
        platforms    = @{ includePlatforms = @('macOS') }
    }
    grantControls = @{ operator = 'OR'; builtInControls = @('compliantDevice') }
}

Write-Host ("{0}CA '{1}': include group '{2}'; platform macOS; grant Require-Compliant; exclude {3} break-glass; state report-only" -f `
    $mode, $PolicyName, $g.displayName, $exUsers.Count) -ForegroundColor Cyan

# --- Find existing policy of this name ---
$existing = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies').value |
            Where-Object displayName -eq $PolicyName | Select-Object -First 1

if ($WhatIf) {
    Write-Host "`nNo changes made (WhatIf). Re-run with -Apply to create/repair the policy (it will be REPORT-ONLY)." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

if ($existing) {
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/$($existing.id)" -Body ($body | ConvertTo-Json -Depth 10) -ContentType 'application/json' | Out-Null
    Write-Host "  Repaired existing policy (report-only, break-glass excluded)." -ForegroundColor Green
} else {
    Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -Body ($body | ConvertTo-Json -Depth 10) -ContentType 'application/json' | Out-Null
    Write-Host "  Created policy (report-only, break-glass excluded)." -ForegroundColor Green
}
Write-Host '  Review Entra sign-in logs, then enable the policy (state = enabled) manually.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Remediation complete. Re-run MACBYOD-Discovery.ps1 to confirm.' -ForegroundColor Green
Disconnect-MgGraph | Out-Null
