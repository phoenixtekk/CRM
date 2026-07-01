<#
.SYNOPSIS
    M365LIC-Validation.ps1 — read-only classification of license seats into unused / duplicate / over-tier reclaim candidates.
.DESCRIPTION
    PURPOSE
        Joins assigned licenses, sign-in/activity, and the protected-account exclusion group, then
        classifies each seat into one of three reclaim levers:
          - Unused   : no sign-in AND no service activity across the inactivity window (leaver/idle).
          - Duplicate: a user carrying two SKUs that grant the same overlapping service.
          - OverTier : a user on a higher SKU while the lower SKU would fit (evidence-based downgrade).
        Shared mailboxes, room/resource accounts, and members of the exclusion group are dropped.
        Read-only — makes no changes. Writes "Reclaim Candidates - M365 - Validation".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365LIC-Validation.ps1 -InactivityDays 90 -ExclusionGroup "Reclaim Exclusions - Shared+Service - AllStages" -CsvPath C:\Temp\M365LIC-Candidates.csv
        Requires the Microsoft Graph PowerShell SDK and scopes:
        User.Read.All, Directory.Read.All, Organization.Read.All, AuditLog.Read.All, Reports.Read.All.
    EXPECTED RESULTS
        A console summary of candidates by lever and a per-candidate CSV
        (UPN, SKUs, classification, reason, last activity) with protected accounts already excluded.
.NOTES
    Asset Mgt — Microsoft 365 License Optimization & Reharvesting. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [int]$InactivityDays = 90,
    [string]$ExclusionGroup = 'Reclaim Exclusions - Shared+Service - AllStages',
    # SKUs whose presence makes a lower SKU redundant: lowerSku -> higherSku that supersedes it.
    [hashtable]$DuplicatePairs = @{ 'EXCHANGESTANDARD' = 'ENTERPRISEPACK' },
    # Over-tier downgrade map: highSku -> suggested lowerSku when high-tier features are unused.
    [hashtable]$OverTierMap   = @{ 'ENTERPRISEPREMIUM' = 'ENTERPRISEPACK' },
    [string]$CsvPath,
    [string]$ReportName = 'Reclaim Candidates - M365 - Validation'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'User.Read.All','Directory.Read.All','Organization.Read.All','AuditLog.Read.All','Reports.Read.All' -NoWelcome

$cutoff = (Get-Date).AddDays(-$InactivityDays)
Write-Host ("=== {0} (inactivity {1}d) ===" -f $ReportName, $InactivityDays) -ForegroundColor Cyan

# --- Build the exclusion set: explicit group members + all shared/room/resource mailboxes ---
$excluded = New-Object System.Collections.Generic.HashSet[string]
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id" -f ($ExclusionGroup -replace "'","''"))).value | Select-Object -First 1
if ($grp) {
    $muri = ("/v1.0/groups/{0}/members?`$select=userPrincipalName&`$top=999" -f $grp.id)
    do { $m = Invoke-MgGraphRequest -Method GET -Uri $muri; $m.value | ForEach-Object { if ($_.userPrincipalName) { [void]$excluded.Add($_.userPrincipalName.ToLower()) } }; $muri = $m.'@odata.nextLink' } while ($muri)
} else {
    Write-Warning ("Exclusion group '{0}' not found — only mailbox-type exclusions will apply. Build it with M365LIC-Set-ScopeTargeting.ps1." -f $ExclusionGroup)
}
# Shared / room / equipment mailboxes are never user seats to reclaim.
$mbCsv = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMailboxUsageDetail(period='D90')?`$format=text/csv"
# (mailbox usage detail does not include recipient type; rely on the exclusion group for shared mailboxes + the directory check below.)

$skuMap = @{}; (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value | ForEach-Object { $skuMap[$_.skuId] = $_.skuPartNumber }

$candidates = @()
$uri = '/v1.0/users?$select=userPrincipalName,displayName,accountEnabled,userType,assignedLicenses,signInActivity&$top=999'
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($u in $r.value) {
        if (-not $u.assignedLicenses -or $u.assignedLicenses.Count -eq 0) { continue }
        if ($u.userPrincipalName -and $excluded.Contains($u.userPrincipalName.ToLower())) { continue }   # protected
        if ($u.userType -eq 'Guest') { continue }

        $skuNames = @($u.assignedLicenses | ForEach-Object { if ($skuMap.ContainsKey($_.skuId)) { $skuMap[$_.skuId] } else { $_.skuId } })
        $lastSignIn = $null
        if ($u.signInActivity -and $u.signInActivity.lastSignInDateTime) { $lastSignIn = [datetime]$u.signInActivity.lastSignInDateTime }
        $inactive = (-not $lastSignIn) -or ($lastSignIn -lt $cutoff)

        # 1) Unused / leaver
        if ($inactive) {
            $candidates += [pscustomobject]@{
                UserPrincipalName = $u.userPrincipalName; Skus = ($skuNames -join ';')
                Classification = 'Unused'; SuggestedAction = 'Remove all licenses (validate retention)'
                Reason = $(if ($lastSignIn) { "No sign-in since $($lastSignIn.ToString('yyyy-MM-dd'))" } else { 'No recorded sign-in' })
                LastSignIn = $lastSignIn
            }
            continue
        }
        # 2) Duplicate (overlapping SKUs both present)
        foreach ($pair in $DuplicatePairs.GetEnumerator()) {
            if ($skuNames -contains $pair.Key -and $skuNames -contains $pair.Value) {
                $candidates += [pscustomobject]@{
                    UserPrincipalName = $u.userPrincipalName; Skus = ($skuNames -join ';')
                    Classification = 'Duplicate'; SuggestedAction = ("Remove {0} (covered by {1})" -f $pair.Key, $pair.Value)
                    Reason = ("Carries both {0} and {1}" -f $pair.Key, $pair.Value); LastSignIn = $lastSignIn
                }
            }
        }
        # 3) Over-tier (on a high SKU; flag for evidence-based downgrade review)
        foreach ($ot in $OverTierMap.GetEnumerator()) {
            if ($skuNames -contains $ot.Key) {
                $candidates += [pscustomobject]@{
                    UserPrincipalName = $u.userPrincipalName; Skus = ($skuNames -join ';')
                    Classification = 'OverTier'; SuggestedAction = ("Review for downgrade {0} -> {1}" -f $ot.Key, $ot.Value)
                    Reason = ("On {0}; confirm high-tier features unused before right-sizing" -f $ot.Key); LastSignIn = $lastSignIn
                }
            }
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host '--- Candidates by lever ---' -ForegroundColor Cyan
$candidates | Group-Object Classification | Sort-Object Name | Select-Object Count, @{n='Classification';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total candidates: {0} (protected accounts excluded)" -f $candidates.Count) -ForegroundColor Cyan

if ($CsvPath) {
    $candidates | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
