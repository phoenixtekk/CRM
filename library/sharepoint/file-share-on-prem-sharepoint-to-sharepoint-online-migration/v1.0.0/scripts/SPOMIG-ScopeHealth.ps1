<#
.SYNOPSIS
    SPOMIG-ScopeHealth.ps1 — read-only scope/config health check that a target site is ready to receive a migration.
.DESCRIPTION
    Confirms the migration prerequisites for a target SharePoint Online site before tasks are defined:
    the site exists and is reachable, the signed-in account can write to it, the target library exists
    (or can be created), and storage headroom is sufficient for the wave. Read-only — checks and
    reports; changes nothing. Run this before SPOMIG-TaskBuilder.ps1.
.EXAMPLE
    .\SPOMIG-ScopeHealth.ps1 -SiteUrl https://contoso.sharepoint.com/sites/PilotProd -Library "Documents" -NeededGB 50
    # PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline (interactive modern auth).
.NOTES
    Expected results: a green/red checklist (reachable, writable, library present, storage headroom).
    Any red must be resolved before defining migration tasks. No changes are made.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SiteUrl,
    [string]$Library = 'Documents',
    [double]$NeededGB = 0
)

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) { throw 'PnP.PowerShell not installed. Install-Module PnP.PowerShell first.' }
Import-Module PnP.PowerShell -ErrorAction Stop

Write-Host '=== Scope/Config Health — target readiness ===' -ForegroundColor Cyan
$checks = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$name,[bool]$ok,[string]$detail){ $checks.Add([pscustomobject]@{ Check=$name; Status=$(if($ok){'PASS'}else{'FAIL'}); Detail=$detail }) }

# Reachable + writable
$web = $null
try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
    $web = Get-PnPWeb -ErrorAction Stop
    Add-Check 'Site reachable' $true $web.Title
    $ctx = Get-PnPContext
    $eff = Get-PnPWeb -Includes EffectiveBasePermissions
    $canAdd = $eff.EffectiveBasePermissions.Has([Microsoft.SharePoint.Client.PermissionKind]::AddListItems)
    Add-Check 'Account can write' $canAdd ("AddListItems=$canAdd")
} catch {
    Add-Check 'Site reachable' $false $_.Exception.Message
}

# Target library present
if ($web) {
    $list = Get-PnPList -Identity $Library -ErrorAction SilentlyContinue
    Add-Check "Library '$Library' present" ([bool]$list) $(if($list){"$($list.ItemCount) items"}else{'not found — will need creating'})
}

# Storage headroom (site quota vs used); NeededGB optional
if ($web) {
    try {
        $site = Get-PnPTenantSite -Identity $SiteUrl -ErrorAction Stop
        $quotaGB = [math]::Round($site.StorageMaximumLevel/1024,1)
        $usedGB  = [math]::Round($site.StorageUsage/1024,1)
        $freeGB  = [math]::Round($quotaGB-$usedGB,1)
        $ok = ($NeededGB -le 0) -or ($freeGB -ge $NeededGB)
        Add-Check 'Storage headroom' $ok ("free {0}GB of {1}GB (need {2}GB)" -f $freeGB,$quotaGB,$NeededGB)
    } catch {
        Add-Check 'Storage headroom' $false 'Need SharePoint Admin (Get-PnPTenantSite) to read quota — verify in admin center.'
    }
}

$checks | Format-Table -AutoSize
$failed = @($checks | Where-Object Status -eq 'FAIL').Count
if ($failed -eq 0) { Write-Host 'Target READY — proceed to SPOMIG-TaskBuilder.ps1.' -ForegroundColor Green }
else { Write-Host ("{0} check(s) FAILED — resolve before defining tasks." -f $failed) -ForegroundColor Yellow }

Disconnect-PnPOnline
