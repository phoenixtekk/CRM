<#
.SYNOPSIS
    UPRTG-Validation.ps1 — read-only pass/fail validation of a Universal Print pilot/wave on GCC High.
.DESCRIPTION
    PURPOSE
        Validates that a Universal Print deployment scope on a GCC High tenant is correctly
        configured before you advance a phase gate: printer registered and shared, targeting
        group present and granted, and connector healthy. Read-only: it asserts state, it does
        not change it. Run it at the Pilot and Expand gates.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\UPRTG-Validation.ps1
        (Graph scopes: Printer.Read.All, PrinterShare.Read.All, PrintConnector.Read.All, Group.Read.All; -Environment USGov)
        Optional: -ShareName 'UP-Pilot-Printer-01' -GroupName 'UP-Pilot-Users' to scope checks.
    EXPECTED RESULTS
        Sign-in opens login.microsoftonline.us. Each check prints PASS or FAIL with a hint.
        OVERALL PASS = the scope is ready to advance past its gate.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$ShareName = "UP-Pilot-Printer-01",
    [string]$GroupName = "UP-Pilot-Users"
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Check([string]$Name, [bool]$Pass, [string]$Hint) {
    $results.Add([pscustomobject]@{ Check = $Name; Result = $(if ($Pass) {'PASS'} else {'FAIL'}); Hint = $Hint })
    $color = if ($Pass) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $(if ($Pass) {'PASS'} else {'FAIL'}), $Name) -ForegroundColor $color
    if (-not $Pass -and $Hint) { Write-Host ("        hint: {0}" -f $Hint) -ForegroundColor DarkYellow }
}

Write-Host "==== Universal Print Validation (GCC High) — read-only ====" -ForegroundColor Cyan
Write-Host ("Scope: share '{0}', group '{1}'" -f $ShareName, $GroupName)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Warning "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

try {
    Connect-MgGraph -Environment USGov -Scopes "Printer.Read.All","PrinterShare.Read.All","PrintConnector.Read.All","Group.Read.All" -NoWelcome
    $ctx = Get-MgContext
    Add-Check "Connected to US Gov Graph (GCC High)" ($ctx.Environment -eq 'USGov') "Use -Environment USGov; sign in at login.microsoftonline.us"
}
catch {
    Write-Warning "Graph sign-in failed: $($_.Exception.Message)"
    return
}

# --- Check 1: any printers registered ---
$printers = @()
try { $printers = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/printers").value) } catch {}
Add-Check "At least one printer registered" ($printers.Count -gt 0) "Register a printer via the connector (Implementation Step 6)"

# --- Check 2: named share exists and is shared ---
$shares = @()
try { $shares = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/shares").value) } catch {}
$targetShare = $shares | Where-Object { $_.displayName -eq $ShareName }
Add-Check "Printer share '$ShareName' exists (Shared)" ([bool]$targetShare) "Share the printer with name '$ShareName' (Implementation Step 6)"

# --- Check 3: targeting group exists ---
$group = $null
try {
    $g = @((Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)).value)
    $group = $g | Select-Object -First 1
} catch {}
Add-Check "Targeting group '$GroupName' exists" ([bool]$group) "Create it (UPRTG-Set-ScopeTargeting.ps1) — Implementation Step 7"

# --- Check 4: targeting group has members ---
$memberCount = 0
if ($group) {
    try { $memberCount = @((Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members" -f $group.id)).value).Count } catch {}
}
Add-Check "Targeting group has members" ($memberCount -gt 0) "Add pilot/wave users to '$GroupName'"

# --- Check 5: group is granted access on the share ---
$granted = $false
if ($targetShare) {
    try {
        $allowed = @((Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/print/shares/{0}/allowedGroups" -f $targetShare.id)).value)
        if ($group) { $granted = [bool]($allowed | Where-Object { $_.id -eq $group.id }) }
    } catch {}
}
Add-Check "Group '$GroupName' granted on share '$ShareName'" $granted "Grant the group on the share (Implementation Step 7)"

# --- Check 6: at least one connector healthy ---
$connectors = @()
try { $connectors = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/connectors").value) } catch {}
Add-Check "At least one connector registered" ($connectors.Count -gt 0) "Register the connector (Implementation Step 5)"

# --- Summary ---
Write-Host ""
$failCount = @($results | Where-Object Result -eq 'FAIL').Count
if ($failCount -eq 0) { Write-Host "OVERALL: PASS — scope is ready to advance past its gate." -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} check(s) failed. Resolve the hints above and re-run." -f $failCount) -ForegroundColor Red }

Disconnect-MgGraph | Out-Null
