<#
.SYNOPSIS
    OPSTRAIN-LabScope.ps1 — create/verify the training scope group of TEST accounts (safe: default -WhatIf; -Commit to apply).
.DESCRIPTION
    PURPOSE
        The one configuration helper in the curriculum. Ensures the training scope group (default
        TRAIN-Pilot-Users) exists in Entra ID via Microsoft Graph, so every lab can target it and never a
        real user. By DEFAULT it only PREVIEWS (-WhatIf) — it reports whether the group exists and what it
        would create. With -Commit it creates the group if missing (as a security group). It never adds
        members automatically and never touches any Purview policy — it only provisions the empty scope
        container; you add TEST accounts deliberately.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Microsoft Graph (group write scope needed only for -Commit):
          Connect-MgGraph -Scopes "Group.ReadWrite.All"
          .\OPSTRAIN-LabScope.ps1                       # preview only (default -WhatIf)
          .\OPSTRAIN-LabScope.ps1 -Commit               # create the group if missing
          .\OPSTRAIN-LabScope.ps1 -ScopeGroup "TRAIN-Pilot-Users" -Commit
    EXPECTED RESULTS
        Preview: reports "would create" or "already exists". -Commit: the group exists afterward and its Id
        is printed. PASS = TRAIN-Pilot-Users exists; then add ONLY test accounts to it before Lab 1.
.NOTES
    White-label Microsoft Purview training tooling. Writes ONLY with -Commit, and ONLY the scope group
    (no members, no policies). No credentials stored. Cmdlets are standard Microsoft Graph PowerShell;
    none are invented.
#>
[CmdletBinding()]
param(
    [string]$ScopeGroup = "TRAIN-Pilot-Users",
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
$mode = if ($Commit) { "COMMIT" } else { "WHATIF (preview only)" }
Write-Host "=== OPSTRAIN LabScope — training scope group [$mode] ===" -ForegroundColor Cyan

try { $ctx = Get-MgContext -ErrorAction Stop } catch { $ctx = $null }
if (-not $ctx) {
    Write-Host "Not connected to Microsoft Graph. Run Connect-MgGraph -Scopes 'Group.ReadWrite.All' (or Group.Read.All to preview)." -ForegroundColor Red
    return
}
Write-Host ("  Tenant={0}; Account={1}" -f $ctx.TenantId, $ctx.Account) -ForegroundColor Gray

# --- Does the group already exist? ---
$existing = $null
try { $existing = Get-MgGroup -Filter "displayName eq '$ScopeGroup'" -ErrorAction Stop } catch {
    Write-Host "  Could not query groups: $($_.Exception.Message)" -ForegroundColor Red; return
}

if ($existing) {
    $memberCount = 0
    try { $memberCount = (Get-MgGroupMember -GroupId $existing.Id -All -ErrorAction Stop | Measure-Object).Count } catch {}
    Write-Host ("  [PASS] '{0}' already exists (Id={1}; members={2})." -f $ScopeGroup, $existing.Id, $memberCount) -ForegroundColor Green
    Write-Host "  Reminder: this group must contain ONLY test accounts. Remove any real user." -ForegroundColor Yellow
    return
}

# --- Not present: preview or create ---
$mailNickname = ($ScopeGroup -replace '[^A-Za-z0-9]', '')
if (-not $Commit) {
    Write-Host ("  [WHATIF] Would create security group '{0}' (mailNickname='{1}', securityEnabled, non-mail-enabled)." -f $ScopeGroup, $mailNickname) -ForegroundColor Yellow
    Write-Host "  Re-run with -Commit to create it. It will be created EMPTY — add only test accounts yourself." -ForegroundColor Yellow
    return
}

try {
    $body = @{
        DisplayName     = $ScopeGroup
        Description      = "Purview Administrator Training — pilot scope. TEST ACCOUNTS ONLY. Labs target this group; never a real user."
        MailEnabled      = $false
        MailNickname     = $mailNickname
        SecurityEnabled  = $true
        GroupTypes       = @()
    }
    $new = New-MgGroup -BodyParameter $body -ErrorAction Stop
    Write-Host ("  [COMMIT] Created '{0}' (Id={1})." -f $ScopeGroup, $new.Id) -ForegroundColor Green
    Write-Host "  Next: add ONLY test accounts as members, then run OPSTRAIN-LabBaseline.ps1." -ForegroundColor Cyan
} catch {
    Write-Host ("  [FAIL] Could not create '{0}': {1}" -f $ScopeGroup, $_.Exception.Message) -ForegroundColor Red
    Write-Host "  Ensure Connect-MgGraph included Group.ReadWrite.All." -ForegroundColor Yellow
}
