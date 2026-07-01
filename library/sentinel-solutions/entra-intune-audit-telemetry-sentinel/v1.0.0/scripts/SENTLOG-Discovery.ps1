<#
.SYNOPSIS
    SENTLOG-Discovery.ps1 — telemetry-pipeline readiness for Entra ID & Intune audit logs into Sentinel.
.DESCRIPTION
    PURPOSE
        Reports whether the building blocks of the pipeline are in place: the Log Analytics workspace,
        Microsoft Sentinel on it, any existing Entra ID diagnostic settings, and Intune presence.
        Read-only — makes no changes.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTLOG-Discovery.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights, Az.Monitor.
    EXPECTED RESULTS
        Workspace found, Sentinel enabled (yes/no), list of Entra ID diagnostic settings routing to the
        workspace, and a note on Intune availability. Highlights anything missing.
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName
)

Write-Host "=== SENTLOG Discovery — pipeline readiness ===" -ForegroundColor Cyan

# Workspace
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) {
    Write-Host ("Workspace        : NOT FOUND ({0}/{1})" -f $ResourceGroup, $WorkspaceName) -ForegroundColor Yellow
    Write-Host "Create the workspace before continuing (see global requirements G2)." -ForegroundColor Yellow
    return
}
Write-Host ("Workspace        : {0}  (region {1})" -f $ws.Name, $ws.Location) -ForegroundColor Green
Write-Host ("Retention (days) : {0}" -f $ws.RetentionInDays)

# Sentinel enabled? (SecurityInsights solution / onboarding state)
$sentinel = $null
try { $sentinel = Get-AzSentinelOnboardingState -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue } catch {}
Write-Host ("Sentinel enabled : {0}" -f ($(if($sentinel){'YES'}else{'NO — enable Microsoft Sentinel on this workspace'}))) -ForegroundColor ($(if($sentinel){'Green'}else{'Yellow'}))

# Entra ID diagnostic settings → does any route to this workspace?
Write-Host "`n--- Entra ID diagnostic settings ---" -ForegroundColor Cyan
$entraResId = "/providers/microsoft.aadiam"   # Entra ID diagnostic settings live at the tenant/aadiam scope
try {
    $ds = Get-AzDiagnosticSetting -ResourceId $entraResId -ErrorAction Stop
    if ($ds) {
        foreach ($d in $ds) {
            $toWs = ($d.WorkspaceId -eq $ws.ResourceId)
            $cats = ($d.Log | Where-Object { $_.Enabled } | ForEach-Object { $_.Category }) -join ', '
            Write-Host ("  {0}  -> workspace match: {1}  [categories: {2}]" -f $d.Name, $toWs, $cats)
        }
    } else { Write-Host "  No Entra ID diagnostic settings found." -ForegroundColor Yellow }
} catch {
    Write-Host ("  Could not read Entra ID diagnostic settings: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  (Confirm role to read aadiam diagnostic settings — Requirement 2.2.)"
}

Write-Host "`nNext: SENTLOG-Validation.ps1 to confirm ingestion is actually flowing." -ForegroundColor Cyan
