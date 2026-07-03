<#
.SYNOPSIS
    DCPG-Set-ScopeTargeting.ps1 — build/grow the pilot and wave target groups for GCC High rollout (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Previews and (only with -Commit) creates or grows the Microsoft Entra security
        groups used to scope the Device Compliance Policies (GCC High) rollout — the pilot
        group and optional expansion-wave groups — and adds specified members. This keeps
        the Assess -> Pilot -> Expand scoping consistent and repeatable. Connects to US Gov
        Graph. DEFAULTS TO -WhatIf — nothing changes unless you pass -Commit.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DCPG-Set-ScopeTargeting.ps1
        (previews only; add -Commit to apply)
        (Graph scopes: Group.ReadWrite.All, User.Read.All; -Environment USGov)
        Add members: -MemberUpns 'user1@contoso.us','user2@contoso.us'
        Different group: -GroupName 'SG-Compliance-Wave1'
    EXPECTED RESULTS
        In preview (default): the group that WOULD be created and members that WOULD be
        added, each prefixed [WHATIF]. With -Commit: the group is created if missing and
        members added, reported [APPLIED]. Existing members are skipped (idempotent).
.NOTES
    White-label — the repeatable way. Read-only planning by default; changes only with -Commit,
    against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$GroupName = 'SG-Compliance-Pilot',
    [string]$GroupDescription = 'Device compliance pilot/wave targeting group (GCC High).',

    [string[]]$MemberUpns = @(),

    # Safety: default is preview-only. Pass -Commit to actually apply.
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
$WhatIfMode = -not $Commit

function Write-Plan {
    param([string]$Message)
    $tag = if ($WhatIfMode) { '[WHATIF]' } else { '[APPLIED]' }
    $color = if ($WhatIfMode) { 'Yellow' } else { 'Green' }
    Write-Host "$tag $Message" -ForegroundColor $color
}

function New-MailNickname {
    param([string]$Name)
    # Entra mailNickname: no spaces or special chars.
    return ($Name -replace '[^a-zA-Z0-9]', '')
}

try {
    $scopes = @('Group.ReadWrite.All', 'User.Read.All')
    Write-Host "Connecting to Microsoft Graph (Environment: $Environment)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Environment -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne $Environment) {
        throw "Connected to '$($ctx.Environment)', expected '$Environment'. Reconnect with -Environment $Environment."
    }
    Write-Host "Connected. Environment: $($ctx.Environment)" -ForegroundColor Green
    if ($WhatIfMode) {
        Write-Host "MODE: PREVIEW (-WhatIf). No changes will be made. Re-run with -Commit to apply.`n" -ForegroundColor Yellow
    } else {
        Write-Host "MODE: COMMIT. Changes WILL be applied.`n" -ForegroundColor Red
    }

    # Find or plan the group.
    $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -Property 'id,displayName' -ErrorAction SilentlyContinue
    if ($group) {
        Write-Host "Group '$GroupName' already exists ($($group.Id))." -ForegroundColor Cyan
    } else {
        Write-Plan "Create security group '$GroupName'."
        if (-not $WhatIfMode) {
            $group = New-MgGroup -DisplayName $GroupName `
                -Description $GroupDescription `
                -MailEnabled:$false `
                -MailNickname (New-MailNickname $GroupName) `
                -SecurityEnabled:$true `
                -ErrorAction Stop
            Write-Host "Created group '$GroupName' ($($group.Id))." -ForegroundColor Green
        }
    }

    # Plan/add members.
    if ($MemberUpns.Count -gt 0) {
        foreach ($upn in $MemberUpns) {
            $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -Property 'id,userPrincipalName' -ErrorAction SilentlyContinue
            if (-not $user) {
                Write-Host "  - User '$upn' not found; skipping." -ForegroundColor Red
                continue
            }

            $alreadyMember = $false
            if ($group -and -not $WhatIfMode -or ($group -and $group.Id)) {
                try {
                    $existing = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
                    $alreadyMember = [bool]($existing | Where-Object { $_.Id -eq $user.Id })
                } catch { $alreadyMember = $false }
            }

            if ($alreadyMember) {
                Write-Host "  - '$upn' is already a member; skipping." -ForegroundColor DarkGray
                continue
            }

            Write-Plan "Add member '$upn' to '$GroupName'."
            if (-not $WhatIfMode -and $group -and $group.Id) {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction Stop
            }
        }
    } else {
        Write-Host "(No -MemberUpns supplied; group membership unchanged.)" -ForegroundColor DarkGray
    }

    if ($WhatIfMode) {
        Write-Host "`nPreview complete. Re-run with -Commit to apply." -ForegroundColor Yellow
    } else {
        Write-Host "`nDone. Assign policy '$GroupName' in Intune, then validate with DCPG-Validation.ps1." -ForegroundColor Green
    }
}
finally {
    if (Get-MgContext) { Disconnect-MgGraph | Out-Null; Write-Host "`nDisconnected from Microsoft Graph." -ForegroundColor DarkGray }
}
