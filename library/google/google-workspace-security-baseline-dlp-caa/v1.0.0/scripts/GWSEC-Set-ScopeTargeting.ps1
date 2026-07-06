<#
.SYNOPSIS
    GWSEC-Set-ScopeTargeting.ps1 — create the security-baseline pilot OU (idempotent, default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Google Workspace organizational unit used to scope the controlled
        security-posture rollout, following the solution naming convention so the hardening baseline,
        DLP rules, and Context-Aware Access assignments can be targeted and rolled back consistently:
            Security Baseline - Pilot
        An existing OU (matched by path) is reused, not duplicated. Users are NOT moved — move a few
        representative pilot users (a super-admin test account, a power user, a field/mobile user) into
        the OU by hand. Then scope 2SV, session control, sharing, DLP, and CAA to this OU in the Admin
        console per the Implementation Guide.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\GWSEC-Set-ScopeTargeting.ps1
        Apply:                  powershell -ExecutionPolicy Bypass -File .\GWSEC-Set-ScopeTargeting.ps1 -Apply
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with the scope
        admin.directory.orgunit (create/read organizational units). Optional -ParentOrgUnitPath sets the
        parent (default '/').
    EXPECTED RESULTS
        The pilot OU 'Security Baseline - Pilot' exists (created if missing, reused if present), with its
        path printed for use when scoping baseline/DLP/CAA settings in the Admin console. Nothing is
        changed unless -Apply is passed.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf); pass -Apply to create the OU. The OU
    name uses ASCII hyphens; keep it verbatim across scripts and Admin-console targeting so validation,
    reporting, and rollback stay consistent.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$OrgUnitName = 'Security Baseline - Pilot',
    [string]$ParentOrgUnitPath = '/',
    [switch]$Apply
)

if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the admin.directory.orgunit scope." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

$targetPath = ($ParentOrgUnitPath.TrimEnd('/') + '/' + $OrgUnitName)

Write-Host "`n=== Security-baseline pilot OU ===" -ForegroundColor Cyan

# Reuse if present
$existing = $null
try {
    $enc = ($targetPath.TrimStart('/'))
    $existing = Invoke-RestMethod -Method GET -Headers $headers -ErrorAction Stop `
        -Uri ("https://admin.googleapis.com/admin/directory/v1/customer/my_customer/orgunits/{0}" -f [uri]::EscapeDataString($enc))
} catch { $existing = $null }

if ($existing -and $existing.orgUnitPath) {
    Write-Host ("  EXISTS: {0}  (path {1})" -f $OrgUnitName, $existing.orgUnitPath) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($OrgUnitName, "Create organizational unit under $ParentOrgUnitPath")) {
        $body = @{
            name              = $OrgUnitName
            parentOrgUnitPath = $ParentOrgUnitPath
            description       = "Pilot scope for the Google Workspace security baseline / DLP / Context-Aware Access rollout."
        } | ConvertTo-Json
        try {
            $created = Invoke-RestMethod -Method POST -Headers $headers -Body $body -ErrorAction Stop `
                -Uri "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/orgunits"
            Write-Host ("  CREATED: {0}  (path {1})" -f $OrgUnitName, $created.orgUnitPath) -ForegroundColor Green
        } catch {
            Write-Host ("  Failed to create {0}: {1}" -f $OrgUnitName, $_.Exception.Message) -ForegroundColor Red
        }
    } else {
        Write-Host ("  WHATIF: would create OU {0} under {1}" -f $OrgUnitName, $ParentOrgUnitPath) -ForegroundColor Yellow
    }
}

Write-Host "`nMove a few representative pilot users into this OU, then scope 2SV, session control, sharing," -ForegroundColor Yellow
Write-Host "DLP rules, and CAA assignments to it in the Admin console (Implementation Steps 2-6; DLP/CAA are edition-gated — verify in your tenant)." -ForegroundColor Yellow
