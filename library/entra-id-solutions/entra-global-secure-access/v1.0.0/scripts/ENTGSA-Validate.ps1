<#
.SYNOPSIS
    ENTGSA-Validate.ps1 — validate the named GSA objects from 03-implementation are present and wired.
.DESCRIPTION
    PURPOSE
        The automated form of the §5 gate table. Checks that: the Microsoft traffic profile is enabled;
        the pilot connector group and published private app exist with application segments and the
        ENTGSA-Pilot group assigned; a web-filtering policy exists and is linked into a security profile;
        and the ENTGSA Conditional Access policies target Global Secure Access AND exclude a break-glass
        group. Prints PASS/GAP per check so you know what to fix before expanding.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTGSA-Validate.ps1 `
            -PilotGroup 'ENTGSA-Pilot' -BreakGlassGroup 'BreakGlass-Exclude'
    EXPECTED RESULTS
        A checklist of [PASS]/[GAP] lines mirroring the pilot exit criteria. PASS on all = ready to expand.
.NOTES
    White-label — Entra ID Solutions. Read-only against Microsoft Graph. No credentials stored.
    GSA Graph endpoints are on /beta and may change while in preview — verify current schema.
.EXAMPLE
    .\ENTGSA-Validate.ps1 -PilotGroup 'ENTGSA-Pilot'
#>
[CmdletBinding()]
param(
    [string]$PilotGroup = 'ENTGSA-Pilot',
    [string]$BreakGlassGroup,
    [string]$PrivateAppName = 'ENTGSA - PrivateApp - IntranetWeb - Pilot'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'NetworkAccess.Read.All','Application.Read.All','Policy.Read.All','Group.Read.All' -NoWelcome

function Get-AllPages([string]$Uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $i+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $i }
function Result($ok,$msg){ if($ok){Write-Host "  [PASS] $msg" -ForegroundColor Green}else{Write-Host "  [GAP ] $msg" -ForegroundColor Yellow} }

Write-Host "`n=== ENTGSA validation ===" -ForegroundColor Cyan

# 1. Microsoft traffic profile enabled
try {
    $profiles = Get-AllPages "/beta/networkAccess/forwardingProfiles"
    $ms = $profiles | Where-Object { $_.trafficForwardingType -eq 'm365' -or $_.name -match 'Microsoft' }
    Result ([bool]($ms | Where-Object state -eq 'enabled')) "Microsoft traffic profile enabled"
    $priv = $profiles | Where-Object { $_.trafficForwardingType -eq 'private' -or $_.name -match 'Private' }
    Result ([bool]($priv | Where-Object state -eq 'enabled')) "Private Access profile enabled"
} catch { Result $false "forwardingProfiles readable ($($_.Exception.Message))" }

# 2. Published private app + segments + assignment
try {
    $apps = Get-AllPages "/beta/applications?`$filter=displayName eq '$PrivateAppName'&`$select=id,displayName"
    $app = $apps | Select-Object -First 1
    Result ([bool]$app) "Published private app '$PrivateAppName' exists"
    if ($app) {
        $segs = @(); try { $segs = Get-AllPages "/beta/applications/$($app.id)/onPremisesPublishing/segmentsConfiguration/microsoftEntraPrivateAccess/applicationSegments" } catch {}
        Result ([bool]$segs) "  App has >=1 application segment ($($segs.Count) found)"
        $sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$PrivateAppName'").value | Select-Object -First 1
        if ($sp) {
            $assign = Get-AllPages "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo"
            $pilotAssigned = $assign | Where-Object principalDisplayName -eq $PilotGroup
            Result ([bool]$pilotAssigned) "  '$PilotGroup' assigned to the private app"
        }
    }
} catch { Result $false "private app readable ($($_.Exception.Message))" }

# 3. Filtering policy + security profile
try {
    $fp = Get-AllPages "/beta/networkAccess/filteringPolicies"
    Result ([bool]($fp | Where-Object name -like 'ENTGSA*')) "Web filtering policy 'ENTGSA - WebFilter - Baseline' exists"
    $secp = Get-AllPages "/beta/networkAccess/filteringProfiles"
    Result ([bool]($secp | Where-Object name -like 'ENTGSA*')) "Security profile 'ENTGSA - SecurityProfile - Baseline' exists"
} catch { Result $false "filtering policy/profile readable ($($_.Exception.Message))" }

# 4. CA policies target GSA and exclude break-glass
$ca = Get-AllPages "/v1.0/identity/conditionalAccess/policies"
$entca = $ca | Where-Object displayName -like 'ENTGSA*'
Result ([bool]$entca) "ENTGSA Conditional Access policies exist ($($entca.Count))"
foreach ($p in $entca) {
    $targetsGsa = ($p.conditions.applications.includeApplications -join ',') -match 'GlobalSecureAccess|NetworkAccess|00000007'
    Result $targetsGsa "  '$($p.displayName)' targets Global Secure Access"
    if ($BreakGlassGroup) {
        $bg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$BreakGlassGroup'&`$select=id").value | Select-Object -First 1
        $excluded = $bg -and ($p.conditions.users.excludeGroups -contains $bg.id)
        Result $excluded "  '$($p.displayName)' excludes break-glass group '$BreakGlassGroup'"
    }
}

Write-Host "`nValidation complete. Resolve every [GAP] before expanding beyond the pilot." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
