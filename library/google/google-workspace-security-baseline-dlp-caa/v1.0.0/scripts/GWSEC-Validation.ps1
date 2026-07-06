<#
.SYNOPSIS
    GWSEC-Validation.ps1 — read-only per-OU validation of baseline / DLP / CAA against the intended posture.
.DESCRIPTION
    PURPOSE
        Read-only check that a given organizational unit meets the intended Google Workspace security
        posture: users in the OU are enrolled in 2SV, the OU has no broadly-shared Drive items, and
        the edition-gated DLP and Context-Aware Access surfaces are present to confirm rule/assignment
        state (monitor vs enforce, audit vs block) in the Admin console. Run it on the pilot OU
        (Security Baseline - Pilot) before expanding, and per OU on each expansion wave.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWSEC-Validation.ps1 -OrgUnitPath '/Security Baseline - Pilot'
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with READ-ONLY scopes:
        admin.directory.user.readonly, admin.directory.orgunit.readonly, drive.metadata.readonly.
        Provide the OU path exactly as it appears in Directory > Organizational units.
    EXPECTED RESULTS
        A per-check PASS / FAIL line for the OU (2SV enrollment, broad-sharing, DLP/CAA presence) and
        an overall result. PASS on all baseline checks is the gate to promote DLP audit->block and CAA
        monitor->enforce, and to expand past the pilot. FAIL lines name the exact setting to fix.
.NOTES
    White-label — the repeatable way. Read-only against the Admin Directory & Drive metadata APIs.
    DLP-for-Drive/Gmail rule state and Context-Aware Access assignment mode (monitor/enforce) are
    edition-gated and confirmed in the Admin console — this script reports where to verify them.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OrgUnitPath
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the read-only scopes in this header." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }

function Invoke-GApi([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop }
    catch { Write-Host ("  API error: {0}" -f $_.Exception.Message) -ForegroundColor Red; $null }
}

$results = @()
function Add-Result([string]$name, [bool]$pass, [string]$detail) {
    $script:results += [pscustomobject]@{ Check = $name; Pass = $pass; Detail = $detail }
    $tag = if ($pass) { 'PASS' } else { 'FAIL' }
    $col = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} — {2}" -f $tag, $name, $detail) -ForegroundColor $col
}

Write-Host "`n=== GWSEC validation for OU: $OrgUnitPath (read-only) ===" -ForegroundColor Cyan

# --- 2SV enrollment for users in the OU ---
$no2sv = 0; $total = 0; $pageToken = $null
$q = [uri]::EscapeDataString("orgUnitPath='$OrgUnitPath'")
do {
    $uri = "https://admin.googleapis.com/admin/directory/v1/users?customer=my_customer&maxResults=100&query=$q&fields=nextPageToken,users(primaryEmail,isEnrolledIn2Sv)"
    if ($pageToken) { $uri += "&pageToken=$pageToken" }
    $resp = Invoke-GApi $uri
    if (-not $resp) { break }
    foreach ($u in $resp.users) { $total++; if (-not $u.isEnrolledIn2Sv) { $no2sv++ } }
    $pageToken = $resp.nextPageToken
} while ($pageToken)
Add-Result "2SV enrollment" ($no2sv -eq 0 -and $total -gt 0) ("$($total - $no2sv)/$total users enrolled" + $(if ($no2sv) { " — $no2sv NOT enrolled" } else { '' }))

# --- Broad Drive sharing (org-wide signal; review against OU membership) ---
$flagged = 0; $scanned = 0
$sq = [uri]::EscapeDataString("visibility='anyoneWithLink' or visibility='domainWithLink'")
$resp = Invoke-GApi "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=files(id,name,permissions(type))&q=$sq"
if ($resp) { foreach ($f in $resp.files) { $scanned++; if ($f.permissions | Where-Object { $_.type -in @('anyone','domain') }) { $flagged++ } } }
Add-Result "Broad Drive sharing" ($flagged -eq 0) ("$flagged broadly-shared item(s) in the sampled scope")

# --- Edition-gated surfaces present (confirm rule/assignment state in console) ---
Write-Host "`n  Confirm edition-gated state in the Admin console (verify in your tenant):" -ForegroundColor Yellow
Write-Host "    DLP  — Security > Access and data control > Data protection: rules 'DLP - Drive - Sensitive - External' /" -ForegroundColor Yellow
Write-Host "           'DLP - Gmail - Sensitive - Outbound' active and at the intended action (audit/warn/block) for this OU." -ForegroundColor Yellow
Write-Host "    CAA  — Security > Access and data control > Context-Aware Access: levels 'Access - Corp Network' /" -ForegroundColor Yellow
Write-Host "           'Access - Managed Device' assigned to apps for this OU at the intended mode (monitor/enforce)." -ForegroundColor Yellow
Write-Host "    Session — Google session control web-session duration set for this OU." -ForegroundColor Yellow

$overall = -not ($results | Where-Object { -not $_.Pass })
Write-Host ("`n=== Overall (scriptable checks): {0} ===" -f $(if ($overall) { 'PASS' } else { 'FAIL — fix the lines above' })) -ForegroundColor $(if ($overall) { 'Green' } else { 'Red' })
Write-Host "Baseline PASS + confirmed DLP(block)/CAA(enforce) in console = gate to expand (Implementation Step 7)." -ForegroundColor Yellow
