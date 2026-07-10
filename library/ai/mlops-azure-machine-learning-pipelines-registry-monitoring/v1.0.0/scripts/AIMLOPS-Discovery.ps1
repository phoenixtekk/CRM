<#
.SYNOPSIS
    AIMLOPS-Discovery.ps1 — read-only inventory of the Azure ML estate before standing up MLOps.
.DESCRIPTION
    PURPOSE
        Discovery for the "MLOps on Azure Machine Learning" solution. Reports existing Azure ML
        workspaces, compute (clusters/instances), registered models and their versions, registered
        data assets, online/batch endpoints, and any configured model monitors. Makes NO changes —
        this is your baseline snapshot and confirms requirements R3 (a non-prod workspace) and
        R4 (a registered training data asset).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AIMLOPS-Discovery.ps1 -ResourceGroup <rg>
        powershell -ExecutionPolicy Bypass -File .\AIMLOPS-Discovery.ps1 -ResourceGroup <rg> -Workspace mlw-platform-nonprod
        Requires the Azure CLI with the 'ml' extension (az extension add -n ml). Run 'az login' first.
        *Verify current az CLI and ml-extension versions — the v2 CLI surface changes between releases.*
    EXPECTED RESULTS
        A per-section snapshot: workspaces, compute, models + versions, data assets, endpoints, and
        monitors — a single readiness picture before you deploy infra.bicep and run the pipeline.
.NOTES
    White-label. Read-only — reports on configuration/identifiers only; makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ResourceGroup,
    [string]$Workspace,
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Continue'

function Write-Section($t) { Write-Host "`n===== $t =====" -ForegroundColor Cyan }

# --- Preconditions ----------------------------------------------------------
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Warning "Azure CLI (az) not found. Install it, then: az extension add -n ml"; return
}
if (-not (az extension show -n ml 2>$null)) {
    Write-Warning "The 'ml' extension is not installed. Run: az extension add -n ml"
}
if ($SubscriptionId) { az account set --subscription $SubscriptionId | Out-Null }

Write-Host "Azure ML discovery for resource group '$ResourceGroup'`n" -ForegroundColor Cyan

# --- Workspaces -------------------------------------------------------------
Write-Section "Azure ML workspaces (R3 — need a non-prod workspace to pilot)"
try {
    $wss = az ml workspace list -g $ResourceGroup -o json 2>$null | ConvertFrom-Json
    if ($wss) {
        $wss | Select-Object name, location, @{n='publicNetworkAccess';e={$_.public_network_access}} | Format-Table -AutoSize
        if (-not $Workspace -and $wss.Count -ge 1) { $Workspace = $wss[0].name }
    } else { Write-Host "  No Azure ML workspaces found — infra.bicep will create one." -ForegroundColor Yellow }
} catch { Write-Warning "Workspace read failed: $($_.Exception.Message)" }

if (-not $Workspace) {
    Write-Host "`nNo workspace to inspect further. Deploy infra.bicep, then re-run with -Workspace." -ForegroundColor Yellow
    return
}
Write-Host "Inspecting workspace: $Workspace" -ForegroundColor Cyan

# --- Compute ----------------------------------------------------------------
Write-Section "Compute (clusters / instances — watch for scale-to-zero on training clusters)"
try {
    az ml compute list -w $Workspace -g $ResourceGroup -o json 2>$null | ConvertFrom-Json |
        Select-Object name, type, @{n='state';e={$_.provisioning_state}} | Format-Table -AutoSize
} catch { Write-Warning "Compute read failed: $($_.Exception.Message)" }

# --- Registered models + versions ------------------------------------------
Write-Section "Registered models and versions (the registry — versioning + lineage)"
try {
    $models = az ml model list -w $Workspace -g $ResourceGroup -o json 2>$null | ConvertFrom-Json
    if ($models) {
        foreach ($m in $models) {
            $vers = az ml model list --name $m.name -w $Workspace -g $ResourceGroup --query "[].version" -o tsv 2>$null
            [pscustomobject]@{ Model = $m.name; Versions = ($vers -join ', ') }
        } | Format-Table -AutoSize
    } else { Write-Host "  No registered models yet." -ForegroundColor Yellow }
} catch { Write-Warning "Model read failed: $($_.Exception.Message)" }

# --- Data assets ------------------------------------------------------------
Write-Section "Registered data assets (R4 — reproducibility needs a versioned data asset)"
try {
    az ml data list -w $Workspace -g $ResourceGroup -o json 2>$null | ConvertFrom-Json |
        Select-Object name, @{n='latestVersion';e={$_.latest_version}}, type | Format-Table -AutoSize
} catch { Write-Warning "Data-asset read failed: $($_.Exception.Message)" }

# --- Endpoints --------------------------------------------------------------
Write-Section "Online endpoints (real-time scoring)"
try {
    az ml online-endpoint list -w $Workspace -g $ResourceGroup -o json 2>$null | ConvertFrom-Json |
        Select-Object name, @{n='auth';e={$_.auth_mode}}, @{n='publicNetworkAccess';e={$_.public_network_access}} |
        Format-Table -AutoSize
} catch { Write-Warning "Online-endpoint read failed: $($_.Exception.Message)" }

Write-Section "Batch endpoints (large / scheduled scoring)"
try {
    az ml batch-endpoint list -w $Workspace -g $ResourceGroup -o json 2>$null | ConvertFrom-Json |
        Select-Object name | Format-Table -AutoSize
} catch { Write-Warning "Batch-endpoint read failed: $($_.Exception.Message)" }

# --- Monitors / schedules ---------------------------------------------------
Write-Section "Schedules / model monitors (drift + performance)  *some features are preview*"
try {
    az ml schedule list -w $Workspace -g $ResourceGroup -o json 2>$null | ConvertFrom-Json |
        Select-Object name, @{n='enabled';e={$_.is_enabled}} | Format-Table -AutoSize
} catch { Write-Warning "Schedule read failed (monitoring may not be enabled): $($_.Exception.Message)" }

Write-Host "`nDiscovery complete. Save this output as your pre-deployment baseline." -ForegroundColor Green
