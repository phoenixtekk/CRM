<#
.SYNOPSIS
    HYBIDG-Discovery.ps1 — read-only discovery of hybrid identity readiness on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Inventories the prerequisites for deploying Hybrid Identity with Entra Connect on a
        Microsoft 365 U.S. Government GCC High tenant: on-premises AD health, the Connect host,
        UPN/domain hygiene, and tenant/domain state read from Microsoft Graph US Gov. Read-only.
        Run it from the intended Connect host (for example the server named your-connect-host).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HYBIDG-Discovery.ps1
        (Graph scopes: Directory.Read.All, Domain.Read.All, Organization.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A section-by-section report. Each check prints PASS or FAIL with detail. Resolve every FAIL
        before configuring. No changes are made to AD or the tenant.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$OutputPath = ".\HYBIDG-Discovery-Report.txt"
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Area,[string]$Check,[bool]$Passed,[string]$Detail)
    $results.Add([pscustomobject]@{
        Area   = $Area
        Check  = $Check
        Status = if ($Passed) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
    $color = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} :: {2} — {3}" -f ($(if($Passed){'PASS'}else{'FAIL'}), $Area, $Check, $Detail)) -ForegroundColor $color
}

Write-Host "=== HYBIDG Discovery (Government / GCC High) — Environment: $Environment ===" -ForegroundColor Cyan

# --- On-premises Active Directory health ---
try {
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory -ErrorAction Stop
        $forest = Get-ADForest
        Add-Result 'AD' 'ActiveDirectory module & forest' $true "Forest: $($forest.Name)"
        $dcdiag = & dcdiag /q 2>&1 | Out-String
        $dcHealthy = -not ($dcdiag -match 'failed test')
        Add-Result 'AD' 'dcdiag' $dcHealthy $(if($dcHealthy){'No failed tests'}else{'dcdiag reported failed tests — investigate'})
        $repl = & repadmin /replsummary 2>&1 | Out-String
        $replHealthy = -not ($repl -match '\b[1-9][0-9]*\b\s+/\s+\d+')
        Add-Result 'AD' 'repadmin /replsummary' $replHealthy 'Review output if FAIL'
    } else {
        Add-Result 'AD' 'ActiveDirectory module' $false 'RSAT ActiveDirectory module not present on this host'
    }
} catch {
    Add-Result 'AD' 'AD health' $false $_.Exception.Message
}

# --- Connect host prerequisites ---
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $osOk = ([version]$os.Version).Major -ge 10
    Add-Result 'Host' 'Windows Server 2016+' $osOk "OS: $($os.Caption)"
    $tls = [Net.ServicePointManager]::SecurityProtocol
    $tlsOk = $tls -band [Net.SecurityProtocolType]::Tls12
    Add-Result 'Host' 'TLS 1.2 available' ([bool]$tlsOk) "SecurityProtocol: $tls"
    $psOk = $PSVersionTable.PSVersion.Major -ge 5
    Add-Result 'Host' 'PowerShell 5.1+' $psOk "PSVersion: $($PSVersionTable.PSVersion)"
} catch {
    Add-Result 'Host' 'Host prerequisites' $false $_.Exception.Message
}

# --- GCC High endpoint reachability (443) ---
$govEndpoints = @(
    'login.microsoftonline.us',
    'graph.microsoft.us',
    'syncservice.gov.us.microsoftonline.com'
)
foreach ($ep in $govEndpoints) {
    try {
        $t = Test-NetConnection -ComputerName $ep -Port 443 -WarningAction SilentlyContinue
        Add-Result 'Endpoints' "443 to $ep" $t.TcpTestSucceeded $(if($t.TcpTestSucceeded){'Reachable'}else{'Blocked — open on proxy/firewall'})
    } catch {
        Add-Result 'Endpoints' "443 to $ep" $false $_.Exception.Message
    }
}

# --- Microsoft Graph US Gov: tenant & domain state ---
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Add-Result 'Graph' 'Microsoft.Graph SDK installed' $false 'Install-Module Microsoft.Graph -Scope CurrentUser'
    } else {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Environment $Environment `
            -Scopes 'Directory.Read.All','Domain.Read.All','Organization.Read.All' -NoWelcome
        $ctx = Get-MgContext
        Add-Result 'Graph' "Connected to $Environment" ($null -ne $ctx) "Tenant: $($ctx.TenantId)"

        $domains = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/domains'
        $verified = @($domains.value | Where-Object { $_.isVerified -and $_.id -notlike '*.onmicrosoft.us' })
        Add-Result 'Graph' 'Verified public domain in Gov tenant' ($verified.Count -gt 0) `
            $(if($verified.Count -gt 0){"Verified: $($verified.id -join ', ')"}else{'No verified public (non-onmicrosoft.us) domain'})

        $org = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization'
        $syncEnabled = $org.value[0].onPremisesSyncEnabled
        Add-Result 'Graph' 'On-premises sync status (informational)' $true "onPremisesSyncEnabled: $syncEnabled"

        Disconnect-MgGraph | Out-Null
    }
} catch {
    Add-Result 'Graph' 'Microsoft Graph US Gov' $false $_.Exception.Message
}

# --- Summary ---
$fail = @($results | Where-Object Status -eq 'FAIL').Count
Write-Host "`n=== Summary: $($results.Count) checks, $fail FAIL ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$results | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "Report written to $OutputPath"
if ($fail -gt 0) { exit 1 } else { exit 0 }
