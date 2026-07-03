<#
.SYNOPSIS
    M365SECG-Set-ScopeTargeting.ps1 — preview-first builder for pilot/wave target groups on GCC High.
.DESCRIPTION
    PURPOSE
        Creates and populates the security group used to scope baseline changes on a Microsoft 365 GCC
        High tenant (default: the pilot group), and can add members from a supplied list of user
        principal names. Defaults to -WhatIf (preview only) — it changes nothing until you re-run with
        -Execute. Set your own values for placeholders such as your-pilot-group-name and
        your-user-upn.
    HOW TO RUN
        Preview : powershell -ExecutionPolicy Bypass -File .\M365SECG-Set-ScopeTargeting.ps1 -GroupName "SEC-Baseline-Pilot" -MemberUpns "user1@your-domain.us","user2@your-domain.us"
        Apply   : powershell -ExecutionPolicy Bypass -File .\M365SECG-Set-ScopeTargeting.ps1 -GroupName "SEC-Baseline-Pilot" -MemberUpns "user1@your-domain.us" -Execute
        (Graph scopes: Group.ReadWrite.All, User.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        In -WhatIf (default): a preview of the group that would be created and the members that would
        be added, with NO change. With -Execute: the group exists and the listed members are added.
        PASS = preview matches your intended pilot/wave scope; then execute deliberately.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; targets Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$GroupName = "SEC-Baseline-Pilot",
    [string[]]$MemberUpns = @(),
    [string]$GroupDescription = "Pilot/wave scope for M365 security baseline changes (GCC High).",
    [switch]$Execute,                 # default OFF => -WhatIf/preview only
    [string]$Environment = "USGov"
)

$ErrorActionPreference = "Stop"
$WhatIf = -not $Execute

function Connect-USGovGraph {
    param([string[]]$Scopes, [string]$Env)
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env / GCC High = https://graph.microsoft.us)..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
        $ctx = Get-MgContext
    }
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. Reconnect with -Environment $Env (GCC High must not use Commercial)."
    }
    return $ctx
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}

Write-Host "==================================================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host " MODE: PREVIEW (-WhatIf).  No changes will be made." -ForegroundColor Yellow
    Write-Host " Re-run with -Execute to apply, after reviewing this preview." -ForegroundColor Yellow
} else {
    Write-Host " MODE: EXECUTE.  The group/members WILL be created on the GCC High tenant." -ForegroundColor Red
}
Write-Host "==================================================================" -ForegroundColor Cyan

$scopes = @("Group.ReadWrite.All","User.Read.All")
$ctx = Connect-USGovGraph -Scopes $scopes -Env $Environment
Write-Host "Connected. Environment = $($ctx.Environment); Tenant = $($ctx.TenantId)" -ForegroundColor Green

# Resolve or plan group
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($group) {
    Write-Host "`nGroup '$GroupName' already exists ($($group.Id))." -ForegroundColor Green
} else {
    Write-Host "`n[CREATE] Security group '$GroupName'" -ForegroundColor Cyan
    Write-Host "         Description: $GroupDescription"
    if ($WhatIf) {
        Write-Host "         PREVIEW ONLY - not created." -ForegroundColor Yellow
    } else {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]','').ToLower()
        $group = New-MgGroup -DisplayName $GroupName -Description $GroupDescription `
            -MailEnabled:$false -MailNickname $mailNick -SecurityEnabled:$true
        Write-Host "         CREATED ($($group.Id))." -ForegroundColor Green
    }
}

# Members
if ($MemberUpns.Count -gt 0) {
    Write-Host "`nMembers to add:" -ForegroundColor Cyan
    foreach ($upn in $MemberUpns) {
        $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $user) {
            Write-Host "  SKIP  $upn (user not found in this GCC High tenant)" -ForegroundColor Yellow
            continue
        }
        Write-Host ("  ADD   {0}" -f $upn)
        if ($WhatIf) {
            Write-Host "        PREVIEW ONLY - not added." -ForegroundColor Yellow
        } elseif ($group) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction Stop
                Write-Host "        ADDED." -ForegroundColor Green
            } catch {
                if ($_.Exception.Message -match "already exist") {
                    Write-Host "        already a member." -ForegroundColor DarkGray
                } else { throw }
            }
        }
    }
} else {
    Write-Host "`nNo -MemberUpns supplied; only the group is planned/created. Add members in entra.microsoft.us or re-run with -MemberUpns." -ForegroundColor DarkGray
}

Write-Host "`n------------------------------------------------------------------" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "PREVIEW complete. Nothing changed. If this matches your intended scope, re-run with -Execute." -ForegroundColor Yellow
} else {
    Write-Host "EXECUTE complete. Target group is ready. Use it as the pilot/wave scope for baseline changes." -ForegroundColor Green
}
