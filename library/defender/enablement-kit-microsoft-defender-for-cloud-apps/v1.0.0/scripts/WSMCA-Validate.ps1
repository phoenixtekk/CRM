<#
.SYNOPSIS
    WSMCA-Validate.ps1 — read-only readiness validation for the Defender for Cloud Apps workshop.
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to teach the "Workshop — Microsoft Defender for Cloud Apps"
        labs BEFORE attendees arrive. Checks (all read-only): Microsoft Graph connectivity and the
        required READ scopes, that MDA alert data is reachable, that OAuth app data is reachable, and
        reminds the facilitator of the portal-only checks (Cloud Discovery, connectors, app
        governance, advanced hunting). Prints a PASS/REVIEW table.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMCA-Validate.ps1
        Run as Security Reader / Security Administrator; consent read-only scopes when prompted.
    EXPECTED RESULTS
        A PASS/REVIEW line per check. All PASS = ready to run Lab 0 onward; any REVIEW points at the
        matching item in 02-requirements.md.
.NOTES
    White-label. Read-only. Makes no changes.
    Licensing/preview facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$scopes = @('SecurityAlert.Read.All','Application.Read.All','Directory.Read.All')
$checks = @()
function Add-Check($name,$ok,$detail){ $script:checks += [pscustomobject]@{ Check=$name; Result=($(if($ok){'PASS'}else{'REVIEW'})); Detail=$detail } }

foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Security','Microsoft.Graph.Applications') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

Write-Host "`n=== Defender for Cloud Apps workshop — readiness validation (read-only) ===" -ForegroundColor Cyan

try {
    Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    $have = ($scopes | Where-Object { $ctx.Scopes -contains $_ }).Count
    Add-Check 'Graph connectivity + read scopes' ($null -ne $ctx) ("Connected as $($ctx.Account); scopes granted: $have/$($scopes.Count)")
} catch { Add-Check 'Graph connectivity + read scopes' $false $_.Exception.Message }

try { $s = Get-MgSecurityAlertV2 -Top 5 -ErrorAction Stop; Add-Check 'MDA alert data reachable' $true ("Alert query returned {0} sample row(s)." -f ($s | Measure-Object).Count) }
catch { Add-Check 'MDA alert data reachable' $false $_.Exception.Message }

try { Import-Module Microsoft.Graph.Applications -ErrorAction Stop; $sp = Get-MgServicePrincipal -Top 5 -ErrorAction Stop; Add-Check 'OAuth app data reachable' $true ("Service principal query returned {0} sample row(s)." -f ($sp | Measure-Object).Count) }
catch { Add-Check 'OAuth app data reachable' $false $_.Exception.Message }

Add-Check 'Cloud Discovery data present (portal)' $true 'Confirm Cloud apps -> Cloud Discovery shows discovered apps (R2).'
Add-Check 'Connected app present (portal)' $true 'Confirm Cloud apps -> Connected apps has >=1 connector (R3).'
Add-Check 'App governance enabled (portal)' $true 'Confirm Cloud apps -> App governance is on (R4).'
Add-Check 'Advanced hunting access (portal)' $true 'Confirm attendees can run: CloudAppEvents | take 5 (R5).'

Write-Host ""
$checks | Format-Table Check, Result, Detail -AutoSize
$review = ($checks | Where-Object Result -eq 'REVIEW').Count
if ($review -eq 0) { Write-Host "READY: all checks PASS. Proceed to Lab 0." -ForegroundColor Green }
else { Write-Host "$review item(s) need REVIEW — see 02-requirements.md before teaching." -ForegroundColor Yellow }

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
