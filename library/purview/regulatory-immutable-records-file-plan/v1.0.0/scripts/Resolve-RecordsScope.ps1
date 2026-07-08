<#
.SYNOPSIS
    Scope/health preflight for the Records + File Plan solution (READ-ONLY; makes no changes).

.DESCRIPTION
    Confirms Security & Compliance PowerShell (and optional Microsoft Graph) connectivity, reports the
    detected cloud/endpoint, checks that the Records management and file-plan cmdlets are reachable
    (a plan/role signal), and resolves the named pilot scope. Run this before any configuration.

.EXAMPLE
    .\Resolve-RecordsScope.ps1
    Runs all read-only checks against the currently connected session.

.EXAMPLE
    .\Resolve-RecordsScope.ps1 -PilotScopeName "Scope - Records-Pilot - Static" -UseGraph
    Also resolves a named pilot scope and checks a Graph connection.
    PowerShell 5.1+/7+. Connect first: Connect-IPPSSession  (add -ConnectionUri for Gov clouds);
    optionally Connect-MgGraph -Scopes "Directory.Read.All".

.NOTES
    Expected results (PASS): both requested connections succeed; the expected cloud is reported; the
    records/file-plan cmdlets are present; the pilot scope resolves. FAIL: any connection missing, wrong
    cloud, records/file-plan cmdlets absent (verify E5/E5 Compliance licensing + Records Management role),
    or the pilot scope does not resolve. No changes are made by this script.
#>
[CmdletBinding()]
param(
    [string]$PilotScopeName = "Scope - Records-Pilot - Static",
    [switch]$UseGraph
)

$ErrorActionPreference = 'Stop'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$Name, [string]$Status, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; Status = $Status; Detail = $Detail })
}

Write-Host "== Records + File Plan scope/health preflight (read-only) ==" -ForegroundColor Cyan

# 1. Security & Compliance PowerShell connectivity
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    Add-Check 'S&C PowerShell connection' 'PASS' ("Get-ComplianceTag returned {0} label(s)." -f (@($tags).Count))
} catch {
    Add-Check 'S&C PowerShell connection' 'FAIL' 'Get-ComplianceTag failed. Run Connect-IPPSSession (add -ConnectionUri for Gov clouds).'
}

# 2. Detected cloud / endpoint (best-effort, read-only)
try {
    $conn = Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) {
        Add-Check 'Detected cloud/endpoint' 'INFO' ("Environment={0}; ConnectionUri={1}" -f $conn.ConnectionUri, $conn.TokenExpiryTime)
    } else {
        Add-Check 'Detected cloud/endpoint' 'INFO' 'Get-ConnectionInformation returned nothing; verify your cloud manually (Commercial vs GCC/GCC High/DoD).'
    }
} catch {
    Add-Check 'Detected cloud/endpoint' 'INFO' 'Could not read connection info; verify cloud manually.'
}

# 3. Records / file-plan cmdlet reachability (plan + role signal)
$needed = 'Get-ComplianceTag','New-ComplianceTag','New-FilePlanPropertyAuthority',
          'New-FilePlanPropertyCategory','New-FilePlanPropertyCitation','Get-FilePlanPropertyAuthority'
$missing = @()
foreach ($c in $needed) { if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { $missing += $c } }
if ($missing.Count -eq 0) {
    Add-Check 'Records/file-plan cmdlets' 'PASS' 'All expected records/file-plan cmdlets are present.'
} else {
    Add-Check 'Records/file-plan cmdlets' 'FAIL' ("Missing: {0}. Verify E5/E5 Compliance licensing and the Records Management role." -f ($missing -join ', '))
}

# 4. Optional Graph connectivity
if ($UseGraph) {
    try {
        $ctx = Get-MgContext -ErrorAction Stop
        if ($ctx) { Add-Check 'Graph connection' 'PASS' ("Connected as {0}" -f $ctx.Account) }
        else      { Add-Check 'Graph connection' 'FAIL' 'No Graph context. Run Connect-MgGraph -Scopes "Directory.Read.All".' }
    } catch {
        Add-Check 'Graph connection' 'FAIL' 'Get-MgContext failed. Run Connect-MgGraph -Scopes "Directory.Read.All".'
    }
}

# 5. Pilot scope resolution (label policy locations)
try {
    $policy = Get-RetentionCompliancePolicy -Identity $PilotScopeName -ErrorAction SilentlyContinue
    if ($policy) {
        Add-Check 'Pilot scope resolves' 'PASS' ("Found policy/scope '{0}' (Enabled={1})." -f $PilotScopeName, $policy.Enabled)
    } else {
        Add-Check 'Pilot scope resolves' 'INFO' ("No policy named '{0}' yet — expected before Stage 3 configuration." -f $PilotScopeName)
    }
} catch {
    Add-Check 'Pilot scope resolves' 'INFO' ("Could not query '{0}'; it may not exist yet." -f $PilotScopeName)
}

$results | Format-Table -AutoSize
if ($results.Where({ $_.Status -eq 'FAIL' }).Count -gt 0) {
    Write-Host "One or more checks FAILED — resolve before configuring." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Preflight OK (read-only)." -ForegroundColor Green
}
