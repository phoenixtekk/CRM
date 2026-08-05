<#
.SYNOPSIS
    APPRET-ImpactAnalyzer.ps1 — dependency & supersedence impact analysis before removal (read-only).
.DESCRIPTION
    PURPOSE
        Answers "what breaks if I remove this app?" Surfaces the blast radius BEFORE you retire an
        app: other Intune apps that declare this app as a DEPENDENCY (they will fight your uninstall),
        the supersedence chains this app sits in, the Entra groups used to assign it (with member
        counts), and Win32 apps that share the same detection/requirement script. Strictly read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPRET-ImpactAnalyzer.ps1 -AppName "LegacyTrack Client"
        US Gov: add  -Environment USGov   or  -Environment USGovDoD
        Requires the Microsoft Graph PowerShell SDK, DeviceManagementApps.Read.All, Group.Read.All.
    EXPECTED RESULTS
        Sections for: apps that DEPEND ON this app (must resolve first), supersedence in/out, assign
        groups + member counts, and shared detection scripts — each an item for the decision record.
.NOTES
    Intune Solutions — read-only. Impact-analysis stage of an application retirement.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AppName,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All' -Environment $Environment -NoWelcome

# All apps (needed to scan relationships and shared scripts)
$all = @(); $uri = "/v1.0/deviceAppManagement/mobileApps"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $all += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$target = $all | Where-Object { $_.displayName -eq $AppName }
if (-not $target) { Write-Host "No app named '$AppName' found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
$target = $target[0]; $tid = $target.id
Write-Host ("Analyzing impact of retiring: {0}  ({1})" -f $target.displayName, $tid) -ForegroundColor Cyan

# 1) Apps that DEPEND ON the target (dependents will try to reinstall it)
Write-Host "`n[1] Apps that DEPEND ON this app (resolve these FIRST):" -ForegroundColor Yellow
$found = $false
foreach ($a in $all) {
    if ($a.id -eq $tid) { continue }
    try {
        $rel = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($a.id)/relationships").value
        foreach ($x in $rel) {
            if ($x.targetId -eq $tid -and $x.'@odata.type' -match 'dependency|supersed') {
                Write-Host ("    {0}  --{1}-->  {2}" -f $a.displayName, ($x.'@odata.type' -replace '#microsoft.graph.',''), $target.displayName)
                $found = $true
            }
        }
    } catch {}
}
if (-not $found) { Write-Host "    (none) — no other app declares this as a dependency/supersedence source." -ForegroundColor Green }

# 2) Relationships declared BY the target
Write-Host "`n[2] Relationships declared by this app (dependencies it needs / apps it supersedes):" -ForegroundColor Yellow
try {
    $rel = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$tid/relationships").value
    if ($rel) { foreach ($x in $rel) { Write-Host ("    {0} -> {1}" -f ($x.'@odata.type' -replace '#microsoft.graph.',''), $x.targetDisplayName) } }
    else { Write-Host "    (none)" -ForegroundColor Green }
} catch { Write-Host "    (none)" -ForegroundColor Green }

# 3) Assign groups + member counts
Write-Host "`n[3] Entra groups used to assign this app (targets to clean up):" -ForegroundColor Yellow
$asg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$tid/assignments").value
if ($asg) {
    foreach ($a in $asg) {
        $gid = $a.target.groupId
        if ($gid) {
            $g = try { Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$gid" } catch { $null }
            $cnt = try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$gid/members/`$count" -Headers @{ ConsistencyLevel='eventual' }) } catch { '?' }
            Write-Host ("    intent={0,-11} group='{1}'  members={2}" -f $a.intent, ($g.displayName ?? $gid), $cnt)
        } else {
            Write-Host ("    intent={0,-11} target={1}" -f $a.intent, $a.target.'@odata.type')
        }
    }
} else { Write-Host "    (no assignments)" -ForegroundColor Green }

# 4) Shared detection/requirement scripts (Win32)
Write-Host "`n[4] Win32 apps sharing a detection/requirement SCRIPT with this app (do NOT delete shared scripts):" -ForegroundColor Yellow
$tdet = @(); if ($target.detectionRules) { $tdet = $target.detectionRules | Where-Object { $_.'@odata.type' -match 'Script' } }
if (-not $tdet) { Write-Host "    This app uses no script-based detection rule — nothing shared to worry about." -ForegroundColor Green }
else {
    $shared = $false
    foreach ($a in $all) {
        if ($a.id -eq $tid -or -not $a.detectionRules) { continue }
        foreach ($d in ($a.detectionRules | Where-Object { $_.'@odata.type' -match 'Script' })) {
            foreach ($td in $tdet) {
                if ($d.scriptContent -and $d.scriptContent -eq $td.scriptContent) { Write-Host ("    SHARED with: {0}" -f $a.displayName) -ForegroundColor Red; $shared = $true }
            }
        }
    }
    if (-not $shared) { Write-Host "    No other app shares this script — safe to remove on cleanup." -ForegroundColor Green }
}

Write-Host "`nReview each finding with the app owner and record it in the Decision Record." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
