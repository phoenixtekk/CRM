<#
.SYNOPSIS
    SENTDEPG-Set-Retention.ps1 — preview/apply the table plan: log tier (Analytics vs Basic/Auxiliary) and retention/archive per table (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Applies the R7 table plan: for each table, the intended log TIER (Analytics for detection-driving
        data; Basic/Auxiliary for high-volume low-signal data) and the interactive RETENTION + total
        (archive) retention in days. It runs in PREVIEW (-WhatIf) by default, printing the plan vs the
        live state; only -Commit applies changes. Notes where Basic/Auxiliary eligibility must be
        verified per table.
    HOW TO RUN
        # Preview (default):
        pwsh -File .\SENTDEPG-Set-Retention.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -PlanPath .\table-plan.csv
        # Apply:
        pwsh -File .\SENTDEPG-Set-Retention.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -PlanPath .\table-plan.csv -Commit

        The plan CSV columns: TableName,Plan,RetentionInDays,TotalRetentionInDays
          Plan = Analytics | Basic | Auxiliary   (verify tier eligibility for each table in your tenant)
        Prereqs: Az.OperationalInsights and Microsoft Sentinel Contributor (or Log Analytics Contributor)
        on the workspace.
    EXPECTED RESULTS
        A per-table table of Plan vs Current; with -Commit, tables are moved to the target tier and
        retention. Detection-driving tables stay on Analytics; low-signal tables move to Basic/Auxiliary.
.NOTES
    White-label. -WhatIf by default; -Commit gates any change. Az PowerShell. No credentials in code.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string] $PlanPath,
    [switch] $Commit,
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
if (-not $Commit) { $WhatIfPreference = $true }
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Default illustrative plan if no CSV supplied — EDIT to your environment; verify tier eligibility.
$defaultPlan = @(
    [pscustomobject]@{ TableName='SigninLogs';        Plan='Analytics'; RetentionInDays=90;  TotalRetentionInDays=365 }
    [pscustomobject]@{ TableName='AuditLogs';         Plan='Analytics'; RetentionInDays=90;  TotalRetentionInDays=365 }
    [pscustomobject]@{ TableName='AzureActivity';     Plan='Analytics'; RetentionInDays=90;  TotalRetentionInDays=365 }
    [pscustomobject]@{ TableName='SecurityIncident';  Plan='Analytics'; RetentionInDays=180; TotalRetentionInDays=730 }
    [pscustomobject]@{ TableName='CommonSecurityLog'; Plan='Analytics'; RetentionInDays=90;  TotalRetentionInDays=365 }
    [pscustomobject]@{ TableName='Syslog';            Plan='Basic';     RetentionInDays=30;  TotalRetentionInDays=90  }
)

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop | Out-Null
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

$plan = if ($PlanPath -and (Test-Path $PlanPath)) { Import-Csv $PlanPath } else {
    Write-Host 'No -PlanPath supplied; using the built-in illustrative plan. EDIT it for your environment.' -ForegroundColor Yellow
    $defaultPlan
}

if (-not $Commit) {
    Write-Host ''
    Write-Host 'PREVIEW MODE (-WhatIf). No changes will be made. Re-run with -Commit to apply.' -ForegroundColor Yellow
}

Write-Section 'Table plan (intended) vs current'
foreach ($row in $plan) {
    $cur = $null
    try { $cur = Get-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -TableName $row.TableName -ErrorAction SilentlyContinue } catch {}
    $curPlan = if ($cur) { $cur.Plan } else { '(absent)' }
    $curRet  = if ($cur) { $cur.RetentionInDays } else { '-' }
    Write-Host ("  {0,-20} plan {1,-9} ret {2,4}/{3,-4}   current: {4}/{5}" -f `
        $row.TableName, $row.Plan, $row.RetentionInDays, $row.TotalRetentionInDays, $curPlan, $curRet)
    if ($row.Plan -in 'Basic','Auxiliary') {
        Write-Host ("      note: verify {0} is eligible for the {1} tier in your tenant." -f $row.TableName, $row.Plan) -ForegroundColor DarkYellow
    }
}

Write-Section 'Apply'
foreach ($row in $plan) {
    try {
        if ($PSCmdlet.ShouldProcess($row.TableName, ("Set tier={0} retention={1}/{2}" -f $row.Plan, $row.RetentionInDays, $row.TotalRetentionInDays))) {
            Update-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName `
                -TableName $row.TableName -Plan $row.Plan `
                -RetentionInDays ([int]$row.RetentionInDays) -TotalRetentionInDays ([int]$row.TotalRetentionInDays) -ErrorAction Stop | Out-Null
            Write-Host ("  applied: {0}" -f $row.TableName) -ForegroundColor Green
        }
    }
    catch {
        Write-Warning ("  {0}: {1}" -f $row.TableName, $_.Exception.Message)
        Write-Host '      (tier change may not be supported for this table — verify eligibility.)'
    }
}

Write-Section 'Done'
if (-not $Commit) { Write-Host 'Preview complete. Re-run with -Commit to apply.' -ForegroundColor Yellow }
else { Write-Host 'Apply complete. Confirm in Sentinel -> Logs -> Tables, and re-run SENTDEPG-Validate.ps1 (Gate 7).' -ForegroundColor Green }
