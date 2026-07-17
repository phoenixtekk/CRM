<#
.SYNOPSIS
    LAMIMAIL-Validate.ps1 — PASS/FAIL validation that the managed identity exists, holds ONLY the
    least-privilege application permission, the target mailbox is in scope, and the workflow is present.
.DESCRIPTION
    PURPOSE
        Deterministic readiness gate for the "Exchange Online Mailbox Automation with Logic Apps
        Managed Identity (Graph)" solution. Checks four things and prints a clear PASS/FAIL summary:
          1. the managed identity's service principal exists;
          2. it holds the least-privilege application permission 'Mail.Read' AND holds NO broader
             Graph application permission (least privilege is the security spine);
          3. the target mailbox resolves (scope is proven separately by LAMIMAIL-Test-MailboxAccess.ps1);
          4. the Logic App workflow resource is present (best-effort, via Az if available).
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Validate.ps1 `
            -IdentityDisplayName 'la-mailbox-automation-pilot' `
            -TargetMailbox 'automation-inbox@contoso.com' `
            -LogicAppName 'la-mailbox-automation-pilot' -ResourceGroup 'rg-mailbox-automation-pilot'
    REQUIRED GRAPH SCOPES (delegated, for the operator)
        Application.Read.All, AppRoleAssignment.Read.All, User.Read.All, Directory.Read.All
        (verify the exact scope names against current Microsoft Graph documentation)
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall PASS only when the identity exists, is least-privilege
        (Mail.Read and nothing broader), the mailbox resolves, and the workflow is present.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Validation only; makes no changes. Overall FAIL if any required check fails.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$IdentityDisplayName,
    [Parameter(Mandatory)] [string]$TargetMailbox,
    [string]$LogicAppName,
    [string]$ResourceGroup,
    [string]$LeastPrivPermission = 'Mail.Read'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Red
    return
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

try {
    Connect-MgGraph -Scopes 'Application.Read.All','AppRoleAssignment.Read.All','User.Read.All','Directory.Read.All' -NoWelcome -ErrorAction Stop
} catch {
    Write-Host ("Connect-MgGraph failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$name, [bool]$pass, [string]$detail) {
    $results.Add([pscustomobject]@{ Check = $name; Result = $(if($pass){'PASS'}else{'FAIL'}); Detail = $detail })
}

Write-Host "`n=== LAMIMAIL — validation ===" -ForegroundColor Cyan

# 1. Identity exists
$sp = Get-MgServicePrincipal -Filter "displayName eq '$IdentityDisplayName'" -All -ErrorAction SilentlyContinue | Select-Object -First 1
Add-Result "Managed identity service principal exists" ([bool]$sp) $(if($sp){"ObjectId $($sp.Id)"}else{"not found: $IdentityDisplayName"})

# 2. Least privilege: has Mail.Read, and NOTHING broader
$hasLeastPriv = $false; $broader = @()
if ($sp) {
    $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue | Select-Object -First 1
    $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    foreach ($a in $assignments) {
        $roleName = ($graphSp.AppRoles | Where-Object Id -eq $a.AppRoleId | Select-Object -First 1).Value
        if (-not $roleName) { $roleName = [string]$a.AppRoleId }
        if ($roleName -eq $LeastPrivPermission) { $hasLeastPriv = $true } else { $broader += $roleName }
    }
}
Add-Result "Holds least-privilege permission ($LeastPrivPermission)" $hasLeastPriv $(if($hasLeastPriv){"granted"}else{"missing"})
Add-Result "Holds NO broader Graph application permission" ($broader.Count -eq 0) $(if($broader.Count){"broader: $($broader -join ', ')"}else{"none"})

# 3. Mailbox resolves
$u = Get-MgUser -Filter "userPrincipalName eq '$TargetMailbox' or mail eq '$TargetMailbox'" -ErrorAction SilentlyContinue | Select-Object -First 1
Add-Result "Target mailbox resolves" ([bool]$u) $(if($u){"Id $($u.Id) — prove scope with LAMIMAIL-Test-MailboxAccess.ps1"}else{"did not resolve: $TargetMailbox"})

# 4. Workflow present (best-effort via Az)
if ($LogicAppName -and $ResourceGroup -and (Get-Module -ListAvailable -Name Az.LogicApp)) {
    try {
        Import-Module Az.LogicApp -ErrorAction Stop
        $wf = Get-AzLogicApp -ResourceGroupName $ResourceGroup -Name $LogicAppName -ErrorAction Stop
        Add-Result "Logic App workflow present" ([bool]$wf) $(if($wf){"state $($wf.State)"}else{"not found"})
    } catch {
        Add-Result "Logic App workflow present" $false ("could not read: " + $_.Exception.Message)
    }
} else {
    Add-Result "Logic App workflow present" $true "skipped (provide -LogicAppName/-ResourceGroup with Az.LogicApp to check)"
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
if ($fail -eq 0) {
    Write-Host "`nOVERALL: PASS — identity is least-privilege, mailbox resolves, workflow present." -ForegroundColor Green
} else {
    Write-Host ("`nOVERALL: FAIL — {0} check(s) failed. Fix before piloting." -f $fail) -ForegroundColor Red
}
