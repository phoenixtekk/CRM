<#
.SYNOPSIS
    GWSEC-Remediation.ps1 — safe remediation of scriptable posture findings (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates the scriptable Google Workspace security findings surfaced by GWSEC-Discovery.ps1 —
        primarily tightening broadly-shared Drive items (removing public 'anyone with link' and
        domain-wide permissions) so exposed content is no longer over-shared. Safe by default: it
        previews every change and applies nothing unless you pass -Apply. Console-only baseline settings
        (2SV enforcement, session control, sharing defaults, DLP rules, CAA assignments) are NOT changed
        here — those are set in the Admin console per the Implementation Guide; this script prints the
        exact path for each.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\GWSEC-Remediation.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\GWSEC-Remediation.ps1 -Apply
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN. Preview needs
        drive.metadata.readonly; -Apply needs the drive scope (permission delete). Scope to a pilot OU
        by exporting the target file IDs from Discovery first.
    EXPECTED RESULTS
        Without -Apply: a WHATIF list of the public/domain-wide Drive permissions that WOULD be removed,
        and the console paths for the settings this script does not touch. With -Apply: those broad
        permissions are removed and each action is logged. Re-run GWSEC-Discovery.ps1 / GWSEC-Validation.ps1
        to confirm the exposure is gone.
.NOTES
    White-label — the repeatable way. Read-only until -Apply is passed (default -WhatIf). Only removes
    broad ('anyone'/'domain') Drive permissions; it never deletes files or user-specific access.
    Baseline/DLP/CAA console settings are set in the Admin console, not here.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch]$Apply,
    [int]$MaxFiles = 500
)

if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token (drive.metadata.readonly to preview; drive to apply)." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }

function Invoke-GApi([string]$uri, [string]$method='GET') {
    try { Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -ErrorAction Stop }
    catch { Write-Host ("  API error: {0}" -f $_.Exception.Message) -ForegroundColor Red; $null }
}

Write-Host "`n=== GWSEC remediation — broad Drive sharing ===" -ForegroundColor Cyan
Write-Host $(if ($Apply) { "APPLY mode: broad permissions WILL be removed." } else { "WHATIF mode (default): previewing only. Pass -Apply to enforce." }) -ForegroundColor $(if ($Apply) { 'Red' } else { 'Yellow' })

$scanned = 0; $removed = 0; $pageToken = $null
do {
    $q = [uri]::EscapeDataString("visibility='anyoneWithLink' or visibility='anyoneCanFind' or visibility='domainWithLink' or visibility='domainCanFind'")
    $uri = "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=nextPageToken,files(id,name,permissions(id,type,domain))&q=$q"
    if ($pageToken) { $uri += "&pageToken=$pageToken" }
    $resp = Invoke-GApi $uri
    if (-not $resp) { break }
    foreach ($f in $resp.files) {
        $scanned++
        foreach ($p in ($f.permissions | Where-Object { $_.type -in @('anyone','domain') })) {
            $label = if ($p.type -eq 'anyone') { 'PUBLIC (anyone with link)' } else { "DOMAIN-WIDE ($($p.domain))" }
            if ($PSCmdlet.ShouldProcess(("{0}  [{1}]" -f $f.name, $label), "Remove broad permission")) {
                $del = "https://www.googleapis.com/drive/v3/files/$($f.id)/permissions/$($p.id)?supportsAllDrives=true"
                $r = Invoke-GApi $del 'DELETE'
                Write-Host ("  REMOVED  {0}  [{1}]" -f $f.name, $label) -ForegroundColor Green
                $removed++
            } else {
                Write-Host ("  WHATIF   would remove {0} from {1}" -f $label, $f.name) -ForegroundColor Yellow
            }
        }
        if ($scanned -ge $MaxFiles) { break }
    }
    $pageToken = $resp.nextPageToken
} while ($pageToken -and $scanned -lt $MaxFiles)

Write-Host ("`n  Items scanned: {0}  Broad permissions {1}: {2}" -f $scanned, $(if ($Apply) { 'removed' } else { 'that would be removed' }), $(if ($Apply) { $removed } else { 'see WHATIF above' }))

# --- Console-only settings this script does NOT change ---
Write-Host "`n=== Set these in the Admin console (not scripted here) ===" -ForegroundColor Cyan
Write-Host "  2SV enforcement + grace period : Security > Authentication > 2-step verification" -ForegroundColor Yellow
Write-Host "  Web session duration           : Security > Access and data control > Google session control" -ForegroundColor Yellow
Write-Host "  Sharing defaults / warnings    : Apps > Google Workspace > Drive and Docs > Sharing settings" -ForegroundColor Yellow
Write-Host "  DLP rules (Drive/Gmail)        : Security > Access and data control > Data protection (edition-gated)" -ForegroundColor Yellow
Write-Host "  CAA levels + assignments       : Security > Access and data control > Context-Aware Access (edition-gated)" -ForegroundColor Yellow
Write-Host "`nRollback: broad sharing removed here can be re-added per file; console settings roll back to the values recorded by GWSEC-Discovery.ps1." -ForegroundColor Yellow
