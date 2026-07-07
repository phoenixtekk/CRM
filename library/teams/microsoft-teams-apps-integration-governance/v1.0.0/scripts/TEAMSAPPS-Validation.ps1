<#
.SYNOPSIS
    TEAMSAPPS-Validation.ps1 — read-only check that a user population is assigned the intended app permission + setup policies.
.DESCRIPTION
    PURPOSE
        Validates the governance rollout: for each user in a pilot group (or an explicit user list),
        confirms the effective app permission policy and app setup policy match the intended names, and
        summarises the permission policy's allow/block mode so you can confirm it allows only the vetted
        set. Read-only — makes no changes; this is the pilot pass/fail gate before org-wide expansion.
    HOW TO RUN
        .\TEAMSAPPS-Validation.ps1 -PolicyGroup 'App Governance Pilot - Users - Pilot' `
            -ExpectedPermissionPolicy 'App Permission Policy - Pilot - Pilot' `
            -ExpectedSetupPolicy 'App Setup Policy - Standard - Prod'
        (PowerShell 5.1+/7+; MicrosoftTeams module + Microsoft Graph SDK for group expansion)
        Connect: Connect-MicrosoftTeams; Connect-MgGraph -Scopes GroupMember.Read.All, User.Read.All
    EXPECTED RESULTS
        A per-user PASS/FAIL table (assigned vs expected permission and setup policy) and an overall
        gate result. No changes are made.
.NOTES
    Teams — Microsoft Teams Apps & Integration Governance. Read-only validation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyGroup,
    [string]$ExpectedPermissionPolicy = 'App Permission Policy - Pilot - Pilot',
    [string]$ExpectedSetupPolicy      = 'App Setup Policy - Standard - Prod',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) { Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module MicrosoftTeams -ErrorAction Stop
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MicrosoftTeams | Out-Null
Connect-MgGraph -Scopes 'GroupMember.Read.All','User.Read.All' -NoWelcome

Write-Host ("=== TEAMSAPPS Validation — group '{0}' (read-only) ===" -f $PolicyGroup) -ForegroundColor Cyan

# Confirm the expected policies exist and summarise the permission-policy allow mode.
$perm = Get-CsTeamsAppPermissionPolicy -Identity $ExpectedPermissionPolicy -ErrorAction SilentlyContinue
if ($perm) { Write-Host ('Permission policy "{0}": third-party={1}, custom={2}' -f $ExpectedPermissionPolicy, $perm.GlobalCatalogAppsType, $perm.PrivateCatalogAppsType) -ForegroundColor Cyan }
else { Write-Warning ('Expected permission policy "{0}" NOT FOUND' -f $ExpectedPermissionPolicy) }
if (-not (Get-CsTeamsAppSetupPolicy -Identity $ExpectedSetupPolicy -ErrorAction SilentlyContinue)) { Write-Warning ('Expected setup policy "{0}" NOT FOUND' -f $ExpectedSetupPolicy) }

# Resolve group members to UPNs.
$g = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id" -f ($PolicyGroup -replace "'","''"))).value | Select-Object -First 1
if (-not $g) { Write-Warning ("Group '{0}' not found — pass an explicit UPN list instead." -f $PolicyGroup); Disconnect-MgGraph | Out-Null; Disconnect-MicrosoftTeams | Out-Null; return }
$members = @()
$u = ("/v1.0/groups/{0}/members?`$select=userPrincipalName&`$top=999" -f $g.id)
do { $r = Invoke-MgGraphRequest -Method GET -Uri $u; $r.value | ForEach-Object { if ($_.userPrincipalName) { $members += $_.userPrincipalName } }; $u = $r.'@odata.nextLink' } while ($u)

$results = foreach ($upn in $members) {
    $assignPerm  = (Get-CsUserPolicyAssignment -Identity $upn -PolicyType TeamsAppPermissionPolicy -ErrorAction SilentlyContinue).PolicyName
    $assignSetup = (Get-CsUserPolicyAssignment -Identity $upn -PolicyType TeamsAppSetupPolicy      -ErrorAction SilentlyContinue).PolicyName
    $permOk  = ($assignPerm  -eq $ExpectedPermissionPolicy)
    $setupOk = ($assignSetup -eq $ExpectedSetupPolicy)
    [pscustomobject]@{
        User            = $upn
        PermissionPolicy = $assignPerm
        SetupPolicy      = $assignSetup
        Result           = if ($permOk -and $setupOk) { 'PASS' } else { 'FAIL' }
    }
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
Write-Host ('--- Gate: {0}/{1} users PASS ---' -f ($results.Count - $fail), $results.Count) -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Red' })
if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved to {0}" -f $CsvPath) -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
Disconnect-MicrosoftTeams | Out-Null
