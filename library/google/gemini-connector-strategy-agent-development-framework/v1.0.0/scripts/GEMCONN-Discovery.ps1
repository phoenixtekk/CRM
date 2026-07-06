<#
.SYNOPSIS
    GEMCONN-Discovery.ps1 — inventory Gemini Enterprise connectors (data stores) and agents across a
    Google Cloud project / location, as the readiness picture before you govern them.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Gemini Connector Strategy & Agent Development Framework" solution.
        For a Google Cloud project and location, lists the Discovery Engine / Agentspace data stores
        (the "connectors" that expose enterprise data to Gemini Enterprise) with their type and content
        config, and enumerates the agents / assistants configured in the same scope. It calls the
        Google Discovery Engine REST API with a gcloud access token and makes no changes. Gemini
        Enterprise / Agentspace surfaces are evolving (preview) — resource shapes and API versions may
        differ in your tenant, so treat any empty result as 'verify in your tenant', not 'none'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Discovery.ps1 -ProjectId 'your-project-id'
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Discovery.ps1 -ProjectId 'your-project-id' -Location 'global'
        Requires the Google Cloud SDK (gcloud) authenticated with a principal that can read Discovery
        Engine resources (for example the Discovery Engine Viewer role). Run 'gcloud auth login' and
        'gcloud config set project your-project-id' first. Needs the Discovery Engine API enabled on
        the project.
    EXPECTED RESULTS
        A per-project snapshot: each data-store / connector with id, type and content config, and each
        configured agent / assistant — a single inventory of what exposes data and what acts on it,
        before you apply approval criteria and agent-development guardrails. Empty sections print a
        'verify in your tenant' note because the APIs are in preview.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
    Gemini Enterprise / Agentspace are preview/rolling-out; API versions, resource names, and console
    paths are cited from Google's public docs where possible and otherwise flagged 'verify in tenant'.
    Never invents connector or agent specifics.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ProjectId,
    [string]$Location = 'global',
    [ValidateSet('v1','v1alpha','v1beta')] [string]$ApiVersion = 'v1'
)

# --- Resolve a Google Cloud access token from gcloud (documented auth pattern) ---
function Get-GcloudToken {
    try {
        $t = (& gcloud auth print-access-token 2>$null)
        if (-not $t) { throw "empty token" }
        return $t.Trim()
    } catch {
        Write-Host "Could not obtain a gcloud access token. Run 'gcloud auth login' first." -ForegroundColor Red
        throw
    }
}

$token   = Get-GcloudToken
$headers = @{ Authorization = "Bearer $token"; 'X-Goog-User-Project' = $ProjectId }
$base    = "https://discoveryengine.googleapis.com/$ApiVersion/projects/$ProjectId/locations/$Location"

Write-Host "`n=== Gemini Connector Strategy & Agent Development — discovery ===" -ForegroundColor Cyan
Write-Host ("Project: {0}   Location: {1}   API: {2}" -f $ProjectId, $Location, $ApiVersion)

# --- Connectors / data stores (dataStores expose enterprise data to Gemini Enterprise) ---
Write-Host "`n-- Connectors (data stores) --" -ForegroundColor Cyan
$anyStore = $false
try {
    $uri = "$base/collections/default_collection/dataStores"
    $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
    if ($resp.dataStores) {
        foreach ($ds in $resp.dataStores) {
            $anyStore = $true
            $id      = ($ds.name -split '/')[-1]
            $type    = if ($ds.industryVertical) { $ds.industryVertical } else { '(unspecified)' }
            $content = if ($ds.contentConfig)    { $ds.contentConfig }    else { '(unspecified)' }
            Write-Host ("   {0,-34} vertical: {1,-16} content: {2}" -f $id, $type, $content)
        }
    }
} catch {
    Write-Host ("   Could not list data stores: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "   (Confirm the Discovery Engine API is enabled and the API version matches your tenant.)" -ForegroundColor Yellow
}
if (-not $anyStore) {
    Write-Host "   No connectors returned. Verify in your tenant — the connector/data-store surface is" -ForegroundColor Yellow
    Write-Host "   in preview and the API version or collection id may differ (try -ApiVersion v1alpha)." -ForegroundColor Yellow
}

# --- Agents / assistants (what acts on the connected data) ---
Write-Host "`n-- Agents / assistants --" -ForegroundColor Cyan
$anyAgent = $false
foreach ($enginePath in @("$base/collections/default_collection/engines")) {
    try {
        $resp = Invoke-RestMethod -Method Get -Uri $enginePath -Headers $headers -ErrorAction Stop
        if ($resp.engines) {
            foreach ($e in $resp.engines) {
                $anyAgent = $true
                $id   = ($e.name -split '/')[-1]
                $kind = if ($e.solutionType) { $e.solutionType } else { '(unspecified)' }
                Write-Host ("   engine/agent {0,-30} solution: {1}" -f $id, $kind)
            }
        }
    } catch {
        Write-Host ("   Could not list engines/agents: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}
if (-not $anyAgent) {
    Write-Host "   No agents/assistants returned. Verify in your tenant — agent resources (Agentspace /" -ForegroundColor Yellow
    Write-Host "   Agent Builder / Agent Engine) are preview and may live under a different API surface." -ForegroundColor Yellow
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
Write-Host "Preview note: cross-check any empty result in the Google Cloud console before concluding 'none'." -ForegroundColor Yellow
