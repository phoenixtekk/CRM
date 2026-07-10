<#
.SYNOPSIS
    FABGOV-Workspace-Provision.ps1 — provision the dev/test/prod lifecycle workspaces with group-based roles (WhatIf-first).
.DESCRIPTION
    PURPOSE
        Creates the three lifecycle workspaces ('Sales BI - Content - Dev/Test/Prod'), assigns Test and Prod
        to the governance capacity, and adds the group-based role assignments from the access model. It runs
        in -WhatIf mode BY DEFAULT (previewing every action); it only makes changes when -Execute is passed.
    HOW TO RUN
        Preview (default, safe):
          .\FABGOV-Workspace-Provision.ps1
        Execute for real (after reviewing the preview):
          .\FABGOV-Workspace-Provision.ps1 -Execute
        Optional overrides: -WorkspacePrefix 'Sales BI - Content' -Capacity 'Fabric Capacity - Analytics - Prod'
        Requires MicrosoftPowerBIMgmt and the Fabric/Power BI Administrator role. The named security groups
        must already exist (requirement 2.3).
    EXPECTED RESULTS
        In preview: a WhatIf line for each workspace create, capacity assignment, and role add.
        With -Execute: the workspaces created/assigned/roled, then a re-run of the model summary.
.NOTES
    Data — Fabric/Power BI Governance. Change script — preview-first, explicitly gated by -Execute.
    White-label. Group and object names are parameters; defaults match the implementation guide.
#>
[CmdletBinding()]
param(
    [switch]$Execute,
    [string]$WorkspacePrefix = 'Sales BI - Content',
    [string]$Capacity = 'Fabric Capacity - Analytics - Prod',
    # Access model: stage -> @{ Group role } (roles: Admin, Member, Contributor, Viewer)
    [hashtable]$Roles = @{
        'Dev'  = @{ 'BI Creators - Analytics - Pilot' = 'Contributor'; 'Fabric Admins - Platform - Prod' = 'Admin' }
        'Test' = @{ 'BI Content Certifiers - Analytics - Prod' = 'Member'; 'Fabric Admins - Platform - Prod' = 'Admin' }
        'Prod' = @{ 'Fabric Admins - Platform - Prod' = 'Admin' }
    }
)

$whatIf = -not $Execute
if ($whatIf) { Write-Host "PREVIEW MODE (no changes). Re-run with -Execute to apply." -ForegroundColor Yellow }
else { Write-Host "EXECUTE MODE — changes WILL be made." -ForegroundColor Red }

if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop
try { Connect-PowerBIServiceAccount -ErrorAction Stop | Out-Null }
catch { Write-Host "Sign-in failed: $($_.Exception.Message)" -ForegroundColor Red; return }

$caps = (Invoke-PowerBIRestMethod -Url "admin/capacities" -Method Get | ConvertFrom-Json).value
$cap = $caps | Where-Object { $_.displayName -eq $Capacity }
if (-not $cap) { Write-Host "Capacity '$Capacity' not found — create/verify it before provisioning (req 2.4)." -ForegroundColor Yellow }

foreach ($stage in 'Dev','Test','Prod') {
    $wsName = "$WorkspacePrefix - $stage"
    $existing = Get-PowerBIWorkspace -Name $wsName -ErrorAction SilentlyContinue

    if (-not $existing) {
        if ($whatIf) { Write-Host "WhatIf: New-PowerBIWorkspace -Name '$wsName'" -ForegroundColor Gray }
        else { $existing = New-PowerBIWorkspace -Name $wsName; Write-Host "Created workspace '$wsName'." -ForegroundColor Green }
    } else { Write-Host "Workspace '$wsName' already exists — reconciling." -ForegroundColor Gray }

    # Capacity assignment for Test/Prod
    if ($stage -in 'Test','Prod' -and $cap) {
        if ($whatIf) { Write-Host "WhatIf: assign '$wsName' to capacity '$Capacity'" -ForegroundColor Gray }
        elseif ($existing) {
            try {
                Invoke-PowerBIRestMethod -Url "groups/$($existing.Id)/AssignToCapacity" -Method Post `
                    -Body (@{ capacityId = $cap.id } | ConvertTo-Json) | Out-Null
                Write-Host "Assigned '$wsName' to '$Capacity'." -ForegroundColor Green
            } catch { Write-Host "Capacity assign failed for '$wsName': $($_.Exception.Message)" -ForegroundColor Yellow }
        }
    }

    # Group-based role assignments
    foreach ($grp in $Roles[$stage].Keys) {
        $role = $Roles[$stage][$grp]
        if ($whatIf) { Write-Host "WhatIf: add group '$grp' as $role on '$wsName'" -ForegroundColor Gray }
        elseif ($existing) {
            try {
                Add-PowerBIWorkspaceUser -Id $existing.Id -PrincipalType Group -Identifier $grp -AccessRight $role -ErrorAction Stop
                Write-Host "Added '$grp' as $role on '$wsName'." -ForegroundColor Green
            } catch { Write-Host "Role add failed ('$grp' on '$wsName'): $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "  Note: Add-PowerBIWorkspaceUser may require the group's object ID rather than name." -ForegroundColor DarkYellow }
        }
    }
}

Write-Host "`nDone ($([string]::Format('{0} mode', $(if($whatIf){'preview'}else{'execute'})))). Validate with FABGOV-Validate.ps1." -ForegroundColor Cyan
Disconnect-PowerBIServiceAccount | Out-Null
