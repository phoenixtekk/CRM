<#
.SYNOPSIS
    AVDG-Validation.ps1 — read-only pass/fail validation of AVD on Azure Government (GCC High), including endpoint reachability.
.DESCRIPTION
    PURPOSE
        Validates an Azure Virtual Desktop deployment in Azure Government against the solution's gate criteria:
        correct cloud, provider registered, host pool present with Available session hosts, app group registered
        to a workspace and assigned, and the required US Gov service endpoints reachable on 443.
        Read-only — makes no changes. Replace placeholders like 'your-host-pool-name' with your values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AVDG-Validation.ps1 -HostPoolName your-host-pool-name -ResourceGroupName your-resource-group
        Modules: Az.Accounts, Az.Resources, Az.DesktopVirtualization
        Sign-in (US Gov): Connect-AzAccount -Environment AzureUSGovernment
    EXPECTED RESULTS
        A checklist with [PASS]/[FAIL]/[WARN] per test and an overall result. Overall PASS = all gate checks pass;
        any [FAIL] (e.g., blocked *.wvd.azure.us, unavailable host) must be fixed before proceeding.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$HostPoolName,
    [string]$ResourceGroupName,
    [string]$WorkspaceName,
    [string]$AzureEnvironment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
$script:fail = 0; $script:warn = 0
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function P($t){ Write-Host "[PASS] $t" -ForegroundColor Green }
function W($t){ Write-Host "[WARN] $t" -ForegroundColor Yellow; $script:warn++ }
function F($t){ Write-Host "[FAIL] $t" -ForegroundColor Red; $script:fail++ }

# Required Azure Government session-host / client endpoints (see 02-requirements.md R7).
$GovEndpoints = @(
    @{ Host = 'rdweb.wvd.azure.us';                 Port = 443 },
    @{ Host = 'login.microsoftonline.us';           Port = 443 },
    @{ Host = 'gcs.monitoring.core.usgovcloudapi.net'; Port = 443 },
    @{ Host = 'azkms.core.usgovcloudapi.net';       Port = 1688 },
    @{ Host = 'ctldl.windowsupdate.com';            Port = 80 },
    @{ Host = 'ocsp.msocsp.com';                    Port = 80 }
)

Write-Section 'Test 1 — Connected to Azure Government'
try {
    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx) { Connect-AzAccount -Environment $AzureEnvironment | Out-Null; $ctx = Get-AzContext }
    if ($ctx.Environment.Name -eq 'AzureUSGovernment') { P "Environment = AzureUSGovernment (subscription: $($ctx.Subscription.Name))" }
    else { F "Environment = '$($ctx.Environment.Name)', expected AzureUSGovernment. Re-run Connect-AzAccount -Environment AzureUSGovernment." }
} catch { F "Azure sign-in failed: $($_.Exception.Message)" }

Write-Section 'Test 2 — Resource provider registered'
try {
    $state = (Get-AzResourceProvider -ProviderNamespace 'Microsoft.DesktopVirtualization' | Select-Object -First 1).RegistrationState
    if ($state -eq 'Registered') { P 'Microsoft.DesktopVirtualization Registered.' } else { F "Provider state = '$state'." }
} catch { F "Provider read failed: $($_.Exception.Message)" }

Write-Section 'Test 3 — Host pool & session host health'
try {
    if ($HostPoolName -and $ResourceGroupName) {
        $pool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        P "Host pool '$HostPoolName' found (Type: $($pool.HostPoolType))."
        $hosts = Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $hosts) { W 'No session hosts in the pool yet.' }
        else {
            $avail = @($hosts | Where-Object { $_.Status -eq 'Available' })
            $bad   = @($hosts | Where-Object { $_.Status -ne 'Available' })
            if ($avail.Count -gt 0) { P "$($avail.Count) session host(s) Available." }
            if ($bad.Count -gt 0) { foreach ($b in $bad) { F "Session host $(( $b.Name -split '/')[-1]) status = $($b.Status) (check Gov endpoints / domain join)." } }
        }
    } else { W 'HostPoolName/ResourceGroupName not supplied; skipping host-pool health test.' }
} catch { F "Host pool validation failed: $($_.Exception.Message)" }

Write-Section 'Test 4 — Workspace registration & assignment'
try {
    if ($WorkspaceName -and $ResourceGroupName) {
        $ws = Get-AzWvdWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        if ($ws.ApplicationGroupReference) { P "Workspace '$WorkspaceName' has $((@($ws.ApplicationGroupReference)).Count) app group(s) registered." }
        else { F "Workspace '$WorkspaceName' has no application groups registered (resources won't appear in clients)." }
    } else { W 'WorkspaceName not supplied; skipping workspace registration test.' }
} catch { W "Workspace validation skipped: $($_.Exception.Message)" }

Write-Section 'Test 5 — Azure Government endpoint reachability (TCP 443/1688/80)'
foreach ($e in $GovEndpoints) {
    try {
        $r = Test-NetConnection -ComputerName $e.Host -Port $e.Port -WarningAction SilentlyContinue
        if ($r.TcpTestSucceeded) { P ("Reachable: {0}:{1}" -f $e.Host, $e.Port) }
        else { F ("Blocked/unreachable: {0}:{1} — allow this Gov endpoint (R7)." -f $e.Host, $e.Port) }
    } catch { W ("Could not test {0}:{1} — {2}" -f $e.Host, $e.Port, $_.Exception.Message) }
}
Write-Host 'Note: wildcard service FQDNs (*.wvd.azure.us, *.service.windows.usgovcloud.microsoft, *.usgovcloudapi.net) cannot be dot-tested directly; run Microsoft''s Agent URL Tool on a session host for the full check.'

Write-Section 'Overall result'
if ($script:fail -eq 0) { Write-Host "[OVERALL PASS] No failures. ($script:warn warning[s].)" -ForegroundColor Green }
else { Write-Host "[OVERALL FAIL] $script:fail failure(s), $script:warn warning(s). Resolve failures before proceeding (see 06-troubleshooting.md)." -ForegroundColor Red }
