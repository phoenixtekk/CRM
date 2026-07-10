<#
.SYNOPSIS
    CPLTADOPT-LicenseOptimization.ps1 — find assigned-but-unused Copilot seats to reclaim/reallocate.
.DESCRIPTION
    PURPOSE
        Read-only report of idle Copilot licenses. Cross-references users ASSIGNED a Microsoft 365
        Copilot license against the Copilot usage report and lists those who have NOT used Copilot in
        the window (or whose last activity is older than a threshold) as reclaim/reallocation
        candidates, with days-since-last-use. Idle seats are pure cost with zero adoption; this tells
        you which to move to people who will use them. It REPORTS ONLY — it never removes a license;
        reassignment is a deliberate admin-center action.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPLTADOPT-LicenseOptimization.ps1
        Optional: -Period D30|D90                usage look-back window (default D90)
        Optional: -IdleDays 30                    flag seats with no use in this many days (default 30)
        Optional: -CopilotServicePlanId <guid>    the Copilot service plan to match (verify in your tenant)
        Optional: -CsvPath .\cpltadopt-idle-seats.csv
        Consents to Reports.Read.All, User.Read.All, Organization.Read.All (read-only).
    EXPECTED RESULTS
        A list of assigned-but-unused Copilot seats with days-since-last-use, as reclaim candidates.
        No licenses are changed — reassign deliberately in the admin center.
        NOTE: Copilot usage-report endpoint and the Copilot service-plan id VARY by tenant/licensing —
        *verify current availability and identifiers in your tenant.*
.NOTES
    White-label — Copilot. Read-only report (no license changes).
#>
[CmdletBinding()]
param(
    [ValidateSet('D30','D90','D180')][string]$Period = 'D90',
    [int]$IdleDays = 30,
    [string]$CopilotServicePlanId = '',
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Reports.Read.All','User.Read.All','Organization.Read.All' -NoWelcome

Write-Host "`n=== Copilot License Optimization ($Period, idle>$IdleDays d) — $(Get-Date -Format s) ===" -ForegroundColor Cyan
Write-Host "REPORT ONLY — no licenses are changed. Reassign deliberately in the admin center." -ForegroundColor Yellow

# last-activity per user from the usage report
$lastActivity = @{}
try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')" -ErrorAction Stop
    $csv = $resp | ConvertFrom-Csv -ErrorAction Stop
    foreach ($r in $csv) {
        $upn = $r.'User Principal Name'
        if ($upn) { $lastActivity[$upn] = $r.'Last Activity Date' }
    }
} catch {
    Write-Warning "Copilot usage report unavailable: $($_.Exception.Message)"
    Write-Warning "*Verify the Copilot usage-report endpoint in your tenant.* Cannot compute idle seats without usage data."
    Disconnect-MgGraph | Out-Null
    return
}

if (-not $CopilotServicePlanId) {
    Write-Warning "No -CopilotServicePlanId supplied — cannot positively identify Copilot-licensed users. Pass the Copilot service-plan GUID (verify in your tenant) for accurate reclaim candidates."
}

$today = Get-Date
$candidates = @()
$users = Get-MgUser -All -Property 'displayName','userPrincipalName','assignedLicenses','department'
foreach ($u in $users) {
    $hasCopilot = if ($CopilotServicePlanId) { ($u.AssignedLicenses | Where-Object { $_.SkuId -eq $CopilotServicePlanId }).Count -gt 0 } else { $false }
    if (-not $hasCopilot) { continue }

    $last = $lastActivity[$u.UserPrincipalName]
    $idle = $true; $days = $null
    if ($last -and ($last -as [datetime])) {
        $days = [int]($today - ([datetime]$last)).TotalDays
        $idle = $days -ge $IdleDays
    }
    if ($idle) {
        $candidates += [pscustomobject]@{ User=$u.UserPrincipalName; Name=$u.DisplayName; Department=$u.Department; LastActivity=($(if($last){$last}else{'never'})); DaysIdle=($(if($days -ne $null){$days}else{'>window'})) }
        Write-Host ("• {0,-40} last: {1,-12} idle: {2}" -f $u.UserPrincipalName, ($(if($last){$last}else{'never'})), ($(if($days -ne $null){"$days d"}else{'>window'}))) -ForegroundColor Yellow
    }
}

Write-Host ("`nReclaim/reallocation candidates: {0}" -f $candidates.Count) -ForegroundColor $(if($candidates.Count){'Yellow'}else{'Green'})
if ($CsvPath) {
    $candidates | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Exported candidates to {0}" -f $CsvPath) -ForegroundColor Green
}
Write-Host "Reassign seats deliberately: M365 admin center -> Billing -> Licenses (or group-based assignment)."
Disconnect-MgGraph | Out-Null
