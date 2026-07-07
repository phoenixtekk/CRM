<#
.SYNOPSIS
  Scope / health helper (READ-ONLY): pre-flight check that the toolchain, sign-in, roles, and site scope
  are ready before running the permission audit and remediation. Makes no changes.
.DESCRIPTION
  Verifies the local prerequisites and connectivity for the SPOPERM toolset: the PnP.PowerShell (and, for
  reporting, Microsoft.Graph) modules are installed; Connect-PnPOnline to the target site succeeds; the
  signed-in account can read the site's groups (a proxy for Site Collection Admin); the associated
  Owners/Members/Visitors groups and their permission levels resolve; and it summarizes the site's
  broken-inheritance footprint so the operator can size the remediation. Optionally confirms Graph
  connectivity for Entra/M365 group expansion. Read-only: no permissions are changed. Run this first.
.EXAMPLE
  .\SPOPERM-Scope.ps1 -Url https://contoso.sharepoint.com/sites/Finance
  # Confirm modules, sign-in, group access, and show the broken-inheritance footprint. No changes.
.EXAMPLE
  .\SPOPERM-Scope.ps1 -Url https://contoso.sharepoint.com/sites/Finance -CheckGraph
  # Also verify read-only Microsoft Graph connectivity for the reporting path.
  # (PowerShell 5.1+/7+, PnP.PowerShell [+ Microsoft.Graph]; connect with Connect-PnPOnline / Connect-MgGraph.)
.NOTES
  Expected results: PASS/FAIL lines for modules, connection, group-read (SCA proxy), and standard-group
  resolution, plus a count of lists with unique permissions. Any FAIL tells you what to fix before
  auditing/remediating. Government cloud: use the correct site URL (*.sharepoint.us) and Graph environment.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [switch]$CheckGraph
)

$pass = @(); $fail = @()
function Ok   { param([string]$m) $script:pass += $m; Write-Host "  PASS  $m" -ForegroundColor Green }
function Nope { param([string]$m) $script:fail += $m; Write-Host "  FAIL  $m" -ForegroundColor Red }

Write-Host "SPOPERM scope / health check for $Url`n" -ForegroundColor Cyan

# 1. Modules
if (Get-Module PnP.PowerShell -ListAvailable) { Ok 'PnP.PowerShell module installed' }
else { Nope 'PnP.PowerShell not installed -> Install-Module PnP.PowerShell' }

if ($CheckGraph) {
    if (Get-Module Microsoft.Graph -ListAvailable) { Ok 'Microsoft.Graph module installed' }
    else { Nope 'Microsoft.Graph not installed -> Install-Module Microsoft.Graph (needed only for -ExpandEntraGroups)' }
}

# 2. Connect
$connected = $false
try {
    Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
    $connected = $true
    Ok "Connect-PnPOnline to $Url succeeded"
} catch {
    Nope "Connect-PnPOnline failed: $($_.Exception.Message)"
}

if ($connected) {
    $web = Get-PnPWeb

    # 3. Group-read as a Site Collection Admin proxy
    try {
        $groups = Get-PnPGroup -ErrorAction Stop
        Ok "Can read site groups ($($groups.Count) group(s)) -- SCA-level access confirmed"
    } catch {
        Nope "Cannot read site groups (need Site Collection Admin): $($_.Exception.Message)"
    }

    # 4. Standard associated groups + levels
    foreach ($role in 'Owner','Member','Visitor') {
        $g = Get-PnPProperty -ClientObject $web -Property "Associated${role}Group"
        if ($g -and $g.Title) {
            $lvl = (Get-PnPGroupPermissions -Identity $g.Title -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join '; '
            Ok "Associated $role group '$($g.Title)' resolves (levels: $lvl)"
        } else {
            Nope "No associated $role group -- run SPOPERM-Remediate-GroupAccess.ps1 -EnsureGroups"
        }
    }

    # 5. Broken-inheritance footprint (sizing only)
    try {
        $lists = Get-PnPList | Where-Object { -not $_.Hidden -and $_.BaseTemplate -ne 544 }
        $unique = 0
        foreach ($l in $lists) {
            Get-PnPProperty -ClientObject $l -Property HasUniqueRoleAssignments | Out-Null
            if ($l.HasUniqueRoleAssignments) { $unique++ }
        }
        Write-Host ("`n  INFO  {0} of {1} list(s)/library(ies) have unique permissions (broken inheritance)." -f $unique, $lists.Count) -ForegroundColor Cyan
    } catch {
        Write-Warning "Could not size broken-inheritance footprint: $($_.Exception.Message)"
    }
}

# 6. Optional Graph connectivity
if ($CheckGraph) {
    try {
        Connect-MgGraph -Scopes 'Group.Read.All','Directory.Read.All' -ErrorAction Stop | Out-Null
        Get-MgGroup -Top 1 -ErrorAction Stop | Out-Null
        Ok 'Microsoft Graph read-only connectivity confirmed (Group.Read.All / Directory.Read.All)'
    } catch {
        Nope "Microsoft Graph check failed (needed only for reporting -ExpandEntraGroups): $($_.Exception.Message)"
    }
}

Write-Host ("`nResult: {0} PASS, {1} FAIL" -f $pass.Count, $fail.Count) -ForegroundColor $(if ($fail.Count) {'Yellow'} else {'Green'})
if ($fail.Count -eq 0) {
    Write-Host "Ready. Next: .\SPOPERM-Discovery.ps1 -Url $Url -CsvPath .\audit.csv" -ForegroundColor Green
} else {
    Write-Host "Resolve the FAIL item(s) above before auditing/remediating." -ForegroundColor Yellow
}
