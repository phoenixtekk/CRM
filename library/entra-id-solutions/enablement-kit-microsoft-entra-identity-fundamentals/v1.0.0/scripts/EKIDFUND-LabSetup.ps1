<#
.SYNOPSIS
    EKIDFUND-LabSetup.ps1 — create (or remove) the cloud-only Identity-Fundamentals lab sandbox.
.DESCRIPTION
    PURPOSE
        Stands up a small, clearly-named, CLOUD-ONLY lab sandbox so learners practice on disposable
        test objects instead of production identities: the practice team group
        Grp-EntraFund-LabTeam-Pilot, the dynamic group Grp-EntraFund-DynamicDept-Pilot (rule
        user.department -eq "LabDept"), the cloud-only test user Lab-EntraFund-User1, and the app
        registration App-EntraFund-LabApp-Pilot. Every object is named for one-command teardown.
        This is the ONLY write script in the kit — it defaults to -WhatIf (preview) and changes
        nothing until you re-run with -WhatIf:$false. -Remove tears the sandbox down (also preview by
        default). It never touches any object it did not create by these exact names.
    HOW TO RUN
        Preview what would be created (default, no changes):
            pwsh -File .\EKIDFUND-LabSetup.ps1
        Create the sandbox after review:
            pwsh -File .\EKIDFUND-LabSetup.ps1 -WhatIf:$false
        Use your real initial domain (default contoso.onmicrosoft.com placeholder):
            pwsh -File .\EKIDFUND-LabSetup.ps1 -Domain yourtenant.onmicrosoft.com -WhatIf:$false
        Tear the sandbox down (preview first, then apply):
            pwsh -File .\EKIDFUND-LabSetup.ps1 -Remove
            pwsh -File .\EKIDFUND-LabSetup.ps1 -Remove -WhatIf:$false
        Consents to Group.ReadWrite.All, User.ReadWrite.All, Application.ReadWrite.All, Directory.Read.All.
        Government cloud: pass -Environment USGov (or USGovDoD).
    EXPECTED RESULTS
        In preview: the sandbox objects that WOULD be created (or removed) and nothing else. When
        applied: the four cloud-only sandbox objects exist (or are gone). Fully reversible via -Remove.
.NOTES
    White-label — Entra ID Solutions. Write action — preview (-WhatIf) by default. Cloud-only sandbox
    objects ONLY; never touches production identities. No credentials in code.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$Domain = 'contoso.onmicrosoft.com',
    [switch]$Remove,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.ReadWrite.All','Application.ReadWrite.All','Directory.Read.All' -Environment $Environment -NoWelcome

$TeamGroup    = 'Grp-EntraFund-LabTeam-Pilot'
$DynGroup     = 'Grp-EntraFund-DynamicDept-Pilot'
$TestUserUpn  = "lab-entrafund-user1@$Domain"
$TestUserName = 'Lab-EntraFund-User1'
$AppName      = 'App-EntraFund-LabApp-Pilot'

function Get-GroupByName($n){ (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$n'").value | Select-Object -First 1 }
function Get-UserByUpn($u){  (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userPrincipalName eq '$u'").value | Select-Object -First 1 }
function Get-AppByName($n){  (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/applications?`$filter=displayName eq '$n'").value | Select-Object -First 1 }

if ($Remove) {
    Write-Host "`n=== Remove Identity-Fundamentals lab sandbox — $(Get-Date -Format s) ===" -ForegroundColor Cyan
    foreach ($item in @(
        @{ Type='App';   Name=$AppName;     Obj=(Get-AppByName $AppName) },
        @{ Type='User';  Name=$TestUserUpn; Obj=(Get-UserByUpn $TestUserUpn) },
        @{ Type='Group'; Name=$DynGroup;    Obj=(Get-GroupByName $DynGroup) },
        @{ Type='Group'; Name=$TeamGroup;   Obj=(Get-GroupByName $TeamGroup) }
    )) {
        if (-not $item.Obj) { Write-Host ("  not present: {0}" -f $item.Name) -ForegroundColor DarkGray; continue }
        $uri = switch ($item.Type) { 'App' {"/v1.0/applications/$($item.Obj.id)"} 'User' {"/v1.0/users/$($item.Obj.id)"} 'Group' {"/v1.0/groups/$($item.Obj.id)"} }
        if ($PSCmdlet.ShouldProcess($item.Name, "Delete lab $($item.Type)")) {
            Invoke-MgGraphRequest -Method DELETE -Uri $uri | Out-Null
            Write-Host ("  REMOVED: {0}" -f $item.Name) -ForegroundColor Green
        } else { Write-Host ("  [WhatIf] would remove: {0}" -f $item.Name) -ForegroundColor Yellow }
    }
    Disconnect-MgGraph | Out-Null; return
}

Write-Host "`n=== Create Identity-Fundamentals lab sandbox (cloud-only) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# 1) Practice team group (assigned)
if (Get-GroupByName $TeamGroup) { Write-Host ("  exists: {0}" -f $TeamGroup) -ForegroundColor DarkGray }
elseif ($PSCmdlet.ShouldProcess($TeamGroup,'Create assigned security group')) {
    $b = @{ displayName=$TeamGroup; mailEnabled=$false; mailNickname='grpEntraFundLabTeam'; securityEnabled=$true }
    Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($b|ConvertTo-Json) | Out-Null
    Write-Host ("  CREATED group: {0}" -f $TeamGroup) -ForegroundColor Green
} else { Write-Host ("  [WhatIf] would create group: {0}" -f $TeamGroup) -ForegroundColor Yellow }

# 2) Dynamic group (rule-driven)
if (Get-GroupByName $DynGroup) { Write-Host ("  exists: {0}" -f $DynGroup) -ForegroundColor DarkGray }
elseif ($PSCmdlet.ShouldProcess($DynGroup,'Create dynamic security group')) {
    $b = @{ displayName=$DynGroup; mailEnabled=$false; mailNickname='grpEntraFundDynDept'; securityEnabled=$true;
            groupTypes=@('DynamicMembership'); membershipRule='user.department -eq "LabDept"'; membershipRuleProcessingState='On' }
    try { Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($b|ConvertTo-Json) | Out-Null
          Write-Host ("  CREATED dynamic group: {0}" -f $DynGroup) -ForegroundColor Green }
    catch { Write-Host ("  NOTE: dynamic membership needs Entra ID P1 — {0}. Verify licensing." -f $_.Exception.Message) -ForegroundColor Yellow }
} else { Write-Host ("  [WhatIf] would create dynamic group: {0} (rule: user.department -eq ""LabDept"")" -f $DynGroup) -ForegroundColor Yellow }

# 3) Cloud-only test user
if (Get-UserByUpn $TestUserUpn) { Write-Host ("  exists: {0}" -f $TestUserUpn) -ForegroundColor DarkGray }
elseif ($PSCmdlet.ShouldProcess($TestUserUpn,'Create cloud-only test user')) {
    $pw = -join ((65..90)+(97..122)+(48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    $b = @{ accountEnabled=$true; displayName=$TestUserName; mailNickname='labEntraFundUser1';
            userPrincipalName=$TestUserUpn; passwordProfile=@{ forceChangePasswordNextSignIn=$true; password=("Aa1!"+$pw) } }
    Invoke-MgGraphRequest -Method POST -Uri '/v1.0/users' -Body ($b|ConvertTo-Json) | Out-Null
    Write-Host ("  CREATED user: {0} (random password, must change at first sign-in)" -f $TestUserUpn) -ForegroundColor Green
} else { Write-Host ("  [WhatIf] would create user: {0}" -f $TestUserUpn) -ForegroundColor Yellow }

# 4) App registration (to teach registration vs enterprise-app)
if (Get-AppByName $AppName) { Write-Host ("  exists: {0}" -f $AppName) -ForegroundColor DarkGray }
elseif ($PSCmdlet.ShouldProcess($AppName,'Create app registration')) {
    $b = @{ displayName=$AppName; signInAudience='AzureADMyOrg' }
    Invoke-MgGraphRequest -Method POST -Uri '/v1.0/applications' -Body ($b|ConvertTo-Json) | Out-Null
    Write-Host ("  CREATED app registration: {0} (see its enterprise-app in Enterprise applications — Lab 5)" -f $AppName) -ForegroundColor Green
} else { Write-Host ("  [WhatIf] would create app registration: {0}" -f $AppName) -ForegroundColor Yellow }

Write-Host "`nSandbox is cloud-only and disposable. Tear down with:  EKIDFUND-LabSetup.ps1 -Remove -WhatIf:`$false" -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
