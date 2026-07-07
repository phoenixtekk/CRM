<#
.SYNOPSIS
  Configuration (SAFE BY DEFAULT - preview unless -Commit): idempotently creates/updates the Teams events
  policies "Events Policy - Standard/Restricted - Prod" for webinars + town halls, and reports Teams
  Premium meeting-template / sensitivity-label readiness (what must be done in the admin center + Purview).
.DESCRIPTION
  Reconciles a desired-state table for the events policy (New-/Set-CsTeamsEventsPolicy) that governs who
  can create webinars (-AllowWebinars) and run town halls (-AllowTownhalls). Without -Commit it reports
  the actions only (dry-run); -WhatIf is honored. It does NOT create meeting templates or sensitivity
  labels - those are Teams Premium and are authored in the Teams admin center and Microsoft Purview
  respectively; the script instead prints a readiness checklist and flags the licensing gate. Events-policy
  parameter names/values are version-dependent - verify for your tenant. Legacy Teams live events use
  Set-CsTeamsMeetingBroadcastPolicy (not configured here) and are being steered toward town halls.
.EXAMPLE
  .\TEAMSMTG-Set-EventsAndTemplates.ps1 -WhatIf
  # Dry-run: show the events-policy actions and the Premium template/label readiness checklist.
.EXAMPLE
  .\TEAMSMTG-Set-EventsAndTemplates.ps1 -Commit
  # Create/update the events policies. Template + sensitivity remain manual (admin center + Purview).
  # (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams.)
.NOTES
  Expected results: each named events policy exists with the intended webinar/town-hall stance. Template
  and sensitivity steps are reported as manual, Premium-gated actions - the script never invents label or
  template internals.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Commit
)

function Confirm-TeamsConnected {
    try { Get-CsTenant -ErrorAction Stop | Out-Null; return $true }
    catch {
        Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Cyan
        try { Connect-MicrosoftTeams -ErrorAction Stop | Out-Null; return $true }
        catch { Write-Error "Connect-MicrosoftTeams failed: $($_.Exception.Message)"; return $false }
    }
}
if (-not (Confirm-TeamsConnected)) { return }

$doWrite = $Commit.IsPresent -and -not $WhatIfPreference

# ---- Desired events-policy state (edit to your baseline) --------------------
$Desired = @(
    [pscustomobject]@{ Identity='Events Policy - Standard - Prod';   AllowWebinars='Enabled';  AllowTownhalls='Enabled'  }
    [pscustomobject]@{ Identity='Events Policy - Restricted - Prod'; AllowWebinars='Disabled'; AllowTownhalls='Disabled' }
)

$existing = @{}
Get-CsTeamsEventsPolicy -ErrorAction SilentlyContinue | ForEach-Object { $existing[$_.Identity] = $_ }

foreach ($d in $Desired) {
    if (-not $existing[$d.Identity]) {
        if ($doWrite -and $PSCmdlet.ShouldProcess($d.Identity, 'New-CsTeamsEventsPolicy')) {
            try { New-CsTeamsEventsPolicy -Identity $d.Identity -ErrorAction Stop | Out-Null
                  Write-Host "CREATED  $($d.Identity)" -ForegroundColor Green }
            catch { Write-Warning "Create failed for $($d.Identity): $($_.Exception.Message)"; continue }
        } else {
            Write-Host "WOULD CREATE  $($d.Identity)" -ForegroundColor Yellow
        }
    }

    $params = @{ Identity = $d.Identity; AllowWebinars = $d.AllowWebinars; AllowTownhalls = $d.AllowTownhalls }
    if ($doWrite -and $PSCmdlet.ShouldProcess($d.Identity, 'Set-CsTeamsEventsPolicy')) {
        try { Set-CsTeamsEventsPolicy @params -ErrorAction Stop
              Write-Host "SET      $($d.Identity): Webinars=$($d.AllowWebinars) Townhalls=$($d.AllowTownhalls)" -ForegroundColor Green }
        catch { Write-Warning "Set failed for $($d.Identity) - parameter may be version-dependent: $($_.Exception.Message)" }
    } else {
        Write-Host "WOULD SET $($d.Identity): Webinars=$($d.AllowWebinars) Townhalls=$($d.AllowTownhalls)" -ForegroundColor Yellow
    }
}

# ---- Teams Premium template + sensitivity readiness (manual, flagged) -------
Write-Host "`n=== Teams Premium template + sensitivity readiness (manual steps) ===" -ForegroundColor Cyan
Write-Host " [ ] Teams Premium licensed on the target organizers?  (verify: M365 admin center > Billing > Licenses)" -ForegroundColor Gray
Write-Host " [ ] 'Meeting Template - Confidential - Prod' created in Teams admin center > Meetings > Meeting templates" -ForegroundColor Gray
Write-Host " [ ] Sensitivity label 'Sensitivity Label - Confidential - Meeting' PUBLISHED in Microsoft Purview by the compliance owner" -ForegroundColor Gray
Write-Host " [ ] Label attached to the template; template published to the intended cohort via a template policy" -ForegroundColor Gray
Write-Host " NOTE: templates/sensitivity/watermark are Teams Premium. Without Premium these silently do nothing." -ForegroundColor DarkYellow
Write-Host " NOTE: what the label protects and its retention are a Purview/compliance determination - not set here." -ForegroundColor DarkYellow

# Best-effort read-only peek at template configuration (cmdlet availability is version-dependent)
try {
    $tpl = Get-CsTeamsMeetingTemplateConfiguration -ErrorAction Stop
    if ($tpl) { Write-Host "`nTemplate configurations present in tenant: $($tpl.Count)" -ForegroundColor Green }
} catch {
    Write-Host "`n(Meeting-template configuration cmdlet not available in this module version - use the admin center; verify cmdlet names for your tenant.)" -ForegroundColor DarkGray
}

if (-not $doWrite) { Write-Host "`nDRY-RUN only (no -Commit). Re-run with -Commit to apply the events policies." -ForegroundColor Cyan }
Write-Host "`nNext: assign the events + meeting policies to the pilot group (TEAMSMTG-AssignmentReport.ps1)." -ForegroundColor Cyan
