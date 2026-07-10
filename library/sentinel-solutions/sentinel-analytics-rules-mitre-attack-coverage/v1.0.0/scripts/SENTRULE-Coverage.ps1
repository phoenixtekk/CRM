<#
.SYNOPSIS
    SENTRULE-Coverage.ps1 — build the MITRE ATT&CK coverage matrix and gap list from enabled rules (read-only).
.DESCRIPTION
    PURPOSE
        Aggregates the MITRE tactics/techniques tagged on enabled analytics rules into a coverage matrix,
        counts detections per tactic and per technique, and lists the UNCOVERED cells (gaps) so you can
        rank and close them by risk. Exports the matrix to CSV. Read-only — it changes nothing. The map
        is only as accurate as the rules' MITRE tags (see 06-troubleshooting.md).
    HOW TO RUN
        pwsh -File .\SENTRULE-Coverage.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace"

        Prereqs: Az.Accounts, Az.SecurityInsights; Microsoft Sentinel Reader on the workspace.
    EXPECTED RESULTS
        A per-tactic coverage table (tactic -> number of enabled rules), the set of covered techniques,
        the list of ATT&CK tactics with ZERO enabled rules (gaps), and a CSV export. Cross-check with
        Sentinel -> MITRE ATT&CK in the portal. Verify the current ATT&CK tactic/technique set for your
        cloud/tenant.
.NOTES
    White-label. Read-only. Az / Microsoft Sentinel PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Enterprise ATT&CK tactics (verify the current set for your tenant/cloud; techniques evolve).
$attackTactics = @(
    'Reconnaissance','ResourceDevelopment','InitialAccess','Execution','Persistence',
    'PrivilegeEscalation','DefenseEvasion','CredentialAccess','Discovery','LateralMovement',
    'Collection','CommandAndControl','Exfiltration','Impact'
)

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop | Out-Null
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

try {
    $rules = @(Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop |
        Where-Object Enabled)
}
catch { Write-Error ("Could not read analytics rules: {0}" -f $_.Exception.Message); return }

if ($rules.Count -eq 0) { Write-Host 'No enabled rules — coverage is empty. Enable rules per 03-implementation.md.' -ForegroundColor Yellow; return }

# --- Per-tactic coverage ----------------------------------------------------------------------------
Write-Section 'MITRE ATT&CK coverage by tactic'
$coverage = foreach ($tac in $attackTactics) {
    $hits = @($rules | Where-Object { $_.Tactic -contains $tac })
    [pscustomobject]@{
        Tactic       = $tac
        EnabledRules = $hits.Count
        Covered      = [bool]($hits.Count -gt 0)
        RuleNames    = ($hits.DisplayName -join '; ')
    }
}
$coverage | Select-Object Tactic, EnabledRules, Covered | Format-Table -AutoSize

# --- Covered techniques -----------------------------------------------------------------------------
Write-Section 'Covered techniques (from enabled-rule tags)'
$techniques = $rules | ForEach-Object { $_.Technique } | Where-Object { $_ } | Sort-Object -Unique
if ($techniques.Count -eq 0) { Write-Host 'No techniques tagged on enabled rules — tag rules so the map is accurate.' -ForegroundColor Yellow }
else { Write-Host ($techniques -join ', ') }

# --- Gaps -------------------------------------------------------------------------------------------
Write-Section 'GAPS — tactics with zero enabled rules (rank by risk against R5)'
$gaps = @($coverage | Where-Object { -not $_.Covered })
if ($gaps.Count -eq 0) { Write-Host 'Every tactic has at least one enabled rule (depth still matters — review per technique).' -ForegroundColor Green }
else {
    foreach ($g in $gaps) { Write-Host ("  GAP: {0}" -f $g.Tactic) -ForegroundColor Red }
    Write-Host ''
    Write-Host ("{0} of {1} tactics have no enabled detection. Prioritise the highest-risk ones." -f $gaps.Count, $attackTactics.Count)
}

# --- Export ----------------------------------------------------------------------------------------
$out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ("SENTRULE-coverage-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
$coverage | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Host ''
Write-Host ("Coverage matrix exported to: {0}" -f $out) -ForegroundColor Green
Write-Host 'Cross-check with Sentinel -> MITRE ATT&CK. A covered tactic means a rule targets it, not that every variant is caught.'
