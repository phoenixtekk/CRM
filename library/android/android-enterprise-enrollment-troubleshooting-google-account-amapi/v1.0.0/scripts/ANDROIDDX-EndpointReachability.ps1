<#
.SYNOPSIS
    ANDROIDDX-EndpointReachability.ps1 — test Google/Microsoft endpoint reachability and diff a dev-vs-prod config snapshot (read-only).
.DESCRIPTION
    PURPOSE
        Two safe, read-only jobs behind one helper. (1) Default mode: from the network a device
        enrolls on, tests TCP 443 reachability to the managed Google Play / Android and Intune / Entra
        service endpoints that enrollment and "add a Google account" depend on, producing the
        'Endpoint Allowlist - Android - Verified' artifact. (2) -CompareConfig mode: diffs two JSON
        config snapshots (e.g. a dev tenant vs a prod tenant) to expose the setting that differs when
        enrollment "works in dev but fails in prod". Nothing is written to any tenant.
    HOW TO RUN
        Reachability:   powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-EndpointReachability.ps1 -CsvPath C:\Temp\endpoints.csv
        Custom list:    powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-EndpointReachability.ps1 -Endpoints @('play.google.com','enrollment.manage.microsoft.com')
        Dev/Prod diff:  powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-EndpointReachability.ps1 -CompareConfig -DevJson .\dev-config.json -ProdJson .\prod-config.json
        Reachability mode needs no Graph connection. Snapshots for -CompareConfig are produced by
        ANDROIDDX-DiagnosticReport.ps1 -JsonPath (or any two comparable exports).
    EXPECTED RESULTS
        Every endpoint 'Reachable' = the network is not blocking enrollment/account-add. Any 'Blocked'
        is a proxy/firewall root cause. In -CompareConfig, the printed differences are the dev-vs-prod
        drift to reconcile.
.NOTES
    Android. Read-only: network probes + local JSON diff; no tenant writes.
    The endpoint list below is a documented CORE set and is NOT exhaustive — Google and Microsoft
    publish and update the authoritative allowlists (Intune network endpoints; Android Enterprise
    network requirements). VERIFY against those current lists for your tenant/region before allowlisting.
#>
[CmdletBinding()] param(
    [string[]]$Endpoints,
    [int]$Port = 443,
    [string]$CsvPath,
    [switch]$CompareConfig,
    [string]$DevJson,
    [string]$ProdJson
)

if ($CompareConfig) {
    if (-not (Test-Path $DevJson) -or -not (Test-Path $ProdJson)) { throw "Both -DevJson and -ProdJson must exist for -CompareConfig." }
    Write-Host "=== Dev vs Prod config diff ===" -ForegroundColor Cyan
    $dev = Get-Content $DevJson -Raw | ConvertFrom-Json
    $prod = Get-Content $ProdJson -Raw | ConvertFrom-Json
    function Get-Leaves($obj,$prefix=''){
        $out=@{}
        if ($null -eq $obj) { return $out }
        if ($obj -is [System.Management.Automation.PSCustomObject]) {
            foreach ($p in $obj.PSObject.Properties) { (Get-Leaves $p.Value ("$prefix$($p.Name).")).GetEnumerator() | ForEach-Object { $out[$_.Key]=$_.Value } }
        } elseif ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [string])) {
            $i=0; foreach ($item in $obj) { (Get-Leaves $item ("$prefix[$i].")).GetEnumerator() | ForEach-Object { $out[$_.Key]=$_.Value }; $i++ }
        } else { $out[$prefix.TrimEnd('.')] = $obj }
        return $out
    }
    $dl = Get-Leaves $dev; $pl = Get-Leaves $prod
    $keys = ($dl.Keys + $pl.Keys) | Sort-Object -Unique
    $diffs = foreach ($k in $keys) {
        $dv = $dl[$k]; $pv = $pl[$k]
        if ("$dv" -ne "$pv") { [pscustomobject]@{ Setting=$k; Dev=$dv; Prod=$pv } }
    }
    if ($diffs) { $diffs | Format-Table -AutoSize; Write-Host ("`n{0} setting(s) differ dev-vs-prod — reconcile these first." -f @($diffs).Count) -ForegroundColor Yellow }
    else { Write-Host "No differences — the two snapshots are identical; look outside config (endpoints, account model, device state)." -ForegroundColor Green }
    return
}

# Documented CORE endpoint set — VERIFY against current Microsoft/Google allowlists (see .NOTES).
if (-not $Endpoints) {
    $Endpoints = @(
        # Google — managed Google Play / Android
        'play.google.com','accounts.google.com','android.clients.google.com','www.googleapis.com',
        'android.googleapis.com','play.googleapis.com','gstatic.com','www.google.com',
        # Microsoft — Intune / Entra enrollment and sign-in
        'login.microsoftonline.com','enrollment.manage.microsoft.com','portal.manage.microsoft.com',
        'm.manage.microsoft.com','graph.microsoft.com','manage.microsoft.com'
    )
}

Write-Host ("=== Endpoint reachability (TCP {0}) — run this FROM the device enrollment network ===" -f $Port) -ForegroundColor Cyan
$rows = foreach ($e in $Endpoints) {
    $ok = $false; $detail = ''
    try {
        $t = Test-NetConnection -ComputerName $e -Port $Port -WarningAction SilentlyContinue
        $ok = [bool]$t.TcpTestSucceeded; $detail = ("RemoteAddress={0}" -f $t.RemoteAddress)
    } catch { $detail = $_.Exception.Message }
    [pscustomobject]@{ Endpoint=$e; Port=$Port; Result=($(if($ok){'Reachable'}else{'Blocked'})); Detail=$detail }
}
$rows | Format-Table -AutoSize
$blocked = @($rows | Where-Object { $_.Result -eq 'Blocked' })
Write-Host ("`nReachable: {0}  Blocked: {1}" -f (@($rows).Count-$blocked.Count), $blocked.Count) -ForegroundColor $(if($blocked.Count){'Red'}else{'Green'})
if ($blocked.Count) { Write-Host "Blocked endpoints are a proxy/firewall/SSL-inspection root cause for 'can't add a Google account' and stalled enrollment. Allowlist per the current Google/Microsoft lists and exempt Google/Microsoft hosts from TLS inspection." -ForegroundColor Yellow }
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath (record as 'Endpoint Allowlist - Android - Verified')." -ForegroundColor Green }
