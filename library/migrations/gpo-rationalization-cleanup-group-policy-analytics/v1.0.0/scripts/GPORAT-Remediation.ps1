<#
.SYNOPSIS
    GPORAT-Remediation.ps1 — safely unlink/remove the dead and duplicate GPOs (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Reads the rationalization register and acts ONLY on GPOs explicitly marked Disposition =
        'retire' or 'consolidate' (merged-away). For each, it removes the GPO's links (Remove-GPLink)
        so it no longer applies, leaving the GPO object present-but-unlinked for rollback — it does
        NOT delete the GPO. Runs in -WhatIf mode by DEFAULT and changes nothing until you pass -Apply.
        The retained GPORAT-Discovery.ps1 export folder plus the unlinked GPOs are your rollback path.
    HOW TO RUN
        Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\GPORAT-Remediation.ps1 -RegisterPath .\GPO-Export\GPORAT-Rationalization-Register.csv
        Apply in the change window (elevated):
        powershell -ExecutionPolicy Bypass -File .\GPORAT-Remediation.ps1 -RegisterPath .\GPO-Export\GPORAT-Rationalization-Register.csv -Apply
    EXPECTED RESULTS
        In preview: prints which GPOs and links WOULD be unlinked and exits. With -Apply: removes the
        links for each retire/consolidate-away GPO (object retained), and advises re-running
        GPORAT-Report.ps1 / GPORAT-Validation.ps1.
.NOTES
    Workplace Marketplace — Migrations. -WhatIf by default; -Apply makes changes. Requires the
    GroupPolicy module and Group Policy write access. Does not delete GPOs (unlink only).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string] $RegisterPath = ".\GPO-Export\GPORAT-Rationalization-Register.csv",
    [switch] $Apply
)

# Default to preview/WhatIf unless -Apply is explicitly passed.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "`n=== GPO link remediation (unlink dead/duplicate) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "MODE: PREVIEW (-WhatIf) — no changes will be made. Re-run with -Apply to change." -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name GroupPolicy)) { Write-Host "GroupPolicy module not found. Install RSAT Group Policy Management Tools." -ForegroundColor Yellow; return }
Import-Module GroupPolicy -ErrorAction Stop

if (-not (Test-Path $RegisterPath)) { Write-Host "Register not found: $RegisterPath. Run GPORAT-Discovery.ps1 and classify first." -ForegroundColor Yellow; return }
$rows = Import-Csv -Path $RegisterPath

$targets = @($rows | Where-Object { @('retire','consolidate') -contains ($_.Disposition).ToString().Trim().ToLower() })
if (-not $targets) { Write-Host "No GPOs marked retire/consolidate in the register — nothing to remediate." -ForegroundColor Green; return }

Write-Host ("{0} GPO(s) marked retire/consolidate-away." -f $targets.Count) -ForegroundColor Cyan

foreach ($t in $targets) {
    $name = $t.DisplayName
    try {
        [xml]$rpt = Get-GPOReport -Name $name -ReportType Xml -ErrorAction Stop
        $linkPaths = @($rpt.GPO.LinksTo | ForEach-Object { $_.SOMPath }) | Where-Object { $_ }
    } catch {
        Write-Host ("  Could not read links for '{0}': {1}" -f $name, $_.Exception.Message) -ForegroundColor Yellow
        continue
    }

    if (-not $linkPaths) { Write-Host ("  '{0}' has no links (already dead) — nothing to unlink." -f $name) -ForegroundColor Gray; continue }

    foreach ($som in $linkPaths) {
        # SOMPath is a DNS-style path (e.g. contoso.com/OU/Sub); convert to a distinguished name target.
        $parts = $som -split '/'
        $domainDns = $parts[0]
        $dcPart = ($domainDns -split '\.' | ForEach-Object { "DC=$_" }) -join ','
        if ($parts.Count -gt 1) {
            $ouPart = (($parts[1..($parts.Count-1)] | ForEach-Object { "OU=$_" })[($parts.Count-2)..0]) -join ','
            $targetDn = "$ouPart,$dcPart"
        } else {
            $targetDn = $dcPart
        }
        if ($PSCmdlet.ShouldProcess("$name @ $targetDn", "Remove GPO link")) {
            try {
                Remove-GPLink -Name $name -Target $targetDn -ErrorAction Stop | Out-Null
                Write-Host ("  Unlinked '{0}' from {1}" -f $name, $targetDn) -ForegroundColor Green
            } catch {
                Write-Host ("  Could not unlink '{0}' from {1}: {2}" -f $name, $targetDn, $_.Exception.Message) -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`nGPO objects are left present-but-unlinked (not deleted) for rollback." -ForegroundColor Gray
Write-Host "Re-run GPORAT-Report.ps1 and GPORAT-Validation.ps1 to confirm the estate is clean." -ForegroundColor Green
