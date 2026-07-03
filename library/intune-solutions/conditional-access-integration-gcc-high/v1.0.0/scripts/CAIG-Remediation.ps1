<#
.SYNOPSIS
    CAIG-Remediation.ps1 — safe CA fixes on GCC High (revert-to-report-only + break-glass exclude). Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Two safe, reversible remediations for a GCC High tenant:
        (1) revert a runaway Conditional Access policy back to Report-only (stops enforcement without
            deleting the policy), and (2) add your break-glass emergency-access accounts to a
            policy's exclusions. Change-making — so it DEFAULTS TO -WhatIf and only writes when you
            pass -Apply. Nothing is deleted.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\CAIG-Remediation.ps1 -PolicyName 'CA - Require MFA - All Apps (Gov)' -RevertToReportOnly
        Apply for real:
          powershell -ExecutionPolicy Bypass -File .\CAIG-Remediation.ps1 -PolicyName 'CA - Require MFA - All Apps (Gov)' -RevertToReportOnly -Apply
        Add break-glass exclusions:
          powershell -ExecutionPolicy Bypass -File .\CAIG-Remediation.ps1 -PolicyName 'CA - Block Legacy Auth (Gov)' -ExcludeBreakGlass -Upns bg1@your-tenant.onmicrosoft.us,bg2@your-tenant.onmicrosoft.us -Apply
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov with Policy.ReadWrite.ConditionalAccess + User.Read.All.
    EXPECTED RESULTS
        WhatIf mode prints the intended change and makes none. With -Apply the policy is updated and
        the new state / exclusions are confirmed.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless -Apply is passed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [switch]$RevertToReportOnly,
    [switch]$ExcludeBreakGlass,
    [string[]]$Upns,
    [switch]$Apply,
    [switch]$WhatIf = $true
)
if ($Apply) { $WhatIf = $false }
if (-not ($RevertToReportOnly -or $ExcludeBreakGlass)) { Write-Host "Specify -RevertToReportOnly and/or -ExcludeBreakGlass." -ForegroundColor Yellow; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.ReadWrite.ConditionalAccess','User.Read.All' -NoWelcome
if ((Get-MgContext).Environment -ne 'USGov') { Write-Host "WRONG CLOUD: not USGov. Reconnect with -Environment USGov." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$mode = $(if ($WhatIf) { '[WHATIF] ' } else { '[APPLY] ' })
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$p = $pols | Where-Object displayName -eq $PolicyName | Select-Object -First 1
if (-not $p) { Write-Host "Policy not found: $PolicyName" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
$pid = $p.id

if ($RevertToReportOnly) {
    Write-Host ("{0}Revert '{1}' state '{2}' -> 'enabledForReportingButNotEnforced'" -f $mode, $PolicyName, $p.state) -ForegroundColor Cyan
    if (-not $WhatIf) {
        Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/identity/conditionalAccess/policies/$pid" -Body (@{ state = 'enabledForReportingButNotEnforced' } | ConvertTo-Json)
        Write-Host "  Reverted to Report-only." -ForegroundColor Green
    }
}

if ($ExcludeBreakGlass) {
    if (-not $Upns) { Write-Host "-ExcludeBreakGlass requires -Upns." -ForegroundColor Yellow }
    else {
        $ex = @($p.conditions.users.excludeUsers)
        $add = @()
        foreach ($u in $Upns) {
            try { $id = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$u").id } catch { Write-Host "  User not found: $u" -ForegroundColor Red; continue }
            if ($ex -notcontains $id) { $add += $id; Write-Host ("{0}Add exclusion: {1}" -f $mode, $u) -ForegroundColor Cyan }
            else { Write-Host ("  Already excluded: {0}" -f $u) -ForegroundColor Green }
        }
        if ($add.Count -gt 0 -and -not $WhatIf) {
            $newEx = @($ex + $add | Select-Object -Unique)
            $body = @{ conditions = @{ users = @{ excludeUsers = $newEx } } } | ConvertTo-Json -Depth 6
            Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/identity/conditionalAccess/policies/$pid" -Body $body
            Write-Host "  Exclusions updated." -ForegroundColor Green
        }
    }
}

if ($WhatIf) { Write-Host "`nNo changes made (WhatIf). Re-run with -Apply to commit." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null
