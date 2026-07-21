<#
.SYNOPSIS
    ENDPTREL-Set-ReviewScope.ps1 — create/assign the 'Reliability – Review Scope' group for the cadence.

.DESCRIPTION
    PURPOSE
        Stands up the ongoing review population for the reliability review cadence: an Entra security
        group named 'Reliability – Review Scope'. This is the ONLY state-changing script in this
        solution, and it DEFAULTS TO -WhatIf (preview only) — it will NOT create or modify anything
        until you explicitly re-run with -Commit (or -WhatIf:$false). By default it creates an ASSIGNED
        security group (you add the in-scope devices), aligned with the population Endpoint Analytics is
        collecting. Optionally, with -Dynamic, it creates a dynamic device group from a rule you supply.
        Idempotent — if the group already exists it reports and does nothing.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTREL-Set-ReviewScope.ps1                       # PREVIEW ONLY (-WhatIf default) — no change
        .\ENDPTREL-Set-ReviewScope.ps1 -Commit               # actually create/assign the group
        .\ENDPTREL-Set-ReviewScope.ps1 -Dynamic -MembershipRule '(device.deviceOSType -eq "Windows")' -Commit

    GRAPH SCOPES
        Group.ReadWrite.All (required to create the group). Reading uses the same connection.

    EXPECTED RESULTS
        In default (-WhatIf) mode: a printed preview of exactly what WOULD be created, and NO change.
        With -Commit: the 'Reliability – Review Scope' group exists in Entra, ready to be aligned with
        your Endpoint Analytics data-collection scope and used by the review cadence.

.NOTES
    White-label — Intune Solutions. STATE-CHANGING — defaults to -WhatIf (safe). Re-run with -Commit to apply.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$GroupName = 'Reliability – Review Scope',
    [string]$MailNickname = 'reliability-review-scope',
    [switch]$Dynamic,
    [string]$MembershipRule = '(device.deviceOSType -eq "Windows")',
    # Convenience switch: -Commit is the plain-language way to turn off the default -WhatIf preview.
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'

# Default posture is PREVIEW: unless the caller passed -Commit (or their own -WhatIf:$false / -Confirm),
# force WhatIfPreference on so nothing is changed by an unqualified run.
if (-not $Commit -and -not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
    Write-Host 'PREVIEW MODE (-WhatIf default): no changes will be made. Re-run with -Commit to apply.' -ForegroundColor Yellow
}

Connect-MgGraph -Scopes 'Group.ReadWrite.All' | Out-Null

# Idempotent: already exists?
$existing = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName.Replace("'","''"))).value
if ($existing) {
    Write-Host "Group '$GroupName' already exists (id $($existing[0].id)) — nothing to do." -ForegroundColor Yellow
    Write-Host 'Align its membership with your Endpoint Analytics data-collection scope, then use it for the review cadence.'
    return
}

$body = @{
    displayName     = $GroupName
    description     = 'Ongoing review population for the Endpoint Analytics reliability review cadence (ENDPTREL solution).'
    mailEnabled     = $false
    mailNickname    = $MailNickname
    securityEnabled = $true
}
if ($Dynamic) {
    $body.groupTypes                    = @('DynamicMembership')
    $body.membershipRule                = $MembershipRule
    $body.membershipRuleProcessingState = 'On'
    $target = "dynamic device group with rule: $MembershipRule"
} else {
    $body.groupTypes = @()
    $target = 'assigned security group (add in-scope devices manually)'
}

if ($PSCmdlet.ShouldProcess($GroupName, "Create $target")) {
    $new = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host "Created '$GroupName' (id $($new.id)) — $target." -ForegroundColor Green
    Write-Host 'Next: align its membership with your Endpoint Analytics data-collection scope and run the reliability review against it.'
} else {
    Write-Host "[WhatIf] Would create '$GroupName' as $target." -ForegroundColor Cyan
    Write-Host 'No change made. Re-run with -Commit to create the group.'
}
