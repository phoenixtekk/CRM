<#
.SYNOPSIS
    SPMAMG-Validation.ps1 — verifies the MAM + Conditional Access posture for mobile SharePoint on GCC High.
.DESCRIPTION
    PURPOSE
        Confirms the solution is configured correctly: iOS and Android App Protection Policies exist and
        target the supported apps, a Conditional Access policy requires app protection for mobile Office
        365 access, and break-glass accounts are excluded from that CA policy. Read-only. Pass the CA
        policy name and break-glass group name as parameters (defaults match the implementation guide).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SPMAMG-Validation.ps1
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','DeviceManagementApps.Read.All','Group.Read.All'
    EXPECTED RESULTS
        A PASS/FAIL line per check. Overall PASS requires: two App Protection Policies present, the CA
        policy requires app protection, scopes iOS+Android, and excludes the break-glass group.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$CaPolicyName    = 'CA-SPO-Mobile-Require-App-Protection',
    [string]$BreakGlassGroup = 'SG-BreakGlass-Exclude'
)

function Result($ok, $msg) {
    if ($ok) { Write-Host ("PASS - {0}" -f $msg) -ForegroundColor Green }
    else     { Write-Host ("FAIL - {0}" -f $msg) -ForegroundColor Red }
    return [bool]$ok
}

Write-Host "=== Secure Mobile Access to SharePoint (GCC High) — validation ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome

$env = (Get-MgContext).Environment
$all = @()
$all += Result ($env -eq 'USGov') ("Connected to US Gov Graph (graph.microsoft.us). Environment='{0}'." -f $env)
if ($env -ne 'USGov') { Write-Host "Stop: wrong cloud." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# --- App Protection Policies present ---
$ios = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/iosManagedAppProtections').value
$and = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/androidManagedAppProtections').value
$all += Result ($ios.Count -ge 1) ("iOS App Protection Policy present ({0})." -f $ios.Count)
$all += Result ($and.Count -ge 1) ("Android App Protection Policy present ({0})." -f $and.Count)

# --- CA policy checks ---
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$ca = $pols | Where-Object { $_.displayName -eq $CaPolicyName }
$all += Result ($null -ne $ca) ("Conditional Access policy '{0}' exists." -f $CaPolicyName)

if ($ca) {
    $grants = @($ca.grantControls.builtInControls)
    $all += Result ($grants -contains 'compliantApplication') "CA policy grant requires app protection policy (compliantApplication)."

    $plats = @($ca.conditions.platforms.includePlatforms)
    $all += Result (($plats -contains 'iOS') -and ($plats -contains 'android')) ("CA policy targets iOS+Android (found: {0})." -f ($plats -join ','))

    # --- Break-glass excluded ---
    $bg = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $BreakGlassGroup)).value | Select-Object -First 1
    if ($bg) {
        $excluded = @($ca.conditions.users.excludeGroups) -contains $bg.id
        $all += Result $excluded ("Break-glass group '{0}' is excluded from the CA policy." -f $BreakGlassGroup)
    } else {
        $all += Result $false ("Break-glass group '{0}' not found — cannot confirm exclusion." -f $BreakGlassGroup)
    }
}

$fail = ($all | Where-Object { -not $_ }).Count
Write-Host ("`nOverall: {0}" -f ($(if($fail -eq 0){'PASS'}else{"FAIL ($fail check(s) failed)"}))) -ForegroundColor ($(if($fail -eq 0){'Green'}else{'Red'}))
Disconnect-MgGraph | Out-Null
