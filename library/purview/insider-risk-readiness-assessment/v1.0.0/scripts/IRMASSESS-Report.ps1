<#
.SYNOPSIS
    IRMASSESS-Report.ps1 — read-only PSEUDONYMIZED IRM readiness scorecard / gap report for stakeholder review (safe: read-only).
.DESCRIPTION
    PURPOSE
        Produces a readiness SCORECARD for HR / privacy / legal review that contains NO personal data —
        COUNTS and gate STATUS only. It reports the IRM role groups by member COUNT (never names), the
        role-SEPARATION result, the unified-audit-log state, a licensing signal, the backing scope group's
        member COUNT, and the portal-only gates as VERIFY-IN-PORTAL reminders. Deliberately pseudonymized so
        the output is safe to circulate: no usernames, no case content, no de-anonymized identities. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IRMASSESS-Report.ps1 -CsvPath .\IRMASSESS-Scorecard.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession); optional Microsoft Graph for the
        licensing signal and the backing-group count.
.EXAMPLE
    .\IRMASSESS-Report.ps1 -CsvPath .\IRMASSESS-Scorecard.csv
    Prints and exports a counts-and-status readiness scorecard (no personal data) for stakeholder sign-off.
.NOTES
    Purview — Insider Risk Readiness Assessment. Read-only. Output is pseudonymized (counts + status only).
    Expected results: a scorecard safe to hand to HR/privacy/legal; the deploy/operate decision is theirs.
#>
[CmdletBinding()]
param(
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

Write-Host '=== IRM Readiness Scorecard (pseudonymized — counts & status only, no personal data) ===' -ForegroundColor Cyan

$scorecard = New-Object System.Collections.Generic.List[object]
function Add-Line($item, $value, $status) {
    $scorecard.Add([pscustomobject]@{ Item = $item; Value = $value; Status = $status })
}

# --- Roles by COUNT + separation (no names) ---
$irmRoleNames = @('Insider Risk Management','Insider Risk Management Admins','Insider Risk Management Analysts','Insider Risk Management Investigators','Insider Risk Management Auditors')
$memberIndex = @{}
foreach ($name in $irmRoleNames) {
    $g = Get-RoleGroup -Identity $name -ErrorAction SilentlyContinue
    $count = 0
    if ($g) {
        try { $members = @(Get-RoleGroupMember -Identity $name -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }); $count = $members.Count } catch { $members = @() }
        foreach ($m in $members) { if (-not $memberIndex.ContainsKey($m)) { $memberIndex[$m] = @() }; $memberIndex[$m] += $name }
        Add-Line ("Role: $name (member COUNT)") $count (if ($name -eq 'Insider Risk Management' -and $count -gt 0) { 'REVIEW-super-group' } elseif ($count -gt 0) { 'PRESENT' } else { 'EMPTY' })
    } else {
        Add-Line ("Role: $name") 'not found' 'VERIFY-IN-PORTAL'
    }
}
# Separation conflicts (report the COUNT of conflicting identities, not who)
$conflictCount = 0
foreach ($m in $memberIndex.Keys) {
    $held = $memberIndex[$m] | Sort-Object -Unique
    foreach ($pair in @(@('Insider Risk Management Analysts','Insider Risk Management Investigators'),@('Insider Risk Management Admins','Insider Risk Management Investigators'),@('Insider Risk Management Admins','Insider Risk Management Analysts'),@('Insider Risk Management Auditors','Insider Risk Management Investigators'))) {
        if (($held -contains $pair[0]) -and ($held -contains $pair[1])) { $conflictCount++; break }
    }
}
Add-Line 'Role separation conflicts (COUNT of identities)' $conflictCount (if ($conflictCount -eq 0) { 'PASS' } else { 'FAIL' })

# --- Audit ---
$auditOn = $null
try { $auditOn = [bool](Get-AdminAuditLogConfig -ErrorAction SilentlyContinue).UnifiedAuditLogIngestionEnabled } catch {}
Add-Line 'Unified audit log ingestion' (if ($auditOn -eq $true) { 'enabled' } elseif ($auditOn -eq $false) { 'disabled' } else { 'unknown' }) (if ($auditOn -eq $true) { 'PASS' } elseif ($auditOn -eq $false) { 'FAIL' } else { 'VERIFY-IN-PORTAL' })

# --- Licensing signal + scope-group count (Graph, optional) ---
if (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue) {
    try {
        $plans = @(); foreach ($sku in (Get-MgSubscribedSku -ErrorAction Stop)) { foreach ($sp in $sku.ServicePlans) { if ($sp.ServicePlanName -match 'INSIDER|RISK') { $plans += $sp.ServicePlanName } } }
        $plans = $plans | Sort-Object -Unique
        Add-Line 'Licensing signal (insider-risk plan)' (if ($plans.Count -gt 0) { ($plans -join ', ') } else { 'none matched' }) (if ($plans.Count -gt 0) { 'PASS' } else { 'VERIFY-IN-PORTAL' })
    } catch { Add-Line 'Licensing signal (insider-risk plan)' 'query failed' 'VERIFY-IN-PORTAL' }
} else { Add-Line 'Licensing signal (insider-risk plan)' 'Graph not connected' 'VERIFY-IN-PORTAL' }

if (Get-Command Get-MgGroup -ErrorAction SilentlyContinue) {
    try {
        $grp = Get-MgGroup -Filter "displayName eq '$ScopeGroupName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
        if ($grp) { $mc = 0; try { $mc = @(Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction SilentlyContinue).Count } catch {}; Add-Line 'Readiness scope group (member COUNT)' $mc 'PRESENT' }
        else { Add-Line 'Readiness scope group' 'not found' 'VERIFY-IN-PORTAL' }
    } catch { Add-Line 'Readiness scope group' 'query failed' 'VERIFY-IN-PORTAL' }
} else { Add-Line 'Readiness scope group' 'Graph not connected' 'VERIFY-IN-PORTAL' }

# --- Portal-only gates (reminders, no data) ---
Add-Line 'Privacy: anonymization ON + minimum indicators' 'portal setting' 'VERIFY-IN-PORTAL'
Add-Line 'Connectors: HR/Entra/DLP/Defender healthy' 'portal setting' 'VERIFY-IN-PORTAL'
Add-Line 'Analytics: run before any policy (anonymized)' 'portal setting' 'VERIFY-IN-PORTAL'
Add-Line 'Readiness policy DISABLED/MINIMAL, narrowly scoped' 'portal setting' 'VERIFY-IN-PORTAL'

$scorecard | Format-Table -AutoSize

$fail = @($scorecard | Where-Object { $_.Status -eq 'FAIL' }).Count
$verify = @($scorecard | Where-Object { $_.Status -eq 'VERIFY-IN-PORTAL' }).Count
Write-Host ("Scorecard: {0} FAIL, {1} VERIFY-IN-PORTAL. This output is pseudonymized (counts/status only) — safe to share with HR/privacy/legal." -f $fail, $verify) -ForegroundColor Cyan
Write-Host 'The decision to DEPLOY IRM, open any case, and any HR/legal action belongs to the governance functions — not this assessment.' -ForegroundColor DarkCyan

if ($CsvPath) {
    $scorecard | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Scorecard exported to {0} (no personal data)." -f $CsvPath) -ForegroundColor Green
}
