<#
.SYNOPSIS
    COPILOT-Remediation.ps1 — safe remediation of oversharing: remove anonymous/org-wide links (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Reduces the top Copilot risk (oversharing) by removing the broad sharing links that let Copilot
        surface content to anyone: anonymous ("anyone") links and organization-wide links on the
        targeted SharePoint sites. Broad group grants (e.g. "Everyone except external users") are
        REPORTED for owner action, not silently deleted — those often reflect legitimate access.
        By default it only REPORTS what it would remove (-WhatIf); pass -Apply to act. It never deletes
        files, unshares specific-people grants, or changes labels/DLP.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\COPILOT-Remediation.ps1 `
                                    -SiteUrlMatch "contoso.sharepoint.com/sites/HR"
        Apply:                  ... .\COPILOT-Remediation.ps1 -SiteUrlMatch "...HR" -Apply
        Requires the Microsoft Graph SDK and consent to: Sites.ReadWrite.All (to delete sharing links),
        Sites.Read.All. Removing links is reversible — owners can re-share to specific people.
    EXPECTED RESULTS
        A list of anonymous/org-wide links on the matched sites; with -Apply each such link is deleted so
        Copilot can no longer surface that content broadly. Re-run COPILOT-Validation.ps1 / COPILOT-Report.ps1
        after to confirm exposure dropped.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf). Always preview with owners first
    (Implementation Step 2). Tenant-level sharing policy and label/DLP changes are done in the portals,
    not by this script.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$SiteUrlMatch,
    [switch]$Apply
)

# Default posture is -WhatIf unless -Apply is explicitly passed.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Sites.ReadWrite.All','Sites.Read.All' -NoWelcome

$sites = @()
try { $sites = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites?search=*&`$top=200").value } catch { }
$sites = $sites | Where-Object { $_.webUrl -like "*$SiteUrlMatch*" }
if (-not $sites) { Write-Host "No sites match '$SiteUrlMatch'." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$removed = 0; $reported = 0; $broadGrants = 0
foreach ($s in $sites) {
    Write-Host ("`nSite: {0}  ({1})" -f $s.displayName, $s.webUrl) -ForegroundColor Cyan
    try { $perms = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/sites/$($s.id)/permissions").value } catch { $perms = @() }
    foreach ($p in $perms) {
        $scope = $p.link.scope
        if ($scope -in @('anonymous','organization')) {
            $reported++
            $desc = "Remove $scope sharing link on '$($s.displayName)'"
            if ($PSCmdlet.ShouldProcess($desc, "Delete broad sharing link")) {
                try {
                    Invoke-MgGraphRequest -Method DELETE -Uri "/v1.0/sites/$($s.id)/permissions/$($p.id)" | Out-Null
                    Write-Host ("  REMOVED: {0} link ({1})" -f $scope, $p.id) -ForegroundColor Green
                    $removed++
                } catch {
                    Write-Host ("  Failed to remove {0} link {1}: {2}" -f $scope, $p.id, $_.Exception.Message) -ForegroundColor Red
                }
            }
        } elseif ($p.grantedToIdentitiesV2.group.displayName -match 'Everyone') {
            $broadGrants++
            Write-Host ("  REVIEW (not auto-removed): broad group grant '{0}' — confirm with owner" -f $p.grantedToIdentitiesV2.group.displayName) -ForegroundColor Yellow
        }
    }
}

Write-Host ("`nBroad links found: {0}  Removed: {1}  Broad group grants flagged for owner: {2}" -f $reported, $removed, $broadGrants) -ForegroundColor Cyan
if (-not $Apply) { Write-Host "Preview only (-WhatIf). Re-run with -Apply after owner review." -ForegroundColor Yellow }
Write-Host "Then re-run COPILOT-Validation.ps1 and COPILOT-Report.ps1 to confirm exposure dropped." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
