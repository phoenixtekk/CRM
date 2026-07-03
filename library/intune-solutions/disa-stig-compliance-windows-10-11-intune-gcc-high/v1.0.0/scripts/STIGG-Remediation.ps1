<#
.SYNOPSIS
    STIGG-Remediation.ps1 — safely fix drifted/misassigned STIG objects in a US Gov tenant (default -WhatIf preview).
.DESCRIPTION
    PURPOSE
        Applies approved remediation to this solution's STIG objects: re-adds a missing target-group
        assignment and (optionally) removes an unintended group assignment so a profile matches the
        phase's intended scope. Defaults to -WhatIf, so it only PREVIEWS actions; nothing changes until
        you re-run with -WhatIf:$false. It does not author or change STIG rule content — that stays with DISA.
    HOW TO RUN
        Preview (safe):  powershell -ExecutionPolicy Bypass -File .\STIGG-Remediation.ps1 -TargetGroup SG-STIG-Pilot-Devices
        Apply:           powershell -ExecutionPolicy Bypass -File .\STIGG-Remediation.ps1 -TargetGroup SG-STIG-Pilot-Devices -WhatIf:$false
        DoD tenant:      add -Environment USGovDoD
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.Read.All;
         -Environment USGov for GCC High or USGovDoD for DoD)
    EXPECTED RESULTS
        A list of planned assignment changes. In preview (default) admin sees "WHATIF: would ..." lines
        and nothing is modified. With -WhatIf:$false, approved assignments are added/removed and confirmed.
        PASS = each intended object ends assigned to TargetGroup. Re-run STIGG-Validation.ps1 to confirm.
.NOTES
    White-label — the repeatable way. Change-making; defaults to -WhatIf. Targets Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$TargetGroup = 'SG-STIG-Pilot-Devices',
    [string]$NamePrefix = 'STIG-Win',

    [switch]$RemoveUnintendedAssignments
)

# Default to preview unless the caller explicitly sets -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

function Connect-StiggGraph {
    param([string]$Env)
    $scopes = @(
        'DeviceManagementConfiguration.ReadWrite.All',
        'Group.Read.All'
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser (PowerShell 7+ recommended)."
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Connecting to Microsoft Graph (US Gov environment: $Env)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Connect-MgGraph did not establish a context." }
    Write-Host ("Connected as {0} (tenant {1})." -f $ctx.Account, $ctx.TenantId) -ForegroundColor Green
}

function Invoke-StiggGet {
    param([string]$RelativeUri)
    $results = @()
    $uri = "/beta/$RelativeUri"
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
    return $results
}

try {
    if ($WhatIfPreference) {
        Write-Host "RUNNING IN PREVIEW (-WhatIf). No changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    } else {
        Write-Host "RUNNING IN APPLY MODE (-WhatIf:`$false). Approved changes WILL be made." -ForegroundColor Red
    }

    Connect-StiggGraph -Env $Environment

    $grp = Invoke-StiggGet ("groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $TargetGroup)
    if (-not $grp) { throw "Target group '$TargetGroup' not found. Create it first (STIGG-Set-ScopeTargeting.ps1)." }
    $targetGroupId = ($grp | Select-Object -First 1).id
    Write-Host "Target group id: $targetGroupId" -ForegroundColor Gray

    # Only Settings Catalog configurationPolicies are remediated here (representative, reversible).
    $configProfiles = Invoke-StiggGet 'deviceManagement/configurationPolicies?$select=id,name' | Where-Object { $_.name -like "$NamePrefix*" }
    if (-not $configProfiles) { Write-Host "No '$NamePrefix*' configuration policies found — nothing to remediate." -ForegroundColor Yellow; return }

    foreach ($p in $configProfiles) {
        $assignUri = "deviceManagement/configurationPolicies/$($p.id)/assignments"
        $assignments = Invoke-StiggGet $assignUri
        $assignedGroupIds = @()
        foreach ($a in $assignments) { if ($a.target.'groupId') { $assignedGroupIds += $a.target.groupId } }

        $needsTarget = -not ($assignedGroupIds -contains $targetGroupId)
        $unintended  = if ($RemoveUnintendedAssignments) { $assignedGroupIds | Where-Object { $_ -ne $targetGroupId } } else { @() }

        if (-not $needsTarget -and -not $unintended) {
            Write-Host ("  OK      '{0}' already scoped correctly." -f $p.name) -ForegroundColor Green
            continue
        }

        # Build the desired assignment set
        $desiredGroupIds = @($targetGroupId)
        if (-not $RemoveUnintendedAssignments) {
            $desiredGroupIds = @($assignedGroupIds + $targetGroupId | Select-Object -Unique)
        }
        $assignmentBody = @{
            assignments = @($desiredGroupIds | ForEach-Object {
                @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $_ } }
            })
        }

        $action = "Set assignments of '$($p.name)' to group(s): $($desiredGroupIds -join ', ')"
        if ($PSCmdlet.ShouldProcess($p.name, $action)) {
            Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/assign" -Body ($assignmentBody | ConvertTo-Json -Depth 6) | Out-Null
            Write-Host ("  APPLIED '{0}' -> {1}" -f $p.name, ($desiredGroupIds -join ', ')) -ForegroundColor Green
        } else {
            Write-Host ("  WHATIF: would set '{0}' -> {1}" -f $p.name, ($desiredGroupIds -join ', ')) -ForegroundColor Yellow
        }
    }

    Write-Host "`nRemediation pass complete. Re-run STIGG-Validation.ps1 -TargetGroup $TargetGroup to confirm." -ForegroundColor Cyan
    if ($WhatIfPreference) { Write-Host "(Preview only — nothing was changed.)" -ForegroundColor Yellow }
}
catch {
    Write-Error "Remediation failed: $($_.Exception.Message)"
    Write-Host "Check: PowerShell 7+, Microsoft.Graph installed, correct -Environment (USGov/USGovDoD), ReadWrite scope consented." -ForegroundColor Yellow
    exit 1
}
finally {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
}
