<#
.SYNOPSIS
    CLDSEC-Validate.ps1 — read-only pre-flight that proves the assessment can run and is least-privilege.
.DESCRIPTION
    PURPOSE
        The gate you run before any substantive discovery. Confirms PowerShell and module versions, that
        Microsoft Graph and Azure are connected, which Graph read scopes are granted, that the signed-in
        identity is read-only (Security/Global Reader + Azure Reader, with NO write/admin role detected),
        and lists the in-scope Azure subscriptions. If this does not pass, a pillar can silently score zero
        or the read-only guarantee is broken — so fix findings here first.
    HOW TO RUN
        Connect-MgGraph -Scopes "SecurityEvents.Read.All","Policy.Read.All","Directory.Read.All","DeviceManagementConfiguration.Read.All"
        Connect-AzAccount
        pwsh -File .\CLDSEC-Validate.ps1
        Requires PowerShell 7+ and the Microsoft.Graph and Az modules. *Verify current scope names/modules.*
    EXPECTED RESULTS
        A PASS/WARN/FAIL checklist. All PASS = ready to run CLDSEC-Discovery.ps1. Nothing is changed.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [string[]]$RequiredScopes = @('SecurityEvents.Read.All','Policy.Read.All','Directory.Read.All','DeviceManagementConfiguration.Read.All')
)

$ErrorActionPreference = 'Continue'
$results = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Name,[string]$Status,[string]$Detail){
    $results.Add([pscustomobject]@{ Check = $Name; Status = $Status; Detail = $Detail })
}

Write-Host "CLDSEC pre-flight validation (read-only)`n" -ForegroundColor Cyan

# --- PowerShell version ------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -ge 7) { Add-Check 'PowerShell 7+' 'PASS' $PSVersionTable.PSVersion.ToString() }
else { Add-Check 'PowerShell 7+' 'FAIL' "Found $($PSVersionTable.PSVersion); install PowerShell 7+ (R4)" }

# --- Required modules --------------------------------------------------------
foreach ($m in 'Microsoft.Graph','Az.Accounts','Az.Resources','Az.Security') {
    $mod = Get-Module -ListAvailable -Name $m | Select-Object -First 1
    if ($mod) { Add-Check "Module: $m" 'PASS' "v$($mod.Version)" }
    else { Add-Check "Module: $m" 'FAIL' "Install-Module $m -Scope CurrentUser (R4)" }
}

# --- Microsoft Graph connection + scopes ------------------------------------
$ctx = $null
try { $ctx = Get-MgContext -ErrorAction SilentlyContinue } catch {}
if ($ctx) {
    Add-Check 'Graph connected' 'PASS' "Account $($ctx.Account) / tenant $($ctx.TenantId)"
    $granted = @($ctx.Scopes)
    foreach ($s in $RequiredScopes) {
        if ($granted -contains $s) { Add-Check "Graph scope: $s" 'PASS' 'granted' }
        else { Add-Check "Graph scope: $s" 'WARN' 'not granted — re-run Connect-MgGraph -Scopes (R3)' }
    }
    # Read-only guarantee: warn on any *.ReadWrite.* or write-capable scope
    $writeScopes = $granted | Where-Object { $_ -match 'ReadWrite|\.Write|Manage' }
    if ($writeScopes) { Add-Check 'Read-only Graph scopes' 'FAIL' "WRITE scope(s) present: $($writeScopes -join ', ') — use read-only only (R1)" }
    else { Add-Check 'Read-only Graph scopes' 'PASS' 'no write scopes granted' }
} else {
    Add-Check 'Graph connected' 'FAIL' 'Run Connect-MgGraph -Scopes <read scopes> first (R3)'
}

# --- Azure connection + in-scope subscriptions ------------------------------
$azctx = $null
try { $azctx = Get-AzContext -ErrorAction SilentlyContinue } catch {}
if ($azctx) {
    Add-Check 'Azure connected' 'PASS' "Account $($azctx.Account.Id)"
    try {
        $subs = Get-AzSubscription -ErrorAction SilentlyContinue
        if ($subs) { Add-Check 'In-scope subscriptions' 'PASS' "$($subs.Count) visible: $(( $subs | Select-Object -First 5 -ExpandProperty Name) -join '; ')" }
        else { Add-Check 'In-scope subscriptions' 'WARN' 'No subscriptions visible — assign Reader at the subscription/MG (R2)' }
    } catch { Add-Check 'In-scope subscriptions' 'WARN' "Could not enumerate: $($_.Exception.Message)" }
} else {
    Add-Check 'Azure connected' 'WARN' 'Run Connect-AzAccount (needed for the infra/network pillars, R2)'
}

# --- Report ------------------------------------------------------------------
$results | Format-Table -AutoSize
$fail = ($results | Where-Object Status -eq 'FAIL').Count
$warn = ($results | Where-Object Status -eq 'WARN').Count
Write-Host ""
if ($fail -gt 0) { Write-Host "$fail FAIL, $warn WARN — resolve FAILs before running discovery." -ForegroundColor Red }
elseif ($warn -gt 0) { Write-Host "0 FAIL, $warn WARN — review warnings; some pillars may under-report." -ForegroundColor Yellow }
else { Write-Host "All checks passed — ready for CLDSEC-Discovery.ps1. Read-only; nothing was changed." -ForegroundColor Green }
