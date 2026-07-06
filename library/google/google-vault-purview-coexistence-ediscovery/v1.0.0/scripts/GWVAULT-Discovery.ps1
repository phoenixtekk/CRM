<#
.SYNOPSIS
    GWVAULT-Discovery.ps1 — retention/hold discovery across the Vault + Purview estate (read-only).
.DESCRIPTION
    PURPOSE
        Read-only inventory of the coexistence governance estate. Enumerates the Google-side state via
        the Google Vault API — matters, holds (and the services each covers), and retention rules
        (default + custom) — so you can see what is preserved and retained in Vault before mirroring to
        Microsoft Purview. Vault and Purview do NOT sync, so it also flags the Purview-side surfaces to
        confirm (eDiscovery cases/hold policies, retention policies) for the same custodians. Nothing is
        changed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWVAULT-Discovery.ps1
        Requires a Google super-admin (or delegated) OAuth access token in GOOGLE_OAUTH_TOKEN with the
        READ-ONLY Vault scope ediscovery.readonly (https://www.googleapis.com/auth/ediscovery.readonly).
        Obtain via 'gcloud auth print-access-token' or your OAuth flow. Purview-side inventory is
        confirmed in the Purview portal (or via the Microsoft Graph / Security & Compliance PowerShell) —
        this script flags it, it does not read Purview.
    EXPECTED RESULTS
        A list of Vault matters with their holds (name + held services) and the tenant retention rules,
        plus a reminder of the matching Purview surfaces to confirm. Nothing is changed. Feed the output
        into GWVAULT-Report.ps1 (coverage/gap) and GWVAULT-Validation.ps1. Verify Gemini-app hold/
        retention support in your tenant.
.NOTES
    White-label — the repeatable way. Read-only against the Google Vault API. This is the technical
    mapping, not legal advice: retention periods and hold scope are legal/records-counsel
    determinations. Vault Gemini-app hold/retention support and the Purview eDiscovery experience are
    evolving — verify in your tenant.
#>
[CmdletBinding()]
param(
    [int]$MaxMatters = 200
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the Vault ediscovery.readonly scope (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token" }

function Invoke-GApi([string]$uri) {
    try { Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ErrorAction Stop }
    catch { Write-Host ("  API error: {0}" -f $_.Exception.Message) -ForegroundColor Red; $null }
}

Write-Host "`n=== Vault <-> Purview coexistence: retention/hold discovery (read-only) ===" -ForegroundColor Cyan
Write-Host "Holds do NOT sync between Vault and Purview — this reads the Vault side and flags the Purview side to confirm.`n"

# --- Vault matters + holds ---
Write-Host "=== Google Vault matters & holds ===" -ForegroundColor Cyan
$matterCount = 0; $holdCount = 0; $pageToken = $null
do {
    $uri = "https://vault.googleapis.com/v1/matters?view=BASIC&pageSize=100&state=OPEN"
    if ($pageToken) { $uri += "&pageToken=$pageToken" }
    $resp = Invoke-GApi $uri
    if (-not $resp) { break }
    foreach ($m in $resp.matters) {
        $matterCount++
        Write-Host ("`n  Matter: {0}  (id {1})" -f $m.name, $m.matterId) -ForegroundColor White
        $holds = Invoke-GApi ("https://vault.googleapis.com/v1/matters/{0}/holds?pageSize=100" -f $m.matterId)
        if ($holds -and $holds.holds) {
            foreach ($h in $holds.holds) {
                $holdCount++
                Write-Host ("    HOLD: {0}  [service: {1}]" -f $h.name, $h.corpus) -ForegroundColor Yellow
            }
        } else {
            Write-Host "    (no holds in this matter — confirm a parallel Purview hold is not required)" -ForegroundColor DarkGray
        }
        if ($matterCount -ge $MaxMatters) { break }
    }
    $pageToken = $resp.nextPageToken
} while ($pageToken -and $matterCount -lt $MaxMatters)
Write-Host ("`n  Open matters: {0}   Holds found: {1}" -f $matterCount, $holdCount)

# --- Vault retention rules ---
Write-Host "`n=== Google Vault retention rules ===" -ForegroundColor Cyan
Write-Host "  Confirm default + custom retention rules per service in Vault > Retention:" -ForegroundColor Yellow
Write-Host "    Gmail, Drive, Chat, Meet, Groups, Calendar, Voice, Sites, and the Gemini app (verify in tenant)." -ForegroundColor Yellow
Write-Host "  A Vault HOLD retains indefinitely and takes precedence over retention rules (Google Vault Help)." -ForegroundColor Yellow

# --- Purview-side surfaces to confirm (not read here) ---
Write-Host "`n=== Microsoft Purview side — confirm in the portal (no auto-sync) ===" -ForegroundColor Cyan
Write-Host "  Purview portal > eDiscovery > Cases > Hold policies — a PARALLEL hold for the same custodians" -ForegroundColor Yellow
Write-Host "  (Exchange mailboxes incl. Teams chat/card/meeting data; SharePoint sites / OneDrive incl. Teams files)." -ForegroundColor Yellow
Write-Host "  Purview portal > Data Lifecycle / Records management > Retention policies — aligned to the longer schedule." -ForegroundColor Yellow

Write-Host "`nNext: run GWVAULT-Report.ps1 (coverage/gap across both) and GWVAULT-Validation.ps1 for the pilot scope." -ForegroundColor Yellow
