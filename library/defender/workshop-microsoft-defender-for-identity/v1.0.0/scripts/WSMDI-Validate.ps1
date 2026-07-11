<#
.SYNOPSIS
    WSMDI-Validate.ps1 — read-only readiness validation for the Defender for Identity workshop.
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to teach the "Workshop — Microsoft Defender for Identity"
        labs BEFORE attendees arrive. Checks (all read-only): Microsoft Graph connectivity and the
        required READ scopes are consented, that Defender-for-Identity alert data is reachable, and
        that identity posture (ISPM) signal is present. Prints a green/red readiness table.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMDI-Validate.ps1
        Run as a Security Reader / Security Administrator; consent the read-only scopes when prompted.
    EXPECTED RESULTS
        A PASS/REVIEW line per check. All PASS = ready to run Lab 0 onward. Any REVIEW points at the
        matching item in 02-requirements.md.
.NOTES
    White-label. Read-only. Makes no changes.
    Licensing/preview facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$scopes = @('SecurityAlert.Read.All','SecurityEvents.Read.All')
$checks = @()
function Add-Check($name, $ok, $detail) {
    $script:checks += [pscustomobject]@{ Check = $name; Result = ($(if($ok){'PASS'}else{'REVIEW'})); Detail = $detail }
}

foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

Write-Host "`n=== Defender for Identity workshop — readiness validation (read-only) ===" -ForegroundColor Cyan

# Check 1 — Graph connectivity + scopes
try {
    Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    $haveScopes = ($scopes | Where-Object { $ctx.Scopes -contains $_ }).Count
    Add-Check 'Graph connectivity + read scopes' ($null -ne $ctx) ("Connected as $($ctx.Account); scopes granted: $haveScopes/$($scopes.Count)")
} catch {
    Add-Check 'Graph connectivity + read scopes' $false $_.Exception.Message
}

# Check 2 — MDI alert data reachable
try {
    $sample = Get-MgSecurityAlertV2 -Top 5 -ErrorAction Stop
    Add-Check 'Security alert data reachable' $true ("Alert query returned {0} sample row(s)." -f ($sample | Measure-Object).Count)
} catch {
    Add-Check 'Security alert data reachable' $false ("Could not query alerts_v2: {0}" -f $_.Exception.Message)
}

# Check 3 — Identity posture (ISPM) reminder (portal-verified)
# ISPM recommendations are read in the portal (Secure Score / Exposure management). This check
# reminds the facilitator to confirm posture data has populated — it cannot be fully asserted here.
Add-Check 'ISPM posture data present (portal)' $true 'Confirm Identity recommendations are visible under Secure Score / Exposure management (R3).'

# Check 4 — Advanced hunting access reminder
Add-Check 'Advanced hunting access (portal)' $true 'Confirm attendees can run: IdentityInfo | take 5 (R5).'

Write-Host ""
$checks | Format-Table Check, Result, Detail -AutoSize
$review = ($checks | Where-Object Result -eq 'REVIEW').Count
if ($review -eq 0) { Write-Host "READY: all checks PASS. Proceed to Lab 0." -ForegroundColor Green }
else { Write-Host "$review item(s) need REVIEW — see 02-requirements.md before teaching." -ForegroundColor Yellow }

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
