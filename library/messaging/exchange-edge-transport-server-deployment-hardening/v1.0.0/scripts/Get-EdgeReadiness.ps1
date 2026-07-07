<#
.SYNOPSIS
  Read-only readiness/discovery for an Edge Transport deployment (host, AD LDS, ports, DNS, EdgeSync).
.DESCRIPTION
  Inspects the local host and (optionally) an internal transport target to confirm Edge Transport
  readiness signals: OS/version, workgroup-vs-domain state, AD LDS presence, required ports (50636
  EdgeSync / 25 SMTP), name resolution both directions, and any existing Exchange/Edge subscription.
  Read-only: it changes nothing. Run on the Edge host (for host checks) and/or where the Exchange
  Management Shell is available (for EdgeSync checks).
.EXAMPLE
  .\Get-EdgeReadiness.ps1 -InternalTransport mbx01.corp.contoso.com
  # Read-only readiness report; checks port/DNS reachability to the named internal transport server.
  (PowerShell 5.1+/7+; Exchange Management Shell for the EdgeSync section on an Exchange host.)
.NOTES
  Expected results: a per-check PASS/WARN/INFO table. WARN on any failed port/DNS/AD-LDS check means
  fix before installing/subscribing the Edge (Gate A). No changes are made.
#>
[CmdletBinding()]
param(
    [string]$InternalTransport,
    [int[]]$Ports = @(50636, 25),
    [string]$EdgeFqdn = [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName
)

$results = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Name, [string]$Status, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; Status = $Status; Detail = $Detail })
}

Write-Host "Edge Transport readiness — read-only discovery" -ForegroundColor Cyan
Write-Host "Edge host FQDN: $EdgeFqdn`n"

# --- OS / version ---
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    Add-Check 'OS version' 'INFO' "$($os.Caption) ($($os.Version))"
} catch { Add-Check 'OS version' 'WARN' $_.Exception.Message }

# --- Domain-join state (Edge should be workgroup / perimeter, NOT internal AD) ---
try {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    if ($cs.PartOfDomain) {
        Add-Check 'Domain-join state' 'WARN' "Joined to domain '$($cs.Domain)'. Edge must be workgroup/perimeter — verify this is NOT the internal production AD."
    } else {
        Add-Check 'Domain-join state' 'PASS' "Workgroup ('$($cs.Workgroup)') — appropriate for a perimeter Edge."
    }
} catch { Add-Check 'Domain-join state' 'WARN' $_.Exception.Message }

# --- AD LDS role (required by the Edge role) ---
try {
    $adlds = Get-WindowsFeature -Name ADLDS -ErrorAction SilentlyContinue
    if (-not $adlds) { $adlds = Get-WindowsFeature -Name AD-LDS -ErrorAction SilentlyContinue }
    if ($adlds -and $adlds.Installed) { Add-Check 'AD LDS role' 'PASS' 'Installed.' }
    elseif ($adlds)                   { Add-Check 'AD LDS role' 'WARN' 'Present but NOT installed — install before Exchange Setup.' }
    else                              { Add-Check 'AD LDS role' 'INFO' 'Get-WindowsFeature unavailable here (verify on the Edge host).' }
} catch { Add-Check 'AD LDS role' 'INFO' $_.Exception.Message }

# --- Port reachability to the internal transport ---
if ($InternalTransport) {
    foreach ($p in $Ports) {
        try {
            $tnc = Test-NetConnection -ComputerName $InternalTransport -Port $p -WarningAction SilentlyContinue
            if ($tnc.TcpTestSucceeded) { Add-Check "Port $p -> $InternalTransport" 'PASS' 'Reachable.' }
            else                       { Add-Check "Port $p -> $InternalTransport" 'WARN' 'NOT reachable — check firewall (50636=EdgeSync, 25=SMTP).' }
        } catch { Add-Check "Port $p -> $InternalTransport" 'WARN' $_.Exception.Message }
    }
    # --- Name resolution both directions ---
    try {
        [void][System.Net.Dns]::GetHostEntry($InternalTransport)
        Add-Check 'DNS: Edge -> internal transport' 'PASS' "Resolved '$InternalTransport'."
    } catch { Add-Check 'DNS: Edge -> internal transport' 'WARN' "Could not resolve '$InternalTransport' (add DNS/HOSTS)." }
} else {
    Add-Check 'Port / DNS to internal transport' 'INFO' 'Pass -InternalTransport <fqdn> to test EdgeSync/SMTP reachability.'
}

# --- Existing Exchange / EdgeSync (only if EMS cmdlets are present) ---
if (Get-Command Get-EdgeSubscription -ErrorAction SilentlyContinue) {
    try {
        $subs = Get-EdgeSubscription -ErrorAction Stop
        if ($subs) { Add-Check 'Edge Subscription' 'INFO' (($subs | ForEach-Object Name) -join ', ') }
        else       { Add-Check 'Edge Subscription' 'INFO' 'None found (expected before subscribing).' }
    } catch { Add-Check 'Edge Subscription' 'INFO' $_.Exception.Message }
    if (Get-Command Test-EdgeSynchronization -ErrorAction SilentlyContinue) {
        try {
            $sync = Test-EdgeSynchronization -ErrorAction Stop
            $state = ($sync | Select-Object -First 1).SyncStatus
            $st = if ("$state" -match 'Normal') { 'PASS' } else { 'WARN' }
            Add-Check 'EdgeSync status' $st "SyncStatus: $state"
        } catch { Add-Check 'EdgeSync status' 'INFO' $_.Exception.Message }
    }
} else {
    Add-Check 'Exchange EdgeSync cmdlets' 'INFO' 'Not in an Exchange Management Shell — run the EdgeSync checks on an Exchange host.'
}

$results | Format-Table -AutoSize
$warn = ($results | Where-Object Status -eq 'WARN').Count
Write-Host ("`nReadiness: {0} WARN item(s). Gate A passes when host is perimeter, AD LDS present, ports 50636/25 reachable, and DNS resolves both ways." -f $warn) -ForegroundColor Yellow
Write-Host "Verify all version-specific prerequisites against Microsoft docs for your exact Exchange Server version/CU." -ForegroundColor DarkGray
