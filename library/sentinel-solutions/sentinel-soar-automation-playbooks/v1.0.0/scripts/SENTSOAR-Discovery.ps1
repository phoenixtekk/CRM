<#
.SYNOPSIS
    SENTSOAR-Discovery.ps1 — SOAR readiness for Microsoft Sentinel automation rules and playbooks.
.DESCRIPTION
    PURPOSE
        Reports whether the SOAR building blocks are in place: Microsoft Sentinel onboarded on the
        workspace, incidents being created, existing automation rules and playbooks (Logic Apps),
        and whether Sentinel has run permission on the SOAR resource group. Read-only — no changes.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTSOAR-Discovery.ps1 -ResourceGroup <workspace-rg> -WorkspaceName "Security Telemetry - Tenant - Workspace" -SoarResourceGroup rg-sentinel-soar
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights, Az.LogicApp, Az.Resources.
    EXPECTED RESULTS
        Sentinel enabled (yes/no), recent-incident count, list of automation rules and playbooks,
        and a note on whether the SOAR resource group hosts Logic Apps. Highlights anything missing.
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string]$SoarResourceGroup = 'rg-sentinel-soar'
)

Write-Host "=== SENTSOAR Discovery — SOAR readiness ===" -ForegroundColor Cyan

# Workspace + Sentinel
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) {
    Write-Host ("Workspace        : NOT FOUND ({0}/{1})" -f $ResourceGroup, $WorkspaceName) -ForegroundColor Yellow
    Write-Host "Create the workspace and enable Microsoft Sentinel before continuing (global requirements G2/G3)." -ForegroundColor Yellow
    return
}
Write-Host ("Workspace        : {0}  (region {1})" -f $ws.Name, $ws.Location) -ForegroundColor Green

$sentinel = $null
try { $sentinel = Get-AzSentinelOnboardingState -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue } catch {}
Write-Host ("Sentinel enabled : {0}" -f ($(if($sentinel){'YES'}else{'NO — enable Microsoft Sentinel on this workspace'}))) -ForegroundColor ($(if($sentinel){'Green'}else{'Yellow'}))

# Recent incidents — is there anything to automate against?
Write-Host "`n--- Incidents (last 7 days) ---" -ForegroundColor Cyan
try {
    $inc = Get-AzSentinelIncident -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop |
        Where-Object { $_.CreatedTimeUtc -gt (Get-Date).AddDays(-7) }
    Write-Host ("  Incidents in last 7 days : {0}" -f (@($inc).Count)) -ForegroundColor ($(if(@($inc).Count -gt 0){'Green'}else{'Yellow'}))
    if (@($inc).Count -eq 0) { Write-Host "  No recent incidents — enable at least one analytics rule (Requirement 2.1)." -ForegroundColor Yellow }
} catch {
    Write-Host ("  Could not read incidents: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# Existing automation rules
Write-Host "`n--- Automation rules ---" -ForegroundColor Cyan
try {
    $rules = Get-AzSentinelAutomationRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
    if ($rules) { $rules | ForEach-Object { Write-Host ("  {0}  (order {1})" -f $_.DisplayName, $_.Order) } }
    else { Write-Host "  None yet — you will create 'Auto-Triage - New Incidents - Pilot'." -ForegroundColor Yellow }
} catch { Write-Host ("  Could not read automation rules: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# Existing playbooks (Logic Apps) in the SOAR resource group
Write-Host "`n--- Playbooks (Logic Apps in {0}) ---" -f $SoarResourceGroup -ForegroundColor Cyan
try {
    $apps = Get-AzLogicApp -ResourceGroupName $SoarResourceGroup -ErrorAction SilentlyContinue
    if ($apps) { $apps | ForEach-Object { Write-Host ("  {0}  (state {1})" -f $_.Name, $_.State) } }
    else { Write-Host ("  No Logic Apps in {0} yet — build the four pilot playbooks (Implementation Steps 2-5)." -f $SoarResourceGroup) -ForegroundColor Yellow }
} catch { Write-Host ("  Resource group {0} not found or unreadable — create it (Implementation Step 1)." -f $SoarResourceGroup) -ForegroundColor Yellow }

Write-Host "`nNext: SENTSOAR-Validate.ps1 to confirm the automation rule and playbook identities." -ForegroundColor Cyan
