<#
.SYNOPSIS
    EDHOLD-Discovery.ps1 — read-only Purview eDiscovery legal-hold posture assessment (safe: read-only).
.DESCRIPTION
    PURPOSE
        Builds the legal-hold baseline before you configure anything: every eDiscovery ComplianceCase, every
        CaseHoldPolicy with its held locations and DISTRIBUTION STATUS (Pending vs Success vs error), the
        CaseHoldRules and whether they are query-based or preserve-everything, plus eDiscovery role-group
        membership and a Premium-licensing signal (whether custodian/communications features are likely
        available). Optionally probes the Microsoft Graph eDiscovery API for custodians where licensed
        (beta — verify in your tenant). Read-only — makes no changes and NEVER releases a hold.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDHOLD-Discovery.ps1 -CsvPath .\EDHOLD-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement);
        optional Microsoft Graph (Connect-MgGraph) for custodian read.
.EXAMPLE
    .\EDHOLD-Discovery.ps1 -CsvPath .\EDHOLD-Posture.csv
    Prints cases, case hold policies (locations + distribution status), rules, and role membership; exports CSV.
.NOTES
    Purview — Legal-Hold & Custodian Management Program. Read-only against Security & Compliance PowerShell.
    Expected results: holds you expect report DistributionStatus=Success across their locations (PASS);
    anything Pending or errored is flagged to validate before you trust it.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$UserPrincipalName,
    [switch]$IncludeGraphCustodians
)

# --- Connect (modern auth / MFA). Reuses an existing session if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-CaseHoldPolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName }
    else { Connect-IPPSSession }
}

Write-Host '=== eDiscovery Legal-Hold Posture Assessment (read-only) ===' -ForegroundColor Cyan

# --- eDiscovery cases ---
$cases = Get-ComplianceCase -ErrorAction SilentlyContinue | Where-Object { $_.CaseType -eq 'eDiscovery' -or $_.CaseType -eq 'AdvancedEdiscovery' }
Write-Host ("--- eDiscovery cases: {0} ---" -f (@($cases).Count)) -ForegroundColor Cyan
$cases | Select-Object Name, CaseType, Status | Sort-Object Name | Format-Table -AutoSize

# --- Case hold policies + their locations and DISTRIBUTION STATUS ---
Write-Host '--- Case hold policies (locations + distribution status) ---' -ForegroundColor Cyan
$policies = Get-CaseHoldPolicy -ErrorAction SilentlyContinue -DistributionDetail
$rows = foreach ($p in $policies) {
    $locs = @()
    foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation') {
        $val = $p.$loc
        if ($val -and $val.Count -gt 0) { $locs += ("{0}={1}" -f $loc.Replace('Location',''), $val.Count) }
    }
    # DistributionStatus: 'Success' when the hold has propagated to all locations; 'Pending' while it distributes.
    $distress = $p.DistributionStatus
    [pscustomobject]@{
        Policy             = $p.Name
        Case               = $p.CaseId
        Enabled            = $p.Enabled
        Mode               = $p.Mode
        DistributionStatus = $distress
        Locations          = ($locs -join ', ')
    }
}
$rows | Sort-Object Policy | Format-Table -AutoSize

$notDone = @($rows | Where-Object { $_.DistributionStatus -and $_.DistributionStatus -ne 'Success' })
if ($notDone.Count -gt 0) {
    Write-Host ("REVIEW: {0} hold policy(ies) are NOT DistributionStatus=Success — validate before trusting:" -f $notDone.Count) -ForegroundColor Yellow
    $notDone | ForEach-Object { Write-Host ("   * {0} ({1})" -f $_.Policy, $_.DistributionStatus) -ForegroundColor Yellow }
} elseif ($rows) {
    Write-Host 'All case hold policies report DistributionStatus=Success.' -ForegroundColor Green
}

# --- Case hold rules: query-based vs preserve-everything ---
Write-Host '--- Case hold rules (query vs preserve-everything) ---' -ForegroundColor Cyan
$rules = Get-CaseHoldRule -ErrorAction SilentlyContinue
$rules | ForEach-Object {
    $kind = if ([string]::IsNullOrWhiteSpace($_.ContentMatchQuery)) { 'preserve-everything' } else { 'query-based' }
    [pscustomobject]@{ Rule = $_.Name; Policy = $_.Policy; Kind = $kind; Query = $_.ContentMatchQuery; Disabled = $_.Disabled }
} | Format-Table -AutoSize

# --- eDiscovery role-group membership (who can run the program) ---
Write-Host '--- eDiscovery role-group membership ---' -ForegroundColor Cyan
foreach ($rg in 'eDiscovery Manager','eDiscovery Administrator') {
    $members = @()
    try { $members = (Get-RoleGroupMember -Identity $rg -ErrorAction SilentlyContinue).Name } catch {}
    Write-Host ("  {0}: {1}" -f $rg, ($(if ($members) { $members -join ', ' } else { '(none / not visible)' })))
}

# --- Premium-licensing signal (custodians + communications require eDiscovery Premium / E5-class) ---
Write-Host '--- Premium licensing signal ---' -ForegroundColor Cyan
$premiumSignal = $false
if (Get-Command Get-ComplianceCase -ErrorAction SilentlyContinue) {
    # AdvancedEdiscovery case type indicates Premium is in use in the tenant.
    if (@($cases | Where-Object { $_.CaseType -eq 'AdvancedEdiscovery' }).Count -gt 0) { $premiumSignal = $true }
}
if ($premiumSignal) {
    Write-Host 'Signal: eDiscovery (Premium) appears to be IN USE (custodians/communications likely available).' -ForegroundColor Green
} else {
    Write-Host 'Signal: no Premium (AdvancedEdiscovery) cases seen — custodians/communications may be UNLICENSED.' -ForegroundColor Yellow
    Write-Host '        Verify E5 / E5 Compliance / E5 eDiscovery & Audit in the admin center (Req 2.1).' -ForegroundColor Yellow
}

# --- Optional: Graph eDiscovery custodian read (beta — verify availability) ---
if ($IncludeGraphCustodians) {
    if (Get-Command Get-MgSecurityCaseEdiscoveryCase -ErrorAction SilentlyContinue) {
        Write-Host '--- Graph eDiscovery custodians (beta) ---' -ForegroundColor Cyan
        try {
            $gcases = Get-MgSecurityCaseEdiscoveryCase -ErrorAction Stop
            foreach ($gc in $gcases) {
                $cust = Get-MgSecurityCaseEdiscoveryCaseCustodian -EdiscoveryCaseId $gc.Id -ErrorAction SilentlyContinue
                Write-Host ("  Case '{0}': {1} custodian(s)" -f $gc.DisplayName, (@($cust).Count))
            }
        } catch {
            Write-Host ("  Graph eDiscovery read unavailable in this tenant/plan: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host 'Graph eDiscovery cmdlets not present (install Microsoft.Graph.Security; endpoints are beta — verify).' -ForegroundColor Yellow
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Hold-policy inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — proceed to configure the pilot case hold (EDHOLD-Config.ps1).' -ForegroundColor Cyan
