<#
.SYNOPSIS
    GWREG-Set-ScopeTargeting.ps1 — create/grow the controlled-data pilot OU/group targeting (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Stages the controlled-data SCOPE that every control in this solution targets: creates (or previews)
        a controlled-data organizational unit and/or a targeting group (e.g. 'Regulated Workspace -
        Controlled Data - Pilot') and optionally adds representative members, so residency, Access
        Management, Access Approvals, and CSE are applied consistently and can be expanded verbatim. It
        DEFAULTS TO -WhatIf and only PREVIEWS; membership/scope changes apply only with -Execute.
    HOW TO RUN
        Preview (default, safe):
          powershell -ExecutionPolicy Bypass -File .\GWREG-Set-ScopeTargeting.ps1 -CustomerId your-customer-id `
            -GroupEmail controlled-data-pilot@your-domain -Members alice@your-domain,bob@your-domain
        Apply (only in the approved change window):
          ... same parameters ... -Execute
        Requires a super-admin OAuth token in GOOGLE_OAUTH_TOKEN with admin.directory.group and
        admin.directory.group.member scopes (and orgunit scope if creating an OU). Nothing changes in -WhatIf.
    EXPECTED RESULTS
        In -WhatIf (default): the group/OU and members that WOULD be created/added, and no change. With
        -Execute: the group is created if absent and members are added, each with a pass/fail line. Use the
        resulting scope in GWREG-Validation.ps1 / GWREG-Report.ps1 and as the target for the controls.
.NOTES
    White-label — the repeatable way. Default -WhatIf; writes only with -Execute in an approved window.
    Creates targeting scope only - it applies NO compliance policy itself (that is the guide's steps).
    Uses the Google Directory API; least-privilege scopes; never invents Assured Controls specifics.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CustomerId,
    [Parameter(Mandatory=$true)][string]$GroupEmail,
    [string]$GroupName = 'Regulated Workspace - Controlled Data - Pilot',
    [string[]]$Members = @(),
    [switch]$Execute
)

$WhatIf = -not $Execute
$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-GApi([string]$method, [string]$uri, $body) {
    try {
        if ($body) { Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -Body ($body | ConvertTo-Json) -ErrorAction Stop }
        else { Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -ErrorAction Stop }
    } catch { Write-Host ("  API error: {0}" -f $_.Exception.Message) -ForegroundColor Red; $null }
}

Write-Host "`n=== Controlled-data scope targeting: $GroupEmail ===" -ForegroundColor Cyan
if ($WhatIf) { Write-Host "MODE: -WhatIf (PREVIEW ONLY - no changes). Pass -Execute in an approved window to apply.`n" -ForegroundColor Yellow }
else { Write-Host "MODE: -Execute (LIVE CHANGES). Ensure change approval is in place.`n" -ForegroundColor Red }

# --- Group presence ---
$existing = Invoke-GApi 'GET' ("https://admin.googleapis.com/admin/directory/v1/groups/{0}" -f [uri]::EscapeDataString($GroupEmail)) $null

if ($existing) {
    Write-Host ("  Group exists: {0} ({1})" -f $existing.name, $existing.email) -ForegroundColor Green
} else {
    if ($WhatIf) {
        Write-Host ("  WHATIF Create group '{0}' <{1}> in customer '{2}'." -f $GroupName, $GroupEmail, $CustomerId) -ForegroundColor Yellow
    } else {
        $body = @{ email = $GroupEmail; name = $GroupName; description = 'Controlled-data scope for regulated Workspace controls (Assured Controls, data regions).' }
        $new = Invoke-GApi 'POST' 'https://admin.googleapis.com/admin/directory/v1/groups' $body
        if ($new) { Write-Host ("  Created group {0}" -f $new.email) -ForegroundColor Green }
    }
}

# --- Members ---
if ($Members.Count) {
    Write-Host "`n  Members:" -ForegroundColor Cyan
    foreach ($m in $Members) {
        if ($WhatIf) {
            Write-Host ("    WHATIF Add member '{0}' to {1}." -f $m, $GroupEmail) -ForegroundColor Yellow
        } else {
            $mb = @{ email = $m; role = 'MEMBER' }
            $res = Invoke-GApi 'POST' ("https://admin.googleapis.com/admin/directory/v1/groups/{0}/members" -f [uri]::EscapeDataString($GroupEmail)) $mb
            if ($res) { Write-Host ("    Added {0}" -f $m) -ForegroundColor Green }
        }
    }
} else {
    Write-Host "`n  No members specified (pass -Members for representative pilot users)." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "This script sets TARGETING SCOPE only - it applies NO compliance policy." -ForegroundColor DarkYellow
Write-Host "Next: apply the controls to this scope (Implementation Steps 1-5), then GWREG-Validation.ps1 / GWREG-Report.ps1." -ForegroundColor Yellow
if ($WhatIf) { Write-Host "No changes made. Review, then re-run with -Execute in the approved window." -ForegroundColor Yellow }
