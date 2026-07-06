<#
.SYNOPSIS
    MACCA-Validation.ps1 — pre-enforcement check: pilot Macs compliant + Entra-registered, break-glass excluded (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        The check to run before you flip the Conditional Access policy from Report-only to On.
        Confirms every Mac in the pilot group is Intune-Compliant and Entra-registered (the two
        facts the compliant-device control depends on), and confirms the break-glass accounts you
        name are excluded from the CA policy so nobody can be locked out.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACCA-Validation.ps1 -PilotGroup macOS-ZeroTrust-Pilot -CaPolicyName 'CA - macOS - Require Compliant Device' -BreakGlassUpns breakglass1@your-tenant.onmicrosoft.com,breakglass2@your-tenant.onmicrosoft.com
        Requires Microsoft Graph SDK and scopes: Group.Read.All, DeviceManagementManagedDevices.Read.All,
        Policy.Read.All, User.Read.All.
    EXPECTED RESULTS
        Per pilot Mac: COMPLIANT/REGISTERED (good) or the failing fact. Per break-glass account:
        EXCLUDED (good) or NOT EXCLUDED (fix before enforcing). "READY TO ENFORCE" only when all pass.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$PilotGroup,
    [Parameter(Mandatory)][string]$CaPolicyName,
    [string[]]$BreakGlassUpns
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementManagedDevices.Read.All','Policy.Read.All','User.Read.All' -NoWelcome

$ready = $true

# --- Pilot Macs: compliant + Entra-registered ---
Write-Host "=== Pilot Macs — compliance + Entra registration ===" -ForegroundColor Cyan
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$PilotGroup'&`$select=id,displayName").value | Select-Object -First 1
if (-not $grp) { Write-Host "Pilot group '$PilotGroup' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; exit 1 }
$members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id,displayName,deviceId").value

# All macOS managed devices, keyed for lookup
$macs = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,complianceState,azureADRegistered,azureADDeviceId,userPrincipalName"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $macs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$macCount = 0
foreach ($m in $members) {
    # Match device members by azureADDeviceId; user members are checked via their Macs by UPN
    $devMatches = @()
    if ($m.deviceId) { $devMatches = $macs | Where-Object { $_.azureADDeviceId -eq $m.deviceId } }
    else { $devMatches = $macs | Where-Object { $_.userPrincipalName -eq $m.displayName -or $_.userPrincipalName -eq $m.userPrincipalName } }
    foreach ($d in $devMatches) {
        $macCount++
        $isComp = $d.complianceState -eq 'compliant'
        $isReg  = [bool]$d.azureADRegistered
        $ok = $isComp -and $isReg
        if (-not $ok) { $ready = $false }
        Write-Host ("  {0,-32} compliant:{1,-4} registered:{2,-5} => {3}" -f $d.deviceName, $isComp, $isReg, ($(if($ok){'OK'}else{'CHECK'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
    }
}
if ($macCount -eq 0) { Write-Host "  (no Macs resolved from the pilot group members)" -ForegroundColor Yellow }

# --- Break-glass exclusion from the CA policy ---
Write-Host "`n=== Break-glass exclusion from '$CaPolicyName' ===" -ForegroundColor Cyan
$pol = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value | Where-Object displayName -eq $CaPolicyName | Select-Object -First 1
if (-not $pol) { Write-Host "CA policy '$CaPolicyName' not found." -ForegroundColor Red; $ready = $false }
elseif ($BreakGlassUpns) {
    $exU = @($pol.conditions.users.excludeUsers)
    $exG = @($pol.conditions.users.excludeGroups)
    foreach ($u in $BreakGlassUpns) {
        $id = $null
        try { $id = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$u`?`$select=id").id } catch { Write-Host "  User not found: $u" -ForegroundColor Red; $ready = $false; continue }
        $inExU = $exU -contains $id
        $inExG = $false
        foreach ($g in $exG) { try { $gm = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$g/members?`$select=id").value.id; if ($gm -contains $id) { $inExG = $true } } catch {} }
        $ok = $inExU -or $inExG
        if (-not $ok) { $ready = $false }
        Write-Host ("  {0,-55} {1}" -f $u, ($(if($ok){'EXCLUDED'}else{'NOT EXCLUDED'}))) -ForegroundColor ($(if($ok){'Green'}else{'Red'}))
    }
} else { Write-Host "  (no -BreakGlassUpns supplied — pass them to verify the exclusion)" -ForegroundColor Yellow }

Write-Host ("`nResult: {0}" -f ($(if($ready){'READY TO ENFORCE'}else{'NOT READY — resolve the items above before enabling On'}))) -ForegroundColor ($(if($ready){'Green'}else{'Yellow'}))
Disconnect-MgGraph | Out-Null
if ($ready) { exit 0 } else { exit 1 }
