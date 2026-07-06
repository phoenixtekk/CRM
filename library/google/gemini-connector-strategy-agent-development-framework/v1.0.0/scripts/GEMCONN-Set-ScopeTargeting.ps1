<#
.SYNOPSIS
    GEMCONN-Set-ScopeTargeting.ps1 — resolve and confirm the Google Cloud project / location / IAM
    scope that connector and agent governance will apply to before you change anything.
.DESCRIPTION
    PURPOSE
        Scope helper for the "Gemini Connector Strategy & Agent Development Framework" solution.
        Resolves the target governance scope from a Google Cloud project id (and location), prints the
        Discovery Engine resource-path prefix that connector/agent operations use, lists the current
        Gemini Enterprise IAM bindings on the project (who is admin/user/editor/viewer), and reports
        whether an access boundary (VPC Service Controls perimeter) covers it. Read-only — it confirms
        WHERE approval criteria and agent guardrails will apply before you assign them. Reuse the
        printed project/location/scope verbatim as input to the other GEMCONN scripts and the console.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Set-ScopeTargeting.ps1 -ProjectId 'your-project-id'
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Set-ScopeTargeting.ps1 -ProjectId 'your-project-id' -Location 'us'
        Requires the Google Cloud SDK (gcloud) authenticated with permission to read the project IAM
        policy and Access Context Manager. Run 'gcloud auth login' first.
    EXPECTED RESULTS
        The resolved project + location, the Discovery Engine resource-path prefix, the Gemini
        Enterprise IAM role bindings on the project (admin / user / editor / viewer), and whether a VPC
        Service Controls perimeter is present — the confirmed target you reuse verbatim in every
        approval decision, script, and test.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
    Object naming convention: Purpose - Scope - Stage, e.g. 'Connector Approval - Pilot Project - Prod'.
    Gemini Enterprise IAM roles (discoveryengine.agentspaceAdmin / agentspaceUser / editor / viewer)
    are cited from Google's public IAM docs; confirm role availability in your tenant. Never invents
    role or resource names.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ProjectId,
    [string]$Location = 'global'
)

Write-Host "`n=== Gemini Connector Strategy & Agent Development — scope targeting ===" -ForegroundColor Cyan

# --- Confirm the project exists / is readable ---
try {
    $proj = & gcloud projects describe $ProjectId --format=json 2>$null | ConvertFrom-Json
    if (-not $proj) { throw "not found" }
    Write-Host ("Resolved project: {0} ({1})   Location: {2}" -f $proj.name, $ProjectId, $Location) -ForegroundColor Green
} catch {
    Write-Host ("Could not read project '{0}'. Confirm the id and your access." -f $ProjectId) -ForegroundColor Red
    return
}

# --- Discovery Engine resource-path prefix used by connector/agent operations ---
$prefix = "projects/$ProjectId/locations/$Location/collections/default_collection"
Write-Host ("Discovery Engine resource-path prefix: {0}" -f $prefix) -ForegroundColor Cyan
Write-Host "  (data stores under .../dataStores, agents/engines under .../engines)"

# --- Gemini Enterprise IAM role bindings on the project ---
Write-Host "`n-- Gemini Enterprise IAM bindings on the project --" -ForegroundColor Cyan
$geminiRoles = @(
    'roles/discoveryengine.agentspaceAdmin',
    'roles/discoveryengine.agentspaceUser',
    'roles/discoveryengine.editor',
    'roles/discoveryengine.viewer'
)
try {
    $iam = & gcloud projects get-iam-policy $ProjectId --format=json 2>$null | ConvertFrom-Json
    $found = $false
    foreach ($b in $iam.bindings) {
        if ($geminiRoles -contains $b.role) {
            $found = $true
            Write-Host ("   {0}" -f $b.role) -ForegroundColor Cyan
            $b.members | ForEach-Object { Write-Host ("      - {0}" -f $_) }
        }
    }
    if (-not $found) {
        Write-Host "   No Gemini Enterprise (discoveryengine.*) role bindings found at project level." -ForegroundColor Yellow
        Write-Host "   Verify in your tenant — roles may be granted at folder/org level or under different" -ForegroundColor Yellow
        Write-Host "   names as the product rolls out." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Could not read the project IAM policy." -ForegroundColor Yellow
}

# --- Access boundary presence ---
Write-Host "`n-- Data-access boundary (VPC Service Controls) --" -ForegroundColor Cyan
try {
    $perimeters = & gcloud access-context-manager perimeters list --format=json 2>$null | ConvertFrom-Json
    if ($perimeters -and $perimeters.Count -gt 0) {
        Write-Host ("   {0} service perimeter(s) exist — confirm this project is inside the intended one." -f $perimeters.Count) -ForegroundColor Green
    } else {
        Write-Host "   No perimeter found / not readable — define one to bound connector & agent data flow." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Could not read Access Context Manager — verify in your tenant." -ForegroundColor Yellow
}

Write-Host "`nReuse the project id, location, and resource-path prefix verbatim in the other GEMCONN scripts and the console." -ForegroundColor Cyan
Write-Host "Scope targeting complete (read-only)." -ForegroundColor Green
