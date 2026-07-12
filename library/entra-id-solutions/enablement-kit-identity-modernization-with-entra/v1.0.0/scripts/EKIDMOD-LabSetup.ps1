<#
.SYNOPSIS
    EKIDMOD-LabSetup.ps1 — Safe, preview-first helper to create/remove the pilot lab scope.
.DESCRIPTION
    PURPOSE
        Create (or tear down) the enablement-lab scaffolding: the security group
        'Identity Modernization - Pilot - Lab' and a few cloud-only sample users, then add the users
        to the group. This is the ONLY change-making script in the kit and it is gated.
    HOW TO RUN
        .\EKIDMOD-LabSetup.ps1            # PREVIEW (-WhatIf): shows what it would do, changes nothing
        .\EKIDMOD-LabSetup.ps1 -Commit    # actually creates the group + sample users
        .\EKIDMOD-LabSetup.ps1 -Remove    # PREVIEW removal; add -Commit to actually delete
        Sign in when prompted. Use ONLY in a lab/non-production or strictly pilot-scoped tenant.
    EXPECTED RESULTS
        Preview mode: a list of intended actions, no changes. Commit mode: the group and sample users
        exist (or are removed). Never touches real users or break-glass accounts.
.NOTES
    White-label. Change-making but preview/-WhatIf by default and clearly gated. Lab use only.
#>
[CmdletBinding()] param(
    [switch]$Commit,
    [switch]$Remove,
    [string]$PilotGroupName = 'Identity Modernization - Pilot - Lab',
    [int]$SampleUserCount = 3,
    [string]$UserPrefix = 'labuser',
    [string]$InitialPassword = ('Lab!' + [guid]::NewGuid().ToString('N').Substring(0,10))
)

$ErrorActionPreference = 'Stop'
$preview = -not $Commit
$tag = $(if($preview){'[PREVIEW]'}else{'[COMMIT]'})
Write-Host "`n=== Identity Modernization — Lab Setup $tag ===" -ForegroundColor Cyan
if ($preview) { Write-Host "Preview mode: no changes will be made. Add -Commit to apply." -ForegroundColor Yellow }

try { Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.ReadWrite.All','Directory.ReadWrite.All' -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }

$domain = (Get-MgDomain -All | Where-Object { $_.IsInitial }).Id
if (-not $domain) { $domain = (Get-MgDomain -All | Select-Object -First 1).Id }

# resolve group
$grp = Get-MgGroup -All | Where-Object { $_.DisplayName -replace '[–—-]','-' -eq ($PilotGroupName -replace '[–—-]','-') } | Select-Object -First 1

if ($Remove) {
    Write-Host "Would remove sample users '$UserPrefix*@$domain' and group '$PilotGroupName'." -ForegroundColor Yellow
    if (-not $preview) {
        for ($i=1;$i -le $SampleUserCount;$i++){ $upn="$UserPrefix$i@$domain"; $u=Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue; if($u){ Remove-MgUser -UserId $u.Id; Write-Host "  removed $upn" } }
        if ($grp) { Remove-MgGroup -GroupId $grp.Id; Write-Host "  removed group '$PilotGroupName'" }
    }
    Write-Host "Done ($tag)." -ForegroundColor Cyan; return
}

# create group
if (-not $grp) {
    Write-Host "Would create security group: '$PilotGroupName'" -ForegroundColor Yellow
    if (-not $preview) {
        $mailNick = ($PilotGroupName -replace '[^a-zA-Z0-9]','')
        $grp = New-MgGroup -DisplayName $PilotGroupName -MailEnabled:$false -SecurityEnabled:$true -MailNickname $mailNick
        Write-Host "  created group id $($grp.Id)" -ForegroundColor Green
    }
} else { Write-Host "Group already exists: '$PilotGroupName'" -ForegroundColor Green }

# create sample users + add to group
for ($i=1; $i -le $SampleUserCount; $i++) {
    $upn = "$UserPrefix$i@$domain"
    $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if ($existing) { Write-Host "  user exists: $upn" -ForegroundColor Green; $uid=$existing.Id }
    else {
        Write-Host "Would create cloud user: $upn" -ForegroundColor Yellow
        if (-not $preview) {
            $pp = @{ ForceChangePasswordNextSignIn=$true; Password=$InitialPassword }
            $u = New-MgUser -DisplayName "Lab User $i" -UserPrincipalName $upn -AccountEnabled:$true -MailNickname "$UserPrefix$i" -PasswordProfile $pp
            $uid=$u.Id; Write-Host "  created $upn" -ForegroundColor Green
        }
    }
    if (-not $preview -and $grp -and $uid) {
        try { New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $uid -ErrorAction Stop; Write-Host "  added $upn to group" } catch { Write-Host "  (already a member or add skipped)" }
    }
}

if (-not $preview) { Write-Host "`nInitial password for created users: $InitialPassword (change on first sign-in)." -ForegroundColor Cyan }
Write-Host "Done ($tag). Next: EKIDMOD-Validate.ps1" -ForegroundColor Cyan
