<#
.SYNOPSIS
    CMMC-Discovery.ps1 — read-only readiness scan for a Purview CMMC program (Compliance Manager).
.DESCRIPTION
    PURPOSE
        Reports the tenant readiness to stand up a CMMC (NIST SP 800-171 / CMMC Level 2) program in
        Microsoft Purview Compliance Manager: the licensing SKUs it can read via Graph, the membership
        of each Compliance Manager role group (the 'CMMC Roles - Separation Evidence' snapshot,
        flagging any administrator who is also a contributor), and whether unified audit logging is on.
        It does NOT create assessments — Compliance Manager is portal-managed and has no write API.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        Install-Module Microsoft.Graph -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\CMMC-Discovery.ps1
        Sign in as a Compliance Administrator / Global Reader when prompted. For GCC High, pass the
        environment endpoints: -ExoConnectionUri and -GraphEnvironment (see params).
    EXPECTED RESULTS
        Licensing SKU list, per-role-group membership with any admin+contributor overlap flagged, and
        an audit-logging state line. Read-only — makes no changes.
.NOTES
    White-label — Purview Solutions. Read-only.
    Uses Get-RoleGroupMember / Get-AdminAuditLogConfig (S&C PowerShell) and Get-MgSubscribedSku (Graph).
    Verify exact role-group names, template availability, and cloud (Commercial vs GCC/GCC High) in
    your own tenant — Purview naming evolves; nothing here is assumed.
#>
[CmdletBinding()] param(
    [string]$ExoConnectionUri,                 # e.g. GCC High: https://ps.compliance.protection.office365.us/powershell-liveid/
    [string]$GraphEnvironment = 'Global'       # e.g. 'USGov' or 'USGovDoD' for government clouds
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if ($ExoConnectionUri) { Connect-IPPSSession -ConnectionUri $ExoConnectionUri -ShowBanner:$false }
else                   { Connect-IPPSSession -ShowBanner:$false }

Write-Host "`n=== Purview CMMC — readiness discovery ===" -ForegroundColor Cyan

# --- Compliance Manager role groups (separation evidence) ---
Write-Host "`n--- Compliance Manager role groups (CMMC Roles - Separation Evidence) ---" -ForegroundColor Cyan
$cmGroups = @(
    'Compliance Manager Administrators',
    'Compliance Manager Assessors',
    'Compliance Manager Contributors',
    'Compliance Manager Readers'
)
$membership = @{}
foreach ($g in $cmGroups) {
    $members = @()
    try { $members = @(Get-RoleGroupMember -Identity $g -ErrorAction Stop | Select-Object -ExpandProperty Name) } catch {
        Write-Host ("  Role group '{0}' not found or unreadable (verify the exact name in your tenant)." -f $g) -ForegroundColor Yellow
    }
    $membership[$g] = $members
    Write-Host ("  {0} ({1}):" -f $g, $members.Count) -ForegroundColor Cyan
    if ($members) { $members | ForEach-Object { Write-Host "    - $_" } }
    else          { Write-Host "    (none)" -ForegroundColor Yellow }
}
# Flag separation-of-duty overlaps: admins who are also contributors
$admins = $membership['Compliance Manager Administrators']
$contrib = $membership['Compliance Manager Contributors']
$overlap = @($admins | Where-Object { $contrib -contains $_ })
if ($overlap) {
    Write-Host ("`n  SEPARATION FLAG: {0} account(s) are both Administrator and Contributor:" -f $overlap.Count) -ForegroundColor Yellow
    $overlap | ForEach-Object { Write-Host "    ! $_" -ForegroundColor Yellow }
    Write-Host "    Confirm this overlap is accepted by the governance owners (least privilege / AC family)." -ForegroundColor Yellow
} else { Write-Host "`n  Separation OK: no Administrator is also a Contributor." -ForegroundColor Green }

# --- Unified audit logging (AU family signal) ---
Write-Host "`n--- Unified audit logging (NIST 800-171 AU signal) ---" -ForegroundColor Cyan
try {
    $audit = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = [bool]$audit.UnifiedAuditLogIngestionEnabled
    Write-Host ("  UnifiedAuditLogIngestionEnabled : {0}" -f $on) -ForegroundColor ($(if($on){'Green'}else{'Yellow'}))
    if (-not $on) { Write-Host "    Enable auditing before relying on AU-family automatic testing (Requirement 2.7)." -ForegroundColor Yellow }
} catch { Write-Host ("  Could not read audit config: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Licensing SKUs (via Graph; entitlement gate for the premium CMMC template) ---
Write-Host "`n--- Licensing SKUs (premium CMMC/NIST template entitlement) ---" -ForegroundColor Cyan
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.DirectoryManagement)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    Connect-MgGraph -Scopes 'Organization.Read.All' -Environment $GraphEnvironment -NoWelcome
    $skus = Get-MgSubscribedSku -ErrorAction Stop
    $skus | Select-Object SkuPartNumber,
        @{n='Enabled';e={$_.PrepaidUnits.Enabled}},
        @{n='Consumed';e={$_.ConsumedUnits}} | Format-Table -AutoSize
    $e5 = @($skus | Where-Object { $_.SkuPartNumber -match 'E5|COMPLIANCE|INFORMATION_PROTECTION' })
    if ($e5) { Write-Host ("  Note: {0} SKU(s) look E5/Compliance-related — CONFIRM the CMMC/NIST premium template is available to create in the portal." -f $e5.Count) -ForegroundColor Cyan }
    else     { Write-Host "  No obvious E5/Compliance SKU seen — the premium CMMC/NIST template may not be available. Verify entitlement (Requirement 2.1)." -ForegroundColor Yellow }
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Host ("  Graph licensing read unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  Verify E5 / E5 Compliance / Premium Assessment Add-On manually (Requirement 2.1)." -ForegroundColor Yellow
}

Write-Host "`nDiscovery complete. Use CMMC-Validation.ps1 to check the technical signals behind NIST 800-171 actions." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
