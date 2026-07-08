<#
.SYNOPSIS
    DLPTEAMS-ScopeHealth.ps1 — report pilot-scope health and preview pilot-scope targeting for Teams DLP (read-only; -WhatIf for any scope change).
.DESCRIPTION
    PURPOSE
        Scope and health helper for Teams DLP. Summarizes the pilot user/security group membership from
        Microsoft Graph and shows the current Teams/SharePoint/OneDrive scope of the Teams DLP policy — so you
        can see what the policy WOULD cover before you widen it. Read-only by default; any scope change is
        preview-only via -WhatIf (this tool does not itself widen scope — it prints the command for you to run
        under change control).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Microsoft Graph and (optionally) Security & Compliance PowerShell:
          Connect-MgGraph -Scopes "Group.Read.All"
          Connect-IPPSSession            # optional, to read the policy scope
          .\DLPTEAMS-ScopeHealth.ps1
          .\DLPTEAMS-ScopeHealth.ps1 -PilotGroup "SG-TeamsDLP-Pilot" -WhatIf
    EXPECTED RESULTS
        A console summary: pilot-group membership (Graph) and the policy's current Teams/SharePoint/OneDrive
        scope. With -WhatIf, a PREVIEW of the scope-widening command (nothing is changed).
.NOTES
    White-label Microsoft Purview tooling. Read-only / -WhatIf only. No credentials stored. Uses standard
    Microsoft Graph (Get-MgGroup / Get-MgGroupMember) and Get-DlpCompliancePolicy; none invented.
#>
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [string]$PilotGroup = "SG-TeamsDLP-Pilot",
    [string]$PolicyName = "DLP-Teams-Pilot"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPTEAMS ScopeHealth — pilot-scope signals (read-only) ===" -ForegroundColor Cyan

function Has-Location($val) { try { return ($null -ne $val -and @($val).Count -gt 0) } catch { return $false } }

# --- Graph: pilot group membership ---
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if ($null -eq $ctx) { throw "no context" }
    try {
        $grp = Get-MgGroup -Filter "displayName eq '$PilotGroup'" -ErrorAction Stop
        if ($grp) {
            $members = Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction Stop
            Write-Host ("  Pilot group '{0}' members: {1}" -f $PilotGroup, @($members).Count) -ForegroundColor Green
        } else {
            Write-Host ("  Pilot group '{0}' not found — create it before scoping the pilot." -f $PilotGroup) -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  WARN: could not read pilot group (scope Group.Read.All?): $($_.Exception.Message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Microsoft Graph not connected. Run Connect-MgGraph -Scopes 'Group.Read.All' for pilot-group signals." -ForegroundColor Yellow
}

# --- S&C PowerShell: current locations/scope of the policy ---
try {
    Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null
    $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($pol) {
        $teams = @($pol.TeamsLocation) -join ", "; if ([string]::IsNullOrWhiteSpace($teams)) { $teams = "(none)" }
        Write-Host ("  Policy '{0}' (Mode={1}):" -f $PolicyName, $pol.Mode) -ForegroundColor Green
        Write-Host ("    Teams scope     : {0}" -f $teams)
        Write-Host ("    SharePoint      : {0}" -f (($(if(Has-Location $pol.SharePointLocation){(@($pol.SharePointLocation) -join ', ')}else{"(none)"}))))
        Write-Host ("    OneDrive        : {0}" -f (($(if(Has-Location $pol.OneDriveLocation){(@($pol.OneDriveLocation) -join ', ')}else{"(none)"}))))
        if (-not (Has-Location $pol.SharePointLocation) -or -not (Has-Location $pol.OneDriveLocation)) {
            Write-Host "    GAP: shared-file locations (SharePoint/OneDrive) not both set — Teams-shared files may be uncovered." -ForegroundColor Yellow
        }
        if (@($pol.TeamsLocation) -contains "All") { Write-Host "    NOTE: Teams scope is ALL users — confirm this is intended (post-pilot only)." -ForegroundColor Yellow }
    } else {
        Write-Host ("  Policy '{0}' not found (run DLPTEAMS-Configure.ps1 -Commit first)." -f $PolicyName) -ForegroundColor Yellow
    }
} catch {
    Write-Host "  (S&C PowerShell not connected — skipping policy-scope read. Connect-IPPSSession to include it.)" -ForegroundColor Gray
}

# --- Scope-change PREVIEW only (this tool never widens scope itself) ---
if ($WhatIf) {
    Write-Host "`n  -WhatIf PREVIEW — to widen the pilot scope, run this yourself under change control:" -ForegroundColor Cyan
    Write-Host ("    Set-DlpCompliancePolicy -Identity '{0}' -TeamsLocation '{1}' -OneDriveLocation '{1}'" -f $PolicyName, $PilotGroup) -ForegroundColor Gray
    Write-Host "  (No change was made. Validate with DLPTEAMS-Validate.ps1 after any scope change.)" -ForegroundColor DarkYellow
}

Write-Host "`nScopeHealth complete. Then DLPTEAMS-Validate.ps1 for configuration gates." -ForegroundColor Cyan
