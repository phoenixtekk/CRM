<#
.SYNOPSIS
    IRMASSESS-Validate.ps1 — read-only IRM readiness validator: per-gate PASS / FAIL / VERIFY-IN-PORTAL (safe: read-only).
.DESCRIPTION
    PURPOSE
        Confirms the IRM readiness prerequisites that ARE scriptable and reports a per-gate result: the
        LICENSING signal (subscribed-SKU service plans via Microsoft Graph), the unified-AUDIT-LOG state, and
        ROLE SEPARATION (the four IRM role groups held by distinct owners, super-group minimal, no conflicting
        membership), plus the backing SCOPE group's presence. Gates that IRM only exposes in the portal
        (privacy/anonymization, connector health, analytics, policy scope) are printed as VERIFY-IN-PORTAL —
        this script never invents a cmdlet for them. Read-only — makes no changes and touches no individual.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IRMASSESS-Validate.ps1 -CsvPath .\IRMASSESS-Validation.csv
        Use -Gate to run a single gate (Licensing | Audit | Roles | Scope | All). Requires Security &
        Compliance PowerShell (Connect-IPPSSession); optional Microsoft Graph for licensing/scope-group gates.
.EXAMPLE
    .\IRMASSESS-Validate.ps1 -Gate Audit
    Reads UnifiedAuditLogIngestionEnabled and reports the audit gate PASS/FAIL only.
.NOTES
    Purview — Insider Risk Readiness Assessment. Read-only validator. No changes, no de-anonymization.
    Expected results: every scriptable gate PASS; portal-only gates printed as VERIFY-IN-PORTAL for sign-off.
#>
[CmdletBinding()]
param(
    [ValidateSet('All','Licensing','Audit','Roles','Scope')][string]$Gate = 'All',
    [string]$ScopeGroupName = 'IRM Priority Users - Readiness - Scope',
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Gate($name, $status, $detail) {
    $results.Add([pscustomobject]@{ Gate = $name; Status = $status; Detail = $detail })
    $color = switch ($status) { 'PASS' { 'Green' } 'FAIL' { 'Yellow' } default { 'DarkCyan' } }
    Write-Host ("  [{0,-16}] {1} — {2}" -f $name, $status, $detail) -ForegroundColor $color
}

Write-Host '=== Insider Risk Management — Readiness Validation ===' -ForegroundColor Cyan

# --- Gate: Licensing signal ---
if ($Gate -in 'All','Licensing') {
    if (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue) {
        try {
            $plans = @()
            foreach ($sku in (Get-MgSubscribedSku -ErrorAction Stop)) {
                foreach ($sp in $sku.ServicePlans) { if ($sp.ServicePlanName -match 'INSIDER|RISK') { $plans += $sp.ServicePlanName } }
            }
            $plans = $plans | Sort-Object -Unique
            if ($plans.Count -gt 0) { Add-Gate 'Licensing' 'PASS' ("insider-risk plan signal: " + ($plans -join ', ') + " (verify your licensing/tenant)") }
            else { Add-Gate 'Licensing' 'VERIFY-IN-PORTAL' 'no insider-risk plan matched — verify in the M365 admin center' }
        } catch { Add-Gate 'Licensing' 'VERIFY-IN-PORTAL' 'could not query SKUs — verify in the admin center' }
    } else {
        Add-Gate 'Licensing' 'VERIFY-IN-PORTAL' 'Graph not connected — Connect-MgGraph -Scopes Organization.Read.All, or verify in admin center'
    }
}

# --- Gate: Unified audit log ---
if ($Gate -in 'All','Audit') {
    $auditOn = $null
    try { $auditOn = [bool](Get-AdminAuditLogConfig -ErrorAction SilentlyContinue).UnifiedAuditLogIngestionEnabled } catch {}
    if ($auditOn -eq $true) { Add-Gate 'Audit' 'PASS' 'unified audit log ingestion enabled' }
    elseif ($auditOn -eq $false) { Add-Gate 'Audit' 'FAIL' 'unified audit log DISABLED — enable before relying on IRM signal' }
    else { Add-Gate 'Audit' 'VERIFY-IN-PORTAL' 'could not read audit config — verify in the Purview audit page' }
}

# --- Gate: Role separation ---
if ($Gate -in 'All','Roles') {
    $irmRoleNames = @('Insider Risk Management','Insider Risk Management Admins','Insider Risk Management Analysts','Insider Risk Management Investigators','Insider Risk Management Auditors')
    $memberIndex = @{}
    $present = @{}
    foreach ($name in $irmRoleNames) {
        $g = Get-RoleGroup -Identity $name -ErrorAction SilentlyContinue
        $present[$name] = [bool]$g
        if ($g) {
            $members = @()
            try { $members = @(Get-RoleGroupMember -Identity $name -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) } catch {}
            foreach ($m in $members) { if (-not $memberIndex.ContainsKey($m)) { $memberIndex[$m] = @() }; $memberIndex[$m] += $name }
        }
    }
    # Four core roles each held by at least one distinct owner?
    $coreRoles = 'Insider Risk Management Admins','Insider Risk Management Analysts','Insider Risk Management Investigators','Insider Risk Management Auditors'
    $conflicts = @()
    $superHolders = @()
    foreach ($m in $memberIndex.Keys) {
        $held = $memberIndex[$m] | Sort-Object -Unique
        if ($held -contains 'Insider Risk Management') { $superHolders += $m }
        foreach ($pair in @(@('Insider Risk Management Analysts','Insider Risk Management Investigators'),@('Insider Risk Management Admins','Insider Risk Management Investigators'),@('Insider Risk Management Admins','Insider Risk Management Analysts'),@('Insider Risk Management Auditors','Insider Risk Management Investigators'))) {
            if (($held -contains $pair[0]) -and ($held -contains $pair[1])) { $conflicts += ("{0}: {1}+{2}" -f $m, $pair[0], $pair[1]) }
        }
    }
    $missingCore = @($coreRoles | Where-Object { -not $present[$_] })
    if ($conflicts.Count -gt 0) {
        Add-Gate 'Roles' 'FAIL' ('separation conflict(s): ' + (($conflicts | Sort-Object -Unique) -join '; '))
    } elseif ($missingCore.Count -gt 0) {
        Add-Gate 'Roles' 'VERIFY-IN-PORTAL' ('role group(s) not found: ' + ($missingCore -join ', ') + ' — verify in the Purview portal')
    } else {
        $superNote = if ($superHolders.Count -gt 0) { " (NOTE: super-group held by $($superHolders.Count) — keep minimal)" } else { '' }
        Add-Gate 'Roles' 'PASS' ("four IRM roles present, no conflicting membership" + $superNote)
    }
}

# --- Gate: backing scope group ---
if ($Gate -in 'All','Scope') {
    if (Get-Command Get-MgGroup -ErrorAction SilentlyContinue) {
        try {
            $grp = Get-MgGroup -Filter "displayName eq '$ScopeGroupName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
            if ($grp) {
                $mc = 0; try { $mc = @(Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction SilentlyContinue).Count } catch {}
                Add-Gate 'Scope' 'PASS' ("backing group '{0}' exists ({1} member(s) — keep minimal). Bind + policy scope: VERIFY-IN-PORTAL" -f $ScopeGroupName, $mc)
            } else {
                Add-Gate 'Scope' 'VERIFY-IN-PORTAL' ("backing group '{0}' not found — create with IRMASSESS-Config.ps1 -Commit" -f $ScopeGroupName)
            }
        } catch { Add-Gate 'Scope' 'VERIFY-IN-PORTAL' 'could not query Graph groups — verify the scope group in the portal' }
    } else {
        Add-Gate 'Scope' 'VERIFY-IN-PORTAL' 'Graph not connected — Connect-MgGraph -Scopes Group.Read.All to check the backing group'
    }
}

# --- Portal-only gates (always shown for the assessment record) ---
if ($Gate -eq 'All') {
    Write-Host '--- Portal-only gates (verify in the Purview portal) ---' -ForegroundColor Cyan
    Add-Gate 'Privacy'    'VERIFY-IN-PORTAL' 'anonymization ON + minimum indicators -> Settings > Privacy / Policy indicators'
    Add-Gate 'Connectors' 'VERIFY-IN-PORTAL' 'HR/Entra/DLP/Defender present & healthy -> Data Connectors / Settings'
    Add-Gate 'Analytics'  'VERIFY-IN-PORTAL' 'tenant Analytics scan run BEFORE any policy (aggregated/anonymized)'
    Add-Gate 'PolicyScope' 'VERIFY-IN-PORTAL' 'readiness policy DISABLED/MINIMAL, scoped to the priority-user group only'
}

$fail = @($results | Where-Object { $_.Status -eq 'FAIL' })
Write-Host ("Result: {0} PASS, {1} FAIL, {2} VERIFY-IN-PORTAL." -f @($results | Where-Object {$_.Status -eq 'PASS'}).Count, $fail.Count, @($results | Where-Object {$_.Status -eq 'VERIFY-IN-PORTAL'}).Count) -ForegroundColor Cyan
if ($fail.Count -eq 0) { Write-Host 'No hard failures — resolve VERIFY-IN-PORTAL items and capture sign-off.' -ForegroundColor Green }
else { Write-Host 'Resolve FAIL gates before proceeding.' -ForegroundColor Yellow }

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Validation results exported to {0}" -f $CsvPath) -ForegroundColor Green
}
