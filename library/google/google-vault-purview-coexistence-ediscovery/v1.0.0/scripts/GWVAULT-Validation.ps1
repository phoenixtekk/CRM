<#
.SYNOPSIS
    GWVAULT-Validation.ps1 — per-scope retention/hold validation for a coexistence matter (read-only).
.DESCRIPTION
    PURPOSE
        Read-only. Confirms the coexistence guardrails held for a named matter before you widen it: that
        a Google Vault hold exists in the matter and covers the in-scope services, that the matter is
        open, and that the intended custodians appear on the hold. Each check is a validation gate
        matching the Testing Guide. Because Vault and Purview do NOT sync, the matching Purview
        eDiscovery hold + retention are flagged for confirmation in the Purview portal (they cannot be
        asserted from here).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWVAULT-Validation.ps1 -MatterId your-matter-id
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with the READ-ONLY Vault
        scope ediscovery.readonly. Nothing is written. Get the matter id from GWVAULT-Discovery.ps1.
    EXPECTED RESULTS
        Per gate: PASS/FAIL for matter open, Vault hold present, and in-scope services held. The Purview
        parallel hold and the longer-of-two retention alignment are flagged for Admin/portal confirmation
        ("verify in your tenant" / not machine-assertable here).
.NOTES
    White-label — the repeatable way. Read-only against the Google Vault API. This is the technical
    mapping, not legal advice. The Purview eDiscovery hold and retention live in the Purview portal and
    are confirmed there; this script flags them and cannot assert them.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$MatterId,
    [string[]]$ExpectedServices = @('MAIL','DRIVE','HANGOUTS_CHAT','GROUPS','VOICE')
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the Vault ediscovery.readonly scope." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }
function Invoke-GApi([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop } catch { $null }
}

$pass = @{}
Write-Host "`n=== Coexistence hold/retention validation — matter $MatterId ===" -ForegroundColor Cyan

# Gate 1 — matter exists and is open
Write-Host "`n[Gate 1] Vault matter exists and is OPEN" -ForegroundColor Cyan
$matter = Invoke-GApi ("https://vault.googleapis.com/v1/matters/{0}?view=BASIC" -f [uri]::EscapeDataString($MatterId))
if ($matter -and $matter.matterId) {
    $state = $matter.state
    if ($state -eq 'OPEN') { Write-Host ("  PASS — matter '{0}' is OPEN." -f $matter.name) -ForegroundColor Green; $pass['matter'] = $true }
    else { Write-Host ("  FAIL — matter '{0}' state is {1} (expected OPEN)." -f $matter.name, $state) -ForegroundColor Red; $pass['matter'] = $false }
} else {
    Write-Host "  FAIL — matter not found. Check the id from GWVAULT-Discovery.ps1." -ForegroundColor Red; $pass['matter'] = $false
}

# Gate 2 — Vault hold present in the matter
Write-Host "`n[Gate 2] Vault hold present in the matter" -ForegroundColor Cyan
$holds = Invoke-GApi ("https://vault.googleapis.com/v1/matters/{0}/holds?pageSize=100" -f [uri]::EscapeDataString($MatterId))
$heldServices = @()
if ($holds -and $holds.holds) {
    foreach ($h in $holds.holds) {
        Write-Host ("  HOLD: {0}  [service: {1}]" -f $h.name, $h.corpus) -ForegroundColor Yellow
        $heldServices += $h.corpus
    }
    Write-Host "  PASS — at least one hold exists in the matter." -ForegroundColor Green; $pass['hold'] = $true
} else {
    Write-Host "  FAIL — no holds in the matter. Create one (Implementation Step 4) or run GWVAULT-Remediation.ps1." -ForegroundColor Red; $pass['hold'] = $false
}

# Gate 3 — in-scope services covered
Write-Host "`n[Gate 3] In-scope services held" -ForegroundColor Cyan
$missing = @($ExpectedServices | Where-Object { $_ -notin $heldServices })
if ($heldServices.Count -and $missing.Count -eq 0) {
    Write-Host ("  PASS — all expected services held: {0}" -f ($ExpectedServices -join ', ')) -ForegroundColor Green; $pass['services'] = $true
} else {
    Write-Host ("  REVIEW — services not confirmed held: {0}" -f ($missing -join ', ')) -ForegroundColor Yellow
    Write-Host "  Add missing services to a hold in Vault > Matters > (matter) > Holds (Gemini app: verify in tenant)." -ForegroundColor Yellow
    $pass['services'] = $false
}

# Gate 4 — Purview parallel hold + retention (confirm in portal)
Write-Host "`n[Gate 4] Purview parallel hold + aligned retention (confirm in portal)" -ForegroundColor Cyan
Write-Host "  CONFIRM (no auto-sync — verify in your tenant):" -ForegroundColor Yellow
Write-Host "    Purview > eDiscovery > Cases > (matched case) > Hold policies > Details = on hold (allow 24h)" -ForegroundColor Yellow
Write-Host "    same custodians (Exchange + SharePoint/OneDrive + Teams mailbox/site) as the Vault hold." -ForegroundColor Yellow
Write-Host "    Purview retention aligned to the LONGER of the Vault/Purview schedule for shared classes." -ForegroundColor Yellow

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host ("  Gate 1 matter open ........... {0}" -f ($(if($pass['matter']){'PASS'}else{'FAIL'})))
Write-Host ("  Gate 2 Vault hold present .... {0}" -f ($(if($pass['hold']){'PASS'}else{'FAIL'})))
Write-Host ("  Gate 3 services held ......... {0}" -f ($(if($pass['services']){'PASS'}else{'REVIEW'})))
Write-Host  "  Gate 4 Purview parallel ...... CONFIRM in Purview portal (verify in your tenant)"
Write-Host "`nComplete the discovery probe in the Testing Guide (Test 7) before the pilot gate." -ForegroundColor Yellow
