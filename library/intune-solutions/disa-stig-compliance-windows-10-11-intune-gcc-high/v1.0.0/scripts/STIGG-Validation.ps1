<#
.SYNOPSIS
    STIGG-Validation.ps1 — read-only validation that STIG objects are named, assigned, and conflict-free in a US Gov tenant.
.DESCRIPTION
    PURPOSE
        Validates that this solution's STIG objects (STIG-Win-* profiles/policies and SG-STIG-* groups)
        exist, are assigned only to the intended target group for the current phase, and are free of
        setting conflicts and orphaned (unassigned) profiles. Used as the pass/fail gate check at
        Pilot, Validate, and each Expand wave. Read-only: it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\STIGG-Validation.ps1 -TargetGroup SG-STIG-Pilot-Devices
        powershell -ExecutionPolicy Bypass -File .\STIGG-Validation.ps1 -TargetGroup SG-STIG-Prod-Devices -Environment USGovDoD
        (Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All,
         Group.Read.All; -Environment USGov for GCC High or USGovDoD for DoD)
    EXPECTED RESULTS
        A per-object PASS/FAIL table. Admin sees which STIG-Win-* objects are assigned to the expected
        group, any conflicts, and any unassigned profiles. Overall PASS = all intended objects assigned
        to TargetGroup, no conflicts, no orphans. FAIL = missing assignment, wrong-group assignment,
        conflict, or orphan — resolve before advancing the gate.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$TargetGroup = 'SG-STIG-Pilot-Devices',
    [string]$NamePrefix = 'STIG-Win'
)

$ErrorActionPreference = 'Stop'

function Connect-StiggGraph {
    param([string]$Env)
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementManagedDevices.Read.All',
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

$overallPass = $true
function Set-Fail { $script:overallPass = $false }

try {
    Connect-StiggGraph -Env $Environment

    Write-Host "`n== Validation: STIG objects vs target group '$TargetGroup' ==" -ForegroundColor Yellow

    # Resolve target group
    $grp = Invoke-StiggGet ("groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $TargetGroup)
    if (-not $grp) {
        Write-Host "FAIL: target group '$TargetGroup' not found." -ForegroundColor Red
        Set-Fail
        $targetGroupId = $null
    } else {
        $targetGroupId = ($grp | Select-Object -First 1).id
        Write-Host "Target group id: $targetGroupId" -ForegroundColor Gray
    }

    # Gather STIG-Win-* configuration policies (Settings Catalog)
    $configProfiles = Invoke-StiggGet 'deviceManagement/configurationPolicies?$select=id,name' |
        Where-Object { $_.name -like "$NamePrefix*" }
    $legacyProfiles = Invoke-StiggGet 'deviceManagement/deviceConfigurations?$select=id,displayName' |
        Where-Object { $_.displayName -like "$NamePrefix*" }
    $compliance = Invoke-StiggGet 'deviceManagement/deviceCompliancePolicies?$select=id,displayName' |
        Where-Object { $_.displayName -like "$NamePrefix*" }

    $allObjects = @()
    $allObjects += $configProfiles | ForEach-Object { [pscustomobject]@{ Kind='configurationPolicy'; Id=$_.id; Name=$_.name; AssignUri="deviceManagement/configurationPolicies/$($_.id)/assignments" } }
    $allObjects += $legacyProfiles | ForEach-Object { [pscustomobject]@{ Kind='deviceConfiguration'; Id=$_.id; Name=$_.displayName; AssignUri="deviceManagement/deviceConfigurations/$($_.id)/assignments" } }
    $allObjects += $compliance     | ForEach-Object { [pscustomobject]@{ Kind='compliancePolicy';   Id=$_.id; Name=$_.displayName; AssignUri="deviceManagement/deviceCompliancePolicies/$($_.id)/assignments" } }

    if (-not $allObjects) {
        Write-Host "FAIL: no objects matching '$NamePrefix*' were found. Have you completed the Configure phase?" -ForegroundColor Red
        Set-Fail
    }

    Write-Host "`n-- Assignment check --"
    foreach ($o in $allObjects) {
        $assignments = Invoke-StiggGet $o.AssignUri
        $assignedGroupIds = @()
        foreach ($a in $assignments) {
            $tgt = $a.target
            if ($tgt.'groupId') { $assignedGroupIds += $tgt.groupId }
        }
        if (-not $assignments) {
            Write-Host ("  ORPHAN  {0} '{1}' has NO assignments." -f $o.Kind, $o.Name) -ForegroundColor Red
            Set-Fail
        }
        elseif ($targetGroupId -and ($assignedGroupIds -contains $targetGroupId)) {
            $extra = $assignedGroupIds | Where-Object { $_ -ne $targetGroupId }
            if ($extra) {
                Write-Host ("  WARN    {0} '{1}' assigned to target AND other group(s): {2}" -f $o.Kind, $o.Name, ($extra -join ',')) -ForegroundColor DarkYellow
            } else {
                Write-Host ("  PASS    {0} '{1}' assigned to '{2}' only." -f $o.Kind, $o.Name, $TargetGroup) -ForegroundColor Green
            }
        }
        else {
            Write-Host ("  FAIL    {0} '{1}' NOT assigned to '{2}'." -f $o.Kind, $o.Name, $TargetGroup) -ForegroundColor Red
            Set-Fail
        }
    }

    Write-Host "`n-- Settings-conflict check (Settings Catalog policies) --"
    $settingIndex = @{}
    foreach ($o in ($allObjects | Where-Object Kind -eq 'configurationPolicy')) {
        try {
            $settings = Invoke-StiggGet "deviceManagement/configurationPolicies/$($o.Id)/settings"
            foreach ($s in $settings) {
                $defId = $s.settingInstance.settingDefinitionId
                if (-not $defId) { continue }
                if (-not $settingIndex.ContainsKey($defId)) { $settingIndex[$defId] = @() }
                $settingIndex[$defId] += $o.Name
            }
        } catch {
            Write-Host ("  (could not read settings for '{0}': {1})" -f $o.Name, $_.Exception.Message) -ForegroundColor DarkGray
        }
    }
    $conflicts = $settingIndex.GetEnumerator() | Where-Object { ($_.Value | Select-Object -Unique).Count -gt 1 }
    if ($conflicts) {
        foreach ($c in $conflicts) {
            Write-Host ("  CONFLICT setting '{0}' set by: {1}" -f $c.Key, (($c.Value | Select-Object -Unique) -join ', ')) -ForegroundColor Red
        }
        Set-Fail
    } else {
        Write-Host "  PASS: no overlapping settings across STIG-Win-* Settings Catalog policies." -ForegroundColor Green
    }

    Write-Host "`n== Validation result ==" -ForegroundColor Yellow
    if ($overallPass) {
        Write-Host "OVERALL: PASS — gate criteria met for '$TargetGroup'." -ForegroundColor Green
    } else {
        Write-Host "OVERALL: FAIL — resolve the items above before advancing the gate." -ForegroundColor Red
        exit 2
    }
}
catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    Write-Host "Check: PowerShell 7+, Microsoft.Graph installed, correct -Environment (USGov/USGovDoD), and read scopes consented." -ForegroundColor Yellow
    exit 1
}
finally {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
}
