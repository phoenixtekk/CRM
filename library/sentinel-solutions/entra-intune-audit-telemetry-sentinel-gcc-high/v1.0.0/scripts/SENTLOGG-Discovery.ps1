<#
.SYNOPSIS
    SENTLOGG-Discovery.ps1 — telemetry-pipeline readiness for Entra ID & Intune audit logs into Sentinel (GCC High).
.DESCRIPTION
    PURPOSE
        Reports whether the building blocks of the pipeline are in place in Azure Government: the Log
        Analytics workspace, Microsoft Sentinel on it, any existing Entra ID diagnostic settings, and
        Intune presence. Read-only — makes no changes. Use your-resource-group and your-workspace-name.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment first (US Gov cloud), then:
        powershell -ExecutionPolicy Bypass -File .\SENTLOGG-Discovery.ps1 -ResourceGroup your-resource-group -WorkspaceName "Security Telemetry - Tenant - Workspace"
        Requires modules: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights, Az.Monitor.
        (Graph-based checks use Connect-MgGraph -Environment USGov.)
    EXPECTED RESULTS
        Workspace found, Sentinel enabled (yes/no), list of Entra ID diagnostic settings routing to the
        workspace, and a note on Intune availability. Highlights anything missing. Pass = workspace and
        Sentinel present; fail = missing prerequisites are flagged.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph/Azure US Gov endpoints.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName
)

Write-Host "=== SENTLOGG Discovery — pipeline readiness (GCC High / Azure Government) ===" -ForegroundColor Cyan

# Confirm we are in the US Gov cloud; if not connected, guide the operator.
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) {
    Write-Host "Not connected. Run: Connect-AzAccount -Environment AzureUSGovernment" -ForegroundColor Yellow
    return
}
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    Write-Host ("WARNING: current Az environment is '{0}', not 'AzureUSGovernment'." -f $ctx.Environment.Name) -ForegroundColor Yellow
    Write-Host "Re-connect with: Connect-AzAccount -Environment AzureUSGovernment (GCC High is a sovereign cloud)." -ForegroundColor Yellow
}

# Workspace
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) {
    Write-Host ("Workspace        : NOT FOUND ({0}/{1})" -f $ResourceGroup, $WorkspaceName) -ForegroundColor Yellow
    Write-Host "Create the workspace in an Azure Government region before continuing (see global requirements G2)." -ForegroundColor Yellow
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
    Write-Host "  (Confirm role to read aadiam diagnostic settings — Requirement 2.2. Use entra.microsoft.us.)"
}

# Intune presence (best-effort via Graph US Gov)
Write-Host "`n--- Intune presence (best-effort) ---" -ForegroundColor Cyan
try {
    $mg = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $mg) {
        Write-Host "  Microsoft Graph not connected. For Intune checks run: Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementManagedDevices.Read.All'" -ForegroundColor Yellow
    } elseif ($mg.Environment -ne 'USGov') {
        Write-Host ("  Graph environment is '{0}', not 'USGov' — reconnect with -Environment USGov for GCC High." -f $mg.Environment) -ForegroundColor Yellow
    } else {
        $devCount = (Get-MgDeviceManagementManagedDevice -Top 1 -ErrorAction Stop | Measure-Object).Count
        Write-Host ("  Intune reachable via graph.microsoft.us (sample managed-device query returned {0} row)." -f $devCount) -ForegroundColor Green
        Write-Host "  Route Intune audit logs in intune.microsoft.us -> Reports -> Diagnostics settings."
    }
} catch {
    Write-Host ("  Intune check skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nNext: SENTLOGG-Validation.ps1 to confirm ingestion is actually flowing." -ForegroundColor Cyan
