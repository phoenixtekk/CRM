<#
.SYNOPSIS
    GPPLAP-Discovery.ps1 — GlobalProtect Connect Before Logon (PLAP) Autopilot deployment-readiness discovery across Entra + Intune.
.DESCRIPTION
    PURPOSE
        Read-only readiness sweep for a GlobalProtect Connect Before Logon (PLAP) deployment during
        Hybrid Azure AD Join Windows Autopilot via Intune. Finds the single Win32 app
        'GlobalProtect – Connect Before Logon (PLAP) – Win32' (and the two-app alternative names), the
        optional SCEP certificate profile, and the pilot/production Autopilot DEVICE groups. Flags whether
        each Assigned group has the Intune Provisioning Client service principal
        (AppId f1346770-5b25-470b-88bd-d5744ab7952c) as an OWNER — required for enrollment-time targeting —
        and whether the app is referenced as a blocking app on any Enrollment Status Page. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPPLAP-Discovery.ps1
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementApps.Read.All
            DeviceManagementConfiguration.Read.All
            DeviceManagementServiceConfig.Read.All
            Group.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A readiness table: the Win32 app Found/Missing with assignment state, the optional cert profile,
        each Autopilot device group Found/Missing with membership type (Assigned) and SP-owner status, and
        whether the app is an ESP blocking app. All green = ready to pilot; any Missing / Dynamic group /
        missing SP owner / not-blocking = fix before deploying (see 02-requirements.md / 03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. GlobalProtect portal/gateway and app internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'PILOT – GlobalProtect PLAP – Autopilot Devices',
    [string] $ProdGroupName  = 'PROD – GlobalProtect PLAP – Autopilot Devices'
)

$ErrorActionPreference = 'Stop'

# Object names this solution creates (match 03-implementation.md verbatim).
$AppName        = 'GlobalProtect – Connect Before Logon (PLAP) – Win32'
$AltBaseApp     = 'GlobalProtect – VPN Client – Win32'
$AltRegApp      = 'GlobalProtect – PLAP Registration – Win32'
$CertProfileName = 'GlobalProtect – PLAP – Device Cert (SCEP) – Windows'

# Intune Provisioning Client first-party SP — must OWN the Assigned group for enrollment-time targeting.
$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementApps.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementServiceConfig.Read.All',
        'Group.Read.All',
        'Directory.Read.All'
    )
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph as $((Get-MgContext).Account)" -ForegroundColor Green
}

function Invoke-Graph {
    param([string] $Uri)
    $results = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $Uri = $resp.'@odata.nextLink'
    } while ($Uri)
    return $results
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'
$beta = 'https://graph.microsoft.com/beta'

Write-Host "`n=== GlobalProtect Connect Before Logon (PLAP) — Autopilot Deployment Readiness ===" -ForegroundColor Cyan

# --- Helper: assignment count for an app --------------------------------------
function Get-AssignmentSummary {
    param([string] $Uri)
    try {
        $a = Invoke-Graph $Uri
        if ($a -and $a.Count -gt 0) { return "$($a.Count) assignment(s)" } else { return "UNASSIGNED" }
    } catch { return "unknown" }
}

# --- Apps (single recommended app + two-app alternative) ----------------------
Write-Host "`n[1] GlobalProtect PLAP app(s) (mobileApps)" -ForegroundColor Cyan
$allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
$appRows = foreach ($name in @($AppName, $AltBaseApp, $AltRegApp)) {
    $match = $allApps | Where-Object { $_.displayName -eq $name }
    if ($match) {
        $assign = Get-AssignmentSummary "$base/deviceAppManagement/mobileApps/$($match[0].id)/assignments"
        $note = if ($name -eq $AppName) { '' } else { ' (two-app alternative)' }
        [pscustomobject]@{ Object = "$name$note"; State = 'Found'; Assignment = $assign }
    } else {
        $note = if ($name -eq $AppName) { '' } else { ' (two-app alternative — optional)' }
        [pscustomobject]@{ Object = "$name$note"; State = 'MISSING'; Assignment = '-' }
    }
}
$appRows | Format-Table -AutoSize -Wrap

# --- Optional certificate profile --------------------------------------------
Write-Host "[2] Optional device certificate profile" -ForegroundColor Cyan
$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
$cert = $allConfigs | Where-Object { $_.displayName -eq $CertProfileName }
if ($cert) {
    $assign = Get-AssignmentSummary "$base/deviceManagement/deviceConfigurations/$($cert[0].id)/assignments"
    [pscustomobject]@{ Object = $CertProfileName; State = 'Found'; Assignment = $assign } | Format-Table -AutoSize -Wrap
} else {
    [pscustomobject]@{ Object = $CertProfileName; State = 'MISSING (optional — only if cert auth)'; Assignment = '-' } | Format-Table -AutoSize -Wrap
}

# --- Autopilot device groups (Assigned + SP owner) ---------------------------
Write-Host "[3] Autopilot device groups — Assigned + Provisioning Client SP owner" -ForegroundColor Cyan
$groupRows = foreach ($gname in @($PilotGroupName, $ProdGroupName)) {
    $enc = [uri]::EscapeDataString($gname)
    $g = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName,membershipRule,groupTypes,securityEnabled"
    if (-not $g) {
        [pscustomobject]@{ Group = $gname; State = 'MISSING'; Membership = '-'; Members = 0; 'SP Owner' = '-' }
        continue
    }
    $gid = $g[0].id
    # Assigned vs Dynamic: Dynamic groups carry 'DynamicMembership' in groupTypes.
    $isDynamic = ($g[0].groupTypes -contains 'DynamicMembership')
    $membership = if ($isDynamic) { 'DYNAMIC (should be Assigned)' } else { 'Assigned' }
    $members = Invoke-Graph "$base/groups/$gid/members?`$select=id"
    # Owner check: is the Provisioning Client SP an owner of this group?
    $owners = Invoke-Graph "$base/groups/$gid/owners?`$select=id,appId,displayName"
    $spOwner = $owners | Where-Object { $_.appId -eq $ProvisioningClientAppId }
    $ownerState = if ($spOwner) { 'PRESENT' } else { 'MISSING (add SP owner!)' }
    [pscustomobject]@{ Group = $gname; State = 'Found'; Membership = $membership; Members = $members.Count; 'SP Owner' = $ownerState }
}
$groupRows | Format-Table -AutoSize -Wrap

# --- ESP blocking-app reference ----------------------------------------------
Write-Host "[4] Enrollment Status Page — is the app a blocking app?" -ForegroundColor Cyan
$espBlocking = 'unknown'
try {
    $espConfigs = Invoke-Graph "$beta/deviceManagement/deviceEnrollmentConfigurations?`$select=id,displayName,'@odata.type',selectedMobileAppNames,selectedMobileAppIds"
    $appId = ($allApps | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1).id
    $found = $false
    foreach ($esp in $espConfigs) {
        $ids = @()
        if ($esp.selectedMobileAppIds) { $ids += $esp.selectedMobileAppIds }
        if ($appId -and ($ids -contains $appId)) { $found = $true; break }
        if ($esp.selectedMobileAppNames -and ($esp.selectedMobileAppNames -contains $AppName)) { $found = $true; break }
    }
    $espBlocking = if ($found) { 'YES — app is an ESP blocking app' } else { 'NO — app not found in any ESP blocking list' }
} catch { $espBlocking = 'unknown (could not read ESP configurations)' }
Write-Host "  $espBlocking" -ForegroundColor $(if ($espBlocking -like 'YES*') { 'Green' } else { 'Yellow' })

# --- Summary -----------------------------------------------------------------
$problems = @()
if (-not ($appRows | Where-Object { $_.Object -eq $AppName -and $_.State -eq 'Found' })) {
    # Not fatal if the two-app alternative is present instead.
    $haveAlt = ($appRows | Where-Object { $_.Object -like "$AltBaseApp*" -and $_.State -eq 'Found' }) -and
               ($appRows | Where-Object { $_.Object -like "$AltRegApp*"  -and $_.State -eq 'Found' })
    if (-not $haveAlt) { $problems += "App '$AppName' (or the two-app alternative) not found" }
}
foreach ($row in $groupRows) {
    if ($row.State -eq 'MISSING') { $problems += "Group '$($row.Group)' missing" }
    elseif ($row.Membership -like 'DYNAMIC*') { $problems += "Group '$($row.Group)' is Dynamic (must be Assigned)" }
    elseif ($row.'SP Owner' -like 'MISSING*') { $problems += "Group '$($row.Group)' missing Provisioning Client SP owner" }
}
if ($espBlocking -like 'NO*') { $problems += "App is not an ESP blocking app" }

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($problems.Count -eq 0) {
    Write-Host "READY: the app, the Assigned + SP-owned device group(s), and the ESP blocking reference are in place." -ForegroundColor Green
} else {
    Write-Host "NOT READY — issues:" -ForegroundColor Yellow
    $problems | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "See 02-requirements.md (R9/R10/R11) / 03-implementation.md to fix." -ForegroundColor Yellow
}
Write-Host "Discovery complete (read-only). No changes were made." -ForegroundColor Green
