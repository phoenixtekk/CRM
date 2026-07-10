<#
.SYNOPSIS
    CPLTGOV-Discovery.ps1 - Discover sensitivity-label coverage and sensitive content for Copilot governance (READ-ONLY).
.DESCRIPTION
    PURPOSE:  Report the published sensitivity LABELS, sensitive information TYPES, DLP policies, and
              auto-labeling policies available in the tenant, check whether the Microsoft 365 Copilot DLP
              location is offered, and confirm auditing - the levers this solution enforces around Copilot.
              With -ScopeOnly it only performs the Step 0 environment/licensing check. Writes
              "Copilot Label Coverage - Estate - Assess" (JSON summary).
    HOW TO RUN:
              1. Connect-IPPSSession                                   # Security & Compliance PowerShell
              2. Connect-MgGraph -Scopes "AuditLog.Read.All","InformationProtectionPolicy.Read"
              3. .\CPLTGOV-Discovery.ps1 -ScopeOnly                    # Step 0 environment check
                 .\CPLTGOV-Discovery.ps1 -OutDir C:\Temp\CPLTGOV
    EXPECTED RESULTS:
              PASS: a coverage summary (labels/SITs/DLP/auto-labeling + Copilot-DLP-location availability)
              is written. FAIL: not connected to Security & Compliance PowerShell.
.NOTES
    White-label. Read-only - creates/changes NO policy or label. Classification (what is "sensitive") is a
    compliance decision, not this script's. DLP-for-Copilot availability is licensing-/preview-gated -
    verify in your tenant. Requires ExchangeOnlineManagement (Connect-IPPSSession) and Microsoft.Graph.
#>

[CmdletBinding()]
param(
    [switch]$ScopeOnly,
    [string]$OutDir = ".",
    [string]$CopilotDlpLocation = "Microsoft365Copilot",
    [string]$ArtifactName = "Copilot Label Coverage - Estate - Assess"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# --- Security & Compliance PowerShell check ---
$ippsOk = $false
try { $null = Get-Command Get-Label -ErrorAction Stop; $ippsOk = $true }
catch { Write-Warning "Connect-IPPSSession is required (Get-Label not available)." }

# --- Levers (read-only) ---
$labels = @(); $sits = @(); $dlp = @(); $autolabel = @()
if ($ippsOk) {
    try { $labels    = Get-Label -ErrorAction Stop } catch { Write-Warning "Get-Label: $($_.Exception.Message)" }
    try { $sits      = Get-DlpSensitiveInformationType -ErrorAction Stop } catch { Write-Warning "Get-DlpSensitiveInformationType: $($_.Exception.Message)" }
    try { $dlp       = Get-DlpCompliancePolicy -ErrorAction Stop } catch { Write-Warning "Get-DlpCompliancePolicy: $($_.Exception.Message)" }
    try { $autolabel = Get-AutoSensitivityLabelPolicy -ErrorAction Stop } catch { Write-Warning "Get-AutoSensitivityLabelPolicy: $($_.Exception.Message)" }
}

Write-Section "Governance levers (read-only)"
Write-Host ("  Published sensitivity labels : {0}" -f @($labels).Count) -ForegroundColor Green
Write-Host ("  Sensitive information types  : {0}" -f @($sits).Count) -ForegroundColor Green
Write-Host ("  DLP policies                 : {0}" -f @($dlp).Count) -ForegroundColor Green
Write-Host ("  Auto-labeling policies       : {0}" -f @($autolabel).Count) -ForegroundColor Green

# --- Copilot DLP location availability (best-effort; portal-verified) ---
$copilotDlpAvailable = "unknown"
try {
    $existingCopilotDlp = @($dlp | Where-Object { "$($_.Workload)" -match 'Copilot' -or "$($_.ContentContainsSensitiveInformation)" -match 'Copilot' })
    $copilotDlpAvailable = if ($existingCopilotDlp.Count -gt 0) { "in-use" } else { "verify in portal when creating a DLP policy" }
} catch { }
Write-Host ("  Microsoft 365 Copilot DLP location: {0} (licensing/preview-gated - verify)" -f $copilotDlpAvailable) -ForegroundColor DarkGray

# --- Auditing signal ---
Write-Host "  Auditing: verify in Purview Audit (Search-UnifiedAuditLog returns Copilot interaction events)." -ForegroundColor DarkGray

if ($ScopeOnly) {
    Write-Host "`n-ScopeOnly: environment/levers reported. No coverage export written." -ForegroundColor Yellow
    return
}
if (-not $ippsOk) { Write-Error "Cannot produce coverage without Security & Compliance PowerShell."; return }

# --- Coverage summary export ---
Write-Section "Writing label-coverage summary"
$summary = [ordered]@{
    Artifact              = $ArtifactName
    GeneratedUtc          = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    SensitivityLabels     = @($labels | ForEach-Object { $_.DisplayName })
    LabelCount            = @($labels).Count
    SensitiveInfoTypeCount= @($sits).Count
    DlpPolicyCount        = @($dlp).Count
    AutoLabelPolicyCount  = @($autolabel).Count
    CopilotDlpLocation    = $CopilotDlpLocation
    CopilotDlpAvailability= $copilotDlpAvailable
    Guidance              = "Locations with UNLABELED sensitive content that Copilot can reach are the priority for labeling and for the 'keep out of Copilot' DLP condition. What is 'sensitive' is a compliance determination - not set here."
}
$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$json = Join-Path $OutDir "$safe.json"
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8
Write-Host "Wrote $json" -ForegroundColor Green
Write-Host "`nRead-only: no policy or label was created or changed." -ForegroundColor Yellow
