<#
.SYNOPSIS
    APPRET-ArtifactFinder.ps1 — find leftover tenant artefacts that reference a retired app (read-only).
.DESCRIPTION
    PURPOSE
        Answers "what does this app leave behind?" Builds the cleanup checklist for the end of a
        retirement: the app object + its assignments, the Entra groups used to target it (and whether
        any OTHER policy/app also uses those groups), Conditional Access policies that name the app's
        enterprise application, app registrations / enterprise apps matching the name, and proactive-
        remediation or platform scripts named for the app. Strictly read-only — it reports; you delete
        by hand (Implementation Step 13) after confirming nothing live still uses each item.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPRET-ArtifactFinder.ps1 -AppName "LegacyTrack Client" -AppCode "APPRET-LGT"
        US Gov: add  -Environment USGov  or  -Environment USGovDoD
        Requires the Microsoft Graph PowerShell SDK with DeviceManagementApps.Read.All,
        DeviceManagementConfiguration.Read.All, Group.Read.All, Application.Read.All, Policy.Read.All.
    EXPECTED RESULTS
        Sections listing each candidate artefact and whether it appears SAFE to remove (nothing else
        references it) or SHARED (leave it). Nothing is deleted.
.NOTES
    Intune Solutions — read-only. Artefact-cleanup planning stage of an application retirement.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AppName,
    [string]$AppCode,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementConfiguration.Read.All','Group.Read.All','Application.Read.All','Policy.Read.All' -Environment $Environment -NoWelcome

$name = $AppName
$code = if ($AppCode) { $AppCode } else { $AppName }

# 1) The app object + assignments
Write-Host "`n[1] Intune app object(s) matching the name:" -ForegroundColor Yellow
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$match = $apps | Where-Object { $_.displayName -like "*$name*" -or ($AppCode -and $_.displayName -like "*$AppCode*") }
$targetGroupIds = @()
if ($match) {
    foreach ($a in $match) {
        Write-Host ("    APP: {0}  (id {1})" -f $a.displayName, $a.id)
        $asg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($a.id)/assignments").value
        foreach ($x in $asg) { if ($x.target.groupId) { $targetGroupIds += $x.target.groupId; Write-Host ("        assignment intent={0} groupId={1}" -f $x.intent, $x.target.groupId) -ForegroundColor Gray } }
    }
    Write-Host "    -> Delete the app object LAST (Step 13.1), after residual count is accepted." -ForegroundColor Cyan
} else { Write-Host "    (no app object — already deleted, or software was never an Intune app)" -ForegroundColor Green }

# 2) Entra groups named for this retirement, and whether anything else uses them
Write-Host "`n[2] Entra groups for this retirement (and other references to them):" -ForegroundColor Yellow
$grps = @(); $guri = "/v1.0/groups?`$filter=startswith(displayName,'$code')&`$select=id,displayName"
do { $gr = Invoke-MgGraphRequest -Method GET -Uri $guri -Headers @{ ConsistencyLevel='eventual' }; $grps += $gr.value; $guri = $gr.'@odata.nextLink' } while ($guri)
$grps += ($targetGroupIds | Select-Object -Unique | ForEach-Object { try { Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$_?`$select=id,displayName" } catch {} })
$grps = $grps | Where-Object { $_ } | Sort-Object id -Unique
if ($grps) {
    foreach ($g in $grps) {
        # Count other mobileApps assigned to this group
        $others = 0
        foreach ($a in $apps) {
            if ($match -and $a.id -in $match.id) { continue }
            try { $aa = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($a.id)/assignments").value } catch { $aa=@() }
            if ($aa.target.groupId -contains $g.id) { $others++ }
        }
        $verdict = if ($others -eq 0) { "SAFE to delete (no other app uses it)" } else { "SHARED — $others other app(s) assign to it; DO NOT delete" }
        Write-Host ("    GROUP '{0}' -> {1}" -f $g.displayName, $verdict) -ForegroundColor ($(if($others){'Red'}else{'Green'}))
    }
} else { Write-Host "    (no matching groups)" -ForegroundColor Green }

# 3) Conditional Access policies referencing the app's enterprise application
Write-Host "`n[3] Conditional Access policies referencing an enterprise app by this name:" -ForegroundColor Yellow
$sp = @(); $spuri = "/v1.0/servicePrincipals?`$filter=startswith(displayName,'$name')&`$select=id,displayName,appId"
do { $s = try { Invoke-MgGraphRequest -Method GET -Uri $spuri } catch { $null }; if($s){ $sp += $s.value; $spuri=$s.'@odata.nextLink' } else { break } } while ($spuri)
if ($sp) {
    $caIds = ($sp.appId + $sp.id)
    try {
        $ca = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identity/conditionalAccess/policies").value
        $hit = $ca | Where-Object { $_.conditions.applications.includeApplications | Where-Object { $_ -in $caIds } }
        if ($hit) { foreach ($p in $hit) { Write-Host ("    CA POLICY '{0}' includes this app — remove the app or retire the policy (Step 13.5)" -f $p.displayName) -ForegroundColor Red } }
        else { Write-Host "    No CA policy references this app." -ForegroundColor Green }
    } catch { Write-Host "    (could not read CA policies — check Policy.Read.All consent)" -ForegroundColor DarkYellow }
    foreach ($x in $sp) { Write-Host ("    ENTERPRISE APP: '{0}' (appId {1}) — remove if nothing else uses it (Step 13.5)" -f $x.displayName, $x.appId) -ForegroundColor Gray }
} else { Write-Host "    (no enterprise application matches this name — nothing to clean in Entra/CA)" -ForegroundColor Green }

# 4) Proactive remediation / platform scripts named for this app
Write-Host "`n[4] Remediation/platform scripts named for this app:" -ForegroundColor Yellow
try {
    $hp = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceHealthScripts?`$select=id,displayName").value
    $hpm = $hp | Where-Object { $_.displayName -like "*$name*" -or ($AppCode -and $_.displayName -like "*$AppCode*") }
    if ($hpm) { foreach ($h in $hpm) { Write-Host ("    REMEDIATION '{0}' — remove after fleet is clean (Step 13.3)" -f $h.displayName) } }
    else { Write-Host "    (no matching remediation scripts)" -ForegroundColor Green }
} catch { Write-Host "    (could not enumerate remediation scripts on this tenant)" -ForegroundColor DarkYellow }

Write-Host "`nNOTE: WDAC / App Control for Business rules and SCCM/ConfigMgr deployments are NOT fully" -ForegroundColor Cyan
Write-Host "queryable here — review them manually per Implementation Step 13.4 and 13.6." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
