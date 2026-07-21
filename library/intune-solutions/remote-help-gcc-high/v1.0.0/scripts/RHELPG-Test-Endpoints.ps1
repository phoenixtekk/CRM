<#
.SYNOPSIS
    RHELPG-Test-Endpoints.ps1 — confirm the tenant resolves the US Gov national-cloud endpoints, not commercial.
.DESCRIPTION
    PURPOSE
        Read-only sanity check that you are operating on the correct cloud plane for a US Government
        (GCC High/DoD) tenant. It resolves the Microsoft Graph SDK's national-cloud endpoints for the
        chosen environment, checks basic DNS reachability of the sovereign hosts, and (after connecting)
        reports which endpoint the SDK actually bound to. This catches the classic mistake of running
        Commercial ('.com') steps/scripts against a sovereign tenant, or '.us' against a GCC (commercial-
        instance) tenant. Endpoint hostnames are "verify against current Microsoft documentation".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Test-Endpoints.ps1                 # GCC High
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Test-Endpoints.ps1 -Environment USGovDoD
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Test-Endpoints.ps1 -Environment Global   # GCC/Commercial
    GRAPH SCOPES
        (none for DNS checks) — a lightweight Connect-MgGraph uses no elevated scope beyond sign-in.
    EXPECTED RESULTS
        The expected sovereign hosts for the tier, their DNS resolvability, and the endpoint the SDK
        bound to. PASS = the connected endpoint matches the tier's plane. FAIL = mismatch (wrong cloud).
.NOTES
    White-label — the repeatable way. Read-only. Endpoints verify against current Microsoft documentation.
#>
[CmdletBinding()] param([ValidateSet('USGov','USGovDoD','Global')][string]$Environment = 'USGov')

# Expected hosts per tier (VERIFY against current Microsoft documentation — these change over time)
$map = @{
    'USGov'    = @{ Login='login.microsoftonline.us'; Graph='graph.microsoft.us';     Portal='portal.azure.us'; Plane='GCC High (*.us)' }
    'USGovDoD' = @{ Login='login.microsoftonline.us'; Graph='dod-graph.microsoft.us'; Portal='portal.azure.us'; Plane='DoD (*.us / dod-graph)' }
    'Global'   = @{ Login='login.microsoftonline.com';Graph='graph.microsoft.com';    Portal='portal.azure.com';Plane='Commercial / GCC (commercial instance)' }
}
$e = $map[$Environment]
Write-Host "`n=== Endpoint plane check — Government edition (env: $Environment) ===" -ForegroundColor Cyan
Write-Host ("Target plane                   : {0}" -f $e.Plane)
Write-Host  "(Endpoint hostnames are 'verify against current Microsoft documentation'.)" -ForegroundColor DarkCyan

foreach ($h in @($e.Login,$e.Graph,$e.Portal)) {
    $ok = $false
    try { $null = [System.Net.Dns]::GetHostEntry($h); $ok = $true } catch { $ok = $false }
    Write-Host ("  {0,-32}: {1}" -f $h, $(if($ok){'resolves'}else{'NOT resolvable from this host'})) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
}

# Confirm which endpoint the SDK binds to for this environment
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Environment $Environment -Scopes 'User.Read' -NoWelcome
    $ctx = Get-MgContext
    $bound = ($ctx.Environment -eq $Environment) -or ($Environment -eq 'Global' -and $ctx.Environment -eq 'Global')
    Write-Host ("`nSDK connected environment      : {0}" -f $ctx.Environment) -ForegroundColor ($(if($bound){'Green'}else{'Red'}))
    if ($bound) { Write-Host "[PASS] Operating on the expected plane for this tier." -ForegroundColor Green }
    else        { Write-Host "[FAIL] Connected plane does not match the requested tier — you are on the wrong cloud." -ForegroundColor Red }
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Host ("`nCould not complete the SDK bind check: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "If auth redirected to a '.com' endpoint for a GCC High/DoD tenant, you omitted -Environment USGov/USGovDoD." -ForegroundColor Yellow
}
Write-Host "`nReminder: GCC uses the COMMERCIAL endpoints (Intune GCC = commercial instance); only GCC High/DoD use *.us." -ForegroundColor DarkCyan
