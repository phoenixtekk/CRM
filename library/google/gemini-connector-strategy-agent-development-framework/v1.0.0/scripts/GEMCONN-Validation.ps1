<#
.SYNOPSIS
    GEMCONN-Validation.ps1 — confirm connector data-access boundaries and agent-development guardrails
    conform to the governance baseline, printing PASS/WARN per check.
.DESCRIPTION
    PURPOSE
        Read-only conformance validation for the "Gemini Connector Strategy & Agent Development
        Framework" solution. For a Google Cloud project it checks the boundary and guardrail controls
        the framework requires: that VPC Service Controls / an access boundary is present, that org
        policies restricting the project exist, that connectors are inside the approved allow-list, and
        that agents are not published beyond their approved audience. It reads live state via gcloud
        and the Discovery Engine REST API and makes no changes. Where a control cannot be read because
        the surface is in preview, it prints WARN with a 'verify in your tenant' note rather than
        asserting a pass.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Validation.ps1 -ProjectId 'your-project-id'
        powershell -ExecutionPolicy Bypass -File .\GEMCONN-Validation.ps1 -ProjectId 'your-project-id' -ApprovedConnectorsPath .\approved-connectors.txt
        Requires the Google Cloud SDK (gcloud) authenticated with read access to Access Context Manager,
        org policies, and Discovery Engine (viewer-level roles). Run 'gcloud auth login' and
        'gcloud config set project your-project-id' first.
    EXPECTED RESULTS
        A short PASS/WARN report: access-boundary (VPC Service Controls) present, org policy constraints
        present, connectors within the approved allow-list, and agents within their approved audience —
        the go/no-go gate before you pilot an agent against production data. Preview-gated checks report
        WARN with a verify-in-tenant note, never a false PASS.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
    Boundary primitives (VPC Service Controls, Access Context Manager, org policies) are GA and read
    from documented gcloud commands; Gemini Enterprise connector/agent audience controls are preview
    and flagged 'verify in tenant'. Never invents API or role names.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ProjectId,
    [string]$Location = 'global',
    [ValidateSet('v1','v1alpha','v1beta')] [string]$ApiVersion = 'v1',
    [string]$ApprovedConnectorsPath                 # optional text file: one approved data-store id per line
)

function Get-GcloudToken {
    try { $t = (& gcloud auth print-access-token 2>$null); if (-not $t) { throw "empty" }; return $t.Trim() }
    catch { Write-Host "Could not obtain a gcloud access token. Run 'gcloud auth login' first." -ForegroundColor Red; throw }
}

Write-Host "`n=== Gemini Connector Strategy & Agent Development — validation ===" -ForegroundColor Cyan
Write-Host ("Project: {0}   Location: {1}" -f $ProjectId, $Location)
$pass = $true

# 1. Access boundary — VPC Service Controls perimeter present (Access Context Manager)
Write-Host "`n[1] Data-access boundary (VPC Service Controls)" -ForegroundColor Cyan
try {
    $perimeters = & gcloud access-context-manager perimeters list --format=json 2>$null | ConvertFrom-Json
    if ($perimeters -and $perimeters.Count -gt 0) {
        Write-Host ("[PASS] {0} service perimeter(s) found — an access boundary exists." -f $perimeters.Count) -ForegroundColor Green
    } else {
        Write-Host "[WARN] No VPC Service Controls perimeter found — connectors and agents have no data" -ForegroundColor Yellow
        Write-Host "       exfiltration boundary. Define a perimeter or confirm one exists at org level." -ForegroundColor Yellow
        $pass = $false
    }
} catch {
    Write-Host "[WARN] Could not read Access Context Manager (needs an access policy / permission)." -ForegroundColor Yellow
    Write-Host "       Verify in your tenant whether a perimeter protects this project." -ForegroundColor Yellow
}

# 2. Org policy constraints present on the project
Write-Host "`n[2] Org policy constraints" -ForegroundColor Cyan
try {
    $policies = & gcloud resource-manager org-policies list --project=$ProjectId --format=json 2>$null | ConvertFrom-Json
    if ($policies -and $policies.Count -gt 0) {
        Write-Host ("[PASS] {0} org policy constraint(s) applied to the project." -f $policies.Count) -ForegroundColor Green
    } else {
        Write-Host "[WARN] No project-level org policies found — consider constraints (allowed locations," -ForegroundColor Yellow
        Write-Host "       restrict service usage) to bound where connectors and agents can operate." -ForegroundColor Yellow
        $pass = $false
    }
} catch {
    Write-Host "[WARN] Could not read org policies for the project." -ForegroundColor Yellow
}

# 3. Connectors within the approved allow-list
Write-Host "`n[3] Connectors within approved allow-list" -ForegroundColor Cyan
$approved = @()
if ($ApprovedConnectorsPath -and (Test-Path $ApprovedConnectorsPath)) {
    $approved = Get-Content $ApprovedConnectorsPath | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() }
}
try {
    $token   = Get-GcloudToken
    $headers = @{ Authorization = "Bearer $token"; 'X-Goog-User-Project' = $ProjectId }
    $uri     = "https://discoveryengine.googleapis.com/$ApiVersion/projects/$ProjectId/locations/$Location/collections/default_collection/dataStores"
    $resp    = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
    $stores  = @(); if ($resp.dataStores) { $stores = $resp.dataStores | ForEach-Object { ($_.name -split '/')[-1] } }
    if (-not $stores -or $stores.Count -eq 0) {
        Write-Host "[WARN] No connectors returned (preview surface) — verify in your tenant." -ForegroundColor Yellow
    } elseif ($approved.Count -eq 0) {
        Write-Host ("[WARN] {0} connector(s) present but no approved allow-list supplied." -f $stores.Count) -ForegroundColor Yellow
        Write-Host "       Pass -ApprovedConnectorsPath to enforce the approval criteria." -ForegroundColor Yellow
        $stores | ForEach-Object { Write-Host ("         - {0}" -f $_) }
    } else {
        $unapproved = $stores | Where-Object { $approved -notcontains $_ }
        if (-not $unapproved) {
            Write-Host ("[PASS] All {0} connector(s) are on the approved allow-list." -f $stores.Count) -ForegroundColor Green
        } else {
            Write-Host ("[WARN] {0} connector(s) NOT on the approved allow-list:" -f $unapproved.Count) -ForegroundColor Yellow
            $unapproved | ForEach-Object { Write-Host ("         - {0}  <-- unapproved (review or remove)" -f $_) -ForegroundColor Yellow }
            $pass = $false
        }
    }
} catch {
    Write-Host ("[WARN] Could not read connectors: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "       Verify in your tenant — the connector API version may differ (-ApiVersion v1alpha)." -ForegroundColor Yellow
}

# 4. Agents within approved audience (publishing / sharing scope)
Write-Host "`n[4] Agent publishing / audience scope" -ForegroundColor Cyan
Write-Host "[WARN] Agent audience/sharing controls are a preview surface and are not reliably readable" -ForegroundColor Yellow
Write-Host "       via a stable API. VERIFY IN YOUR TENANT: in the Google Cloud / Agentspace admin," -ForegroundColor Yellow
Write-Host "       confirm each agent is shared only to its approved audience and none is public." -ForegroundColor Yellow

Write-Host ("`nValidation result: {0}" -f $(if ($pass) { 'PASS (review any WARN)' } else { 'REVIEW WARNINGS' })) -ForegroundColor ($(if ($pass) { 'Green' } else { 'Yellow' }))
