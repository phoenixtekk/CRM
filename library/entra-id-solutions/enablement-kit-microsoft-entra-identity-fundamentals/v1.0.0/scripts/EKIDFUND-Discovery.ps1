<#
.SYNOPSIS
    EKIDFUND-Discovery.ps1 — read-only inventory of Microsoft Entra identity fundamentals.
.DESCRIPTION
    PURPOSE
        A read-only "before picture" of the tenant fundamentals, used to ground the enablement kit:
        user and guest counts, group counts (security vs Microsoft 365, assigned vs dynamic),
        directory-role assignments (flagging Global Administrator over-assignment), app-registration
        and enterprise-application counts, the detected licensing tier (Entra ID P1 / P2), MFA
        registration coverage, and any existing Conditional Access policies. This is a teaching prop
        and a readiness check — it changes NOTHING in the tenant.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        pwsh -File .\EKIDFUND-Discovery.ps1
        pwsh -File .\EKIDFUND-Discovery.ps1 -CsvPath .\ekidfund-discovery.csv
        Consents to read-only scopes (Directory.Read.All, Policy.Read.All, RoleManagement.Read.Directory,
        AuditLog.Read.All, Application.Read.All, UserAuthenticationMethod.Read.All). No changes.
        Government cloud: pass -Environment USGov (or USGovDoD).
    EXPECTED RESULTS
        A console summary of the fundamentals with a few "teach this" callouts (e.g. Global Admin count,
        licensing tier, MFA coverage). Nothing is modified. Optional CSV export of the summary rows.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('Directory.Read.All','Policy.Read.All','RoleManagement.Read.Directory',
            'AuditLog.Read.All','Application.Read.All','UserAuthenticationMethod.Read.All')
Connect-MgGraph -Scopes $scopes -Environment $Environment -NoWelcome

Write-Host "`n=== Entra Identity Fundamentals Discovery — $(Get-Date -Format s) ===" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($area,$metric,$value){ $rows.Add([pscustomobject]@{ Area=$area; Metric=$metric; Value=$value }) }

# --- Tenant / domains ---
try {
    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value | Select-Object -First 1
    Write-Host ("`n-- Tenant --") -ForegroundColor Cyan
    Write-Host ("  Name: {0}" -f $org.displayName)
    Write-Host ("  Tenant ID: {0}" -f $org.id)
    $verified = @($org.verifiedDomains | Where-Object { $_.isVerified }).Count
    Write-Host ("  Verified domains: {0}" -f $verified)
    Add-Row 'Tenant' 'Name' $org.displayName; Add-Row 'Tenant' 'TenantId' $org.id; Add-Row 'Tenant' 'VerifiedDomains' $verified
} catch { Write-Host "  (could not read organization)" -ForegroundColor DarkGray }

# --- Users / guests ---
Write-Host "`n-- Identities --" -ForegroundColor Cyan
try {
    $memberCount = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/`$count?`$filter=userType eq 'Member'" -Headers @{ ConsistencyLevel='eventual' })
    $guestCount  = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/`$count?`$filter=userType eq 'Guest'"  -Headers @{ ConsistencyLevel='eventual' })
    Write-Host ("  Member users: {0}   Guest users: {1}" -f $memberCount, $guestCount)
    Add-Row 'Identities' 'MemberUsers' $memberCount; Add-Row 'Identities' 'GuestUsers' $guestCount
} catch { Write-Host "  (could not count users)" -ForegroundColor DarkGray }
try {
    $sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/`$count" -Headers @{ ConsistencyLevel='eventual' })
    Write-Host ("  Service principals (enterprise apps): {0}" -f $sp)
    Add-Row 'Identities' 'ServicePrincipals' $sp
} catch { }

# --- Groups ---
Write-Host "`n-- Groups --" -ForegroundColor Cyan
try {
    $groups = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/groups?$select=securityEnabled,groupTypes,membershipRule&$top=999').value
    $sec = @($groups | Where-Object { $_.securityEnabled -and ($_.groupTypes -notcontains 'Unified') }).Count
    $m365 = @($groups | Where-Object { $_.groupTypes -contains 'Unified' }).Count
    $dyn = @($groups | Where-Object { $_.groupTypes -contains 'DynamicMembership' }).Count
    Write-Host ("  Total: {0}   Security: {1}   Microsoft 365: {2}   Dynamic: {3}" -f $groups.Count, $sec, $m365, $dyn)
    Add-Row 'Groups' 'Total' $groups.Count; Add-Row 'Groups' 'Security' $sec; Add-Row 'Groups' 'M365' $m365; Add-Row 'Groups' 'Dynamic' $dyn
} catch { Write-Host "  (could not read groups)" -ForegroundColor DarkGray }

# --- Directory roles (least-privilege teaching) ---
Write-Host "`n-- Directory roles --" -ForegroundColor Cyan
try {
    $roles = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/directoryRoles').value
    foreach ($r in $roles) {
        $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/directoryRoles/{0}/members/`$count" -f $r.id) -Headers @{ ConsistencyLevel='eventual' })
        if ($r.displayName -eq 'Global Administrator') {
            $col = if ([int]$members -gt 5) { 'Red' } else { 'Green' }
            Write-Host ("  {0,-34} {1} member(s)" -f $r.displayName, $members) -ForegroundColor $col
            if ([int]$members -gt 5) { Write-Host "      TEACH: Global Administrator looks over-assigned — least privilege says keep this tiny." -ForegroundColor Yellow }
            Add-Row 'Roles' 'GlobalAdminMembers' $members
        } elseif ([int]$members -gt 0) {
            Write-Host ("  {0,-34} {1} member(s)" -f $r.displayName, $members) -ForegroundColor DarkGray
        }
    }
} catch { Write-Host "  (could not read directory roles — needs RoleManagement.Read.Directory)" -ForegroundColor DarkGray }

# --- Applications ---
Write-Host "`n-- Applications --" -ForegroundColor Cyan
try {
    $appReg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/applications/`$count" -Headers @{ ConsistencyLevel='eventual' })
    Write-Host ("  App registrations (definitions): {0}" -f $appReg)
    Write-Host  "  (Each registration may have a matching enterprise app / service principal — see Lab 5.)" -ForegroundColor DarkGray
    Add-Row 'Applications' 'AppRegistrations' $appReg
} catch { Write-Host "  (could not count app registrations)" -ForegroundColor DarkGray }

# --- Licensing (P1 / P2 detection) ---
Write-Host "`n-- Licensing --" -ForegroundColor Cyan
try {
    $plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName
    $p1 = $plans -contains 'AAD_PREMIUM'; $p2 = $plans -contains 'AAD_PREMIUM_P2'
    Write-Host ("  Entra ID P1: {0}   Entra ID P2: {1}" -f $p1, $p2) -ForegroundColor White
    if (-not $p1) { Write-Host "  NOTE: no P1 detected — the report-only Conditional Access lab (Lab 6) becomes a read-only CA tour. Verify licensing." -ForegroundColor Yellow }
    if (-not $p2) { Write-Host "  NOTE: no P2 detected — risk policies / PIM are out of scope here (that is ENTPIM / ENTZTCA). Verify licensing." -ForegroundColor DarkGray }
    Add-Row 'Licensing' 'EntraP1' $p1; Add-Row 'Licensing' 'EntraP2' $p2
} catch { Write-Host "  (could not read subscribedSkus)" -ForegroundColor DarkGray }

# --- Conditional Access inventory (read-only) ---
Write-Host "`n-- Conditional Access policies --" -ForegroundColor Cyan
try {
    $ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
    Write-Host ("  Total CA policies: {0}" -f $ca.Count)
    foreach ($p in $ca | Select-Object -First 15) { Write-Host ("   • {0,-50} [{1}]" -f $p.displayName, $p.state) -ForegroundColor DarkGray }
    Add-Row 'ConditionalAccess' 'PolicyCount' $ca.Count
} catch { Write-Host "  (could not read CA policies — needs P1 and Policy.Read.All)" -ForegroundColor DarkGray }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`nExported to $CsvPath" -ForegroundColor Green }
Write-Host "`nRead-only discovery complete. Nothing was changed." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
