<#
.SYNOPSIS
    CAIG-Discovery.ps1 — GCC High sovereign-cloud + local device state for Conditional Access.
.DESCRIPTION
    PURPOSE
        Confirms you are targeting the US Government (GCC High) cloud and reports the facts CA
        decisions depend on. Shows the active Microsoft Graph environment (must be graph.microsoft.us),
        the local Entra join / PRT state, and an inventory of current Conditional Access policies.
        Read-only. Use it first, before making any changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAIG-Discovery.ps1
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All'
    EXPECTED RESULTS
        Graph host = graph.microsoft.us (USGov), device Entra-join/PRT summary, and a policy count.
        PASS when the environment shows USGov; FAIL/wrong-cloud if it shows graph.microsoft.com.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param()

Write-Host "=== Conditional Access (GCC High) — discovery: $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# --- Local device state (offline, no Graph needed) ---
$dsreg = (dsregcmd /status) 2>$null
$aad = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$prt = ($dsreg | Select-String 'AzureAdPrt\s*:\s*YES') -ne $null
$mdm = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
Write-Host ("Entra joined : {0}" -f ($(if($aad){'YES'}else{'NO'}))) -ForegroundColor ($(if($aad){'Green'}else{'Yellow'}))
Write-Host ("PRT present  : {0} (needed for seamless SSO + device-based CA)" -f ($(if($prt){'YES'}else{'NO'}))) -ForegroundColor ($(if($prt){'Green'}else{'Yellow'}))
Write-Host ("MDM enrolled : {0}" -f ($(if($mdm){'YES'}else{'NO'})))

# --- US Gov Graph connection ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All' -NoWelcome

$ctx = Get-MgContext
$env = $ctx.Environment
Write-Host ""
Write-Host ("Graph environment : {0}" -f $env) -ForegroundColor ($(if($env -eq 'USGov'){'Green'}else{'Red'}))
if ($env -ne 'USGov') {
    Write-Host "WRONG CLOUD: not connected to US Gov (graph.microsoft.us). Reconnect with -Environment USGov." -ForegroundColor Red
} else {
    Write-Host "Graph host        : https://graph.microsoft.us (GCC High)" -ForegroundColor Green
}

# --- Conditional Access policy inventory ---
try {
    $pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
    $enf = ($pols | Where-Object state -eq 'enabled').Count
    $ro  = ($pols | Where-Object state -eq 'enabledForReportingButNotEnforced').Count
    $off = ($pols | Where-Object state -eq 'disabled').Count
    Write-Host ("`nConditional Access policies: {0} total  |  enforced {1}  |  report-only {2}  |  disabled {3}" -f $pols.Count, $enf, $ro, $off) -ForegroundColor Cyan
} catch {
    Write-Host "Could not read CA policies (check role / scopes: Policy.Read.All)." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
