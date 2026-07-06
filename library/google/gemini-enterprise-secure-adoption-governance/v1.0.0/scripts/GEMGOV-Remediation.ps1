<#
.SYNOPSIS
    GEMGOV-Remediation.ps1 — safe oversharing remediation: remove public/domain-wide Drive links (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Reduces the top Gemini Enterprise risk (oversharing) by removing the broad Drive sharing that
        lets Gemini surface content to anyone: public 'anyone with the link' and domain-wide 'anyone in
        your organization' permissions on the targeted items. Broad group / shared-drive grants are
        REPORTED for owner action, not silently deleted — those often reflect legitimate access. By
        default it only REPORTS what it would remove (-WhatIf); pass -Apply to act. It never deletes
        files, removes specific-person grants, or changes DLP/IRM.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\GEMGOV-Remediation.ps1 -UrlMatch sites/hr
        Apply:                  ... .\GEMGOV-Remediation.ps1 -UrlMatch sites/hr -Apply
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with the drive scope
        (https://www.googleapis.com/auth/drive) to delete permissions. Removing a broad link is
        reversible — owners can re-share to specific people.
    EXPECTED RESULTS
        A list of public/domain-wide permissions on the matched items; with -Apply each such permission is
        deleted so Gemini can no longer surface that content broadly. Re-run GEMGOV-Validation.ps1 /
        GEMGOV-Report.ps1 after to confirm exposure dropped.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf). Always preview with owners first
    (Implementation Step 2). Tenant sharing policy, Trust rules, DLP/IRM, and Gemini toggles are set in
    the Admin console (verify in your tenant), not by this script.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$UrlMatch,
    [switch]$Apply
)

# Default posture is -WhatIf unless -Apply is explicitly passed.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the drive scope." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }
function Invoke-GApiGet([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop } catch { $null }
}

$q = [System.Web.HttpUtility]::UrlEncode("visibility='anyoneWithLink' or visibility='anyoneCanFind' or visibility='domainWithLink' or visibility='domainCanFind'")
$uri = "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=files(id,name,webViewLink,permissions(id,type,domain))&q=$q"
$resp = Invoke-GApiGet $uri
$items = @()
if ($resp -and $resp.files) {
    $items = $resp.files | Where-Object { $_.webViewLink -like "*$UrlMatch*" }
}
if (-not $items) { Write-Host "No broadly shared items match '$UrlMatch'." -ForegroundColor Yellow; return }

$reported = 0; $removed = 0; $flaggedForOwner = 0
foreach ($f in $items) {
    Write-Host ("`nItem: {0}  ({1})" -f $f.name, $f.webViewLink) -ForegroundColor Cyan
    foreach ($p in $f.permissions) {
        if ($p.type -in @('anyone','domain')) {
            $reported++
            $label = if ($p.type -eq 'anyone') { 'PUBLIC (anyone with link)' } else { "DOMAIN-WIDE ($($p.domain))" }
            $desc = "Remove $label permission on '$($f.name)'"
            if ($PSCmdlet.ShouldProcess($desc, "Delete broad Drive permission")) {
                try {
                    $del = "https://www.googleapis.com/drive/v3/files/$($f.id)/permissions/$($p.id)?supportsAllDrives=true"
                    Invoke-RestMethod -Method DELETE -Uri $del -Headers $headers -ErrorAction Stop | Out-Null
                    Write-Host ("  REMOVED: {0} (perm {1})" -f $label, $p.id) -ForegroundColor Green
                    $removed++
                } catch {
                    Write-Host ("  Failed to remove {0} (perm {1}): {2}" -f $label, $p.id, $_.Exception.Message) -ForegroundColor Red
                }
            }
        } elseif ($p.type -eq 'group') {
            $flaggedForOwner++
            Write-Host "  REVIEW (not auto-removed): broad group grant — confirm with owner." -ForegroundColor Yellow
        }
    }
}

Write-Host ("`nBroad permissions found: {0}  Removed: {1}  Group grants flagged for owner: {2}" -f $reported, $removed, $flaggedForOwner) -ForegroundColor Cyan
if (-not $Apply) { Write-Host "Preview only (-WhatIf). Re-run with -Apply after owner review." -ForegroundColor Yellow }
Write-Host "Then re-run GEMGOV-Validation.ps1 and GEMGOV-Report.ps1 to confirm exposure dropped." -ForegroundColor Yellow
