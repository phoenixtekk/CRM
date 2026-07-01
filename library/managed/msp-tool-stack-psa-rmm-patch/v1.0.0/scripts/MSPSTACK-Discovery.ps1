<#
.SYNOPSIS
    MSPSTACK-Discovery — Inventory current MSP tooling and integration readiness.

    PURPOSE:
        Captures a baseline of the current internal MSP tool stack so the practice
        knows what exists before designing and standing up PSA, RMM, and Patch
        Management. Probes for configured PSA/RMM/patch endpoints, agent presence on
        the local machine, update-source reachability, and integration-credential
        readiness. Works for both greenfield (nothing yet) and existing environments.

    HOW TO RUN:
        # Generic discovery (no vendor APIs required):
        .\MSPSTACK-Discovery.ps1 -OutputPath .\mspstack-discovery.json

        # Optionally probe vendor REST endpoints you already have:
        .\MSPSTACK-Discovery.ps1 -PsaBaseUri 'https://psa.example' `
            -RmmBaseUri 'https://rmm.example' -OutputPath .\mspstack-discovery.json

    EXPECTED RESULTS:
        A console summary and a JSON file describing: detected PSA/RMM/patch config,
        local RMM agent presence, update-source reachability, and a readiness verdict
        per plane. No changes are made to any system.

.NOTES
    Managed — read-only.
#>

[CmdletBinding()]
param(
    [string]$PsaBaseUri,
    [string]$RmmBaseUri,
    [string]$PatchBaseUri,
    [string[]]$RmmAgentProcessName = @('NinjaRMMAgent', 'CagService', 'AEMAgent', 'gcc'),
    [string[]]$UpdateSource = @('https://www.microsoft.com', 'https://update.microsoft.com'),
    [string]$OutputPath = ".\mspstack-discovery.json"
)

$ErrorActionPreference = 'Stop'

function Test-Endpoint {
    param([string]$Uri)
    if ([string]::IsNullOrWhiteSpace($Uri)) { return $null }
    try {
        $null = Invoke-WebRequest -Uri $Uri -Method Head -TimeoutSec 10 -UseBasicParsing
        return [pscustomobject]@{ Uri = $Uri; Reachable = $true; Error = $null }
    } catch {
        return [pscustomobject]@{ Uri = $Uri; Reachable = $false; Error = $_.Exception.Message }
    }
}

Write-Host "=== MSPSTACK Discovery (read-only) ===" -ForegroundColor Cyan

# --- Local RMM agent presence ---
$agentsFound = @()
foreach ($name in $RmmAgentProcessName) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    $proc = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($svc -or $proc) {
        $agentsFound += [pscustomobject]@{
            Name    = $name
            Service = if ($svc) { $svc.Status.ToString() } else { 'n/a' }
            Process = [bool]$proc
        }
    }
}

# --- Plane endpoint reachability ---
$psaProbe   = Test-Endpoint -Uri $PsaBaseUri
$rmmProbe   = Test-Endpoint -Uri $RmmBaseUri
$patchProbe = Test-Endpoint -Uri $PatchBaseUri

# --- Update-source reachability ---
$updateProbes = foreach ($u in $UpdateSource) { Test-Endpoint -Uri $u }

# --- Readiness verdicts ---
$readiness = [pscustomobject]@{
    PsaConfigured    = [bool]$PsaBaseUri
    RmmConfigured    = [bool]$RmmBaseUri
    PatchConfigured  = [bool]$PatchBaseUri
    RmmAgentPresent  = ($agentsFound.Count -gt 0)
    UpdateReachable  = ($updateProbes | Where-Object Reachable).Count -gt 0
    Greenfield       = (-not $PsaBaseUri -and -not $RmmBaseUri -and -not $PatchBaseUri -and $agentsFound.Count -eq 0)
}

$result = [pscustomobject]@{
    GeneratedUtc   = (Get-Date).ToUniversalTime().ToString('o')
    Computer       = $env:COMPUTERNAME
    PsaProbe       = $psaProbe
    RmmProbe       = $rmmProbe
    PatchProbe     = $patchProbe
    UpdateProbes   = $updateProbes
    RmmAgents      = $agentsFound
    Readiness      = $readiness
}

$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ""
Write-Host "PSA configured   : $($readiness.PsaConfigured)"
Write-Host "RMM configured   : $($readiness.RmmConfigured)"
Write-Host "Patch configured : $($readiness.PatchConfigured)"
Write-Host "RMM agent present: $($readiness.RmmAgentPresent)  ($($agentsFound.Count) found)"
Write-Host "Update reachable : $($readiness.UpdateReachable)"
if ($readiness.Greenfield) {
    Write-Host "Verdict          : GREENFIELD — no existing stack detected." -ForegroundColor Yellow
} else {
    Write-Host "Verdict          : Existing tooling detected — baseline captured." -ForegroundColor Green
}
Write-Host "Saved to         : $OutputPath" -ForegroundColor Cyan
