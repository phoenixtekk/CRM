<#
.SYNOPSIS
    CLSREPORT-Configure.ps1 — enable classification-reporting prerequisites (audit ingestion + scoped Content Explorer viewer role groups). Safe-by-default: -WhatIf preview; writes only with -Commit.
.DESCRIPTION
    PURPOSE
        Turns on the two governed prerequisites the reporting depends on: (1) unified audit log ingestion
        (Activity Explorer's data source) via Set-AdminAuditLogConfig, and (2) least-privilege Content
        Explorer viewer role-group membership (Content Explorer List Viewer for coverage reporting; Content
        Explorer Content Viewer only for those who must open sensitive items) via Add-RoleGroupMember.
        Creates NO labels, SITs, or policies — it grants sight of the existing classification signal.
    HOW TO RUN
        # Preview every intended change (default, no writes):
        powershell -ExecutionPolicy Bypass -File .\CLSREPORT-Configure.ps1 -EnableAudit -GrantListViewer -Members user1@contoso.com,user2@contoso.com -WhatIf
        # Apply after change-control approval:
        powershell -ExecutionPolicy Bypass -File .\CLSREPORT-Configure.ps1 -EnableAudit -GrantListViewer -Members user1@contoso.com -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and Exchange Online PowerShell
        (Connect-ExchangeOnline) via the ExchangeOnlineManagement module. PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        With -WhatIf (default): prints each action it WOULD take, makes no change. With -Commit: enables
        audit ingestion (if -EnableAudit) and adds the named members to the requested viewer role group(s).
        PASS signal: re-running CLSREPORT-Validate.ps1 shows audit ingestion True and the intended members
        present, with Content Viewer minimal.
.NOTES
    Purview — Classification Reporting & Analytics. Writes gated by -Commit (default is -WhatIf preview). No credentials in code.
    Expected results: audit ingestion True + intended viewer-role membership; Content Viewer kept minimal (it exposes sensitive content).
#>
[CmdletBinding()]
param(
    [switch]$EnableAudit,
    [switch]$GrantListViewer,
    [switch]$GrantContentViewer,
    [string[]]$Members = @(),
    [string]$ListViewerRoleGroup    = 'Content Explorer List Viewer',
    [string]$ContentViewerRoleGroup = 'Content Explorer Content Viewer',
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$UserPrincipalName
)

# Safe-by-default: unless -Commit is passed, run in preview (-WhatIf) mode and write nothing.
$preview = -not $Commit
if ($preview) { Write-Host 'PREVIEW MODE (no changes). Re-run with -Commit to apply, after change-control approval.' -ForegroundColor Yellow }
else          { Write-Host 'COMMIT MODE — changes WILL be made. Ensure change-control approval is in place.'        -ForegroundColor Magenta }

# --- Modules / connections (modern auth / MFA). Reuses existing sessions if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RoleGroupMember -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-ExchangeOnline -ShowBanner:$false }
}

# --- 1. Enable unified audit log ingestion (Activity Explorer data source) ---
if ($EnableAudit) {
    Write-Host '--- Unified audit log ingestion ---' -ForegroundColor Cyan
    $current = $null
    try { $current = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled } catch {
        Write-Host ("Could not read current audit config ({0}) — verify the Exchange Online connection / role." -f $_.Exception.Message) -ForegroundColor Yellow
    }
    if ($current -eq $true) {
        Write-Host 'Already enabled: UnifiedAuditLogIngestionEnabled = True. No change needed.' -ForegroundColor Green
    } elseif ($preview) {
        Write-Host 'WOULD RUN: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true  (allow time for the pipeline to backfill before judging coverage).' -ForegroundColor Yellow
    } else {
        try {
            Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -ErrorAction Stop
            Write-Host 'DONE: audit ingestion enabled. Allow time for the pipeline to populate before judging activity coverage.' -ForegroundColor Green
        } catch {
            Write-Host ("FAILED to enable audit ingestion: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
}

# --- 2. Grant scoped Content Explorer viewer roles ---
function Add-Viewers {
    param([string]$RoleGroup, [string[]]$People, [bool]$Preview)
    if (-not $People -or $People.Count -eq 0) {
        Write-Host ("No -Members supplied for '{0}' — nothing to grant." -f $RoleGroup) -ForegroundColor Gray
        return
    }
    $existing = @()
    try { $existing = @(Get-RoleGroupMember -Identity $RoleGroup -ErrorAction Stop | Select-Object -ExpandProperty Name) } catch {
        Write-Host ("Could not read '{0}' membership ({1}) — verify the role group exists / your role." -f $RoleGroup, $_.Exception.Message) -ForegroundColor Yellow
    }
    foreach ($m in $People) {
        if ($existing -contains $m) { Write-Host ("Already a member of '{0}': {1}" -f $RoleGroup, $m) -ForegroundColor Green; continue }
        if ($Preview) {
            Write-Host ("WOULD RUN: Add-RoleGroupMember -Identity '{0}' -Member '{1}'" -f $RoleGroup, $m) -ForegroundColor Yellow
        } else {
            try {
                Add-RoleGroupMember -Identity $RoleGroup -Member $m -ErrorAction Stop
                Write-Host ("DONE: added {0} to '{1}'." -f $m, $RoleGroup) -ForegroundColor Green
            } catch {
                Write-Host ("FAILED to add {0} to '{1}': {2}" -f $m, $RoleGroup, $_.Exception.Message) -ForegroundColor Red
            }
        }
    }
}

if ($GrantListViewer) {
    Write-Host '--- Content Explorer List Viewer (coverage reporting) ---' -ForegroundColor Cyan
    Add-Viewers -RoleGroup $ListViewerRoleGroup -People $Members -Preview:$preview
}
if ($GrantContentViewer) {
    Write-Host '--- Content Explorer Content Viewer (opens SENSITIVE item content — keep minimal) ---' -ForegroundColor Cyan
    Write-Host 'REVIEW: Content Viewer exposes real sensitive data. Grant only the minimal approved set (Req 2.2).' -ForegroundColor Yellow
    Add-Viewers -RoleGroup $ContentViewerRoleGroup -People $Members -Preview:$preview
}

if (-not ($EnableAudit -or $GrantListViewer -or $GrantContentViewer)) {
    Write-Host 'Nothing selected. Pass one or more of: -EnableAudit, -GrantListViewer, -GrantContentViewer (with -Members).' -ForegroundColor Yellow
}

Write-Host 'Done. Validate with CLSREPORT-Validate.ps1.' -ForegroundColor Cyan
