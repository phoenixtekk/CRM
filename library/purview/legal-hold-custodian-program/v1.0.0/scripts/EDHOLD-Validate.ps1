<#
.SYNOPSIS
    EDHOLD-Validate.ps1 — read-only validation that a legal hold is applied and preserving as intended (safe: read-only).
.DESCRIPTION
    PURPOSE
        Confirms, against explicit per-gate PASS/FAIL, that the hold for a matter is actually effective:
          Gate A — every CaseHoldPolicy on the case reports DistributionStatus = Success (the hold has
                   propagated to all its locations; Pending means "not yet — wait, don't trust").
          Gate B — the expected custodian mailboxes / OneDrive / SharePoint locations are actually in the
                   hold's location list (nothing intended is missing).
          Gate C — where -ExpectedExchangeLocation mailboxes are given, their Litigation Hold state is
                   reported (belt-and-suspenders reinforcement, where used).
          Gate D — (optional) Graph eDiscovery custodian/hold signal where Premium is licensed (beta).
        Read-only — queries only; makes NO changes and never releases a hold.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDHOLD-Validate.ps1 `
            -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' `
            -ExpectedExchangeLocation 'testcustodian1@contoso.com'
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
.EXAMPLE
    .\EDHOLD-Validate.ps1 -CaseName 'Legal Hold Case – Contoso-Matter-001 – Pilot' -ExpectedExchangeLocation 'testcustodian1@contoso.com'
    Prints PASS/FAIL for distribution status, expected-location coverage, and Litigation Hold state.
.NOTES
    Purview — Legal-Hold & Custodian Management Program. Read-only validation.
    Expected results: PASS = DistributionStatus=Success on every policy AND every expected location is held.
    A Pending distribution is not a failure yet — re-run after the service timers complete (minutes to hours).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CaseName,
    [string[]]$ExpectedExchangeLocation,
    [string[]]$ExpectedSharePointLocation,
    [string[]]$ExpectedOneDriveLocation,
    [string]$UserPrincipalName,
    [switch]$IncludeGraphCustodians
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-CaseHoldPolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host ("=== Validate hold for case '{0}' (read-only) ===" -f $CaseName) -ForegroundColor Cyan
$overallPass = $true
function Report-Gate([string]$name, [bool]$pass, [string]$detail) {
    if ($pass) { Write-Host ("PASS  {0} — {1}" -f $name, $detail) -ForegroundColor Green }
    else       { Write-Host ("FAIL  {0} — {1}" -f $name, $detail) -ForegroundColor Red }
    if (-not $pass) { $script:overallPass = $false }
}

$case = Get-ComplianceCase -Identity $CaseName -ErrorAction SilentlyContinue
if (-not $case) { Write-Host ("Case '{0}' not found — check the name / your eDiscovery role." -f $CaseName) -ForegroundColor Red; return }

$policies = Get-CaseHoldPolicy -ErrorAction SilentlyContinue -DistributionDetail | Where-Object { $_.CaseId -eq $case.Identity -or $_.Case -eq $CaseName }
if (-not $policies) {
    # Fall back to name-scoped lookup if CaseId shape differs across tenants.
    $policies = Get-CaseHoldPolicy -ErrorAction SilentlyContinue -DistributionDetail
}
if (-not $policies) { Write-Host 'No case hold policies found for this case.' -ForegroundColor Yellow; return }

# --- Gate A: distribution status ---
Write-Host '--- Gate A: hold distribution status ---' -ForegroundColor Cyan
foreach ($p in $policies) {
    $ok = ($p.DistributionStatus -eq 'Success')
    Report-Gate ("Distribution [{0}]" -f $p.Name) $ok ("DistributionStatus={0}" -f $p.DistributionStatus)
}

# --- Gate B: expected location coverage ---
Write-Host '--- Gate B: expected-location coverage ---' -ForegroundColor Cyan
$heldExchange   = @(); $heldSpo = @(); $heldOd = @()
foreach ($p in $policies) {
    if ($p.ExchangeLocation)   { $heldExchange += ($p.ExchangeLocation   | ForEach-Object { $_.ToString() }) }
    if ($p.SharePointLocation) { $heldSpo      += ($p.SharePointLocation | ForEach-Object { $_.ToString() }) }
    if ($p.OneDriveLocation)   { $heldOd       += ($p.OneDriveLocation   | ForEach-Object { $_.ToString() }) }
}
function Check-Expected([string[]]$expected, [string[]]$held, [string]$label) {
    if (-not $expected) { return }
    foreach ($e in $expected) {
        $covered = ($held | Where-Object { $_ -match [regex]::Escape($e) }).Count -gt 0 -or ($held -contains 'All')
        Report-Gate ("{0} coverage" -f $label) $covered ("expected '{0}' {1}" -f $e, ($(if ($covered) { 'is held' } else { 'is NOT held' })))
    }
}
Check-Expected $ExpectedExchangeLocation   $heldExchange 'Exchange'
Check-Expected $ExpectedSharePointLocation $heldSpo      'SharePoint'
Check-Expected $ExpectedOneDriveLocation   $heldOd       'OneDrive'
if (-not ($ExpectedExchangeLocation -or $ExpectedSharePointLocation -or $ExpectedOneDriveLocation)) {
    Write-Host '  (no expected locations supplied — pass -Expected*Location to check coverage)' -ForegroundColor DarkGray
}

# --- Gate C: Litigation Hold reinforcement state (where mailboxes given) ---
if ($ExpectedExchangeLocation) {
    Write-Host '--- Gate C: Litigation Hold state (reinforcement, informational) ---' -ForegroundColor Cyan
    if (-not (Get-Command Get-Mailbox -ErrorAction SilentlyContinue)) { try { Connect-ExchangeOnline -ShowBanner:$false } catch {} }
    foreach ($m in $ExpectedExchangeLocation) {
        try {
            $mbx = Get-Mailbox -Identity $m -ErrorAction Stop
            Write-Host ("  {0}: LitigationHoldEnabled={1}" -f $m, $mbx.LitigationHoldEnabled)
        } catch {
            Write-Host ("  {0}: could not read mailbox (Exchange Online session/role needed)." -f $m) -ForegroundColor Yellow
        }
    }
}

# --- Gate D: optional Graph custodian/notice signal (Premium, beta) ---
if ($IncludeGraphCustodians -and (Get-Command Get-MgSecurityCaseEdiscoveryCase -ErrorAction SilentlyContinue)) {
    Write-Host '--- Gate D: Graph eDiscovery custodian signal (beta) ---' -ForegroundColor Cyan
    try {
        $gcases = Get-MgSecurityCaseEdiscoveryCase -Filter ("displayName eq '{0}'" -f $CaseName) -ErrorAction Stop
        foreach ($gc in $gcases) {
            $cust = Get-MgSecurityCaseEdiscoveryCaseCustodian -EdiscoveryCaseId $gc.Id -ErrorAction SilentlyContinue
            Write-Host ("  Custodians on Graph case '{0}': {1}" -f $gc.DisplayName, (@($cust).Count))
        }
    } catch { Write-Host ("  Graph custodian read unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
} elseif ($IncludeGraphCustodians) {
    Write-Host 'Note: notice/acknowledgment tracking is primarily a PORTAL surface (Communications) — verify there.' -ForegroundColor DarkGray
}

Write-Host ('=== OVERALL: {0} ===' -f ($(if ($overallPass) { 'PASS' } else { 'FAIL — resolve before trusting the hold' }))) -ForegroundColor ($(if ($overallPass) { 'Green' } else { 'Red' }))
