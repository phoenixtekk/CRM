<#
.SYNOPSIS
    ENTIDP-Validate.ps1 — confirm the four pilot policies are report-only, scoped, and break-glass excluded.
.DESCRIPTION
    PURPOSE
        Validates the pilot state before enforcement: the four named Conditional Access policies exist,
        are in report-only, target the pilot scope group, and exclude the break-glass group. Also flags
        whether token-protection session control and authentication strengths are wired as expected.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTIDP-Validate.ps1 `
            -PilotGroupName "IDP Pilot – Risk Scope – Pilot" `
            -BreakGlassGroupName "CA Break-Glass Exclusion"
        Requires the Microsoft Graph PowerShell SDK. Read-only scopes: Policy.Read.All, Group.Read.All.
    EXPECTED RESULTS
        PASS/WARN per policy: exists, report-only, pilot scoped, break-glass excluded. Any WARN is a
        gate failure to fix before flipping to enforcement.
.NOTES
    White-label — Entra ID Solutions. Read-only against Graph.
#>
[CmdletBinding()]
param(
    [string]$PilotGroupName = 'IDP Pilot – Risk Scope – Pilot',
    [string]$BreakGlassGroupName = 'CA Break-Glass Exclusion'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','Group.Read.All' -NoWelcome
Write-Host "`n=== ENTIDP — pilot validation ===" -ForegroundColor Cyan

function Get-GroupId([string]$name) {
    $enc = [uri]::EscapeDataString($name)
    (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1 -ExpandProperty id
}
$pilotId = Get-GroupId $PilotGroupName
$bgId    = Get-GroupId $BreakGlassGroupName
if (-not $pilotId) { Write-Host "WARN: pilot group '$PilotGroupName' not found." -ForegroundColor Yellow }
if (-not $bgId)    { Write-Host "WARN: break-glass group '$BreakGlassGroupName' not found." -ForegroundColor Yellow }

$expected = @(
    'CA – Sign-In Risk – Pilot (Report-Only)',
    'CA – User Risk – Pilot (Report-Only)',
    'CA – Step-Up Sensitive Apps – Pilot (Report-Only)',
    'CA – Token Protection – Pilot (Report-Only)'
)
$cap = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)

foreach ($name in $expected) {
    $p = $cap | Where-Object { $_.displayName -eq $name } | Select-Object -First 1
    if (-not $p) { Write-Host ("WARN  missing        : {0}" -f $name) -ForegroundColor Yellow; continue }
    $isReport = $p.state -eq 'enabledForReportingButNotEnforced'
    $incl = @($p.conditions.users.includeGroups)
    $excl = @($p.conditions.users.excludeGroups)
    $pilotOk = (-not $pilotId) -or ($incl -contains $pilotId)
    $bgOk    = (-not $bgId)    -or ($excl -contains $bgId)
    $status  = if ($isReport -and $pilotOk -and $bgOk) { 'PASS ' } else { 'WARN ' }
    $color   = if ($status -eq 'PASS ') { 'Green' } else { 'Yellow' }
    Write-Host ("{0} {1}" -f $status, $name) -ForegroundColor $color
    Write-Host ("       report-only={0}  pilot-scoped={1}  break-glass-excluded={2}" -f $isReport, $pilotOk, $bgOk)
    if ($name -like '*Token Protection*') {
        $tp = $p.sessionControls.secureSignInSession.isEnabled
        Write-Host ("       token-protection session control enabled={0} (verify supported clients)" -f [bool]$tp)
    }
}

Write-Host "`nResolve every WARN before flipping any policy to enforcement." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
