<#
.SYNOPSIS
  Read-only validation / scope-health check of the Teams governance controls: creation control, naming,
  classification, expiration, ownership, and stale handling. Emits PASS/FAIL per gate. Makes NO changes.
.DESCRIPTION
  Confirms each governance control is configured as intended and reports the pilot/production scope health.
  Use after the Configure stage (against the pilot) and again after production expansion. Returns a
  non-zero exit code if any required gate fails, so it can gate a pipeline.
.EXAMPLE
  .\Test-TeamsGovernanceReadiness.ps1 -CreatorsGroupName "Group Creators - Governed - Pilot" -ExpectedExpirationDays 180
  (PowerShell 5.1+/7+, Microsoft.Graph + Microsoft.Graph.Beta; connect with Connect-MgGraph)
.NOTES
  Expected results: a PASS/FAIL line per gate (creation controlled, naming enforced, classification on,
  expiration active, ownership, stale handled) and an overall result. Read-only — safe to run anytime.
#>
[CmdletBinding()]
param(
    [string]$CreatorsGroupName,
    [int]$ExpectedExpirationDays,
    [int]$MinOwners = 2,
    [int]$StaleDays = 180
)

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Group.Read.All","Directory.Read.All","GroupMember.Read.All" | Out-Null
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Gate([string]$name, [bool]$pass, [string]$detail) {
    $results.Add([pscustomobject]@{ Gate = $name; Result = ($pass ? 'PASS' : 'FAIL'); Detail = $detail })
    $color = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} - {2}" -f ($pass ? 'PASS' : 'FAIL'), $name, $detail) -ForegroundColor $color
}

Write-Host "`n===== Teams governance validation gates =====" -ForegroundColor Yellow
$dir = Get-MgBetaDirectorySetting -All -ErrorAction SilentlyContinue | Where-Object DisplayName -eq 'Group.Unified'

# Gate 1: creation controlled
$enable  = if ($dir) { ($dir.Values | Where-Object Name -eq 'EnableGroupCreation').Value } else { 'true' }
$allowed = if ($dir) { ($dir.Values | Where-Object Name -eq 'GroupCreationAllowedGroupId').Value } else { $null }
Add-Gate 'Creation controlled' (($enable -eq 'false') -and [bool]$allowed) "EnableGroupCreation=$enable; allowedGroup=$([bool]$allowed)"

# Gate 1b: creators group matches expectation
if ($CreatorsGroupName) {
    $grp = Get-MgGroup -Filter "displayName eq '$CreatorsGroupName'" -All -ErrorAction SilentlyContinue
    Add-Gate 'Creators group bound' ($grp -and $grp.Id -eq $allowed) "expected '$CreatorsGroupName'"
}

# Gate 2: naming enforced
$naming = if ($dir) { ($dir.Values | Where-Object Name -eq 'PrefixSuffixNamingRequirement').Value } else { $null }
Add-Gate 'Naming enforced' ([bool]$naming) "PrefixSuffixNamingRequirement='$naming'"

# Gate 3: classification on
$labels = if ($dir) { ($dir.Values | Where-Object Name -eq 'EnableMIPLabels').Value } else { 'false' }
Add-Gate 'Classification enabled' ($labels -eq 'true') "EnableMIPLabels=$labels"

# Gate 4: expiration active
$life = Get-MgGroupLifecyclePolicy -ErrorAction SilentlyContinue
$expOk = [bool]$life
if ($ExpectedExpirationDays -and $life) { $expOk = ($life.GroupLifetimeInDays -eq $ExpectedExpirationDays) }
Add-Gate 'Expiration active' $expOk ("lifetime=$(if($life){$life.GroupLifetimeInDays}else{'none'}) scope=$(if($life){$life.ManagedGroupTypes}else{'n/a'})")

# Gate 5 & 6: ownership + stale (estate scan)
$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property "id,displayName,createdDateTime,renewedDateTime,resourceProvisioningOptions"
$now = Get-Date
$ownerless = 0; $stale = 0
foreach ($g in $groups) {
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All -ErrorAction SilentlyContinue).Count
    if ($owners -lt $MinOwners) { $ownerless++ }
    $lastTouch = if ($g.RenewedDateTime) { $g.RenewedDateTime } else { $g.CreatedDateTime }
    if ($lastTouch -and ([int]($now - $lastTouch).TotalDays) -ge $StaleDays) { $stale++ }
}
Add-Gate 'Ownership standard' ($ownerless -eq 0) "$ownerless team(s) below $MinOwners owners"
Add-Gate 'Stale handled'      ($stale -eq 0)     "$stale team(s) stale >= $StaleDays days"

# --- Overall ---
$failed = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host "`n===== RESULT =====" -ForegroundColor Yellow
if ($failed -eq 0) { Write-Host "ALL GATES PASS." -ForegroundColor Green }
else               { Write-Host "$failed gate(s) FAILED — do not expand until resolved." -ForegroundColor Red }
$results | Format-Table -AutoSize
if ($failed -gt 0) { exit 1 }
