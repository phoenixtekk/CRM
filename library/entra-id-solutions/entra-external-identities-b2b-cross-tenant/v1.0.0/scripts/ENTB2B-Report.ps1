<#
.SYNOPSIS
    ENTB2B-Report.ps1 — guest-lifecycle report: guests by last sign-in, never-signed-in, and inactive.
.DESCRIPTION
    PURPOSE
        Produces a guest-lifecycle report for governance and cleanup planning: every guest (#EXT#) user
        with account state, creation date, last sign-in, and an "inactive days" bucket, plus a summary of
        never-signed-in and long-inactive guests. Optionally writes a CSV. Read-only — it changes nothing;
        it only tells you which guests are cleanup candidates for ENTB2B-CleanupStaleGuests.ps1.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTB2B-Report.ps1 -InactiveDays 90 -CsvPath .\entb2b-guest-report.csv
        Connects to Microsoft Graph with read-only scopes: User.Read.All, AuditLog.Read.All (signInActivity).
    EXPECTED RESULTS
        A per-guest table and summary counts (total / never signed in / inactive > N days), and an optional
        CSV. signInActivity requires Entra ID P1+ and AuditLog.Read.All. Read-only.
.NOTES
    White-label. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [int]$InactiveDays = 90,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'User.Read.All','AuditLog.Read.All' -NoWelcome

Write-Host "`n=== ENTB2B — guest-lifecycle report (inactive threshold: $InactiveDays days) ===" -ForegroundColor Cyan

$guests = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userType eq 'Guest'&`$select=id,displayName,userPrincipalName,mail,accountEnabled,createdDateTime,externalUserState,signInActivity&`$top=999").value)
$now = Get-Date
$rows = foreach ($g in $guests) {
    $last = $g.signInActivity.lastSignInDateTime
    $days = if ($last) { [int]((New-TimeSpan -Start ([datetime]$last) -End $now).TotalDays) } else { $null }
    $bucket = if (-not $last) { 'NeverSignedIn' } elseif ($days -ge $InactiveDays) { "Inactive>=$InactiveDays" } else { 'Active' }
    [pscustomobject]@{
        DisplayName    = $g.displayName
        UserPrincipal  = $g.userPrincipalName
        Mail           = $g.mail
        Enabled        = $g.accountEnabled
        InviteState    = $g.externalUserState
        Created        = $g.createdDateTime
        LastSignIn     = $last
        InactiveDays   = $days
        Bucket         = $bucket
    }
}

$rows | Sort-Object Bucket, InactiveDays -Descending | Format-Table DisplayName, UserPrincipal, Enabled, InviteState, LastSignIn, InactiveDays, Bucket -AutoSize

$never    = @($rows | Where-Object Bucket -eq 'NeverSignedIn')
$inactive = @($rows | Where-Object Bucket -like 'Inactive*')
Write-Host ("`nTotal guests        : {0}" -f $rows.Count) -ForegroundColor Yellow
Write-Host ("Never signed in     : {0}" -f $never.Count)    -ForegroundColor ($(if($never.Count){'Yellow'}else{'Green'}))
Write-Host ("Inactive >= $InactiveDays days : {0}" -f $inactive.Count) -ForegroundColor ($(if($inactive.Count){'Yellow'}else{'Green'}))
Write-Host "These are cleanup CANDIDATES — review before running ENTB2B-CleanupStaleGuests.ps1 (which defaults to -WhatIf)." -ForegroundColor Cyan

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "CSV written: $CsvPath" -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
