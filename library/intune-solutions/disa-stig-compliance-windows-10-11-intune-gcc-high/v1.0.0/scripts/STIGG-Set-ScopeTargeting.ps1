<#
.SYNOPSIS
    STIGG-Set-ScopeTargeting.ps1 — build STIG target groups and assign STIG objects to them in a US Gov tenant (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates this solution's Entra device security groups (SG-STIG-Pilot-Devices, SG-STIG-Prod-Devices)
        if missing, and bulk-assigns the STIG-Win-* profiles/policies to a chosen target group for the
        current phase (pilot, then prod expansion waves). Defaults to -WhatIf, so it only PREVIEWS actions;
        nothing changes until you re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (safe):  powershell -ExecutionPolicy Bypass -File .\STIGG-Set-ScopeTargeting.ps1 -TargetGroup SG-STIG-Pilot-Devices -CreateGroups
        Apply:           powershell -ExecutionPolicy Bypass -File .\STIGG-Set-ScopeTargeting.ps1 -TargetGroup SG-STIG-Pilot-Devices -CreateGroups -WhatIf:$false
        DoD tenant:      add -Environment USGovDoD
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.ReadWrite.All;
         -Environment USGov for GCC High or USGovDoD for DoD)
    EXPECTED RESULTS
        A list of planned group creations and profile assignments. In preview (default) admin sees
        "WHATIF: would ..." lines and nothing is modified. With -WhatIf:$false, groups are created and
        STIG-Win-* objects are assigned to TargetGroup. PASS = groups exist and objects are assigned.
        Confirm with STIGG-Validation.ps1.
.NOTES
    White-label — the repeatable way. Change-making; defaults to -WhatIf. Targets Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$TargetGroup = 'SG-STIG-Pilot-Devices',
    [string]$NamePrefix = 'STIG-Win',

    [switch]$CreateGroups,
    [string[]]$GroupsToEnsure = @('SG-STIG-Pilot-Devices', 'SG-STIG-Prod-Devices')
)

# Default to preview unless the caller explicitly sets -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

function Connect-StiggGraph {
    param([string]$Env)
    $scopes = @(
        'DeviceManagementConfiguration.ReadWrite.All',
        'Group.ReadWrite.All'
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

function Get-GroupIdByName {
    param([string]$Name)
    $g = Invoke-StiggGet ("groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $Name)
    if ($g) { return ($g | Select-Object -First 1).id }
    return $null
}

try {
    if ($WhatIfPreference) {
        Write-Host "RUNNING IN PREVIEW (-WhatIf). No changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    } else {
        Write-Host "RUNNING IN APPLY MODE (-WhatIf:`$false). Approved changes WILL be made." -ForegroundColor Red
    }

    Connect-StiggGraph -Env $Environment

    # 1) Ensure groups (assigned, security-enabled device groups)
    if ($CreateGroups) {
        Write-Host "`n-- Ensure target groups --"
        foreach ($gName in $GroupsToEnsure) {
            $existingId = Get-GroupIdByName -Name $gName
            if ($existingId) {
                Write-Host ("  OK      group '{0}' exists ({1})." -f $gName, $existingId) -ForegroundColor Green
                continue
            }
            $mailNick = ($gName -replace '[^a-zA-Z0-9]', '')
            $groupBody = @{
                displayName     = $gName
                description     = "STIG targeting group (created by STIGG-Set-ScopeTargeting.ps1)."
                mailEnabled     = $false
                mailNickname    = $mailNick
                securityEnabled = $true
                groupTypes      = @()
            }
            if ($PSCmdlet.ShouldProcess($gName, "Create security group")) {
                $new = Invoke-MgGraphRequest -Method POST -Uri "/beta/groups" -Body ($groupBody | ConvertTo-Json -Depth 4)
                Write-Host ("  CREATED group '{0}' ({1}). Add device members in portal.azure.us." -f $gName, $new.id) -ForegroundColor Green
            } else {
                Write-Host ("  WHATIF: would create security group '{0}'." -f $gName) -ForegroundColor Yellow
            }
        }
    }

    # 2) Resolve the target group for assignment
    $targetGroupId = Get-GroupIdByName -Name $TargetGroup
    if (-not $targetGroupId) {
        if ($WhatIfPreference) {
            Write-Host ("`n(Preview) Target group '{0}' does not exist yet — it would be created above in apply mode. Skipping assignment preview resolution." -f $TargetGroup) -ForegroundColor Yellow
            return
        }
        throw "Target group '$TargetGroup' not found. Re-run with -CreateGroups."
    }

    # 3) Assign STIG-Win-* configuration policies to the target group (additive)
    Write-Host "`n-- Assign STIG-Win-* configuration policies to '$TargetGroup' --"
    $configProfiles = Invoke-StiggGet 'deviceManagement/configurationPolicies?$select=id,name' | Where-Object { $_.name -like "$NamePrefix*" }
    if (-not $configProfiles) { Write-Host "  No '$NamePrefix*' configuration policies found — create them in the Configure phase first." -ForegroundColor Yellow }

    foreach ($p in $configProfiles) {
        $assignUri = "deviceManagement/configurationPolicies/$($p.id)/assignments"
        $assignments = Invoke-StiggGet $assignUri
        $assignedGroupIds = @()
        foreach ($a in $assignments) { if ($a.target.'groupId') { $assignedGroupIds += $a.target.groupId } }

        if ($assignedGroupIds -contains $targetGroupId) {
            Write-Host ("  OK      '{0}' already assigned to '{1}'." -f $p.name, $TargetGroup) -ForegroundColor Green
            continue
        }

        $desiredGroupIds = @($assignedGroupIds + $targetGroupId | Select-Object -Unique)
        $assignmentBody = @{
            assignments = @($desiredGroupIds | ForEach-Object {
                @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $_ } }
            })
        }
        if ($PSCmdlet.ShouldProcess($p.name, "Assign to $TargetGroup")) {
            Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/assign" -Body ($assignmentBody | ConvertTo-Json -Depth 6) | Out-Null
            Write-Host ("  ASSIGNED '{0}' -> '{1}'." -f $p.name, $TargetGroup) -ForegroundColor Green
        } else {
            Write-Host ("  WHATIF: would assign '{0}' -> '{1}'." -f $p.name, $TargetGroup) -ForegroundColor Yellow
        }
    }

    Write-Host "`nScope-targeting pass complete. Confirm with STIGG-Validation.ps1 -TargetGroup $TargetGroup." -ForegroundColor Cyan
    if ($WhatIfPreference) { Write-Host "(Preview only — nothing was changed.)" -ForegroundColor Yellow }
}
catch {
    Write-Error "Scope-targeting failed: $($_.Exception.Message)"
    Write-Host "Check: PowerShell 7+, Microsoft.Graph installed, correct -Environment (USGov/USGovDoD), ReadWrite scopes consented." -ForegroundColor Yellow
    exit 1
}
finally {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
}
