<#
.SYNOPSIS
    ABMPROV-Validation.ps1 — per-user Managed Apple ID / federation + per-device enrollment-model check (read-only).
.DESCRIPTION
    PURPOSE
        For supplied users, reports whether they are in the provisioning scope group and whether the
        provisioning job is active (so a Managed Apple ID is/should be provisioned and federated). For
        supplied devices (or all iOS devices), reports the enrollment model so you can confirm each is
        the intended COD / BYOD / Shared shape. Read-only against Microsoft Graph. The authoritative
        Managed-Apple-ID state lives in ABM and is deferred to Apple's documentation; this validates
        the Entra/Intune side that drives it.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROV-Validation.ps1 -UserUpns user1@contoso.com
        powershell -ExecutionPolicy Bypass -File .\ABMPROV-Validation.ps1 -DeviceNames iPhone-COD-01
        (No params = validates all managed iOS devices.)
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.Read.All, Synchronization.Read.All, Group.Read.All, User.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Per user: in-scope (yes/no) + provisioning job active (yes/no). Per device: enrollment profile
        type mapped to COD (supervised + user affinity), BYOD (user enrollment), or Shared (no user
        affinity).
.NOTES
    Entra ID Solutions — Entra ID + ABM federation & auto-provisioning. Read-only. ABM state deferred.
#>
[CmdletBinding()]
param(
    [string]$AppDisplayName = 'Apple Business Manager - Federation - Prod',
    [string[]]$ScopeGroups  = @('Managed Apple ID Provisioning - Pilot - Stage','Managed Apple ID Provisioning - Corp - Prod'),
    [string[]]$UserUpns     = @(),
    [string[]]$DeviceNames  = @()
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Synchronization.Read.All','Group.Read.All','User.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# Resolve provisioning job state once
$jobActive = $false
$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if ($sp) {
    try {
        $jobs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs").value
        if ($jobs | Where-Object { $_.status.code -eq 'Active' }) { $jobActive = $true }
    } catch {}
}
Write-Host ("Provisioning job active : {0}" -f $jobActive) -ForegroundColor $(if ($jobActive) {'Green'} else {'Yellow'})

# Build the set of in-scope user ids from the scope groups
$inScope = @{}
foreach ($g in $ScopeGroups) {
    $ge = $g.Replace("'","''")
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
    if (-not $grp) { continue }
    try {
        $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id,userPrincipalName").value
        foreach ($m in $members) { if ($m.userPrincipalName) { $inScope[$m.userPrincipalName.ToLower()] = $g } }
    } catch {}
}

# Per-user validation
Write-Host "`n=== Per-user Managed Apple ID / federation readiness ===" -ForegroundColor Cyan
if ($UserUpns.Count -eq 0) {
    Write-Host "(no -UserUpns supplied — listing in-scope users)" -ForegroundColor DarkGray
    foreach ($u in $inScope.Keys) { Write-Host ("  {0}  in-scope via '{1}'  provisioning={2}" -f $u, $inScope[$u], $jobActive) -ForegroundColor Green }
} else {
    foreach ($upn in $UserUpns) {
        $key = $upn.ToLower()
        if ($inScope.ContainsKey($key)) {
            $state = if ($jobActive) { 'PROVISIONED (job active)' } else { 'IN SCOPE but job not active' }
            Write-Host ("  {0} : in scope ('{1}') — {2}" -f $upn, $inScope[$key], $state) -ForegroundColor $(if ($jobActive) {'Green'} else {'Yellow'})
        } else {
            Write-Host ("  {0} : NOT in any provisioning scope group — add via ABMPROV-Set-ScopeTargeting.ps1" -f $upn) -ForegroundColor Yellow
        }
    }
}

# Per-device enrollment model
function Get-Model($d) {
    $pt = "$($d.deviceEnrollmentType)"
    switch -Wildcard ($pt) {
        '*UserEnrollment*'      { return 'BYOD (account-driven User Enrollment)' }
        '*AppleUserShared*'     { return 'Shared (no user affinity)' }
        '*DeviceEnrollment*'    { if ($d.userId) { return 'COD (device enrollment, user affinity)' } else { return 'Shared (no user affinity)' } }
        default {
            if ($pt -like '*Dep*' -or $pt -like '*AutomatedDevice*') {
                if ($d.userId) { return 'COD (ADE, user affinity)' } else { return 'Shared (ADE, no user affinity)' }
            }
            return ("Other / legacy ({0})" -f $pt)
        }
    }
}

Write-Host "`n=== Per-device enrollment model ===" -ForegroundColor Cyan
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=deviceName,operatingSystem,deviceEnrollmentType,userId,userPrincipalName"
$devices = @()
try { $devices = (Invoke-MgGraphRequest -Method GET -Uri $uri).value } catch { Write-Host "  (unable to read managed devices)" -ForegroundColor Yellow }
if ($DeviceNames.Count -gt 0) { $devices = $devices | Where-Object { $DeviceNames -contains $_.deviceName } }
if (-not $devices -or $devices.Count -eq 0) { Write-Host "  (no matching iOS devices)" -ForegroundColor Yellow }
foreach ($d in $devices) {
    Write-Host ("  {0,-28} -> {1}" -f $d.deviceName, (Get-Model $d)) -ForegroundColor Green
}

Write-Host "`nAuthoritative Managed Apple ID state lives in Apple Business Manager (deferred to Apple docs)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
