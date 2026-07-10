<#
.SYNOPSIS
    ENTZTCAG-Discovery.ps1 — inventory Conditional Access policies, legacy auth, and licensing.
.DESCRIPTION
    PURPOSE
        Read-only assessment for a Conditional Access baseline: every existing CA policy and its state
        (enabled / disabled / report-only), which policies apply to "all users" and whether they
        exclude any accounts, detected legacy-authentication sign-ins from the audit log, per-persona
        sign-in volume, and whether the tenant has Entra ID P2 (so you know if the risk policies apply).
        This is your before baseline and your legacy-auth migration list.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\ENTZTCAG-Discovery.ps1
        Consents to Policy.Read.All, AuditLog.Read.All, Directory.Read.All (read-only). No changes.
    EXPECTED RESULTS
        A listing of CA policies with states and exclusions, a count of recent legacy-auth sign-ins,
        and the detected licensing tier. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Government (GCC High) edition: connects to the US Gov cloud via Connect-MgGraph -Environment USGov (DoD/IL5: USGovDoD, Graph host dod-graph.microsoft.us). Some CA capabilities (P2/Identity Protection risk conditions, auth strengths, device controls) may lag or differ in GCC High/DoD — verify against current Microsoft Government documentation. Read-only.
#>
[CmdletBinding()]
param(
    [int]$LegacyLookbackDays = 7,
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','AuditLog.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Conditional Access Baseline Discovery — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# --- Existing CA policies ---
$policies = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
Write-Host ("`n-- Conditional Access policies ({0}) --" -f $policies.Count) -ForegroundColor Cyan
$rows = @()
foreach ($p in $policies) {
    $includeAll = ($p.conditions.users.includeUsers -contains 'All')
    $excl = @($p.conditions.users.excludeUsers).Count + @($p.conditions.users.excludeGroups).Count
    $stateColor = switch ($p.state) { 'enabled' {'Green'} 'enabledForReportingButNotEnforced' {'Yellow'} default {'DarkGray'} }
    Write-Host ("  • {0,-55} [{1}]  allUsers={2} exclusions={3}" -f $p.displayName, $p.state, $includeAll, $excl) -ForegroundColor $stateColor
    if ($includeAll -and $excl -eq 0) { Write-Host "      WARN: targets All users with NO exclusions — lock-out risk. Exclude break-glass." -ForegroundColor Red }
    $rows += [pscustomobject]@{ Name=$p.displayName; State=$p.state; AllUsers=$includeAll; Exclusions=$excl }
}

# --- Legacy authentication sign-ins ---
Write-Host "`n-- Legacy authentication sign-ins (last $LegacyLookbackDays days) --" -ForegroundColor Cyan
$since = (Get-Date).AddDays(-$LegacyLookbackDays).ToString('yyyy-MM-ddT00:00:00Z')
try {
    $filter = "createdDateTime ge $since and (clientAppUsed eq 'Exchange ActiveSync' or clientAppUsed eq 'Other clients')"
    $signins = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/signIns?`$filter=$([uri]::EscapeDataString($filter))&`$top=200").value
    $byUser = $signins | Group-Object userPrincipalName | Sort-Object Count -Descending
    if (-not $byUser) { Write-Host "  none detected (good — legacy auth may already be blocked)" -ForegroundColor Green }
    foreach ($g in $byUser | Select-Object -First 20) { Write-Host ("  {0,-45} {1} sign-ins" -f $g.Name, $g.Count) -ForegroundColor Yellow }
} catch { Write-Host "  (could not query sign-in logs — needs AuditLog.Read.All and P1+)" -ForegroundColor DarkGray }

# --- Licensing (P2 detection via Identity Protection service plan) ---
Write-Host "`n-- Licensing --" -ForegroundColor Cyan
try {
    $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
    $plans = $skus.servicePlans.servicePlanName
    $hasP2 = $plans -contains 'AAD_PREMIUM_P2'
    $hasP1 = $plans -contains 'AAD_PREMIUM'
    Write-Host ("  Entra ID P1: {0}   Entra ID P2: {1}" -f $hasP1, $hasP2) -ForegroundColor White
    if (-not $hasP2) { Write-Host "  NOTE: risk policies CA004/CA005 require P2 — omit or substitute compliant-device+MFA." -ForegroundColor Yellow }
} catch { Write-Host "  (could not read subscribedSkus)" -ForegroundColor DarkGray }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`nExported to $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
