<#
.SYNOPSIS
    CLSTRAIN-ScopeHealth.ps1 — report seed/scope health and preview pilot-scope targeting for the classifier wiring (read-only; -WhatIf for any scope change).
.DESCRIPTION
    PURPOSE
        Seed/scope helper for trainable classifiers. Summarizes the pilot user/security group membership from
        Microsoft Graph and shows the current scope + mode of the auto-labeling wiring policy — so you can see
        what the wired control WOULD cover before you widen it. Reminds you to confirm the SEED site and the
        classifier's PUBLISHED status in the portal (neither is readable via S&C PowerShell). Read-only by
        default; any scope change is preview-only via -WhatIf (this tool does not itself widen scope — it
        prints the command for you to run under change control).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Microsoft Graph and (optionally) Security & Compliance PowerShell:
          Connect-MgGraph -Scopes "Group.Read.All"
          Connect-IPPSSession            # optional, to read the policy scope
          .\CLSTRAIN-ScopeHealth.ps1
          .\CLSTRAIN-ScopeHealth.ps1 -PilotGroup "SG-Classifier-Pilot" -WhatIf
    EXPECTED RESULTS
        A console summary: pilot-group membership (Graph) and the auto-labeling policy's current scope/mode.
        With -WhatIf, a PREVIEW of the scope-widening command (nothing is changed).
.NOTES
    White-label Microsoft Purview tooling. Read-only / -WhatIf only. No credentials stored. Uses standard
    Microsoft Graph (Get-MgGroup / Get-MgGroupMember) and Get-AutoSensitivityLabelPolicy; none invented. The
    SEED site and classifier PUBLISHED status are confirmed in the Purview portal.
#>
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [string]$PilotGroup = "SG-Classifier-Pilot",
    [string]$PolicyName = "AL-Classifier-Pilot",
    [string]$SeedSite   = "Seed-Contracts"
)

$ErrorActionPreference = "Stop"
Write-Host "=== CLSTRAIN ScopeHealth — seed/scope signals (read-only) ===" -ForegroundColor Cyan

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

# --- S&C PowerShell: current scope/mode of the wiring policy ---
try {
    Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Out-Null
    $pol = Get-AutoSensitivityLabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($pol) {
        Write-Host ("  Auto-labeling policy '{0}' (Mode={1}; Label={2})" -f $PolicyName, $pol.Mode, $pol.ApplySensitivityLabel) -ForegroundColor Green
        foreach ($prop in @('SharePointLocation','OneDriveLocation','ExchangeLocation')) {
            if ($pol.PSObject.Properties.Name -contains $prop) {
                $val = @($pol.$prop) -join ", "; if ([string]::IsNullOrWhiteSpace($val)) { $val = "(none)" }
                Write-Host ("    {0,-18}: {1}" -f $prop, $val)
                if (@($pol.$prop) -contains "All") { Write-Host ("      NOTE: {0} is ALL — confirm intended (post-pilot only)." -f $prop) -ForegroundColor Yellow }
            }
        }
    } else {
        Write-Host ("  Policy '{0}' not found (run CLSTRAIN-Configure.ps1 -Commit first)." -f $PolicyName) -ForegroundColor Yellow
    }
} catch {
    Write-Host "  (S&C PowerShell not connected — skipping policy-scope read. Connect-IPPSSession to include it.)" -ForegroundColor Gray
}

Write-Host "`n  Confirm in the Purview portal (not readable here):" -ForegroundColor Cyan
Write-Host ("    - Seed site '{0}' holds enough correctly-categorized POSITIVE examples (R3)." -f $SeedSite) -ForegroundColor Gray
Write-Host  "    - The trainable classifier is PUBLISHED and passed its accuracy gate (R7) before wiring." -ForegroundColor Gray

# --- Scope-change PREVIEW only (this tool never widens scope itself) ---
if ($WhatIf) {
    Write-Host "`n  -WhatIf PREVIEW — to widen the pilot scope, run this yourself under change control:" -ForegroundColor Cyan
    Write-Host ("    Set-AutoSensitivityLabelPolicy -Identity '{0}' -AddSharePointLocation '<site-url>'" -f $PolicyName) -ForegroundColor Gray
    Write-Host "  (No change was made. Verify the exact add-location parameter for your tenant, then validate with CLSTRAIN-Validate.ps1.)" -ForegroundColor DarkYellow
}

Write-Host "`nScopeHealth complete. Then CLSTRAIN-Validate.ps1 for the wiring configuration gates." -ForegroundColor Cyan
