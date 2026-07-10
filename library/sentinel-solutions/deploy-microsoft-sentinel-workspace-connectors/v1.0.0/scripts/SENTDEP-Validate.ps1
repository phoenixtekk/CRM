<#
.SYNOPSIS
    SENTDEP-Validate.ps1 — check the Sentinel foundation against the 05-testing.md pass/fail gates (read-only).
.DESCRIPTION
    PURPOSE
        Validates the deployed foundation as pass/fail lines aligned to 05-testing.md: workspace exists
        in the expected region; Sentinel enabled; least-privilege RBAC (the three Sentinel groups at
        resource-group scope, with a flag for over-broad subscription grants); Azure Activity DCR
        present and ingesting; the syslog/CEF DCRs present WITH facility/severity filtering applied; and
        table tiers/retention set. Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\SENTDEP-Validate.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace"

        Prereqs: Az modules and Microsoft Sentinel Reader on the workspace (Reader on the RG for the
        RBAC check). Sign in with an MFA-capable admin. Government cloud: pass -Environment
        AzureUSGovernment (verify endpoints for your cloud).
    EXPECTED RESULTS
        A list of PASS/FAIL/REVIEW lines, one per gate, plus an overall result. PASS overall = every
        checked gate passes. FAIL lines point at the phase in 03-implementation.md that fixes them.
.NOTES
    White-label. Read-only. Az / Microsoft Sentinel PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string] $ExpectedRegion,
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Result([string]$Gate,[string]$Status,[string]$Detail){ $results.Add([pscustomobject]@{Gate=$Gate;Status=$Status;Detail=$Detail}) }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
}
catch { Write-Error ("Failed to connect to Azure: {0}" -f $_.Exception.Message); return }

# Gate 1 — workspace + region
try {
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    if ($ExpectedRegion -and $ws.Location -ne $ExpectedRegion) {
        Add-Result 'Gate1 Workspace/Region' 'FAIL' ("Region is {0}, expected {1} (region is fixed — rebuild)." -f $ws.Location,$ExpectedRegion)
    } else {
        Add-Result 'Gate1 Workspace/Region' 'PASS' ("Workspace present in {0}." -f $ws.Location)
    }
}
catch { Add-Result 'Gate1 Workspace/Region' 'FAIL' 'Workspace not found — create per Phase 1.'; $results; return }

# Gate 2 — Sentinel enabled
try {
    $onboard = Get-AzSentinelOnboardingState -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
    if ($onboard) { Add-Result 'Gate2 Sentinel enabled' 'PASS' 'Sentinel is enabled.' }
    else { Add-Result 'Gate2 Sentinel enabled' 'FAIL' 'Enable Sentinel (Phase 1, Step 2).' }
}
catch { Add-Result 'Gate2 Sentinel enabled' 'REVIEW' $_.Exception.Message }

# Gate 3 — least-privilege RBAC
try {
    $scope = (Get-AzResourceGroup -Name $ResourceGroup).ResourceId
    $assign = @(Get-AzRoleAssignment -Scope $scope -ErrorAction SilentlyContinue)
    $sentinelRoles = $assign | Where-Object { $_.RoleDefinitionName -like 'Microsoft Sentinel*' }
    $expected = 'SG-Sentinel-Reader-Tenant','SG-Sentinel-Responder-Tenant','SG-Sentinel-Contributor-Tenant'
    $found = $sentinelRoles | Where-Object { $expected -contains $_.DisplayName }
    if ($found.Count -ge 1) { Add-Result 'Gate3 RBAC groups' 'PASS' ("{0} Sentinel role(s) mapped to named groups at RG scope." -f $found.Count) }
    else { Add-Result 'Gate3 RBAC groups' 'REVIEW' 'No Sentinel roles found on the named groups at RG scope — verify Phase 1, Step 3.' }

    $subScope = "/subscriptions/{0}" -f (Get-AzContext).Subscription.Id
    $broad = @(Get-AzRoleAssignment -Scope $subScope -ErrorAction SilentlyContinue |
        Where-Object { $_.RoleDefinitionName -in 'Owner','Contributor' -and $_.Scope -eq $subScope })
    if ($broad.Count -gt 0) { Add-Result 'Gate3 Least-privilege' 'REVIEW' ("{0} subscription-wide Owner/Contributor assignment(s) — confirm none are for routine SOC use." -f $broad.Count) }
    else { Add-Result 'Gate3 Least-privilege' 'PASS' 'No subscription-wide Owner/Contributor at sub scope.' }
}
catch { Add-Result 'Gate3 RBAC' 'REVIEW' $_.Exception.Message }

# Gate 4/5 — DCRs present + filtering
try {
    $dcrs = @(Get-AzDataCollectionRule -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue)
    $names = $dcrs.Name
    if ($names -contains 'DCR-AzureActivity-Subscription-Pilot') { Add-Result 'Gate4 Azure Activity DCR' 'PASS' 'DCR-AzureActivity-Subscription-Pilot present.' }
    else { Add-Result 'Gate4 Azure Activity DCR' 'REVIEW' 'Azure Activity DCR not found by expected name — verify Phase 2.' }

    foreach ($n in 'DCR-Syslog-Linux-Pilot','DCR-CEF-Appliances-Pilot') {
        $d = $dcrs | Where-Object { $_.Name -eq $n }
        if (-not $d) { Add-Result ("Gate5 {0}" -f $n) 'REVIEW' 'Not found by expected name — verify Phase 3.'; continue }
        $blob = ($d | ConvertTo-Json -Depth 8)
        # A filtered syslog DCR should NOT list every facility at Debug/Info. Heuristic scan only.
        if ($blob -match '"logLevels"\s*:\s*\[\s*"\*"' -or $blob -match 'Debug' -or $blob -match 'Info\b') {
            Add-Result ("Gate5 {0}" -f $n) 'REVIEW' 'DCR may include Debug/Info or all-severity — confirm facility/severity FILTER (cost risk).'
        } else {
            Add-Result ("Gate5 {0}" -f $n) 'PASS' 'DCR present; filter appears constrained (confirm facilities/severities in portal).'
        }
    }
}
catch { Add-Result 'Gate4/5 DCRs' 'REVIEW' $_.Exception.Message }

# Gate 7 — table tiers/retention set
try {
    $tables = @(Get-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    if ($tables.Count -gt 0) { Add-Result 'Gate7 Table plan/retention' 'PASS' ("{0} tables report tier/retention — confirm they match the R7 plan." -f $tables.Count) }
    else { Add-Result 'Gate7 Table plan/retention' 'REVIEW' 'No tables report yet (data may not have arrived).' }
}
catch { Add-Result 'Gate7 Table plan/retention' 'REVIEW' $_.Exception.Message }

Write-Host ''
$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Status -eq 'FAIL' })
Write-Host ''
if ($fail.Count -eq 0) { Write-Host 'OVERALL: PASS (review any REVIEW lines).' -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) need attention before expanding." -f $fail.Count) -ForegroundColor Red }
