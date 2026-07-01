<#
.SYNOPSIS
    NSCASB-Remediation.ps1 — safe remediation of CASB scoping/coverage gaps (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Detects and (with -Execute) fixes the safe, identity-side gaps this package can act on:
        a missing CASB scope group in Entra ID. It REPORTS — but never auto-changes — Netskope policy
        objects (those changes are deferred to the Netskope console/REST per the official docs). By
        default it only previews the action it would take.
    HOW TO RUN
        Preview (no changes):  powershell -ExecutionPolicy Bypass -File .\NSCASB-Remediation.ps1 -WhatIf
        Apply identity fixes:  powershell -ExecutionPolicy Bypass -File .\NSCASB-Remediation.ps1 -Execute
        Requires the Microsoft Graph PowerShell SDK and Group.ReadWrite.All (for -Execute).
    EXPECTED RESULTS
        A list of detected gaps and, in -WhatIf mode, the exact change that would be made. With
        -Execute, a missing scope group is created. Netskope policy gaps are reported only.
.NOTES
    Network / CASB. Identity changes are gated behind -Execute; Netskope changes deferred to vendor docs.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $Execute,
    [switch] $WhatIf,
    [string[]] $ScopeGroup = @('CASB Pilot - Pilot users - Pilot','CASB Broad - All users - Expand')
)

# Default posture is preview-only unless -Execute is explicitly passed.
$apply = $Execute.IsPresent -and -not $WhatIf.IsPresent

Write-Host "`n=== NSCASB Remediation ($(if($apply){'EXECUTE'}else{'WHATIF / preview'})) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($apply) { @('Group.ReadWrite.All') } else { @('Group.Read.All') }
Connect-MgGraph -Scopes $scopes -NoWelcome

# --- Gap: missing CASB scope group (safe to remediate on the identity side) ---
Write-Host "`n[Scope-group coverage]" -ForegroundColor Cyan
foreach ($g in $ScopeGroup) {
    $f = "displayName eq '$($g.Replace("'","''"))'"
    $found = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value
    if ($found) {
        Write-Host ("  OK   {0} exists." -f $g) -ForegroundColor Green
        continue
    }
    if ($apply) {
        if ($PSCmdlet.ShouldProcess($g, "Create Entra security group")) {
            $body = @{
                displayName     = $g
                mailEnabled     = $false
                mailNickname    = ($g -replace '[^a-zA-Z0-9]','')
                securityEnabled = $true
            }
            try {
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body ($body | ConvertTo-Json) | Out-Null
                Write-Host ("  FIXED created group {0}" -f $g) -ForegroundColor Green
            } catch {
                Write-Host ("  ERR  could not create {0}: {1}" -f $g, $_.Exception.Message) -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host ("  WOULD create missing scope group: {0}" -f $g) -ForegroundColor Yellow
    }
}

# --- Netskope policy gaps (REPORT ONLY — deferred) ---
Write-Host "`n[Netskope policy gaps — REPORT ONLY / DEFERRED]" -ForegroundColor DarkYellow
Write-Host "  This script does NOT auto-edit Netskope policy. Review and fix in the Netskope console" -ForegroundColor DarkYellow
Write-Host "  (or REST API per the official Netskope docs) when validation flags any of:" -ForegroundColor DarkYellow
Write-Host "   - a sanctioned app with no Sanctioned apps policy - In-scope apps - Configure" -ForegroundColor DarkYellow
Write-Host "   - a high-risk unsanctioned app with no control on the Unsanctioned apps policy" -ForegroundColor DarkYellow
Write-Host "   - an unhealthy API connection (API connections - Sanctioned apps - Configure)" -ForegroundColor DarkYellow
Write-Host "   - a policy still scoped to the broad group before the pilot pass gate" -ForegroundColor DarkYellow

if (-not $apply) { Write-Host "`nPreview only — re-run with -Execute to apply identity-side fixes." -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
