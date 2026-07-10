<#
.SYNOPSIS
    ENTIGA-Report.ps1 — export audit / recertification evidence (read-only, Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Produces the recertification artifact auditors ask for: current access package assignments
        (who has what, when granted, when it expires) and the most recent access review decisions
        (who reviewed, the decision, and the justification). Also lists in-scope users missing a
        Manager attribute (needed for manager-as-approver / manager-based reviews).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTIGA-Report.ps1 -CsvFolder C:\Temp\entiga-audit
    EXPECTED RESULTS
        Console summary + CSVs: assignments.csv, review-decisions.csv, missing-manager.csv.
        Keep the CSVs as recertification evidence.
.NOTES
    White-label — Entra ID Solutions. Read-only against Microsoft Graph. No credentials stored.
.EXAMPLE
    .\ENTIGA-Report.ps1 -CsvFolder C:\Temp\entiga-audit
#>
[CmdletBinding()] param([string]$CsvFolder = ".\entiga-audit")

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'EntitlementManagement.Read.All','AccessReview.Read.All','User.Read.All' -NoWelcome

if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
function Get-AllPages([string]$Uri) {
    $items=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $items+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $items
}

# --- Access package assignments (who has what, granted/expiry) -----------------
Write-Host "`n=== Access package assignments ===" -ForegroundColor Cyan
$assign = Get-AllPages "/v1.0/identityGovernance/entitlementManagement/assignments?`$expand=accessPackage,target&`$filter=state eq 'delivered'"
$aRows = $assign | ForEach-Object {
    [pscustomobject]@{
        User       = $_.target.email
        Package    = $_.accessPackage.displayName
        State      = $_.state
        GrantedUtc = $_.schedule.startDateTime
        ExpiresUtc = $_.schedule.expiration.endDateTime
    }
}
if ($aRows) { $aRows | Format-Table -AutoSize } else { Write-Host "  (no delivered assignments)" -ForegroundColor Yellow }
if ($aRows) { $aRows | Export-Csv (Join-Path $CsvFolder 'assignments.csv') -NoTypeInformation }

# --- Recent access review decisions -------------------------------------------
Write-Host "`n=== Recent access review decisions ===" -ForegroundColor Cyan
$defs = Get-AllPages "/v1.0/identityGovernance/accessReviews/definitions"
$dRows = @()
foreach ($d in ($defs | Where-Object displayName -like 'ENTIGA*')) {
    $instances = Get-AllPages "/v1.0/identityGovernance/accessReviews/definitions/$($d.id)/instances"
    $latest = $instances | Sort-Object { $_.startDateTime } -Descending | Select-Object -First 1
    if (-not $latest) { continue }
    $decisions = Get-AllPages "/v1.0/identityGovernance/accessReviews/definitions/$($d.id)/instances/$($latest.id)/decisions"
    foreach ($dec in $decisions) {
        $dRows += [pscustomobject]@{
            Review        = $d.displayName
            ReviewedUser  = $dec.target.userPrincipalName
            Decision      = $dec.decision
            AppliedResult = $dec.applyResult
            Reviewer      = $dec.reviewedBy.displayName
            Justification = $dec.justification
        }
    }
}
if ($dRows) { $dRows | Format-Table -AutoSize } else { Write-Host "  (no decisions yet — run a review to completion)" -ForegroundColor Yellow }
if ($dRows) { $dRows | Export-Csv (Join-Path $CsvFolder 'review-decisions.csv') -NoTypeInformation }

# --- Users missing a Manager (affects manager-based approval/review) ----------
Write-Host "`n=== In-scope users missing a Manager ===" -ForegroundColor Cyan
$users = Get-AllPages "/v1.0/users?`$select=id,userPrincipalName,accountEnabled,userType&`$filter=accountEnabled eq true and userType eq 'Member'&`$top=200"
$noMgr = @()
foreach ($u in $users) {
    try { Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$($u.id)/manager?`$select=id" -ErrorAction Stop | Out-Null }
    catch { $noMgr += [pscustomobject]@{ User=$u.userPrincipalName } }
}
Write-Host ("  {0} of {1} sampled members have no manager set" -f $noMgr.Count, $users.Count) -ForegroundColor Yellow
if ($noMgr) { $noMgr | Export-Csv (Join-Path $CsvFolder 'missing-manager.csv') -NoTypeInformation }

Write-Host "`nEvidence written to $CsvFolder" -ForegroundColor Green
Disconnect-MgGraph | Out-Null
