<#
.SYNOPSIS
    CPADMDX-Probe-Endpoint.ps1 - Call a Microsoft Graph Copilot admin (beta or GA) endpoint and DECODE
    the response, mapping 401/403/404/429 to the likely root-cause branch. READ-ONLY (GET only).

.DESCRIPTION
    PURPOSE
      Reproduces the failing call with the REAL status code and error body visible (the console UI
      often hides it), then prints the most likely runbook branch. It NEVER fabricates a response
      shape - on failure it reports exactly what Graph returned.

    HOW TO RUN
      1. Connect first (or let this script connect):  see CPADMDX-Preflight.ps1
      2. Probe the default package-catalog endpoint:
           .\CPADMDX-Probe-Endpoint.ps1 -Environment Global
      3. Probe a specific package by id, or any other admin path/version:
           .\CPADMDX-Probe-Endpoint.ps1 -Path 'copilot/admin/catalog/packages/{id}' -ApiVersion beta
           .\CPADMDX-Probe-Endpoint.ps1 -Path 'copilot/admin/policySettings/microsoft.copilot.allowwebsearch'
           .\CPADMDX-Probe-Endpoint.ps1 -Path 'copilot/admin/catalog/packages' -ApiVersion v1.0

    EXPECTED RESULTS
      On success: HTTP 200 and a short summary of the returned object (or 'value: null' for an
      unconfigured policy setting, which is a documented non-error).
      On failure: the HTTP status, error code, error message, request-id, and a printed branch
      pointer (A-J). Writes CPADMDX-Diagnostics\CPADMDX-Probe.json.

.NOTES
    Copilot category - read-only diagnostics for the Microsoft Graph Copilot admin (beta) API.
    GET requests only. Beta endpoints are subject to change; verify against current Microsoft docs.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global',

    # Path AFTER the version segment, e.g. 'copilot/admin/catalog/packages'
    [string]$Path = 'copilot/admin/catalog/packages',

    [ValidateSet('beta','v1.0')]
    [string]$ApiVersion = 'beta',

    [string[]]$Scopes = @('CopilotPackages.Read.All','CopilotPolicySettings.Read'),

    [string]$OutputFolder = '.\CPADMDX-Diagnostics'
)

$ErrorActionPreference = 'Stop'

function Get-GraphHost([string]$env) {
    switch ($env) {
        'USGov'    { 'https://graph.microsoft.us' }
        'USGovDoD' { 'https://dod-graph.microsoft.us' }
        default    { 'https://graph.microsoft.com' }
    }
}

if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes $Scopes -NoWelcome | Out-Null
}
$ctx = Get-MgContext
$authType = if ($ctx.AuthType) { $ctx.AuthType } elseif ($ctx.Account) { 'Delegated' } else { 'AppOnly' }
$uri = "$(Get-GraphHost $Environment)/$ApiVersion/$($Path.TrimStart('/'))"

Write-Host "== CPADMDX Probe ==" -ForegroundColor Cyan
Write-Host "GET $uri"
Write-Host "AuthType: $authType  |  Cloud: $Environment"
Write-Host ""

$finding = [ordered]@{
    Timestamp   = (Get-Date).ToString('o')
    Uri         = $uri
    ApiVersion  = $ApiVersion
    Environment = $Environment
    AuthType    = $authType
    StatusCode  = $null
    ErrorCode   = $null
    ErrorMessage= $null
    RequestId   = $null
    Branch      = $null
    Outcome     = $null
}

try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop
    $finding.StatusCode = 200
    $finding.Outcome = 'SUCCESS'
    Write-Host "HTTP 200 OK" -ForegroundColor Green
    if ($null -ne $resp.value) {
        Write-Host "Returned a collection with $(@($resp.value).Count) item(s)."
    }
    elseif ($resp.PSObject.Properties.Name -contains 'value' -and $null -eq $resp.value) {
        Write-Host "Returned 'value: null' - documented non-error (e.g. unconfigured policy setting)." -ForegroundColor Yellow
        $finding.Outcome = 'SUCCESS_NULL'
    }
    else {
        $id = $resp.id; $dn = $resp.displayName
        Write-Host "Returned object  id=$id  displayName=$dn"
    }
}
catch {
    $status = $null; $code = $null; $msg = $null; $reqId = $null; $retryAfter = $null
    $ex = $_.Exception
    if ($ex.Response) {
        try { $status = [int]$ex.Response.StatusCode } catch {}
        try { $retryAfter = $ex.Response.Headers['Retry-After'] } catch {}
    }
    # Try to parse the Graph error body from the exception message (JSON)
    $raw = $_.ErrorDetails.Message
    if (-not $raw) { $raw = $ex.Message }
    try {
        $body = $raw | ConvertFrom-Json
        if ($body.error) { $code = $body.error.code; $msg = $body.error.message; $reqId = $body.error.innerError.'request-id' }
    } catch { $msg = $raw }

    if (-not $status -and $raw -match '(\b\d{3}\b)') { $status = [int]$Matches[1] }

    $finding.StatusCode  = $status
    $finding.ErrorCode   = $code
    $finding.ErrorMessage= $msg
    $finding.RequestId   = $reqId
    $finding.Outcome     = 'FAILURE'

    Write-Host ("HTTP {0}  {1}" -f $status, $code) -ForegroundColor Red
    Write-Host ("message : {0}" -f $msg)
    if ($reqId) { Write-Host ("request-id: {0}" -f $reqId) }

    # --- Decode to a branch ---
    $branch = switch ($status) {
        401 { 'A - Authentication failed. Reconnect with a fresh token in the correct cloud.' }
        403 {
            if ($msg -match 'user context is required') {
                'B - App-only token rejected; the endpoint requires a DELEGATED user. Switch to interactive sign-in.'
            }
            elseif ($authType -eq 'AppOnly') {
                'B - You are app-only; these endpoints need delegated. (Confirm scope/role after switching.)'
            }
            else {
                'C/D/E/F/G - Delegated 403. Run CPADMDX-Resolve-Scopes.ps1: missing scope=C, ungranted consent=D, missing admin role=E; if all clean and Gov cloud=F; if license-gated=G.'
            }
        }
        404 { 'H - Path/namespace/version not found (verify exact route + version). If path is provably correct, it may be tenant/cloud not enabled (F/R8), or an unsupported policy-setting id.' }
        429 { "I - Throttled. Honor Retry-After ($retryAfter s) then retry; otherwise exponential backoff." }
        422 { 'policySettings only: 422 = setting is group-scoped; this endpoint returns tenant-level only.' }
        502 { 'policySettings only: 502 tooManyGroupPolicies = too many group-level policies in the tenant.' }
        default { 'J (or re-read Step 0) - unexpected status; capture the raw body and compare against a known-good tenant.' }
    }
    $finding.Branch = $branch
    Write-Host ""
    Write-Host "Likely branch -> $branch" -ForegroundColor Yellow
    if ($retryAfter) { $finding.RetryAfter = $retryAfter }
}

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
([pscustomobject]$finding) | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $OutputFolder 'CPADMDX-Probe.json') -Encoding UTF8
Write-Host ""
Write-Host "Saved: $(Join-Path $OutputFolder 'CPADMDX-Probe.json')" -ForegroundColor Green

return [pscustomobject]$finding
