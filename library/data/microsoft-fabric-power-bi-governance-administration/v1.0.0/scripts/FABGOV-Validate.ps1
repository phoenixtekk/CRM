<#
.SYNOPSIS
    FABGOV-Validate.ps1 — validate the Fabric/Power BI governance baseline against the intended model.
.DESCRIPTION
    PURPOSE
        Checks the governance state against the design in the implementation guide and reports pass/fail
        per check: (1) the lifecycle workspaces are on the expected capacity, (2) workspace roles are
        group-based only (no individual users), (3) the deployment pipeline stages are paired to the
        right workspaces. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FABGOV-Validate.ps1
        Optional overrides:
          -Capacity      'Fabric Capacity - Analytics - Prod'
          -WorkspacePrefix 'Sales BI - Content'
          -Pipeline      'Deployment Pipeline - Sales BI - DevTestProd'
        Requires MicrosoftPowerBIMgmt and the Fabric/Power BI Administrator role.
    EXPECTED RESULTS
        A PASS/FAIL line per check with the offending object named on any failure, and a non-zero exit
        code if any check fails (so it can gate a pipeline).
.NOTES
    Data — Fabric/Power BI Governance. Read-only against the Power BI admin REST APIs.
    White-label. Object names are parameters; defaults match the implementation guide.
#>
[CmdletBinding()]
param(
    [string]$Capacity = 'Fabric Capacity - Analytics - Prod',
    [string]$WorkspacePrefix = 'Sales BI - Content',
    [string]$Pipeline = 'Deployment Pipeline - Sales BI - DevTestProd'
)

if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop
try { Connect-PowerBIServiceAccount -ErrorAction Stop | Out-Null }
catch { Write-Host "Sign-in failed: $($_.Exception.Message)" -ForegroundColor Red; exit 2 }

$fail = 0
function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail)
    if ($Ok) { Write-Host ("PASS  {0}" -f $Name) -ForegroundColor Green }
    else { Write-Host ("FAIL  {0} :: {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}
function Get-PbiValue { param([string]$Uri)
    try { (Invoke-PowerBIRestMethod -Url $Uri -Method Get | ConvertFrom-Json).value } catch { @() }
}

# --- Resolve capacity ---
$caps = Get-PbiValue "admin/capacities"
$cap = $caps | Where-Object { $_.displayName -eq $Capacity }
Check "Capacity '$Capacity' exists and Active" ([bool]($cap -and $cap.state -eq 'Active')) "not found or not Active"

# --- Resolve the three lifecycle workspaces ---
$allWs = Get-PbiValue "admin/groups?`$top=5000&`$expand=users"
foreach ($stage in 'Dev','Test','Prod') {
    $wsName = "$WorkspacePrefix - $stage"
    $w = $allWs | Where-Object { $_.name -eq $wsName }
    Check "Workspace '$wsName' exists" ([bool]$w) "workspace not found"
    if (-not $w) { continue }

    # 5.4 capacity assignment (Test/Prod expected on the capacity)
    if ($stage -in 'Test','Prod') {
        $onCap = $w.isOnDedicatedCapacity -and $cap -and ($w.capacityId -eq $cap.id)
        Check "'$wsName' assigned to '$Capacity'" ([bool]$onCap) "not on the expected capacity"
    }

    # 5.3 roles must be group-based only (no individual user principals holding roles)
    $userPrincipals = $w.users | Where-Object { $_.principalType -eq 'User' }
    Check "'$wsName' roles are group-based only" ([bool](-not $userPrincipals)) `
        ("individual user(s) hold roles: " + (($userPrincipals | ForEach-Object { $_.identifier }) -join ', '))
}

# --- 5.5 deployment pipeline stage pairing ---
$pipes = Get-PbiValue "admin/pipelines?`$expand=stages"
$pipe = $pipes | Where-Object { $_.displayName -eq $Pipeline }
Check "Pipeline '$Pipeline' exists" ([bool]$pipe) "pipeline not found"
if ($pipe) {
    $expected = @{ 0 = "$WorkspacePrefix - Dev"; 1 = "$WorkspacePrefix - Test"; 2 = "$WorkspacePrefix - Prod" }
    foreach ($order in 0,1,2) {
        $stg = $pipe.stages | Where-Object { $_.order -eq $order }
        $wsForStage = $allWs | Where-Object { $_.id -eq $stg.workspaceId }
        $ok = $wsForStage -and ($wsForStage.name -eq $expected[$order])
        Check ("Pipeline stage $order paired to '{0}'" -f $expected[$order]) ([bool]$ok) `
            ("stage $order is paired to '" + ($wsForStage.name) + "'")
    }
}

Write-Host ""
if ($fail -eq 0) { Write-Host "All governance checks PASSED." -ForegroundColor Green }
else { Write-Host ("$fail check(s) FAILED — see above." ) -ForegroundColor Red }
Disconnect-PowerBIServiceAccount | Out-Null
exit ([int]([bool]$fail))
