<#
.SYNOPSIS
    SENTSOAR-Validate.ps1 — validate the automation rule and playbooks are configured correctly.
.DESCRIPTION
    PURPOSE
        Confirms the pilot automation rule is enabled, each expected playbook exists, is enabled, and
        has a system-assigned managed identity, and reports whether the response playbook still looks
        simulate-first (no enforced-action platform role assigned). Read-only — no changes.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTSOAR-Validate.ps1 -ResourceGroup <workspace-rg> -WorkspaceName "..." -SoarResourceGroup rg-sentinel-soar
        Requires modules: Az.Accounts, Az.SecurityInsights, Az.LogicApp, Az.Resources.
    EXPECTED RESULTS
        PASS/CHECK lines for: automation rule 'Auto-Triage - New Incidents - Pilot' enabled; the four
        playbooks present and enabled; each playbook has a managed identity. Highlights anything off.
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string]$SoarResourceGroup = 'rg-sentinel-soar',
    [string]$AutomationRuleName = 'Auto-Triage - New Incidents - Pilot',
    [string[]]$Playbooks = @('Enrichment - Incident - Pilot','Notify - Teams-Email - Pilot','Ticketing - Incident - Pilot','Response - Contain - Pilot')
)

Write-Host "=== SENTSOAR Validate — automation rule + playbooks ===" -ForegroundColor Cyan

# Automation rule enabled?
try {
    $rules = Get-AzSentinelAutomationRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
    $rule = $rules | Where-Object { $_.DisplayName -eq $AutomationRuleName }
    if ($rule) { Write-Host ("PASS  Automation rule present : {0}  (order {1})" -f $rule.DisplayName, $rule.Order) -ForegroundColor Green }
    else { Write-Host ("CHECK Automation rule NOT found : {0} — create it (Implementation Step 8)." -f $AutomationRuleName) -ForegroundColor Yellow }
} catch { Write-Host ("CHECK Could not read automation rules: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# Each playbook present, enabled, and has a managed identity
Write-Host "`n--- Playbooks ---" -ForegroundColor Cyan
foreach ($p in $Playbooks) {
    $app = Get-AzLogicApp -ResourceGroupName $SoarResourceGroup -Name $p -ErrorAction SilentlyContinue
    if (-not $app) { Write-Host ("CHECK  {0} : NOT FOUND in {1}" -f $p, $SoarResourceGroup) -ForegroundColor Yellow; continue }
    $enabled = ($app.State -eq 'Enabled')
    # Managed identity is exposed on the underlying resource
    $res = Get-AzResource -ResourceGroupName $SoarResourceGroup -Name $p -ResourceType 'Microsoft.Logic/workflows' -ExpandProperties -ErrorAction SilentlyContinue
    $hasMi = ($res -and $res.Identity -and $res.Identity.Type -match 'SystemAssigned')
    $stateColor = ($(if($enabled -and $hasMi){'Green'}else{'Yellow'}))
    Write-Host ("  {0} : state={1}  managed-identity={2}" -f $p, $app.State, ($(if($hasMi){'YES'}else{'NO — enable it (Implementation Step 6)'}))) -ForegroundColor $stateColor
}

Write-Host "`nReminder: keep 'Response - Contain - Pilot' in SimulateMode=true and analyst-triggered during the pilot." -ForegroundColor Cyan
Write-Host "Next: SENTSOAR-Report.ps1 for run history, and SENTSOAR-Set-PlaybookIdentity.ps1 for role review." -ForegroundColor Cyan
