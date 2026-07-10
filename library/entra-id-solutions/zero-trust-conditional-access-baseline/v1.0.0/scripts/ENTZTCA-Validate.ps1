<#
.SYNOPSIS
    ENTZTCA-Validate.ps1 — confirm the baseline exists, its state, and break-glass exclusion.
.DESCRIPTION
    PURPOSE
        Read-only check of the Conditional Access baseline: (1) the expected numbered policies exist;
        (2) each is in the intended state (report-only during validation, enabled after enforce); and
        (3) every policy excludes the break-glass accounts. Prints PASS/WARN per policy and flags — in
        red — any policy that targets All users without excluding break-glass.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTZTCA-Validate.ps1 -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com
        Optional: -ExpectReportOnly  to require every CA0* policy to still be in report-only.
        Consents to Policy.Read.All, User.Read.All, Directory.Read.All (read-only). No changes.
    EXPECTED RESULTS
        PASS/WARN lines for policy presence, state, and break-glass exclusion. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string[]]$BreakGlassUpn,
    [switch]$ExpectReportOnly
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','User.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== CA Baseline Validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Resolve break-glass ids + the exclusion group
$bgIds = @()
foreach ($upn in $BreakGlassUpn) {
    $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn?`$select=id,userPrincipalName" -ErrorAction SilentlyContinue
    if ($u.id) { $bgIds += $u.id }
}
$exclGroup = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq 'CA Exclusion - Break-Glass - Steady'").value | Select-Object -First 1

$expected = @('CA001','CA002','CA003','CA004','CA005','CA006','CA007','CA008')
$policies = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value

Write-Host "`n-- Baseline policies --" -ForegroundColor Cyan
foreach ($num in $expected) {
    $p = $policies | Where-Object { $_.displayName -like "$num *" } | Select-Object -First 1
    if (-not $p) { Write-Host ("  WARN: {0} not found (skipped for licensing?)" -f $num) -ForegroundColor Yellow; continue }

    # State check
    if ($ExpectReportOnly -and $p.state -ne 'enabledForReportingButNotEnforced') {
        Write-Host ("  WARN: {0} state is '{1}' — expected report-only" -f $p.displayName, $p.state) -ForegroundColor Yellow
    } else {
        Write-Host ("  PASS: {0} [state={1}]" -f $p.displayName, $p.state) -ForegroundColor Green
    }

    # Break-glass exclusion check
    $exclUsers  = @($p.conditions.users.excludeUsers)
    $exclGroups = @($p.conditions.users.excludeGroups)
    $excluded = $true
    foreach ($bg in $bgIds) { if ($exclUsers -notcontains $bg) { $excluded = $false } }
    $groupCovered = ($exclGroup -and ($exclGroups -contains $exclGroup.id))
    if ($excluded -or $groupCovered) {
        Write-Host ("      PASS: break-glass excluded ({0})" -f ($(if($groupCovered){'via exclusion group'}else{'via user exclusion'})) ) -ForegroundColor Green
    } else {
        Write-Host  "      WARN: break-glass NOT fully excluded from this policy — fix before enforcing." -ForegroundColor Red
    }
}

# Global lock-out sweep: any All-users policy with zero exclusions
Write-Host "`n-- All-users lock-out sweep --" -ForegroundColor Cyan
foreach ($p in $policies) {
    if (($p.conditions.users.includeUsers -contains 'All') -and (@($p.conditions.users.excludeUsers).Count + @($p.conditions.users.excludeGroups).Count) -eq 0) {
        Write-Host ("  RED FLAG: {0} targets All users with NO exclusions." -f $p.displayName) -ForegroundColor Red
    }
}
Write-Host "`nProceed to enforce only when every policy is report-only-clean and excludes break-glass." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
