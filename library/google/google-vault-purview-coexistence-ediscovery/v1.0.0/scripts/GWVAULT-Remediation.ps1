<#
.SYNOPSIS
    GWVAULT-Remediation.ps1 — close a Vault-side coexistence hold gap by adding a hold (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Closes a coexistence coverage gap on the Google side by creating a Google Vault hold (for the
        named service) inside an existing matter, scoped to the custodians who should be preserved but
        are not yet held in Vault. By default it only REPORTS what it would create (-WhatIf); pass -Apply
        to act. It never deletes matters, releases existing holds, or changes retention rules. It cannot
        touch Microsoft Purview — the MATCHING Purview eDiscovery hold must be placed in the Purview
        portal in parallel (holds do not sync); this script reports the Purview action needed.
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\GWVAULT-Remediation.ps1 -MatterId your-matter-id -Service MAIL -Accounts user1@your-domain,user2@your-domain
        Apply:                  ... .\GWVAULT-Remediation.ps1 -MatterId your-matter-id -Service MAIL -Accounts user1@your-domain -Apply
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with the Vault ediscovery
        scope (https://www.googleapis.com/auth/ediscovery) to create holds. Valid -Service values include
        MAIL, DRIVE, HANGOUTS_CHAT, GROUPS, VOICE, CALENDAR (confirm current corpus names + Gemini-app
        support in your tenant).
    EXPECTED RESULTS
        A preview (or, with -Apply, creation) of a Vault hold in the matter covering the named service +
        custodians. The matching Purview parallel hold is reported for you to place in the portal. Re-run
        GWVAULT-Validation.ps1 / GWVAULT-Report.ps1 to confirm the gap closed on both sides.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf). Always confirm the hold list with
    legal/records counsel first — retention periods and hold scope are legal determinations, not this
    script's. Purview holds, retention alignment, and Gemini-app support are handled in the vendors'
    consoles (verify in your tenant).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$MatterId,
    [Parameter(Mandatory=$true)][ValidateSet('MAIL','DRIVE','HANGOUTS_CHAT','GROUPS','VOICE','CALENDAR')][string]$Service,
    [Parameter(Mandatory=$true)][string[]]$Accounts,
    [string]$HoldName = 'Coexistence - Custodians - Hold',
    [switch]$Apply
)

# Default posture is -WhatIf unless -Apply is explicitly passed.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the Vault ediscovery scope." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

Write-Host "`n=== Vault coexistence hold remediation (matter $MatterId) ===" -ForegroundColor Cyan
Write-Host ("Service: {0}   Accounts: {1}   Hold: {2}" -f $Service, ($Accounts -join ', '), $HoldName)

$desc = "Create Vault hold '$HoldName' [$Service] for $($Accounts.Count) account(s) in matter $MatterId"
if ($PSCmdlet.ShouldProcess($desc, "Create Google Vault hold")) {
    $body = @{
        name     = $HoldName
        corpus   = $Service
        accounts = @($Accounts | ForEach-Object { @{ email = $_ } })
    } | ConvertTo-Json -Depth 5
    try {
        $created = Invoke-RestMethod -Method POST -Headers $headers -Body $body -ErrorAction Stop `
            -Uri ("https://vault.googleapis.com/v1/matters/{0}/holds" -f [uri]::EscapeDataString($MatterId))
        Write-Host ("  CREATED: hold '{0}' [{1}] (id {2})" -f $created.name, $created.corpus, $created.holdId) -ForegroundColor Green
    } catch {
        Write-Host ("  Failed to create hold: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
} else {
    Write-Host ("  WHATIF: would create Vault hold '{0}' [{1}] for: {2}" -f $HoldName, $Service, ($Accounts -join ', ')) -ForegroundColor Yellow
}

Write-Host "`n=== Parallel Purview action (NOT done by this script — holds do not sync) ===" -ForegroundColor Cyan
Write-Host "  Place the MATCHING Purview eDiscovery hold for the SAME custodians:" -ForegroundColor Yellow
Write-Host "    Purview portal > eDiscovery > Cases > (matched case) > Hold policies > Create policy" -ForegroundColor Yellow
Write-Host "    add Exchange mailboxes (+ Teams mailbox/site) and SharePoint/OneDrive; Apply hold (allow 24h)." -ForegroundColor Yellow
if (-not $Apply) { Write-Host "`nPreview only (-WhatIf). Re-run with -Apply after counsel review." -ForegroundColor Yellow }
Write-Host "Then re-run GWVAULT-Validation.ps1 and GWVAULT-Report.ps1 to confirm coverage on both sides." -ForegroundColor Yellow
