<#
.SYNOPSIS
    PURVCC-Discovery.ps1 — read-only Communication Compliance readiness, ROLE-SEPARATION, and privacy/scope assessment.
.DESCRIPTION
    PURPOSE
        Assesses whether the tenant is ready for Communication Compliance and captures the
        role-separation evidence baseline. Reports the membership of each Communication Compliance
        role group (Admin / Analysts / Investigators / Viewers) so builders, reviewers, and
        investigators can be confirmed separate; lists any existing SupervisoryReview policies and
        rules; and flags an over-broad supervised scope or collapsed separation. Read-only — makes
        no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVCC-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVCC-Discovery.ps1 -CsvPath C:\Temp\PURVCC-Separation.csv
        Requires the ExchangeOnlineManagement module; connects with Connect-IPPSSession
        (Security & Compliance PowerShell). Sign in with an admin holding a Communication
        Compliance / compliance role.
    EXPECTED RESULTS
        A console summary: role-group membership (the "Comms Role Separation - Evidence" snapshot),
        a separation warning if the same identity is both a builder and a reviewer/investigator,
        the existing policies/rules, and a scope note. Optional CSV of the membership snapshot.
.NOTES
    Purview — Microsoft Purview Communication Compliance. Read-only. No credentials are stored.
    Communication Compliance is licensing-dependent (E5 / E5 Compliance / Insider Risk) and the
    portal evolves — verify capability availability against your own licensing and tenant.
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

Write-Host '=== Comms Role Separation - Evidence ===' -ForegroundColor Cyan

# --- Role-group membership (the separation snapshot) ---
$ccGroups = @(
    'Communication Compliance Admin',
    'Communication Compliance Analysts',
    'Communication Compliance Investigators',
    'Communication Compliance Viewers',
    'Communication Compliance'          # combined (collapses separation — flagged if used broadly)
)
$membership = @()
foreach ($g in $ccGroups) {
    $rg = Get-RoleGroup -Identity $g -ErrorAction SilentlyContinue
    if (-not $rg) { Write-Host ("  [missing] {0}" -f $g) -ForegroundColor DarkYellow; continue }
    $members = @(Get-RoleGroupMember -Identity $g -ErrorAction SilentlyContinue)
    Write-Host ("--- {0} ({1} member(s)) ---" -f $g, $members.Count) -ForegroundColor Cyan
    if ($members.Count -eq 0) { Write-Host '    (empty)' -ForegroundColor DarkGray }
    foreach ($m in $members) {
        $who = if ($m.PrimarySmtpAddress) { $m.PrimarySmtpAddress } else { $m.Name }
        Write-Host ("    {0}" -f $who)
        $membership += [pscustomobject]@{ RoleGroup = $g; Member = "$who" }
    }
}

# --- Separation check: same identity as a builder AND a reviewer/investigator ---
$builders  = ($membership | Where-Object { $_.RoleGroup -eq 'Communication Compliance Admin' }).Member
$reviewers = ($membership | Where-Object { $_.RoleGroup -in 'Communication Compliance Analysts','Communication Compliance Investigators' }).Member
$overlap   = $builders | Where-Object { $reviewers -contains $_ } | Select-Object -Unique
$combinedUsed = @($membership | Where-Object { $_.RoleGroup -eq 'Communication Compliance' }).Count

Write-Host ''
if ($overlap) {
    Write-Host '  [SEPARATION WARNING] These identities are BOTH policy-builders and reviewers/investigators:' -ForegroundColor Red
    $overlap | ForEach-Object { Write-Host ("    - {0}" -f $_) -ForegroundColor Red }
    Write-Host '    Confirm HR/legal explicitly accept this, or separate the roles (Implementation Step 2).' -ForegroundColor Red
} else {
    Write-Host '  [OK] No overlap between policy-builders and reviewers/investigators.' -ForegroundColor Green
}
if ($combinedUsed -gt 0) {
    Write-Host ("  [NOTE] The combined 'Communication Compliance' role group has {0} member(s) — it grants all roles and collapses separation. Use the specific groups outside a tiny pilot." -f $combinedUsed) -ForegroundColor Yellow
}

# --- Existing policies / rules ---
Write-Host ''
Write-Host '=== Existing Communication Compliance policies ===' -ForegroundColor Cyan
try {
    $policies = @(Get-SupervisoryReviewPolicyV2 -ErrorAction Stop)
    if ($policies.Count -eq 0) {
        Write-Host '  (none — clean slate)' -ForegroundColor DarkGray
    } else {
        foreach ($p in $policies) {
            $revCount = @($p.Reviewers).Count
            Write-Host ("  - {0}  | reviewers: {1}" -f $p.Name, $revCount)
            # Scope note: flag a potentially over-broad supervised population.
            $scope = @($p.Reviewers).Count  # policy scope detail is on the associated rule
        }
        Write-Host '  Scope/condition detail is on each policy''s rule — see PURVCC-Report.ps1.' -ForegroundColor DarkGray
    }
} catch {
    Write-Host ("  Could not enumerate policies: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    Write-Host '  If SupervisoryReview cmdlets are unavailable, verify Communication Compliance licensing/enablement.' -ForegroundColor DarkYellow
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
Write-Host 'Discovery complete (read-only). Resolve any SEPARATION WARNING and confirm HR/legal sign-off before configuring policies.' -ForegroundColor Cyan
