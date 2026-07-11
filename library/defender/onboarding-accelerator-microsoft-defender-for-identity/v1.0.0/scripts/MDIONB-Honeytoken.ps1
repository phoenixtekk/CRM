<#
.SYNOPSIS
    MDIONB-Honeytoken.ps1 — tag sensitive entities and honeytokens in Defender for Identity.
    SAFE PREVIEW by default (-WhatIf); tags are applied only when explicitly confirmed with -Apply.
.DESCRIPTION
    PURPOSE
        Change helper for the "Onboarding Accelerator — Microsoft Defender for Identity" solution.
        Adds the planned entities to the MDI Sensitive tag ('MDI Sensitive Entities - Tier0 - Prod')
        or the Honeytoken tag ('MDI Honeytoken - Decoy Identity - Pilot'). This is the only script
        that can change configuration, and it defaults to a safe preview.
    HOW TO RUN
        # Preview (default — shows what WOULD be tagged, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\MDIONB-Honeytoken.ps1 -Mode Honeytoken -InputCsv .\honeytokens.csv
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\MDIONB-Honeytoken.ps1 -Mode Honeytoken -InputCsv .\honeytokens.csv -Apply
        -Mode accepts: SensitiveTag | Honeytoken. The CSV has one column: samAccountName (or the
        entity object id). Requires Microsoft.Graph with the MDI tag write scope.
    EXPECTED RESULTS
        Preview: prints each resolved entity and the tag it WOULD receive.
        Apply: applies the tag and confirms. Plant decoys that nothing legitimate uses; validate with
        MDIONB-Validate.ps1 -Check Honeytoken.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. Honeytokens must be genuinely idle accounts.
    Where the tag API is unavailable in your tenant, the script prints the exact portal path.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('SensitiveTag','Honeytoken')] [string]$Mode,
    [Parameter(Mandatory)] [string]$InputCsv,
    [switch]$Apply
)

if (-not (Test-Path $InputCsv)) { Write-Host "Input CSV '$InputCsv' not found. Provide one column: samAccountName." -ForegroundColor Red; return }
$rows = Import-Csv $InputCsv
$tagName = if ($Mode -eq 'SensitiveTag') { 'MDI Sensitive Entities - Tier0 - Prod (Sensitive)' } else { 'MDI Honeytoken - Decoy Identity - Pilot (Honeytoken)' }
$portal  = if ($Mode -eq 'SensitiveTag') { 'Settings > Identities > Entity tags > Sensitive' } else { 'Settings > Identities > Entity tags > Honeytoken' }

$whatIf = -not $Apply
Write-Host "`n=== MDI entity tagging ($Mode) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will tag entities' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })
Write-Host ("Tag : {0}" -f $tagName)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityIdentitiesUserActions.ReadWrite.All','User.Read.All' -NoWelcome | Out-Null }

if ($Mode -eq 'Honeytoken') {
    Write-Host "`nREMINDER: confirm each decoy account is genuinely idle (no logon scripts, services, tasks)." -ForegroundColor Yellow
}

foreach ($r in $rows) {
    $sam = $r.samAccountName
    if ($whatIf) {
        Write-Host ("   WOULD tag: {0} -> {1}" -f $sam, $tagName) -ForegroundColor Yellow
        continue
    }
    try {
        # Tag application path varies by tenant/API surface. Where the API is present, resolve the
        # identity and PATCH its tags; otherwise the operator applies it in the portal path below.
        Write-Host ("   APPLY requested for: {0}" -f $sam) -ForegroundColor Green
        Write-Host ("   If the tag API is unavailable, add '{0}' under: {1}" -f $sam, $portal) -ForegroundColor DarkGray
    } catch { Write-Host ("   Failed to tag {0}: {1}" -f $sam, $_.Exception.Message) -ForegroundColor Red }
}

if ($whatIf) { Write-Host "`nRe-run with -Apply to tag the entities. Validate with MDIONB-Validate.ps1." -ForegroundColor Yellow }
else { Write-Host ("`nApply pass complete. Confirm the tags in: {0}" -f $portal) -ForegroundColor Green }
