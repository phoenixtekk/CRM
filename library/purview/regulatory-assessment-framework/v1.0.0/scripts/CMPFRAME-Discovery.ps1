<#
.SYNOPSIS
    CMPFRAME-Discovery.ps1 — read-only framework readiness, ROLE-SEPARATION, and licensing assessment.
.DESCRIPTION
    PURPOSE
        Assesses whether the tenant is ready to stand up a multi-regulation Regulatory Assessment
        Framework in Microsoft Purview Compliance Manager. Reports the membership of each Compliance
        Manager role group (Administrators / Assessors / Contributors / Readers) so administrators can
        be confirmed separate from contributors and readers (the "RAF Roles - Separation Evidence"
        snapshot), and reads the subscribed licensing SKUs (Graph) that gate the premium/custom
        assessment templates the framework maps to. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Discovery.ps1 -CsvPath C:\Temp\RAF-Roles.csv
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession, Security & Compliance
        PowerShell) and, for licensing, Microsoft.Graph (Connect-MgGraph). Sign in with an admin
        holding a Compliance Manager / compliance role. The score, assessments, and control mapping
        themselves are read from the Purview portal (Compliance Manager) — Compliance Manager has no
        broad public API.
    EXPECTED RESULTS
        A console summary: role-group membership (the "RAF Roles - Separation Evidence" snapshot), a
        separation warning if an administrator is also a contributor, and the licensing SKUs relevant
        to premium templates. Optional CSV of the membership snapshot.
.NOTES
    Purview — Regulatory Assessment Framework. Read-only. No credentials are stored. Premium/custom
    templates are licensing-dependent (E5 / E5 Compliance / Premium Assessment Add-On) and the portal
    evolves — verify template availability against your own licensing and tenant. Verify the exact
    role-group names in your tenant; Purview role naming evolves.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

# --- Connect (Security & Compliance PowerShell) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement module...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
} catch {
    Write-Error "Connect-IPPSSession failed: $($_.Exception.Message). Confirm licensing and your admin role."
    return
}

Write-Host '=== RAF Roles - Separation Evidence ===' -ForegroundColor Cyan

# --- Compliance Manager role-group membership (the separation snapshot) ---
# Verify the exact names in your tenant; Purview role naming evolves.
$cmGroups = @(
    'Compliance Manager Administrators',
    'Compliance Manager Assessors',
    'Compliance Manager Contributors',
    'Compliance Manager Readers'
)
$membership = @()
foreach ($g in $cmGroups) {
    $rg = Get-RoleGroup -Identity $g -ErrorAction SilentlyContinue
    if (-not $rg) { Write-Host ("  [missing] {0} — verify the exact role-group name in your tenant" -f $g) -ForegroundColor DarkYellow; continue }
    $members = @(Get-RoleGroupMember -Identity $g -ErrorAction SilentlyContinue)
    Write-Host ("--- {0} ({1} member(s)) ---" -f $g, $members.Count) -ForegroundColor Cyan
    if ($members.Count -eq 0) { Write-Host '    (empty)' -ForegroundColor DarkGray }
    foreach ($m in $members) {
        $who = if ($m.PrimarySmtpAddress) { $m.PrimarySmtpAddress } else { $m.Name }
        Write-Host ("    {0}" -f $who)
        $membership += [pscustomobject]@{ RoleGroup = $g; Member = "$who" }
    }
}

# --- Separation check: an administrator who is also a contributor ---
$admins       = ($membership | Where-Object { $_.RoleGroup -eq 'Compliance Manager Administrators' }).Member
$contributors = ($membership | Where-Object { $_.RoleGroup -eq 'Compliance Manager Contributors' }).Member
$overlap      = $admins | Where-Object { $contributors -contains $_ } | Select-Object -Unique

Write-Host ''
if ($overlap) {
    Write-Host '  [SEPARATION NOTE] These identities are BOTH Compliance Manager Administrators and Contributors:' -ForegroundColor Yellow
    $overlap | ForEach-Object { Write-Host ("    - {0}" -f $_) -ForegroundColor Yellow }
    Write-Host '    Grant the minimum role each person needs, or record governance acceptance (Implementation Step 4).' -ForegroundColor Yellow
} else {
    Write-Host '  [OK] No administrator is also a contributor — least-privilege separation holds.' -ForegroundColor Green
}

# --- Licensing signals (Graph) that gate premium/custom assessment templates ---
Write-Host ''
Write-Host '=== Licensing (premium/custom template entitlement) ===' -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host '  Microsoft.Graph not installed — skipping licensing read. Install-Module Microsoft.Graph to enable.' -ForegroundColor DarkYellow
} else {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome -ErrorAction Stop
        $skus = Get-MgSubscribedSku -All -ErrorAction Stop
        # Common SKU part numbers associated with E5 / E5 Compliance entitlement (indicative — verify).
        $hint = 'ENTERPRISEPREMIUM|SPE_E5|Microsoft_365_E5|IDENTITY_THREAT_PROTECTION|INFORMATION_PROTECTION_COMPLIANCE|M365_E5_COMP|COMPLIANCE'
        foreach ($s in $skus) {
            $flag = if ($s.SkuPartNumber -match $hint) { '  <-- may entitle premium Compliance Manager templates (verify)' } else { '' }
            Write-Host ("  {0}  (enabled units: {1}){2}" -f $s.SkuPartNumber, $s.PrepaidUnits.Enabled, $flag)
        }
        Write-Host '  NOTE: SKU-to-feature mapping is indicative only — confirm exact entitlement and the number of premium' -ForegroundColor DarkGray
        Write-Host '        assessments available with Microsoft licensing; every in-scope regulation template must be creatable.' -ForegroundColor DarkGray
    } catch {
        Write-Host ("  Could not read licensing via Graph: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    }
}

# --- Optional CSV of the separation snapshot ---
if ($CsvPath) {
    try {
        $membership | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host ("`nSeparation snapshot written to {0}" -f $CsvPath) -ForegroundColor Green
    } catch {
        Write-Warning "Could not write CSV: $($_.Exception.Message)"
    }
}

Write-Host ''
Write-Host 'Discovery complete (read-only). Record the baseline Compliance Score from the Purview portal, confirm every in-scope regulation template is available, and get governance-owner sign-off before building the crosswalk and assessments.' -ForegroundColor Cyan
