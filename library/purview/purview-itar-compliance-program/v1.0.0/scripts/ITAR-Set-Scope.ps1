<#
.SYNOPSIS
    ITAR-Set-Scope.ps1 — build/update the 'ITAR - Authorized Persons Pilot' Entra group (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates or updates the Microsoft Entra security group used to pilot and then expand the ITAR
        program ('ITAR - Authorized Persons Pilot') and, optionally, adds a supplied list of AUTHORIZED
        U.S. PERSONS. This is the scope the label/DLP/retention controls target; membership must never be
        widened beyond authorized U.S. persons (an export-control/HR determination). Runs in -WhatIf by
        default; pass -Apply to make changes. It never deletes the group or removes members.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\ITAR-Set-Scope.ps1
        Apply (create/update):   powershell -ExecutionPolicy Bypass -File .\ITAR-Set-Scope.ps1 -Apply
        Add members:             .\ITAR-Set-Scope.ps1 -Apply -Members user1@contoso.com,user2@contoso.com
        Sign in with a Groups Administrator (or better) when Connect-MgGraph prompts.
    EXAMPLE
        .\ITAR-Set-Scope.ps1 -WhatIf
    EXPECTED RESULTS
        Reports whether the group exists and what would change (WhatIf) or creates/updates it (-Apply),
        then reports membership. Only add users export-control/HR has confirmed are authorized U.S. persons.
.NOTES
    White-label — Purview Solutions. Default is a dry run. PowerShell 5.1+/7+.
    Microsoft Graph: Group.ReadWrite.All (+ User.Read.All to resolve members). No credentials in code.
#>
[CmdletBinding()] param(
    [string]  $GroupName    = 'ITAR - Authorized Persons Pilot',
    [string]  $MailNickname = 'itar-authorized-persons-pilot',
    [string[]]$Members,
    [switch]  $Apply,
    [switch]  $WhatIf
)
$doApply = $Apply -and -not $WhatIf
$mode = $(if($doApply){'APPLY'}else{'WHATIF (preview only)'})

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Import-Module Microsoft.Graph.Users  -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host ("`n=== Microsoft Purview ITAR — authorized-persons pilot group [{0}] ===" -f $mode) -ForegroundColor Cyan
Write-Host "  REMINDER: only add users confirmed as AUTHORIZED U.S. PERSONS (export-control/HR determination)." -ForegroundColor Yellow

# 1. Find or create the group
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($group) {
    Write-Host ("  Group '{0}' already exists (Id {1})." -f $GroupName, $group.Id) -ForegroundColor Green
} else {
    Write-Host ("  Group '{0}' not found -> would create a security group." -f $GroupName) -ForegroundColor Yellow
    if ($doApply) {
        $group = New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $MailNickname `
            -SecurityEnabled:$true -Description 'Authorized-U.S.-person pilot scope for the Microsoft Purview ITAR program.'
        Write-Host ("    created (Id {0})." -f $group.Id) -ForegroundColor Green
    }
}

# 2. Optionally add members (never removes)
if ($Members -and $group) {
    Write-Host "`n  Members to ensure present (must be authorized U.S. persons):" -ForegroundColor Cyan
    foreach ($m in $Members) {
        $user = Get-MgUser -Filter "userPrincipalName eq '$m'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $user) { Write-Host ("    {0} — not found, skipping." -f $m) -ForegroundColor Yellow; continue }
        $already = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $user.Id }
        if ($already) { Write-Host ("    {0} — already a member." -f $m) -ForegroundColor Green }
        else {
            Write-Host ("    {0} — would add." -f $m) -ForegroundColor Yellow
            if ($doApply) { New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id; Write-Host "      added." -ForegroundColor Green }
        }
    }
} elseif ($group) {
    Write-Host "`n  (No -Members supplied — group ensured only; add authorized U.S. persons with -Members.)" -ForegroundColor DarkGray
}

# 3. Report current membership
if ($group) {
    $count = @(Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue).Count
    Write-Host ("`n  Current membership count: {0}" -f $count) -ForegroundColor Cyan
}

if ($doApply) { Write-Host "`nDone. Target this group as the pilot scope in the label/DLP/retention policies — never widen beyond authorized persons." -ForegroundColor Green }
else          { Write-Host "`nPreview only. Re-run with -Apply to create/update the group and add authorized U.S. persons." -ForegroundColor Cyan }

Disconnect-MgGraph | Out-Null
