<#
.SYNOPSIS
    ENTIGA-GuestReview.ps1 — report guest accounts + stale-access preview (read-only / -WhatIf).
.DESCRIPTION
    PURPOSE
        Sizes and governs guest (external) access. Lists every guest with creation date, last
        interactive sign-in, and pending-acceptance state, and flags guests idle beyond a threshold as
        stale-access candidates to feed into 'ENTIGA - Review - AllGuests - Quarterly'. By default it
        only REPORTS. With -Commit it would disable stale guests; -WhatIf (the default when -Commit is
        set without confirmation) previews exactly which accounts would be affected — nothing is changed
        without an explicit -Commit.
    HOW TO RUN
        Report only:   .\ENTIGA-GuestReview.ps1 -StaleDays 90 -CsvPath C:\Temp\guests.csv
        Preview change:.\ENTIGA-GuestReview.ps1 -StaleDays 90 -Commit -WhatIf
        Apply (gated): .\ENTIGA-GuestReview.ps1 -StaleDays 90 -Commit        # disables stale guests
    EXPECTED RESULTS
        A guest inventory table + a stale-guest list. PASS = no unexpected/idle guests linger.
.NOTES
    White-label — Entra ID Solutions. Read-only by default; any change is gated behind -Commit with a
    -WhatIf preview. No credentials stored. Disabling (not deleting) is used so it is reversible.
.EXAMPLE
    .\ENTIGA-GuestReview.ps1 -StaleDays 60
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [int]$StaleDays = 90,
    [string]$CsvPath,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# User.Read.All for inventory; write scope only needed if you actually -Commit a disable.
$scopes = @('User.Read.All','AuditLog.Read.All')
if ($Commit) { $scopes += 'User.ReadWrite.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

function Get-AllPages([string]$Uri) {
    $items=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $items+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $items
}

$cutoff = (Get-Date).AddDays(-$StaleDays)
Write-Host "`n=== Guest inventory (stale threshold: $StaleDays days) ===" -ForegroundColor Cyan
$guests = Get-AllPages "/v1.0/users?`$filter=userType eq 'Guest'&`$select=id,displayName,userPrincipalName,mail,accountEnabled,createdDateTime,externalUserState,signInActivity&`$top=200"

$rows = foreach ($g in $guests) {
    $last = $g.signInActivity.lastSignInDateTime
    $lastDt = if ($last) { [datetime]$last } else { $null }
    $stale = (-not $lastDt) -or ($lastDt -lt $cutoff)
    [pscustomobject]@{
        Guest        = $g.displayName
        Upn          = $g.userPrincipalName
        Enabled      = $g.accountEnabled
        InviteState  = $g.externalUserState
        CreatedUtc   = $g.createdDateTime
        LastSignIn   = $last
        Stale        = $stale
        Id           = $g.id
    }
}
$rows | Sort-Object Stale -Descending | Format-Table Guest,Upn,Enabled,InviteState,LastSignIn,Stale -AutoSize
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }

$staleGuests = $rows | Where-Object { $_.Stale -and $_.Enabled }
Write-Host ("`n{0} guests total | {1} stale/idle > {2} days and still enabled" -f $rows.Count, $staleGuests.Count, $StaleDays) -ForegroundColor Yellow

if (-not $Commit) {
    Write-Host "`nReport-only mode. Feed the stale list into 'ENTIGA - Review - AllGuests - Quarterly'," -ForegroundColor Cyan
    Write-Host "or re-run with -Commit -WhatIf to preview disabling the stale guests." -ForegroundColor Cyan
} else {
    Write-Host "`n-Commit set: would disable the following stale guests (reversible). Use -WhatIf to preview only." -ForegroundColor Magenta
    foreach ($s in $staleGuests) {
        if ($PSCmdlet.ShouldProcess($s.Upn, "Disable stale guest account (set accountEnabled=false)")) {
            Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/users/$($s.Id)" -Body @{ accountEnabled = $false } | Out-Null
            Write-Host "  disabled $($s.Upn)" -ForegroundColor Green
        }
    }
}
Disconnect-MgGraph | Out-Null
