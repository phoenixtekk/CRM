<#
.SYNOPSIS
    EGRESSG-Validation.ps1 — test reachability to representative Microsoft 365 GCC High endpoints from a real endpoint (read-only).
.DESCRIPTION
    PURPOSE
        Derives the current GCC High set from the USGOVGCCHigh instance, then tests TCP/UDP
        reachability from the machine it runs on to representative Gov endpoints across identity,
        Intune, Defender/EPM, Exchange, SharePoint, Teams and Graph. Intended to run on a pilot
        device behind the filtered egress path. No Microsoft IPs are hardcoded; test FQDNs are the
        documented Gov service names. Reports a PASS/FAIL table.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESSG-Validation.ps1
        (note the GCC High endpoints web-service instance: USGOVGCCHigh)
    EXPECTED RESULTS
        A table with one row per service area, each PASS (reachable) or FAIL (blocked). Overall
        PASS only when every required row is PASS. FAIL rows point you at the troubleshooting guide.
.NOTES
    White-label — the repeatable way. Read-only; queries the GCC High endpoints web service.
#>

#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('USGOVGCCHigh')]
    [string]$Instance = 'USGOVGCCHigh',
    [string]$WebServiceRoot = 'https://endpoints.office.com'
)

$ErrorActionPreference = 'Stop'
$clientRequestId = [guid]::NewGuid().Guid

# --- Confirm the GCC High instance before testing -------------------------------------------------
try {
    $version = Invoke-RestMethod -Uri "$WebServiceRoot/version/$Instance`?clientRequestId=$clientRequestId"
} catch {
    Write-Error "FAIL: could not reach the endpoints web service ($($_.Exception.Message))."
    exit 1
}
if ($version.instance -ne 'USGovGCCHigh') {
    Write-Error "FAIL: web service returned instance '$($version.instance)', expected 'USGovGCCHigh'. Wrong cloud."
    exit 1
}
Write-Host ("GCC High instance confirmed (version {0}). Running reachability tests..." -f $version.latest)
Write-Host ""

# --- Representative documented Gov endpoints (stable FQDNs, not IPs) -------------------------------
$tcpTargets = @(
    [pscustomobject]@{ Area='Identity';     Host='login.microsoftonline.us';                 Port=443 }
    [pscustomobject]@{ Area='Enrollment';   Host='enterpriseregistration.microsoftonline.us'; Port=443 }
    [pscustomobject]@{ Area='Graph';        Host='graph.microsoft.us';                       Port=443 }
    [pscustomobject]@{ Area='Exchange';     Host='outlook.office365.us';                     Port=443 }
    [pscustomobject]@{ Area='M365 portal';  Host='www.office365.us';                         Port=443 }
    [pscustomobject]@{ Area='Defender';     Host='security.microsoft.us';                    Port=443 }
)

# Wildcard service areas — probe a concrete host under the documented wildcard.
$wildcardTargets = @(
    [pscustomobject]@{ Area='Intune svc';   Host='portal.manage.microsoft.us';  Port=443; Note='under *.manage.microsoft.us (no-inspect)' }
    [pscustomobject]@{ Area='Defender/EPM'; Host='fef.msuc03.dm.microsoft.us';  Port=443; Note='under *.dm.microsoft.us (no-inspect)' }
    [pscustomobject]@{ Area='SharePoint';   Host='admin.onedrive.us';           Port=443; Note='OneDrive/SharePoint Gov admin' }
    [pscustomobject]@{ Area='Teams';        Host='gov.teams.microsoft.us';      Port=443; Note='under *.gov.teams.microsoft.us' }
)

function Test-TcpEndpoint {
    param([string]$TargetHost, [int]$Port)
    try {
        $r = Test-NetConnection -ComputerName $TargetHost -Port $Port -WarningAction SilentlyContinue
        return [bool]$r.TcpTestSucceeded
    } catch { return $false }
}

$results = New-Object System.Collections.Generic.List[object]

foreach ($t in ($tcpTargets + $wildcardTargets)) {
    $ok = Test-TcpEndpoint -TargetHost $t.Host -Port $t.Port
    $results.Add([pscustomobject]@{
        ServiceArea = $t.Area
        Endpoint    = ("{0}:{1}" -f $t.Host, $t.Port)
        Result      = if ($ok) { 'PASS' } else { 'FAIL' }
        Note        = ($t.PSObject.Properties['Note'].Value)
    })
}

# Teams media (UDP) — informational; UDP reachability is not reliably testable everywhere.
$results.Add([pscustomobject]@{
    ServiceArea = 'Teams media'
    Endpoint    = 'UDP 3478-3481'
    Result      = 'CHECK'
    Note        = 'Confirm UDP 3478-3481 allowed to derived Teams ranges; not TCP-testable'
})

$results | Format-Table -AutoSize | Out-String | Write-Host

$fails = $results | Where-Object Result -eq 'FAIL'
if ($fails) {
    Write-Host ""
    Write-Warning "OVERALL: FAIL — $($fails.Count) endpoint(s) unreachable. See 06-troubleshooting.md."
    Write-Host "If an SSL-inspected-sensitive endpoint failed, confirm it is on EGRESSG-NoInspect-GCCHigh."
    exit 1
} else {
    Write-Host ""
    Write-Host "OVERALL: PASS — all tested GCC High endpoints reachable. Confirm Teams UDP media manually."
}
