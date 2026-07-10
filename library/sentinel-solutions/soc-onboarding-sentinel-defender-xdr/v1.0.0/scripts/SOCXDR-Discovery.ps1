<#
.SYNOPSIS
    SOCXDR-Discovery.ps1 — readiness for unifying Microsoft Sentinel + Defender XDR incidents.
.DESCRIPTION
    PURPOSE
        Reports whether the building blocks are in place: the Log Analytics workspace, Microsoft
        Sentinel on it, the Microsoft Defender XDR data connector and its state, and whether any
        Microsoft incident-creation rules exist (duplicate-incident risk). Read-only — makes no changes.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SOCXDR-Discovery.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - SOC - Workspace"
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights.
    EXPECTED RESULTS
        Workspace found, Sentinel enabled (yes/no), the Defender XDR connector state, and a count of
        Microsoft incident-creation rules to disable. Highlights anything missing.
.NOTES
    Sentinel Solutions. White-label. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName
)

Write-Host "=== SOCXDR Discovery — unified-queue readiness ===" -ForegroundColor Cyan

# Workspace
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) {
    Write-Host ("Workspace        : NOT FOUND ({0}/{1})" -f $ResourceGroup, $WorkspaceName) -ForegroundColor Yellow
    Write-Host "Create the workspace before continuing (see global requirements G2)." -ForegroundColor Yellow
    return
}
Write-Host ("Workspace        : {0}  (region {1})" -f $ws.Name, $ws.Location) -ForegroundColor Green

# Sentinel enabled?
$sentinel = $null
try { $sentinel = Get-AzSentinelOnboardingState -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue } catch {}
Write-Host ("Sentinel enabled : {0}" -f ($(if($sentinel){'YES'}else{'NO — enable Microsoft Sentinel on this workspace'}))) -ForegroundColor ($(if($sentinel){'Green'}else{'Yellow'}))

# Defender XDR data connector state
Write-Host "`n--- Microsoft Defender XDR connector ---" -ForegroundColor Cyan
try {
    $connectors = Get-AzSentinelDataConnector -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
    $xdr = $connectors | Where-Object { $_.Kind -match 'MicrosoftThreatProtection|Microsoft365Defender|MicrosoftDefenderXDR|MTP' }
    if ($xdr) {
        foreach ($c in $xdr) { Write-Host ("  Connector kind: {0}  (id {1})" -f $c.Kind, $c.Name) -ForegroundColor Green }
        Write-Host "  Defender XDR connector present. Confirm incident sync is ON (SOCXDR-Validate.ps1)." -ForegroundColor Green
    } else {
        Write-Host "  Defender XDR connector NOT configured — install the 'Microsoft Defender XDR' solution from Content hub and connect (Implementation Steps 2-3)." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not read data connectors: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  (Confirm Microsoft Sentinel Contributor on the workspace — Requirement 2.3.)"
}

# Microsoft incident-creation rules (duplicate risk)
Write-Host "`n--- Duplicate-incident risk (Microsoft incident-creation rules) ---" -ForegroundColor Cyan
try {
    $rules = Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
    $mstic = $rules | Where-Object { $_.Kind -eq 'MicrosoftSecurityIncidentCreation' }
    $active = $mstic | Where-Object { $_.Enabled }
    Write-Host ("  Microsoft incident-creation rules : {0} total, {1} ENABLED" -f ($mstic | Measure-Object).Count, ($active | Measure-Object).Count) -ForegroundColor ($(if(($active|Measure-Object).Count -gt 0){'Yellow'}else{'Green'}))
    if ($active) { $active | ForEach-Object { Write-Host ("    - {0} (ENABLED — disable to de-duplicate)" -f $_.DisplayName) -ForegroundColor Yellow } }
} catch {
    Write-Host ("  Could not read analytics rules: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nNext: SOCXDR-Validate.ps1 to confirm incidents are actually syncing." -ForegroundColor Cyan
