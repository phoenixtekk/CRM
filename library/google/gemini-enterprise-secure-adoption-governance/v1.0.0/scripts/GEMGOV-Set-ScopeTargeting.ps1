<#
.SYNOPSIS
    GEMGOV-Set-ScopeTargeting.ps1 — create the Gemini Enterprise pilot scope group (idempotent, default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Google Workspace group used to scope the controlled Gemini Enterprise
        rollout, following the solution naming convention so Gemini enablement and the data-access
        boundary can be targeted consistently:
            Gemini Adoption - Pilot Users - Pilot
        An existing group (matched by email) is reused, not duplicated. Members are NOT added — add a few
        representative pilot users by hand per your standard. In the Admin console, target Gemini service
        status and the 'Allow Gemini Enterprise to access Google Workspace data' setting at this group
        (or the pilot OU) so scope stays bounded and is easy to roll back.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\GEMGOV-Set-ScopeTargeting.ps1 -GroupEmail gemini-pilot@your-domain
        Apply:                  ... .\GEMGOV-Set-ScopeTargeting.ps1 -GroupEmail gemini-pilot@your-domain -Apply
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with the scope
        admin.directory.group (create/read groups).
    EXPECTED RESULTS
        The pilot scope group exists (created if missing, reused if present), with its email/id printed for
        use in Gemini service-status and data-access targeting in the Admin console.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf); pass -Apply to create the group. The
    display name uses ASCII hyphens; keep it verbatim across scripts and Admin-console targeting. Gemini
    Enterprise service/data-access toggles are set in the Admin console (verify in your tenant).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)][string]$GroupEmail,
    [switch]$Apply
)

if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the admin.directory.group scope." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

$displayName = 'Gemini Adoption - Pilot Users - Pilot'

Write-Host "`n=== Gemini Enterprise pilot scope group ===" -ForegroundColor Cyan

# Reuse if present
$existing = $null
try {
    $existing = Invoke-RestMethod -Method GET -Headers $headers -ErrorAction Stop `
        -Uri ("https://admin.googleapis.com/admin/directory/v1/groups/{0}" -f [uri]::EscapeDataString($GroupEmail))
} catch { $existing = $null }

if ($existing -and $existing.email) {
    Write-Host ("  EXISTS: {0}  ({1}, id {2})" -f $displayName, $existing.email, $existing.id) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($displayName, "Create Google Workspace group ($GroupEmail)")) {
        $body = @{
            email       = $GroupEmail
            name        = $displayName
            description = "Scope group for the Gemini Enterprise secure-adoption pilot ($displayName)."
        } | ConvertTo-Json
        try {
            $created = Invoke-RestMethod -Method POST -Headers $headers -Body $body -ErrorAction Stop `
                -Uri "https://admin.googleapis.com/admin/directory/v1/groups"
            Write-Host ("  CREATED: {0}  ({1}, id {2})" -f $displayName, $created.email, $created.id) -ForegroundColor Green
        } catch {
            Write-Host ("  Failed to create {0}: {1}" -f $GroupEmail, $_.Exception.Message) -ForegroundColor Red
        }
    } else {
        Write-Host ("  WHATIF: would create group {0} ({1})" -f $displayName, $GroupEmail) -ForegroundColor Yellow
    }
}

Write-Host "`nAdd a few representative pilot users, then target Gemini service status + the data-access" -ForegroundColor Yellow
Write-Host "setting at this group (or the pilot OU) in the Admin console (Implementation Steps 4-7; verify in your tenant)." -ForegroundColor Yellow
