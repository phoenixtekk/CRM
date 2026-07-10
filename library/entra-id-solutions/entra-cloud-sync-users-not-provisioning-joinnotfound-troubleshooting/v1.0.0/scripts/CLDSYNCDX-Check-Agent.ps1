<#
.SYNOPSIS
    CLDSYNCDX-Check-Agent.ps1 — focused Entra Connect cloud sync provisioning-agent health check on this host.
.DESCRIPTION
    PURPOSE
        Checks, with PASS/FAIL per precondition, everything the cloud sync provisioning agent needs to
        be healthy on this host: the "Microsoft Entra Provisioning Agent" and "Microsoft Entra Connect
        Agent Updater" services are Running, the PowerShell execution policy is workable (not
        Unrestricted), a sample outbound 443 endpoint is reachable, and an agent config / proxy is
        present. Prints the exact remedy for each FAIL. Read-only: it never changes anything.
    HOW TO RUN
        Run ELEVATED on the provisioning-agent host:
            powershell -ExecutionPolicy Bypass -File .\CLDSYNCDX-Check-Agent.ps1
            powershell -ExecutionPolicy Bypass -File .\CLDSYNCDX-Check-Agent.ps1 -TestEndpoint login.microsoftonline.com
        No Microsoft Graph scopes needed — this inspects the local host only.
    EXPECTED RESULTS
        A PASS/FAIL line per precondition; each FAIL prints its remedy (start the service, open outbound
        443, set the proxy, adjust the execution policy). All PASS => the agent side is healthy; move to
        the tenant-side checks (see 06-troubleshooting.md §Agent health).
.NOTES
    White-label — the repeatable way. Read-only local inspection. Cloud sync service internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $TestEndpoint = 'login.microsoftonline.com'
)

$ErrorActionPreference = 'Continue'
Write-Host "=== Entra Connect Cloud Sync — Agent Health Check ===" -ForegroundColor Cyan
Write-Host "Host: $env:COMPUTERNAME`n"

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string]$Name, [bool]$Pass, [string]$Detail, [string]$Remedy)
    $results.Add([pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail; Remedy = $Remedy })
}

# 1 + 2. Agent services Running.
foreach ($svcName in @('Microsoft Entra Provisioning Agent', 'Microsoft Entra Connect Agent Updater')) {
    $svc = Get-Service -DisplayName $svcName -ErrorAction SilentlyContinue
    $running = ($svc -and $svc.Status -eq 'Running')
    Add-Result ("Service running: {0}" -f $svcName) $running `
        $(if ($svc) { ("status: {0}" -f $svc.Status) } else { 'service not found' }) `
        ("Start the '{0}' service (set Startup type = Automatic); if it will not stay running, collect the Trace folder with CLDSYNCDX-Collect-Diagnostics.ps1." -f $svcName)
}

# 3. Execution policy workable (not Unrestricted; ideally RemoteSigned/Undefined/Bypass).
$policy = Get-ExecutionPolicy
$policyOk = ($policy -ne 'Unrestricted')
Add-Result 'Execution policy is workable (not Unrestricted)' $policyOk `
    ("effective policy: {0}" -f $policy) `
    'Run tools with -ExecutionPolicy Bypass for the session, or set RemoteSigned; avoid leaving the machine Unrestricted.'

# 4. Outbound 443 reachability to a sample endpoint.
$net = $null
try { $net = Test-NetConnection -ComputerName $TestEndpoint -Port 443 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue } catch {}
$reachable = [bool]($net -and $net.TcpTestSucceeded)
Add-Result ("Outbound 443 reachable: {0}" -f $TestEndpoint) $reachable `
    $(if ($net) { ("TcpTestSucceeded: {0}" -f $net.TcpTestSucceeded) } else { 'test could not run' }) `
    'Open outbound 80/443 to the documented Microsoft endpoints from this host through the proxy/firewall, then restart the agent services.'

# 5. Agent config / proxy present.
$agentDir = Join-Path $env:ProgramData 'Microsoft\Azure AD Connect Provisioning Agent'
$cfgPresent = Test-Path $agentDir
$proxyLine = ((netsh winhttp show proxy) 2>$null | Out-String).Trim()
Add-Result 'Agent data folder / proxy config present' $cfgPresent `
    ("agent folder: {0}; winhttp proxy: {1}" -f $(if ($cfgPresent) { 'present' } else { 'MISSING' }), $(if ($proxyLine) { ($proxyLine -replace '\s+', ' ') } else { 'n/a' })) `
    'If the host uses a proxy, configure the agent for it per Microsoft guidance and restart the agent services; a missing agent folder means the agent is not installed here.'

# --- Report ------------------------------------------------------------------
$results | Format-Table Check, Result, Detail -AutoSize -Wrap
$fails = @($results | Where-Object { $_.Result -eq 'FAIL' })
Write-Host ""
if ($fails.Count -eq 0) {
    Write-Host "OVERALL: PASS — the agent-host side is healthy; move to the tenant-side checks (CLDSYNCDX-Check-Provisioning.ps1)." -ForegroundColor Green
} else {
    Write-Host "OVERALL: FAIL — remedy each item below, then re-run:" -ForegroundColor Red
    foreach ($f in $fails) { Write-Host ("  [{0}] {1}" -f $f.Check, $f.Remedy) -ForegroundColor Yellow }
    Write-Host "See 06-troubleshooting.md (Agent health)." -ForegroundColor Yellow
}
Write-Host "Read-only: no changes were made." -ForegroundColor Green
