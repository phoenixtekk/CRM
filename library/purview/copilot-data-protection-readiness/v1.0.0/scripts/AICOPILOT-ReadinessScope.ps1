<#
.SYNOPSIS
    Copilot data-protection readiness scope & health check (READ-ONLY, no changes).
.DESCRIPTION
    Confirms Security & Compliance PowerShell and Microsoft Graph sign-in, reports whether unified
    auditing is on, and enumerates the licensing-dependent remediation levers available (sensitivity
    labels, label policies, DLP policies, auto-labeling policies) so you know what is present before
    remediation. Writes the export "Copilot Readiness - Tenant - Scope". Read-only by design.
.EXAMPLE
    .\AICOPILOT-ReadinessScope.ps1
    Runs the read-only readiness check using existing Connect-IPPSSession / Connect-MgGraph sessions.
.EXAMPLE
    .\AICOPILOT-ReadinessScope.ps1 -OutDir C:\Temp\CopilotReadiness
    Writes the export files (JSON + CSV) to the named folder. PowerShell 5.1+/7+.
.NOTES
    Requires: ExchangeOnlineManagement (Connect-IPPSSession) and Microsoft.Graph modules; an admin with
    the least-privilege Purview role. No credentials/secrets are stored or requested.
    Expected results (PASS): both sessions connect, auditing reported ON, and the label/DLP/auto-label
    inventory is listed. FAIL: a Connect-* error, or auditing OFF (remediate before relying on reports).
#>

[CmdletBinding()]
param(
    [string]$OutDir = ".",
    [string]$ArtifactName = "Copilot Readiness - Tenant - Scope"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

$result = [ordered]@{
    Artifact   = $ArtifactName
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    Connections = [ordered]@{}
    Auditing   = $null
    Levers     = [ordered]@{}
    Notes      = @()
}

# --- Security & Compliance PowerShell ---
Write-Section "Security & Compliance PowerShell (Connect-IPPSSession)"
try {
    $ippsCmd = Get-Command Get-Label -ErrorAction Stop
    $result.Connections.SecurityCompliance = "connected"
    Write-Host "Connected to Security & Compliance PowerShell." -ForegroundColor Green
} catch {
    $result.Connections.SecurityCompliance = "NOT connected"
    $result.Notes += "Run Connect-IPPSSession with a compliance admin before this script."
    Write-Warning "Security & Compliance PowerShell not connected. Run Connect-IPPSSession first."
}

# --- Microsoft Graph ---
Write-Section "Microsoft Graph (Connect-MgGraph)"
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if ($ctx) {
        $result.Connections.Graph = "connected as $($ctx.Account)"
        Write-Host "Connected to Microsoft Graph as $($ctx.Account)." -ForegroundColor Green
    } else {
        $result.Connections.Graph = "NOT connected"
        $result.Notes += "Run Connect-MgGraph with Sites.Read.All / InformationProtectionPolicy.Read scopes."
        Write-Warning "Microsoft Graph not connected. Run Connect-MgGraph first."
    }
} catch {
    $result.Connections.Graph = "NOT connected"
    $result.Notes += "Microsoft.Graph module / Connect-MgGraph required for oversharing discovery."
    Write-Warning "Microsoft Graph not available: $($_.Exception.Message)"
}

# --- Unified auditing ---
Write-Section "Unified audit log"
try {
    $auditCfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = $auditCfg.UnifiedAuditLogIngestionEnabled
    $result.Auditing = if ($on) { "ON" } else { "OFF" }
    if ($on) { Write-Host "Unified auditing: ON." -ForegroundColor Green }
    else { Write-Warning "Unified auditing appears OFF - enable it (Requirement 2.3)." }
} catch {
    $result.Auditing = "unknown"
    $result.Notes += "Could not read audit config (needs Exchange Online / compliance session)."
    Write-Warning "Could not determine auditing state: $($_.Exception.Message)"
}

# --- Levers: labels, label policies, DLP, auto-labeling ---
Write-Section "Available remediation levers"
try { $result.Levers.SensitivityLabels    = @(Get-Label -ErrorAction Stop).Count } catch { $result.Levers.SensitivityLabels = "n/a" }
try { $result.Levers.LabelPolicies        = @(Get-LabelPolicy -ErrorAction Stop).Count } catch { $result.Levers.LabelPolicies = "n/a" }
try { $result.Levers.DlpPolicies          = @(Get-DlpCompliancePolicy -ErrorAction Stop).Count } catch { $result.Levers.DlpPolicies = "n/a" }
try { $result.Levers.AutoLabelingPolicies = @(Get-AutoSensitivityLabelPolicy -ErrorAction Stop).Count } catch { $result.Levers.AutoLabelingPolicies = "n/a" }

$result.Levers.GetEnumerator() | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Key, $_.Value) }
$result.Notes += "DLP-for-Copilot location, SAM reports (DAG/RCD/RSS/RAC), and container/mandatory labeling are licensing-/tenant-dependent - verify in the portal; this read-only check does not assert their availability."

# --- Write export ---
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$null = New-Item -ItemType Directory -Force -Path $OutDir
$jsonPath = Join-Path $OutDir "$safe.json"
$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "`nWrote $jsonPath" -ForegroundColor Green
Write-Host "Read-only: no changes were made." -ForegroundColor Yellow
