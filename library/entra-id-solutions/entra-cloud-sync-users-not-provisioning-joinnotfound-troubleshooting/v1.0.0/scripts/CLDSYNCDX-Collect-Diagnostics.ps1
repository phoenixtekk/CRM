<#
.SYNOPSIS
    CLDSYNCDX-Collect-Diagnostics.ps1 — on-host master collector for Entra Connect cloud sync (provisioning agent).
.DESCRIPTION
    PURPOSE
        The entry point. Read-only, on-host snapshot for a cloud sync "users skipped / JoinNotFound /
        not provisioning" incident. Collects: the "Microsoft Entra Provisioning Agent" and "Microsoft
        Entra Connect Agent Updater" service states; the PowerShell execution policy; the presence of a
        proxy / agent configuration; the agent Trace folder
        (C:\ProgramData\Microsoft\Azure AD Connect Provisioning Agent\Trace); and — if the
        AADCloudSyncTools module is available — a full Export-AADCloudSyncToolsLogs bundle. Everything
        is zipped to a timestamped output folder. Makes NO changes.
    HOW TO RUN
        Run ELEVATED on the provisioning-agent host (needed to read the services and the Trace folder):
            powershell -ExecutionPolicy Bypass -File .\CLDSYNCDX-Collect-Diagnostics.ps1
            powershell -ExecutionPolicy Bypass -File .\CLDSYNCDX-Collect-Diagnostics.ps1 -OutFolder .\CloudSyncDiag
        No Microsoft Graph scopes needed — this inspects the local host only.
    EXPECTED RESULTS
        A console summary and a timestamped folder/zip containing the agent Trace folder, the service
        state, and (if the module is present) the AADCloudSyncTools log export — ready to hand to the
        focused Check-* / Get-* tools or to a support case (see 03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only local inspection. Cloud sync service internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $OutFolder = ".\CloudSyncDiag"
)

$ErrorActionPreference = 'Continue'

$stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$dest    = Join-Path $OutFolder ("Cloud Sync - Diagnostics - {0}" -f $stamp)
New-Item -ItemType Directory -Path $dest -Force | Out-Null

$summary = [System.Collections.Generic.List[string]]::new()
function Add-Line { param([string]$Text) $summary.Add($Text); Write-Host $Text }

Add-Line "=== Entra Connect Cloud Sync — Diagnostic Collection ==="
Add-Line ("Host        : {0}" -f $env:COMPUTERNAME)
Add-Line ("Collected   : {0}" -f (Get-Date -Format o))
Add-Line ("Read-only   : yes (no host/tenant/configuration changes)")
Add-Line ("Output       : {0}" -f (Resolve-Path $dest).Path)
Add-Line ''

# --- Agent service states ----------------------------------------------------
$serviceNames = @('Microsoft Entra Provisioning Agent', 'Microsoft Entra Connect Agent Updater')
Add-Line "-- Agent services --"
foreach ($svcName in $serviceNames) {
    $svc = Get-Service -DisplayName $svcName -ErrorAction SilentlyContinue
    if (-not $svc) {
        # fall back to legacy display names, then report absent
        $svc = Get-Service -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like '*Provisioning Agent*' -or $_.DisplayName -like '*Connect Agent Updater*' } |
            Where-Object { $_.DisplayName -eq $svcName } | Select-Object -First 1
    }
    if ($svc) {
        Add-Line ("[SVC] {0} : {1}" -f $svcName, $svc.Status)
    } else {
        Add-Line ("[SVC] {0} : NOT FOUND" -f $svcName)
    }
}
Add-Line ''

# --- PowerShell execution policy ---------------------------------------------
$policy = Get-ExecutionPolicy
Add-Line ("[POLICY] Execution policy (effective) : {0}" -f $policy)
Add-Line ''

# --- Proxy / agent configuration presence ------------------------------------
Add-Line "-- Proxy / agent configuration --"
$winhttp = (netsh winhttp show proxy) 2>$null
if ($winhttp) { $winhttp | ForEach-Object { Add-Line ("[PROXY] {0}" -f $_.Trim()) } }
$agentDir = Join-Path $env:ProgramData 'Microsoft\Azure AD Connect Provisioning Agent'
$configPresent = Test-Path $agentDir
Add-Line ("[CFG] Agent data folder present : {0} ({1})" -f $(if ($configPresent) { 'YES' } else { 'NO' }), $agentDir)
Add-Line ''

# --- Copy the agent Trace folder ---------------------------------------------
$traceDir = Join-Path $agentDir 'Trace'
if (Test-Path $traceDir) {
    $traceDest = Join-Path $dest 'Trace'
    try {
        Copy-Item -Path $traceDir -Destination $traceDest -Recurse -Force -ErrorAction Stop
        $count = @(Get-ChildItem $traceDest -Recurse -File -ErrorAction SilentlyContinue).Count
        Add-Line ("[TRACE] Copied Trace folder ({0} file(s))." -f $count)
    } catch {
        Add-Line ("[TRACE] Could not copy Trace folder: {0}" -f $_.Exception.Message)
    }
} else {
    Add-Line ("[TRACE] Trace folder not found at {0}" -f $traceDir)
}
Add-Line ''

# --- AADCloudSyncTools log export (if available) -----------------------------
if (Get-Module -ListAvailable -Name AADCloudSyncTools) {
    try {
        Import-Module AADCloudSyncTools -ErrorAction Stop
        Add-Line "[LOGS] AADCloudSyncTools present — exporting logs (Connect-AADCloudSyncTools may prompt for sign-in)."
        try { Connect-AADCloudSyncTools -ErrorAction Stop } catch { Add-Line ("[LOGS] Connect-AADCloudSyncTools note: {0}" -f $_.Exception.Message) }
        Export-AADCloudSyncToolsLogs -OutputPath $dest -ErrorAction Stop
        Add-Line "[LOGS] Export-AADCloudSyncToolsLogs completed."
    } catch {
        Add-Line ("[LOGS] AADCloudSyncTools export skipped: {0}" -f $_.Exception.Message)
    }
} else {
    Add-Line "[LOGS] AADCloudSyncTools module not found — collected services + Trace only. Install-Module AADCloudSyncTools for the full export."
}
Add-Line ''

# --- Write the summary and zip -----------------------------------------------
$summaryPath = Join-Path $dest 'CLDSYNCDX-summary.txt'
$summary | Out-File -FilePath $summaryPath -Encoding utf8

$zipPath = "$dest.zip"
try {
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path (Join-Path $dest '*') -DestinationPath $zipPath -Force -ErrorAction Stop
    Write-Host ("`nBundle written to {0}" -f $zipPath) -ForegroundColor Green
} catch {
    Write-Host ("`nCollected to folder {0} (zip step skipped: {1})" -f $dest, $_.Exception.Message) -ForegroundColor Yellow
}
Write-Host "Next: run CLDSYNCDX-Check-Agent.ps1 (host) and CLDSYNCDX-Get-ProvisioningLog.ps1 (Graph). No changes were made." -ForegroundColor Green
