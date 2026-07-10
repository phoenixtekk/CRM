<#
.SYNOPSIS
    SENTRULE-Export.ps1 — export enabled analytics rules to files for detection-as-code (export-only).
.DESCRIPTION
    PURPOSE
        Serializes the workspace's analytics rules to JSON files (one per rule) plus a manifest, so
        detections become versioned, reviewable, portable code you commit to Repo-Detections-Main. It
        WRITES FILES ONLY — it never imports, edits, disables, or overwrites any live rule. This is the
        Gate 8 artifact in 05-testing.md.
    HOW TO RUN
        pwsh -File .\SENTRULE-Export.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -OutDir .\detections-export
        pwsh -File .\SENTRULE-Export.ps1 ... -EnabledOnly

        Prereqs: Az.Accounts, Az.SecurityInsights; Microsoft Sentinel Reader on the workspace. Commit the
        output to version control (GitHub / Azure DevOps). For the native pipeline, connect the repo via
        Sentinel -> Repositories (verify availability in your cloud).
    EXPECTED RESULTS
        One <RuleName>.json per rule under -OutDir, plus manifest.json listing exported rules and their
        MITRE tags. Nothing in the workspace changes. PASS = every rule to be promoted exists as a file
        with a rollback point in version control.
.NOTES
    White-label. Export/read-only — writes local files, never mutates live rules. Az PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string] $OutDir,
    [switch] $EnabledOnly,
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not $OutDir) { $OutDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'detections-export' }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop | Out-Null
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

try {
    $rules = @(Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop)
    if ($EnabledOnly) { $rules = @($rules | Where-Object Enabled) }
}
catch { Write-Error ("Could not read analytics rules: {0}" -f $_.Exception.Message); return }

if ($rules.Count -eq 0) { Write-Host 'No rules to export.' -ForegroundColor Yellow; return }

Write-Section ("Exporting {0} rule(s) to {1} (write-only; live rules untouched)" -f $rules.Count, $OutDir)
$manifest = New-Object System.Collections.Generic.List[object]
foreach ($r in $rules) {
    $safe = ($r.DisplayName -replace '[^\w\-]', '_')
    $file = Join-Path $OutDir ("{0}.json" -f $safe)
    try {
        $r | ConvertTo-Json -Depth 20 | Out-File -FilePath $file -Encoding UTF8
        $manifest.Add([pscustomobject]@{
            DisplayName = $r.DisplayName
            Kind        = $r.Kind
            Enabled     = $r.Enabled
            Tactics     = ($r.Tactic -join ',')
            Techniques  = ($r.Technique -join ',')
            File        = (Split-Path $file -Leaf)
        })
        Write-Host ("  exported: {0}" -f $r.DisplayName) -ForegroundColor Green
    }
    catch { Write-Warning ("  {0}: {1}" -f $r.DisplayName, $_.Exception.Message) }
}

$manifestPath = Join-Path $OutDir 'manifest.json'
$manifest | ConvertTo-Json -Depth 6 | Out-File -FilePath $manifestPath -Encoding UTF8

Write-Section 'Done'
Write-Host ("Manifest written: {0}" -f $manifestPath) -ForegroundColor Green
Write-Host 'Commit the export directory to Repo-Detections-Main (version control) for review, diff, and rollback.'
Write-Host 'To deploy detections FROM code, use Sentinel -> Repositories or an approved pipeline (verify availability in your cloud).'
