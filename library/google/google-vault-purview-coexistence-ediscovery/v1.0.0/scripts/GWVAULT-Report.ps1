<#
.SYNOPSIS
    GWVAULT-Report.ps1 — coverage/gap report for Vault <-> Purview coexistence holds (read-only).
.DESCRIPTION
    PURPOSE
        Read-only. Builds the coexistence coverage/gap picture that drives the pilot and expansion gates:
        across the Google Vault estate it counts open matters, holds, and the services each hold covers,
        and (given an optional custodian list) flags custodians that appear held in Vault so you can
        confirm the MATCHING Purview eDiscovery hold exists — because holds do NOT sync, a custodian held
        on only one ecosystem is a coexistence gap. Use the baseline before rollout and re-run to prove
        both-sides coverage.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWVAULT-Report.ps1 [-CsvPath .\coexistence-coverage.csv] [-CustodianCsv .\custodians.csv]
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with the READ-ONLY Vault
        scope ediscovery.readonly. Optional -CustodianCsv is a local file with an 'email' column of
        in-scope custodians. Nothing is written to the tenant (only the optional local CSV).
    EXPECTED RESULTS
        A summary: open matters, total holds, services covered, and (if provided) which custodians are
        held in Vault vs still to confirm on Purview. Optional CSV of the rows. Save the baseline; re-run
        after each wave and confirm every both-sides custodian is held on both (Testing Test 6).
.NOTES
    White-label — the repeatable way. Read-only against the Google Vault API. This is the technical
    mapping, not legal advice. The Purview coverage is confirmed in the Purview portal (eDiscovery cases
    / hold policies); this report reads the Vault side and marks the Purview side to confirm.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$CustodianCsv,
    [int]$MaxMatters = 200
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

$rows = @()
$matterCount = 0; $holdCount = 0; $heldAccounts = @{}
$services = @{}
$pageToken = $null
do {
    $uri = "https://vault.googleapis.com/v1/matters?view=BASIC&pageSize=100&state=OPEN"
    if ($pageToken) { $uri += "&pageToken=$pageToken" }
    $resp = Invoke-GApi $uri
    if (-not $resp) { break }
    foreach ($m in $resp.matters) {
        $matterCount++
        $holds = Invoke-GApi ("https://vault.googleapis.com/v1/matters/{0}/holds?view=FULL_HOLD&pageSize=100" -f $m.matterId)
        if ($holds -and $holds.holds) {
            foreach ($h in $holds.holds) {
                $holdCount++
                if ($h.corpus) { $services[$h.corpus] = $true }
                foreach ($acct in @($h.accounts)) {
                    if ($acct.email) { $heldAccounts[$acct.email.ToLower()] = $true }
                }
                $rows += [pscustomobject]@{
                    Matter   = $m.name
                    Hold     = $h.name
                    Service  = $h.corpus
                    Scope    = if ($h.orgUnit) { 'OrgUnit' } elseif ($h.accounts) { 'Accounts' } else { 'n/a' }
                }
            }
        }
        if ($matterCount -ge $MaxMatters) { break }
    }
    $pageToken = $resp.nextPageToken
} while ($pageToken -and $matterCount -lt $MaxMatters)

Write-Host "`n=== Vault <-> Purview coexistence coverage/gap report ===" -ForegroundColor Cyan
Write-Host ("  Open Vault matters ............ {0}" -f $matterCount)
Write-Host ("  Vault holds ................... {0}" -f $holdCount) -ForegroundColor $(if($holdCount){'Green'}else{'Yellow'})
Write-Host ("  Services covered by holds ..... {0}" -f (($services.Keys | Sort-Object) -join ', '))
Write-Host  "  Purview parallel coverage ..... confirm in Purview portal (eDiscovery cases/hold policies; no auto-sync)" -ForegroundColor DarkGray

# --- Custodian gap check (Vault side; Purview side to confirm) ---
if ($CustodianCsv -and (Test-Path $CustodianCsv)) {
    Write-Host "`n=== Custodian coverage (Vault side; confirm Purview parallel hold) ===" -ForegroundColor Cyan
    $custodians = Import-Csv $CustodianCsv
    foreach ($c in $custodians) {
        $email = ($c.email).ToLower()
        $inVault = $heldAccounts.ContainsKey($email)
        $tag = if ($inVault) { 'HELD in Vault — confirm Purview parallel hold' } else { 'NOT held in Vault — coexistence GAP; place Vault hold + confirm Purview' }
        $color = if ($inVault) { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-40}  {1}" -f $email, $tag) -ForegroundColor $color
        $rows += [pscustomobject]@{ Matter='(custodian)'; Hold=$email; Service=$(if($inVault){'VaultHeld'}else{'GAP'}); Scope='Custodian' }
    }
    Write-Host "  Note: OrgUnit-scoped Vault holds may cover custodians not listed as explicit accounts — verify in Vault." -ForegroundColor DarkGray
}

if ($CsvPath -and $rows.Count) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}

Write-Host "`nSave this baseline; re-run after each wave and confirm every both-sides custodian is held on both (Testing Test 6)." -ForegroundColor Yellow
