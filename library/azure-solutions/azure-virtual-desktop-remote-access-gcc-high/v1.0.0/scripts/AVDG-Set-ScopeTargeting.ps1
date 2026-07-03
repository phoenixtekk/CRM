<#
.SYNOPSIS
    AVDG-Set-ScopeTargeting.ps1 — build/grow the AVD assignment group in controlled waves on Azure Government (GCC High). Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Manages the security group that scopes AVD access (for example 'AVD Users - Finance - Pilot') so you can
        expand the pilot in controlled waves. Ensures the group exists and adds the supplied users, previewing
        every change first. SAFE BY DEFAULT — runs in -WhatIf mode; pass -WhatIf:$false (or -Confirm) to apply.
        Replace placeholders like 'AVD Users - Finance - Pilot' and 'user@your-gov-domain' with your values.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\AVDG-Set-ScopeTargeting.ps1 -GroupName 'AVD Users - Finance - Pilot' -UserUpns 'user1@your-gov-domain','user2@your-gov-domain'
        Apply:             .\AVDG-Set-ScopeTargeting.ps1 -GroupName 'AVD Users - Finance - Pilot' -UserUpns 'user1@your-gov-domain' -WhatIf:$false
        Modules: Microsoft.Graph.Authentication, Microsoft.Graph.Groups, Microsoft.Graph.Users
        Sign-in (US Gov Graph): Connect-MgGraph -Environment USGov -Scopes 'Group.ReadWrite.All','User.Read.All'
    EXPECTED RESULTS
        In -WhatIf mode: a plan of the group to create/use and each user to add, no changes made. With -WhatIf:$false:
        the group exists and the listed users are members, with confirmation output. Re-validate after each wave.
.NOTES
    White-label — the repeatable way. Uses Microsoft Graph US Gov endpoints; write actions gated by -WhatIf/-Confirm.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)][string]$GroupName,
    [Parameter(Mandatory = $true)][string[]]$UserUpns,
    [string]$GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $PSBoundParameters.ContainsKey('Confirm')) {
    $WhatIfPreference = $true
    Write-Host '[SAFE MODE] No -WhatIf/-Confirm supplied; running in -WhatIf (preview) mode. Pass -WhatIf:$false to apply.' -ForegroundColor Yellow
}
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Write-Section 'Connect (Microsoft Graph — US Gov)'
try {
    if (-not (Get-MgContext)) { Connect-MgGraph -Environment $GraphEnvironment -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome -ErrorAction Stop }
    $mg = Get-MgContext
    Write-Host "Graph environment: $($mg.Environment) | Account: $($mg.Account)"
    if ($mg.Environment -ne 'USGov') { Write-Host "[WARN] Graph environment is '$($mg.Environment)', expected USGov. Disconnect-MgGraph and reconnect with -Environment USGov." -ForegroundColor Yellow }
} catch { Write-Host "[FAIL] Graph sign-in failed: $($_.Exception.Message)" -ForegroundColor Red; return }

Write-Section "Ensure group '$GroupName'"
$group = $null
try { $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
if ($group) {
    Write-Host "[EXISTS] Group '$GroupName' found (Id: $($group.Id))." -ForegroundColor Green
} else {
    $mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '').ToLower()
    if ($PSCmdlet.ShouldProcess("Entra (US Gov): $GroupName", 'Create security group')) {
        $group = New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true -Description 'AVD access scope group (managed by AVDG-Set-ScopeTargeting.ps1)'
        Write-Host "[APPLIED] Created group '$GroupName' (Id: $($group.Id))." -ForegroundColor Green
    } else {
        Write-Host "[WHATIF] Would create security group '$GroupName'." -ForegroundColor Yellow
    }
}

Write-Section 'Add users (wave)'
foreach ($upn in $UserUpns) {
    try {
        $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $user) { Write-Host "[SKIP] User '$upn' not found in the Gov tenant." -ForegroundColor Yellow; continue }
        $isMember = $false
        if ($group -and $group.Id) {
            try { $isMember = [bool](Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $user.Id }) } catch {}
        }
        if ($isMember) { Write-Host "[SKIP] '$upn' already a member." -ForegroundColor Green; continue }
        if ($PSCmdlet.ShouldProcess("Group: $GroupName", "Add member '$upn'")) {
            if ($group -and $group.Id) {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                Write-Host "[APPLIED] Added '$upn'." -ForegroundColor Green
            } else { Write-Host "[WHATIF] Would add '$upn' (group would be created first)." -ForegroundColor Yellow }
        } else {
            Write-Host "[WHATIF] Would add '$upn' to '$GroupName'." -ForegroundColor Yellow
        }
    } catch { Write-Host "[ERROR] '$upn': $($_.Exception.Message)" -ForegroundColor Red }
}

Write-Section 'Scope targeting complete'
if ($WhatIfPreference) { Write-Host 'Preview only — no changes were made. Re-run with -WhatIf:$false to apply this wave.' -ForegroundColor Yellow }
else { Write-Host "Wave applied. Confirm the group is assigned to the AVD application group, then re-run AVDG-Validation.ps1." }
