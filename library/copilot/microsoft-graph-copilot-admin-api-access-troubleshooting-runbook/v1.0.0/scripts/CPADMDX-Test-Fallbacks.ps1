<#
.SYNOPSIS
    CPADMDX-Test-Fallbacks.ps1 - Try the SUPPORTED alternatives to a blocked Copilot admin beta call
    (GA usage-reports endpoint, GA package-catalog path, and a pointer to admin-center / Purview audit
    fallbacks) so you can prove which supported path returns the data you need. READ-ONLY.

.DESCRIPTION
    PURPOSE
      When a /beta/copilot/admin/* call cannot be relied on (Branch F/J), this script exercises the
      supported fallbacks and reports which ones return data in YOUR tenant/cloud:
        1. GA usage reports:  GET /v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='D7')
        2. GA package catalog: GET /v1.0/copilot/admin/catalog/packages   (if offered in your cloud)
        3. Prints the non-API fallbacks (M365 admin center Agents export; Purview audit) to consider.
      It performs GET requests only and never fabricates a response.

    HOW TO RUN
      1. Connect with the fallback scopes:
           Connect-MgGraph -Environment Global -Scopes 'Reports.Read.All','CopilotPackages.Read.All'
      2. Run:
           .\CPADMDX-Test-Fallbacks.ps1 -Environment Global
           .\CPADMDX-Test-Fallbacks.ps1 -Environment USGov   # confirm what IS available in GCC High

    EXPECTED RESULTS
      For each fallback: the HTTP status and whether data came back, plus a recommendation. Writes
      CPADMDX-Diagnostics\CPADMDX-Fallbacks.json.

.NOTES
    Copilot category - read-only diagnostics for the Microsoft Graph Copilot admin (beta) API.
    Usage-reports API is GA; verify current period values and permissions against Microsoft Learn.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global',

    [ValidateSet('D7','D30','D90','D180','ALL')]
    [string]$Period = 'D7',

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

function Test-Endpoint([string]$name, [string]$uri) {
    $r = [ordered]@{ Name=$name; Uri=$uri; StatusCode=$null; HasData=$false; Note=$null }
    try {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop
        $r.StatusCode = 200
        if ($resp.value) { $r.HasData = @($resp.value).Count -gt 0; $r.Note = "$(@($resp.value).Count) row(s)" }
        elseif ($resp) { $r.HasData = $true; $r.Note = 'object returned' }
        else { $r.Note = 'empty' }
        Write-Host ("[{0}] HTTP 200  {1}" -f $name, $r.Note) -ForegroundColor Green
    }
    catch {
        $raw = $_.ErrorDetails.Message; if (-not $raw) { $raw = $_.Exception.Message }
        $code=$null;$msg=$raw
        try { $b = $raw | ConvertFrom-Json; if ($b.error){$code=$b.error.code;$msg=$b.error.message} } catch {}
        if ($raw -match '(\b\d{3}\b)') { $r.StatusCode = [int]$Matches[1] }
        $r.Note = "$code : $msg"
        Write-Host ("[{0}] FAILED  HTTP {1}  {2}" -f $name, $r.StatusCode, $code) -ForegroundColor Yellow
    }
    [pscustomobject]$r
}

if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes 'Reports.Read.All','CopilotPackages.Read.All' -NoWelcome | Out-Null
}
$base = Get-GraphHost $Environment
Write-Host "== CPADMDX Test-Fallbacks ($Environment) ==" -ForegroundColor Cyan

$results = @()
$results += Test-Endpoint 'GA Usage Reports' "$base/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')"
$results += Test-Endpoint 'GA Package Catalog (v1.0)' "$base/v1.0/copilot/admin/catalog/packages"

Write-Host ""
Write-Host "Non-API supported fallbacks to consider:" -ForegroundColor Cyan
Write-Host " - Microsoft 365 admin center > Agents (Agent Registry): manual/scheduled inventory export."
Write-Host "   (For a scheduled Agent Builder inventory + sharing export, see the sibling 'Agent Builder Inventory' product.)"
Write-Host " - Microsoft Purview: Copilot/agent activity in the audit log for compliance reporting."
if ($Environment -ne 'Global') {
    Write-Host " - NOTE: Copilot admin beta endpoints are Global-only today; in GCC High/DoD rely on the above." -ForegroundColor Yellow
}

$out = [pscustomobject]@{
    Timestamp   = (Get-Date).ToString('o')
    Environment = $Environment
    Results     = $results
    NonApiFallbacks = @('M365 admin center > Agents export','Microsoft Purview audit log')
}
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$out | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutputFolder 'CPADMDX-Fallbacks.json') -Encoding UTF8
Write-Host ""
Write-Host "Saved: $(Join-Path $OutputFolder 'CPADMDX-Fallbacks.json')" -ForegroundColor Green
return $out
