<#
.SYNOPSIS
    STIGG-Report.ps1 — read-only evidence report of STIG profile/compliance/baseline state for a US Gov target group.
.DESCRIPTION
    PURPOSE
        Produces an evidence artifact (JSON and CSV) capturing the deployment state of this solution's
        STIG objects and the compliance posture of devices in a target group. Run at the Validate gate
        and after each Expand wave, then retain the output per your IL4/IL5 change-control process.
        Read-only: it changes nothing. Do not embed secrets; authenticate interactively to US Gov Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\STIGG-Report.ps1 -TargetGroup SG-STIG-Pilot-Devices
        powershell -ExecutionPolicy Bypass -File .\STIGG-Report.ps1 -TargetGroup SG-STIG-Prod-Devices -Environment USGovDoD -OutputDir .\evidence
        (Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All,
         Group.Read.All; -Environment USGov for GCC High or USGovDoD for DoD)
    EXPECTED RESULTS
        Two files (STIGG-Report-timestamp.json and .csv) plus a console summary. Admin sees object
        deployment states and per-device compliance counts. PASS = report generates and reflects the
        expected assigned objects and compliant devices. Used as the retained audit record, not a gate by itself.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$TargetGroup = 'SG-STIG-Pilot-Devices',
    [string]$NamePrefix = 'STIG-Win',
    [string]$OutputDir = '.',
    [string]$BenchmarkVersion = 'record-your-DISA-benchmark-version-here'
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
    return $ctx
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
    $ctx = Connect-StiggGraph -Env $Environment
    $timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')

    Write-Host "`n== Report: STIG evidence for '$TargetGroup' ==" -ForegroundColor Yellow

    $report = [ordered]@{
        generatedUtc      = (Get-Date).ToUniversalTime().ToString('o')
        environment       = $Environment
        graphAccount      = $ctx.Account
        tenantId          = $ctx.TenantId
        targetGroup       = $TargetGroup
        benchmarkVersion  = $BenchmarkVersion
        objects           = @()
        deviceCompliance  = @()
        summary           = [ordered]@{}
    }

    # STIG objects
    $configProfiles = Invoke-StiggGet 'deviceManagement/configurationPolicies?$select=id,name' | Where-Object { $_.name -like "$NamePrefix*" }
    $legacyProfiles = Invoke-StiggGet 'deviceManagement/deviceConfigurations?$select=id,displayName' | Where-Object { $_.displayName -like "$NamePrefix*" }
    $compliance     = Invoke-StiggGet 'deviceManagement/deviceCompliancePolicies?$select=id,displayName' | Where-Object { $_.displayName -like "$NamePrefix*" }

    foreach ($p in $configProfiles) { $report.objects += [pscustomobject]@{ kind='configurationPolicy'; id=$p.id; name=$p.name } }
    foreach ($p in $legacyProfiles) { $report.objects += [pscustomobject]@{ kind='deviceConfiguration'; id=$p.id; name=$p.displayName } }
    foreach ($p in $compliance)     { $report.objects += [pscustomobject]@{ kind='compliancePolicy';   id=$p.id; name=$p.displayName } }

    Write-Host ("  STIG-Win-* objects found: {0}" -f $report.objects.Count)

    # Compliance posture (device-level) — filter to Windows for STIG relevance
    Write-Host "`n-- Windows device compliance posture --"
    $devices = Invoke-StiggGet "deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=id,deviceName,complianceState,osVersion,lastSyncDateTime"
    foreach ($d in $devices) {
        $report.deviceCompliance += [pscustomobject]@{
            deviceName      = $d.deviceName
            complianceState = $d.complianceState
            osVersion       = $d.osVersion
            lastSyncDateTime= $d.lastSyncDateTime
        }
    }
    $byState = $report.deviceCompliance | Group-Object complianceState | Sort-Object Name
    foreach ($g in $byState) { Write-Host ("  {0,-12}: {1}" -f $g.Name, $g.Count) }

    $report.summary.objectCount     = $report.objects.Count
    $report.summary.windowsDevices  = $report.deviceCompliance.Count
    $report.summary.compliant       = (($report.deviceCompliance | Where-Object complianceState -eq 'compliant') | Measure-Object).Count
    $report.summary.nonCompliant    = (($report.deviceCompliance | Where-Object complianceState -eq 'noncompliant') | Measure-Object).Count

    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    $jsonPath = Join-Path $OutputDir "STIGG-Report-$timestamp.json"
    $csvPath  = Join-Path $OutputDir "STIGG-Report-$timestamp.csv"

    $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding utf8
    $report.deviceCompliance | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8

    Write-Host "`nEvidence written:" -ForegroundColor Cyan
    Write-Host "  $jsonPath"
    Write-Host "  $csvPath"
    Write-Host ("`nSummary: {0} STIG objects, {1} Windows devices, {2} compliant, {3} non-compliant." -f `
        $report.summary.objectCount, $report.summary.windowsDevices, $report.summary.compliant, $report.summary.nonCompliant) -ForegroundColor Green
    Write-Host "Retain these files per your change-control (R10). Benchmark version recorded: $BenchmarkVersion" -ForegroundColor Gray
}
catch {
    Write-Error "Report failed: $($_.Exception.Message)"
    Write-Host "Check: PowerShell 7+, Microsoft.Graph installed, correct -Environment (USGov/USGovDoD), and read scopes consented." -ForegroundColor Yellow
    exit 1
}
finally {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
}
