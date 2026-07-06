<#
.SYNOPSIS
    GEMGOV-Validation.ps1 — per-scope guardrail validation for the Gemini Enterprise pilot (read-only).
.DESCRIPTION
    PURPOSE
        Read-only. Confirms the guardrails held on the pilot scope before you widen it: broad Drive
        sharing removed on the targeted items, DLP/IRM protection present, and the pilot scope group
        exists and is bounded (Gemini enablement and the 'Allow Gemini Enterprise to access Google
        Workspace data' setting are confirmed in the Admin console per edition). Each check is a
        validation gate matching the Testing Guide.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GEMGOV-Validation.ps1 -PilotGroupEmail gemini-pilot@your-domain [-UrlMatch sites/hr]
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with READ-ONLY scopes:
        drive.readonly (or drive.metadata.readonly) and admin.directory.group.readonly. Nothing is written.
    EXPECTED RESULTS
        Per gate: PASS/FAIL for broad-sharing removed on the targeted scope, DLP/IRM present (admin-console
        confirm), and the pilot scope group present. Gemini service on/off and data-access scoping are
        flagged for admin-console confirmation ("verify in your tenant").
.NOTES
    White-label — the repeatable way. Read-only against the Google Drive & Directory APIs. Gemini
    Enterprise service-status and data-access toggles live in Generative AI > Gemini Enterprise (per
    edition) and are evolving / partly preview — confirm them in the Admin console; this script cannot
    assert them and flags them for verification.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$PilotGroupEmail,
    [string]$UrlMatch
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }
function Invoke-GApi([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop }
    catch { $null }
}

$pass = @{}

Write-Host "`n=== Gemini Enterprise pilot guardrail validation ===" -ForegroundColor Cyan

# Gate 1 — broad sharing removed on the targeted scope
Write-Host "`n[Gate 1] Broad Drive sharing removed on targeted scope" -ForegroundColor Cyan
$q = [System.Web.HttpUtility]::UrlEncode("visibility='anyoneWithLink' or visibility='anyoneCanFind' or visibility='domainWithLink' or visibility='domainCanFind'")
$uri = "https://www.googleapis.com/drive/v3/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=100&fields=files(name,webViewLink)&q=$q"
$resp = Invoke-GApi $uri
$broad = @()
if ($resp -and $resp.files) {
    $broad = if ($UrlMatch) { $resp.files | Where-Object { $_.webViewLink -like "*$UrlMatch*" } } else { $resp.files }
}
if (-not $broad -or $broad.Count -eq 0) {
    Write-Host "  PASS — no public/domain-wide items on the targeted scope." -ForegroundColor Green; $pass['broad'] = $true
} else {
    Write-Host ("  FAIL — {0} item(s) still broadly shared. Run GEMGOV-Remediation.ps1 -Apply." -f $broad.Count) -ForegroundColor Red
    $broad | Select-Object -First 10 | ForEach-Object { Write-Host ("    - {0}" -f $_.name) -ForegroundColor Yellow }
    $pass['broad'] = $false
}

# Gate 2 — DLP / IRM present (admin-console confirm)
Write-Host "`n[Gate 2] DLP / IRM guardrails present" -ForegroundColor Cyan
Write-Host "  CONFIRM in Admin console: Security > Data protection — DLP rules apply IRM (prevent" -ForegroundColor Yellow
Write-Host "  download/print/copy) to sensitive content; CSE applied where required. Gemini does not" -ForegroundColor Yellow
Write-Host "  retrieve IRM/CSE-protected content. (Not machine-assertable here — verify in your tenant.)" -ForegroundColor Yellow

# Gate 3 — pilot scope group present
Write-Host "`n[Gate 3] Pilot scope group present and bounded" -ForegroundColor Cyan
$grp = Invoke-GApi ("https://admin.googleapis.com/admin/directory/v1/groups/{0}" -f [uri]::EscapeDataString($PilotGroupEmail))
if ($grp -and $grp.email) {
    Write-Host ("  PASS — pilot group exists: {0} (members: {1})" -f $grp.email, $grp.directMembersCount) -ForegroundColor Green
    $pass['group'] = $true
} else {
    Write-Host ("  FAIL — pilot group '{0}' not found. Create it with GEMGOV-Set-ScopeTargeting.ps1." -f $PilotGroupEmail) -ForegroundColor Red
    $pass['group'] = $false
}

# Gate 4 — Gemini enablement + data-access scoped (verify in tenant)
Write-Host "`n[Gate 4] Gemini enablement & data-access scoped to the pilot" -ForegroundColor Cyan
Write-Host "  CONFIRM in Admin console (verify in your tenant):" -ForegroundColor Yellow
Write-Host "    Generative AI > Gemini Enterprise > Service status = On for the pilot OU/group only." -ForegroundColor Yellow
Write-Host "    'Allow Gemini Enterprise to access Google Workspace data' = scoped to the pilot only." -ForegroundColor Yellow

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host ("  Gate 1 broad-sharing removed .. {0}" -f ($(if($pass['broad']){'PASS'}else{'FAIL'})))
Write-Host  "  Gate 2 DLP/IRM present ........ CONFIRM in Admin console"
Write-Host ("  Gate 3 pilot group present ... {0}" -f ($(if($pass['group']){'PASS'}else{'FAIL'})))
Write-Host  "  Gate 4 enablement pilot-only .. CONFIRM in Admin console (verify in your tenant)"
Write-Host "`nComplete the exposure probes in the Testing Guide (Tests 4-6) before the pilot gate." -ForegroundColor Yellow
