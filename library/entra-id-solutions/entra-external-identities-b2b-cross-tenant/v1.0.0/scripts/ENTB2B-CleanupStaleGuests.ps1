<#
.SYNOPSIS
    ENTB2B-CleanupStaleGuests.ps1 — safely disable (then remove) stale guest accounts (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Reduces guest sprawl by acting on stale guests: guests who have NEVER signed in or have been
        inactive longer than a threshold. This is a CHANGE script — it runs in -WhatIf (preview) mode BY
        DEFAULT and only writes when you pass -WhatIf:$false. The default action is DISABLE (accountEnabled
        = false), the reversible first step; pass -Delete to remove (still gated by -WhatIf). It ALWAYS
        skips accounts on the -ExcludeUpns list (put break-glass and any internal/service accounts there),
        and it only ever targets userType = Guest. Deletion is destructive; disable-before-delete is the
        recommended path and the customer owns the retention/records decision.
    HOW TO RUN
        Preview disable (default): powershell -ExecutionPolicy Bypass -File .\ENTB2B-CleanupStaleGuests.ps1 `
                                       -InactiveDays 180 -IncludeNeverSignedIn `
                                       -ExcludeUpns "bg1@contoso.onmicrosoft.com","bg2@contoso.onmicrosoft.com"
        Apply disable:             add -WhatIf:$false to the same command.
        Apply delete (destructive): add -Delete -WhatIf:$false (review the preview first).
        Connects to Microsoft Graph with change scope: User.ReadWrite.All (+ AuditLog.Read.All for signInActivity).
    EXPECTED RESULTS
        In preview: the exact guests that WOULD be disabled/deleted, with reason. On apply: those guests are
        disabled (or deleted). Excluded UPNs and non-guests are never touched. Re-run ENTB2B-Report.ps1 after.
.NOTES
    White-label. Change script — default -WhatIf, disable-before-delete, excludes break-glass. Guests only.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [int]$InactiveDays = 180,
    [switch]$IncludeNeverSignedIn,
    [switch]$Delete,
    [string[]]$ExcludeUpns = @()
)
# Default to preview unless the caller explicitly turns -WhatIf off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'User.ReadWrite.All','AuditLog.Read.All' -NoWelcome

$action = if ($Delete) { 'DELETE' } else { 'DISABLE' }
Write-Host "`n=== ENTB2B — stale guest cleanup ($action; inactive >= $InactiveDays days; never-signed-in included: $IncludeNeverSignedIn) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "MODE: PREVIEW (-WhatIf). No changes will be written. Add -WhatIf:`$false to apply." -ForegroundColor Yellow }
if ($Delete) { Write-Host "WARNING: -Delete is destructive. Disable-before-delete is recommended; the customer owns the retention decision." -ForegroundColor Red }

$now = Get-Date
$guests = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userType eq 'Guest'&`$select=id,displayName,userPrincipalName,accountEnabled,signInActivity&`$top=999").value)

$targets = foreach ($g in $guests) {
    if ($ExcludeUpns -contains $g.userPrincipalName) { Write-Host "  SKIP excluded: $($g.userPrincipalName)" -ForegroundColor Cyan; continue }
    $last = $g.signInActivity.lastSignInDateTime
    $reason = $null
    if (-not $last) { if ($IncludeNeverSignedIn) { $reason = 'NeverSignedIn' } }
    else { $days = [int]((New-TimeSpan -Start ([datetime]$last) -End $now).TotalDays); if ($days -ge $InactiveDays) { $reason = "Inactive $days days" } }
    if ($reason) { [pscustomobject]@{ Id=$g.id; Upn=$g.userPrincipalName; Enabled=$g.accountEnabled; Reason=$reason } }
}

if (-not $targets) { Write-Host "`nNo stale guests matched the criteria." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

Write-Host ("`n{0} stale guest(s) matched:" -f @($targets).Count) -ForegroundColor Yellow
foreach ($t in $targets) {
    $desc = "$action stale guest $($t.Upn) [$($t.Reason)]"
    if ($PSCmdlet.ShouldProcess($t.Upn, $desc)) {
        if ($Delete) { Invoke-MgGraphRequest -Method DELETE -Uri "/v1.0/users/$($t.Id)" | Out-Null; Write-Host "  DELETED $($t.Upn)" -ForegroundColor Green }
        else         { Invoke-MgGraphRequest -Method PATCH  -Uri "/v1.0/users/$($t.Id)" -Body (@{ accountEnabled = $false } | ConvertTo-Json) | Out-Null; Write-Host "  DISABLED $($t.Upn)" -ForegroundColor Green }
    } else {
        Write-Host "  WHATIF would $action $($t.Upn) [$($t.Reason)]" -ForegroundColor Yellow
    }
}

Write-Host "`nRe-run ENTB2B-Report.ps1 to confirm." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
