<#
.SYNOPSIS
    EKMFACA-Discovery.ps1 — read-only inventory of MFA methods and Conditional Access.
.DESCRIPTION
    PURPOSE
        A read-only "before picture" for the MFA & Conditional Access enablement kit: enabled MFA
        methods (from the authentication-methods policy) and tenant-wide MFA-registration coverage,
        every existing Conditional Access policy and its state (enabled / disabled / report-only),
        which policies target "all users" and whether they exclude any accounts (a lock-out-risk
        flag), detected legacy-authentication sign-ins, and the licensing tier (Entra ID P1 / P2).
        This is a teaching prop and a readiness check — it changes NOTHING.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        pwsh -File .\EKMFACA-Discovery.ps1
        pwsh -File .\EKMFACA-Discovery.ps1 -CsvPath .\ekmfaca-discovery.csv -LegacyLookbackDays 7
        Consents to read-only scopes (Policy.Read.All, Directory.Read.All, AuditLog.Read.All,
        Reports.Read.All, Policy.Read.ConditionalAccess). Government cloud: -Environment USGov.
    EXPECTED RESULTS
        A console summary of methods, registration coverage, CA policies + states + exclusions,
        legacy-auth sign-ins, and licensing. Nothing is modified. Optional CSV export.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [int]$LegacyLookbackDays = 7,
    [string]$CsvPath,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','Directory.Read.All','AuditLog.Read.All','Reports.Read.All' -Environment $Environment -NoWelcome

Write-Host "`n=== MFA & Conditional Access Discovery — $(Get-Date -Format s) ===" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($area,$metric,$value){ $rows.Add([pscustomobject]@{ Area=$area; Metric=$metric; Value=$value }) }

# --- MFA methods policy (which methods are enabled) ---
Write-Host "`n-- MFA methods (authentication-methods policy) --" -ForegroundColor Cyan
try {
    $amp = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationMethodsPolicy'
    foreach ($m in $amp.authenticationMethodConfigurations) {
        $col = if ($m.state -eq 'enabled') { 'Green' } else { 'DarkGray' }
        Write-Host ("  {0,-34} {1}" -f $m.id, $m.state) -ForegroundColor $col
        Add-Row 'MFAMethods' $m.id $m.state
    }
    Write-Host "  (Strength order: SMS/voice < authenticator+number-matching < FIDO2/passkey/WHfB/CBA = phishing-resistant. Verify passkey/CBA availability.)" -ForegroundColor DarkGray
} catch { Write-Host "  (could not read authentication-methods policy — needs Policy.Read.All)" -ForegroundColor DarkGray }

# --- MFA registration coverage ---
Write-Host "`n-- MFA registration coverage (tenant-wide) --" -ForegroundColor Cyan
try {
    $reg = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/reports/authenticationMethods/userRegistrationDetails?$top=999').value
    $total = $reg.Count
    $mfa = @($reg | Where-Object { $_.isMfaCapable }).Count
    $pr  = @($reg | Where-Object { $_.isPasswordlessCapable }).Count
    $pct = if ($total) { [math]::Round(100.0*$mfa/$total,1) } else { 0 }
    Write-Host ("  Users evaluated: {0}   MFA-capable: {1} ({2}%)   Passwordless-capable: {3}" -f $total, $mfa, $pct, $pr)
    Add-Row 'MFARegistration' 'UsersEvaluated' $total; Add-Row 'MFARegistration' 'MfaCapable' $mfa; Add-Row 'MFARegistration' 'PasswordlessCapable' $pr
} catch { Write-Host "  (registration report unavailable — needs Reports.Read.All / P1+. Verify in Entra -> Authentication methods -> Activity.)" -ForegroundColor DarkGray }

# --- Conditional Access inventory + lock-out sweep ---
Write-Host "`n-- Conditional Access policies --" -ForegroundColor Cyan
try {
    $ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
    Write-Host ("  Total: {0}" -f $ca.Count)
    foreach ($p in $ca) {
        $includeAll = ($p.conditions.users.includeUsers -contains 'All')
        $excl = @($p.conditions.users.excludeUsers).Count + @($p.conditions.users.excludeGroups).Count
        $stateColor = switch ($p.state) { 'enabled' {'Green'} 'enabledForReportingButNotEnforced' {'Yellow'} default {'DarkGray'} }
        Write-Host ("   • {0,-50} [{1}] allUsers={2} exclusions={3}" -f $p.displayName, $p.state, $includeAll, $excl) -ForegroundColor $stateColor
        if ($includeAll -and $excl -eq 0) { Write-Host "       WARN: All users with NO exclusions — lock-out risk. Exclude break-glass." -ForegroundColor Red }
    }
    Add-Row 'ConditionalAccess' 'PolicyCount' $ca.Count
    Add-Row 'ConditionalAccess' 'ReportOnlyCount' (@($ca | Where-Object { $_.state -eq 'enabledForReportingButNotEnforced' }).Count)
} catch { Write-Host "  (could not read CA policies — needs P1 and Policy.Read.All)" -ForegroundColor DarkGray }

# --- Legacy-auth sign-ins ---
Write-Host "`n-- Legacy authentication sign-ins (last $LegacyLookbackDays days) --" -ForegroundColor Cyan
$since = (Get-Date).AddDays(-$LegacyLookbackDays).ToString('yyyy-MM-ddT00:00:00Z')
try {
    $filter = "createdDateTime ge $since and (clientAppUsed eq 'Exchange ActiveSync' or clientAppUsed eq 'Other clients')"
    $si = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/signIns?`$filter=$([uri]::EscapeDataString($filter))&`$top=200").value
    $byUser = $si | Group-Object userPrincipalName | Sort-Object Count -Descending
    if (-not $byUser) { Write-Host "  none detected (legacy auth may already be blocked)" -ForegroundColor Green }
    foreach ($g in $byUser | Select-Object -First 15) { Write-Host ("  {0,-45} {1} sign-ins" -f $g.Name, $g.Count) -ForegroundColor Yellow }
    Add-Row 'LegacyAuth' 'UsersWithLegacySignins' (@($byUser).Count)
} catch { Write-Host "  (could not query sign-in logs — needs AuditLog.Read.All and P1+)" -ForegroundColor DarkGray }

# --- Licensing ---
Write-Host "`n-- Licensing --" -ForegroundColor Cyan
try {
    $plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName
    $p1 = $plans -contains 'AAD_PREMIUM'; $p2 = $plans -contains 'AAD_PREMIUM_P2'
    Write-Host ("  Entra ID P1: {0}   Entra ID P2: {1}" -f $p1, $p2) -ForegroundColor White
    if (-not $p1) { Write-Host "  NOTE: no P1 — Labs 2-6 become a read-only CA tour (no policy build). Verify licensing." -ForegroundColor Yellow }
    if (-not $p2) { Write-Host "  NOTE: no P2 — risk-based conditions are out of scope here (Identity Protection / ENTZTCA). Verify." -ForegroundColor DarkGray }
    Add-Row 'Licensing' 'EntraP1' $p1; Add-Row 'Licensing' 'EntraP2' $p2
} catch { Write-Host "  (could not read subscribedSkus)" -ForegroundColor DarkGray }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`nExported to $CsvPath" -ForegroundColor Green }
Write-Host "`nRead-only discovery complete. Nothing was changed." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
