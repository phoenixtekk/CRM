<#
.SYNOPSIS
    MACLOCK-Remediation.ps1 — safe remediation of Mac-originated lockout/spray sources (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Works the Mac-originated failure findings from MACLOCK-Discovery.ps1 and produces the safe,
        well-understood remediation actions that reduce them. Two kinds of action: (1) tenant-side
        scoping actions this script can perform via Microsoft Graph (e.g. add an affected user to the
        Mac pilot scope so the MFA policy applies) and (2) endpoint actions on the Mac that are
        reported as MANUAL with exact steps (clear stale keychain items, re-enter the current password
        in Mail/Wi-Fi, resolve SecureToken / local-account divergence). SAFE BY DEFAULT: runs in
        -WhatIf and only reports what it WOULD do; pass -Apply to make the supported changes. It never
        silently rewrites a user's keychain or SecureToken. Use 'your-tenant-id' style values, not
        bracketed placeholders.
    HOW TO RUN
        Preview (default, no changes):  powershell -ExecutionPolicy Bypass -File .\MACLOCK-Remediation.ps1
        Apply after review:             ... .\MACLOCK-Remediation.ps1 -Apply
        With your findings file:        ... .\MACLOCK-Remediation.ps1 -FindingsPath .\maclock-findings.json -Apply
        Requires the Microsoft Graph PowerShell SDK and consent to Group.ReadWrite.All (for the pilot
        scoping action) — granted on connect.
    EXPECTED RESULTS
        In preview mode: a list of the tenant-side scoping changes that WOULD be made and the MANUAL
        Mac-side steps to perform, with nothing altered. In -Apply mode: the same list, with each
        supported scoping change applied and confirmed. MANUAL steps are always reported, never
        attempted.
.NOTES
    White-label — the repeatable way. SAFE BY DEFAULT (-WhatIf). Never blind-apply an
    authentication-impacting change; review the preview, confirm the change-control ticket and
    rollback, then -Apply. Endpoint keychain / SecureToken fixes are performed on the Mac per the
    Implementation Guide, not remotely by this script.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$FindingsPath,
    [string]$PilotGroupName = 'MACLOCK Scope - Pilot - Macs',
    [switch]$Apply
)

# Safe by default: without -Apply (and without explicit -WhatIf), force WhatIf on.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Load findings (from Discovery) or a representative sample.
if ($FindingsPath -and (Test-Path $FindingsPath)) {
    $findings = Get-Content -Raw -Path $FindingsPath | ConvertFrom-Json
} else {
    Write-Host "No -FindingsPath supplied; using the bundled sample findings." -ForegroundColor Yellow
    $findings = @(
        [pscustomobject]@{ user = 'user1@your-domain'; action = 'add-to-pilot'; note = 'Mac re-submitting old password via Mail profile' },
        [pscustomobject]@{ user = 'user2@your-domain'; action = 'manual-keychain'; note = 'Clear stale Wi-Fi/802.1X keychain item, re-enter current password' },
        [pscustomobject]@{ user = 'user3@your-domain'; action = 'manual-securetoken'; note = 'Re-align local account password + SecureToken with current Entra password' }
    )
}

Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

function Get-GroupByName([string]$name) {
    $escaped = $name.Replace("'","''")
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escaped'").value } catch { @() }
}
function Get-UserByUpn([string]$upn) {
    $escaped = $upn.Replace("'","''")
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userPrincipalName eq '$escaped'").value } catch { @() }
}

Write-Host "`n=== MACLOCK remediation ===" -ForegroundColor Cyan
if ($WhatIfPreference) {
    Write-Host "PREVIEW MODE (-WhatIf): no changes will be made. Re-run with -Apply after review." -ForegroundColor Yellow
}

$pilot = Get-GroupByName $PilotGroupName
if (-not $pilot) {
    Write-Host ("  Pilot group '{0}' not found. Run MACLOCK-Set-ScopeTargeting.ps1 -Apply first." -f $PilotGroupName) -ForegroundColor Yellow
}

foreach ($f in $findings) {
    switch ($f.action) {
        'add-to-pilot' {
            if (-not $pilot) { Write-Host ("  SKIP  add-to-pilot {0} (no pilot group)" -f $f.user) -ForegroundColor DarkGray; break }
            $u = Get-UserByUpn $f.user
            if (-not $u) { Write-Host ("  SKIP  user not found: {0}" -f $f.user) -ForegroundColor DarkGray; break }
            if ($PSCmdlet.ShouldProcess($f.user, "Add to '$PilotGroupName' so the MFA policy applies")) {
                try {
                    $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u[0].id)" }
                    Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($pilot[0].id)/members/`$ref" -Body ($body | ConvertTo-Json)
                    Write-Host ("  APPLIED  added {0} to {1}" -f $f.user, $PilotGroupName) -ForegroundColor Green
                } catch {
                    Write-Host ("  NOTE     {0} may already be a member: {1}" -f $f.user, $_.Exception.Message) -ForegroundColor DarkGray
                }
            } else {
                Write-Host ("  WOULD APPLY  add {0} to {1}" -f $f.user, $PilotGroupName) -ForegroundColor DarkGray
            }
        }
        'manual-keychain' {
            Write-Host ("  MANUAL  {0}  — on the Mac: clear the stale keychain item and re-enter the current password" -f $f.user) -ForegroundColor Yellow
            Write-Host ("          {0}" -f $f.note)
            Write-Host "          Keychain Access > delete the stale login/Wi-Fi/mail item; re-enter the current Entra password in Mail / Wi-Fi."
        }
        'manual-securetoken' {
            Write-Host ("  MANUAL  {0}  — on the Mac: resolve SecureToken / local-account divergence" -f $f.user) -ForegroundColor Yellow
            Write-Host ("          {0}" -f $f.note)
            Write-Host "          Re-align the local account password + SecureToken with the current Entra password (per your Mac admin runbook), then re-populate keychain items."
        }
        default {
            Write-Host ("  UNKNOWN action '{0}' for {1} — review manually." -f $f.action, $f.user) -ForegroundColor DarkGray
        }
    }
}

Write-Host "`nRe-run MACLOCK-Validation.ps1 to confirm the reduction, then MACLOCK-Report.ps1 to capture before/after evidence." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
