<#
.SYNOPSIS
    OPSEXEC-Configure.ps1 - write the metric definition and register the scheduled collection (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Materializes the agreed metric set into "Exec Metrics - Compliance Signals - Definition" (a JSON
        file: KPIs, sources, thresholds, in-scope denominators, portal-only value owners/read-dates) and
        optionally registers the scheduled collection task "Exec Collector - Purview Signals - Scheduled".
        Safe by default: prints what it WOULD write/register; only -Commit changes anything. The only
        writes are a local file and a scheduled task - no Purview policy is changed, no secrets stored.
    HOW TO RUN
        powershell -File .\OPSEXEC-Configure.ps1 -DefinitionPath .\ExecMetrics.json -WhatIf
        powershell -File .\OPSEXEC-Configure.ps1 -DefinitionPath .\ExecMetrics.json -Commit
        powershell -File .\OPSEXEC-Configure.ps1 -RegisterSchedule -Cadence Monthly -ReportScript .\OPSEXEC-Report.ps1 -DefinitionPath .\ExecMetrics.json -WhatIf
    EXPECTED RESULTS
        -WhatIf prints the definition JSON and/or the schtasks command. -Commit writes the file and/or
        registers the task. -RegisterSchedule -Remove -Commit unregisters it (rollback).
.NOTES
    Purview category - Executive Dashboard. Writes gated behind -Commit. Keep Insider Risk values
    AGGREGATE/de-identified. No secrets. Pilot the definition (Stage=Pilot) before scheduling.
#>
[CmdletBinding(DefaultParameterSetName='Definition')]
param(
    [Parameter(Mandatory)] [string]$DefinitionPath,
    [string[]]$InScopeWorkloads = @('Exchange','SharePoint','OneDrive','Teams'),
    [string]$Cadence = 'Monthly',                 # Monthly | Weekly
    [string]$ReportScript,                        # path to OPSEXEC-Report.ps1 for the scheduled run
    [switch]$RegisterSchedule,
    [switch]$Remove,                              # with -RegisterSchedule -Commit: unregister the task
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
$writes = $Commit.IsPresent
function Note($m){ Write-Host $m -ForegroundColor $(if($writes){'Green'}else{'Yellow'}) }
$prefix = $(if($writes){'[COMMIT] '}else{'[WHATIF] '})

# A default, editable metric definition (thresholds/values are placeholders to agree with stakeholders)
$definition = [ordered]@{
    name        = 'Exec Metrics - Compliance Signals - Definition'
    generatedAt = (Get-Date).ToString('u')
    refreshWindowDays = 35
    inScope     = @{ workloads = $InScopeWorkloads }
    sections    = [ordered]@{
        posture = @(
            @{ kpi='Compliance Manager Score';        source='portal:ComplianceManager'; unit='percent'; thresholds=@{green=80;amber=60}; value=$null; readBy=$null; readDate=$null }
            @{ kpi='Improvement Actions Outstanding';  source='portal:ComplianceManager'; unit='count';   thresholds=@{green=10;amber=30};  value=$null; readBy=$null; readDate=$null }
            @{ kpi='Regulatory Assessments Active';     source='portal:ComplianceManager'; unit='count';   thresholds=@{green=3;amber=1};    value=$null; readBy=$null; readDate=$null }
        )
        dataRisk = @(
            @{ kpi='Sensitivity Label Coverage';       source='api:ContentExplorer';       unit='percent'; thresholds=@{green=70;amber=40} }
            @{ kpi='DLP High-Severity Matches (30d)';  source='api:ActivityExplorer';      unit='count';   thresholds=@{green=25;amber=75} }
            @{ kpi='Sensitive Items Detected';         source='api:ContentExplorer';       unit='count';   thresholds=@{green=0;amber=0} }
            @{ kpi='Retention Coverage';               source='api:RetentionPolicies';     unit='percent'; thresholds=@{green=90;amber=60} }
            @{ kpi='Insider Risk Active Alerts';       source='portal:InsiderRisk';        unit='count';   thresholds=@{green=5;amber=20}; note='AGGREGATE by severity only - no names'; value=$null; readBy=$null; readDate=$null }
            @{ kpi='DSPM Recommendations Open';        source='portal:DSPM';               unit='count';   thresholds=@{green=5;amber=15}; value=$null; readBy=$null; readDate=$null }
        )
        trend = @(
            @{ kpi='Compliance Score Trend';  source='trend:ExecTrendBaseline' }
            @{ kpi='DLP Match Trend';         source='trend:ExecTrendBaseline' }
            @{ kpi='Labeled-Content Trend';   source='trend:ExecTrendBaseline' }
            @{ kpi='Insider-Risk Alert Trend';source='trend:ExecTrendBaseline' }
        )
    }
}

if (-not $RegisterSchedule) {
    $json = $definition | ConvertTo-Json -Depth 8
    if (Test-Path $DefinitionPath) { Note "$prefix definition exists at $DefinitionPath - preserving existing values; review before overwrite." }
    if ($writes) {
        if (Test-Path $DefinitionPath) { Copy-Item $DefinitionPath "$DefinitionPath.bak" -Force; Note "Backed up existing definition to $DefinitionPath.bak" }
        $json | Set-Content -Path $DefinitionPath -Encoding UTF8
        Note "Wrote metric definition -> $DefinitionPath"
        Write-Host "Next: enter portal-only values (Compliance Manager score, Insider-Risk aggregate, DSPM) with readBy/readDate, then run OPSEXEC-Report.ps1 -Stage Pilot." -ForegroundColor Cyan
    } else {
        Write-Host "$prefix would write the following definition to $DefinitionPath :" -ForegroundColor Yellow
        Write-Host $json
    }
    return
}

# --- Schedule registration ---
if (-not $ReportScript) { $ReportScript = Join-Path (Split-Path -Parent $DefinitionPath) 'OPSEXEC-Report.ps1' }
$taskName = 'Exec Collector - Purview Signals - Scheduled'
if ($Remove) {
    $cmd = "schtasks /Delete /TN `"$taskName`" /F"
    if ($writes) { cmd /c $cmd; Note "Removed scheduled task '$taskName'" } else { Write-Host "$prefix would run: $cmd" -ForegroundColor Yellow }
    return
}
$sc = $(if($Cadence -eq 'Weekly'){'WEEKLY'}else{'MONTHLY'})
$action = "powershell -NoProfile -File `"$ReportScript`" -DefinitionPath `"$DefinitionPath`" -Stage Publish"
$cmd = "schtasks /Create /TN `"$taskName`" /TR `"$action`" /SC $sc /ST 06:00 /F"
if ($writes) {
    cmd /c $cmd
    Note "Registered scheduled collection '$taskName' ($Cadence). Each run appends to Exec Trend - Monthly Snapshot - Baseline."
} else {
    Write-Host "$prefix would register the scheduled collection with:" -ForegroundColor Yellow
    Write-Host "  $cmd"
    Write-Host "Do NOT commit the schedule until the pilot one-pager reconciles + validates (Impl Steps 5-6)." -ForegroundColor Cyan
}
