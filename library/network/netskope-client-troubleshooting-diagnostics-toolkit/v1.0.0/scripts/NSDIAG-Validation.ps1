<#
.SYNOPSIS
    NSDIAG-Validation.ps1 — connectivity, steering, and auth-state checks for the Netskope client.
.DESCRIPTION
    PURPOSE
        Read-only. Validates the endpoint's network fundamentals and the client's running state:
        DNS resolution, TCP reachability to one or more edge hostnames, client service/process up,
        and a decryption-cert presence check. Produces a clear PASS/FAIL summary for triage.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSDIAG-Validation.ps1 `
            -EdgeHost "<your-netskope-edge-hostname>" -EdgePort 443
        The edge hostname/port for your tenant are documented by Netskope — supply them explicitly.
    EXPECTED RESULTS
        DNS, TCP reachability, and client-up checks each report PASS/FAIL; an overall result prints.
.NOTES
    Network category — client troubleshooting toolkit. Read-only. Uses only standard OS facilities.
#>
[CmdletBinding()]
param(
    [string[]]$EdgeHost = @(),
    [int]$EdgePort = 443,
    [string]$DnsTestName = 'www.microsoft.com'
)

Write-Host "=== Netskope client validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$results = [ordered]@{}

# 1. DNS resolution
try {
    $null = Resolve-DnsName -Name $DnsTestName -ErrorAction Stop
    $results['DNS resolution'] = $true
} catch { $results['DNS resolution'] = $false }

# 2. Client service / process up
$svcUp = [bool](Get-Service -ErrorAction SilentlyContinue |
    Where-Object { ($_.Name -match 'netskope|stAgent' -or $_.DisplayName -match 'Netskope') -and $_.Status -eq 'Running' })
$procUp = [bool](Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'netskope|stAgent' })
$results['Client running'] = ($svcUp -or $procUp)

# 3. Decryption cert present (steering with inspection depends on it)
$certUp = [bool]( @('Cert:\LocalMachine\Root','Cert:\LocalMachine\CA') | ForEach-Object {
    Get-ChildItem $_ -ErrorAction SilentlyContinue | Where-Object { $_.Subject -match 'Netskope' -or $_.Issuer -match 'Netskope' }
} )
$results['Decryption cert present'] = $certUp

# 4. TCP reachability to the supplied edge host(s)
if ($EdgeHost.Count -eq 0) {
    Write-Host "No -EdgeHost supplied; TCP reachability skipped (supply the Netskope edge hostname per vendor docs)." -ForegroundColor Yellow
} else {
    foreach ($h in $EdgeHost) {
        $t = Test-NetConnection -ComputerName $h -Port $EdgePort -WarningAction SilentlyContinue
        $results["TCP $h`:$EdgePort"] = [bool]$t.TcpTestSucceeded
        if ($t.PingReplyDetails) { Write-Host ("  RTT to {0}: {1} ms" -f $h, $t.PingReplyDetails.RoundtripTime) -ForegroundColor DarkCyan }
    }
}

Write-Host "`n-- Check results --"
foreach ($k in $results.Keys) {
    $ok = $results[$k]
    Write-Host ("  {0,-28} {1}" -f $k, ($(if($ok){'PASS'}else{'FAIL'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
}

$overall = -not ($results.Values -contains $false)
if ($overall) { Write-Host "`nResult: VALIDATION PASSED" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: VALIDATION FAILED — see the failed checks; classify against the failure-class runbooks." -ForegroundColor Yellow; exit 1 }
