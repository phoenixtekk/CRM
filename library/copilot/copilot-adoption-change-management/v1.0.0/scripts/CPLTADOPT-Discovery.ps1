<#
.SYNOPSIS
    CPLTADOPT-Discovery.ps1 — Copilot adoption baseline: assigned licenses vs. actual usage.
.DESCRIPTION
    PURPOSE
        Read-only baseline for the adoption program. Reports how many users are ASSIGNED a Microsoft
        365 Copilot license versus how many have ACTUALLY USED Copilot in the reporting window — the
        enablement-vs-activation gap that the whole program exists to close. Optionally scopes to a
        pilot group to confirm every member is licensed. Save the output and the date as your baseline.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser        # once
        powershell -ExecutionPolicy Bypass -File .\CPLTADOPT-Discovery.ps1
        Optional: -Period D30|D7|D90          usage look-back window (default D30)
        Optional: -GroupId <id>               limit the licensed-check to a pilot/cohort group
        Optional: -CopilotServicePlanId <guid>  the Copilot service plan to match (verify in your tenant)
        Optional: -CsvPath .\cpltadopt-baseline.csv
        Consents to Reports.Read.All, User.Read.All, Group.Read.All, Organization.Read.All (read-only).
    EXPECTED RESULTS
        Assigned-license count, active-user count, the adoption gap, and (if -GroupId) any unlicensed
        cohort members. No changes are made.
        NOTE: The Copilot usage-report endpoint and the Copilot service-plan id VARY by tenant and
        licensing — *verify current availability and identifiers in your tenant.*
.NOTES
    White-label — Copilot. Read-only. Change-management adoption program.
#>
[CmdletBinding()]
param(
    [ValidateSet('D7','D30','D90','D180')][string]$Period = 'D30',
    [string]$GroupId,
    [string]$CopilotServicePlanId = '',   # e.g. the Microsoft 365 Copilot service plan GUID — verify in your tenant
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Reports.Read.All','User.Read.All','Group.Read.All','Organization.Read.All' -NoWelcome

Write-Host "`n=== Copilot Adoption Baseline ($Period) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# 1) Active users from the Copilot usage report (endpoint availability varies — verify)
$activeUpns = @()
try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')" -ErrorAction Stop
    # Response is CSV text; parse to find users with any recent Copilot activity
    $csv = $resp | ConvertFrom-Csv -ErrorAction SilentlyContinue
    if ($csv) {
        $activeUpns = @($csv | Where-Object {
            ($_.PSObject.Properties.Name -match 'Last Activity Date' -and $_.'Last Activity Date') -or
            ($_.PSObject.Properties.Value -match '\d{4}-\d{2}-\d{2}')
        } | ForEach-Object { $_.'User Principal Name' } | Where-Object { $_ })
    }
    Write-Host ("Active Copilot users in window: {0}" -f $activeUpns.Count) -ForegroundColor Green
} catch {
    Write-Warning "Copilot usage report unavailable ($($_.Exception.Message))."
    Write-Warning "*Verify the Copilot usage-report endpoint/period support in your tenant.* Falling back to license-only baseline."
}

# 2) Assigned Copilot licenses
$licensed = @()
$allUsers = Get-MgUser -All -Property 'displayName','userPrincipalName','assignedLicenses','department'
foreach ($u in $allUsers) {
    $plans = @($u.AssignedLicenses | ForEach-Object { $_.SkuId })
    $hasCopilot = if ($CopilotServicePlanId) {
        ($u.AssignedLicenses | Where-Object { $_.SkuId -eq $CopilotServicePlanId }).Count -gt 0
    } else {
        # Without a supplied id, we cannot positively identify Copilot; report license presence only.
        $false
    }
    if ($hasCopilot) { $licensed += $u.UserPrincipalName }
}
if (-not $CopilotServicePlanId) {
    Write-Warning "No -CopilotServicePlanId supplied — cannot positively identify Copilot seats. Pass the Copilot service-plan GUID (verify in your tenant) for an accurate assigned count."
}
Write-Host ("Assigned Copilot licenses: {0}" -f $licensed.Count)

# 3) The adoption gap
if ($licensed.Count -gt 0) {
    $adoptedInLicensed = @($licensed | Where-Object { $activeUpns -contains $_ })
    $gap = $licensed.Count - $adoptedInLicensed.Count
    Write-Host ("Adopted (licensed AND active): {0}" -f $adoptedInLicensed.Count) -ForegroundColor Green
    Write-Host ("ADOPTION GAP (licensed, not yet active): {0}" -f $gap) -ForegroundColor $(if($gap){'Yellow'}else{'Green'})
}

# 4) Optional cohort licensing check
if ($GroupId) {
    Write-Host "`n--- Pilot cohort licensing ---" -ForegroundColor Cyan
    $members = Get-MgGroupMember -GroupId $GroupId -All -ErrorAction SilentlyContinue
    foreach ($m in $members) {
        $upn = $m.AdditionalProperties.userPrincipalName
        if (-not $upn) { continue }
        $isLic = $licensed -contains $upn
        Write-Host ("  {0,-40} licensed={1}" -f $upn, $isLic) -ForegroundColor $(if($isLic){'White'}else{'Yellow'})
    }
}

if ($CsvPath) {
    $rows = $allUsers | ForEach-Object {
        [pscustomobject]@{ User=$_.UserPrincipalName; Department=$_.Department; Licensed=($licensed -contains $_.UserPrincipalName); Active=($activeUpns -contains $_.UserPrincipalName) }
    }
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported baseline to {0}" -f $CsvPath) -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
