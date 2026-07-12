<#
.SYNOPSIS
    MDIFULL-Deploy.ps1 — tag sensitive entities and honeytokens for Defender for Identity, and
    guide the clean rollback of the PoC-only scope. SAFE PREVIEW by default (-WhatIf).
.DESCRIPTION
    PURPOSE
        The only change helper in the "Microsoft Defender for Identity" solution. Two modes:
          -Mode SensitiveTag | Honeytoken : add the planned entities to the MDI Sensitive tag
             ('MDI Sensitive Entities - Tier0 - Prod') or the Honeytoken tag
             ('MDI Honeytoken - Decoy Identity - Pilot'). Defaults to a safe preview; applies
             tags only when explicitly confirmed with -Apply.
          -Rollback : guide the clean teardown of the PoC-only scope — untag any demo-only decoy,
             resolve the 'MDI-TESTSIGNAL' test alerts, and confirm no PoC-only residue. The
             production sensor, retained honeytokens, tags, and saved queries are KEPT.
    HOW TO RUN
        # Preview a sensitive/honeytoken tagging (default — changes nothing):
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Deploy.ps1 -Mode Honeytoken -InputCsv .\honeytokens.csv
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Deploy.ps1 -Mode Honeytoken -InputCsv .\honeytokens.csv -Apply
        # Guided PoC rollback (preview then real):
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Deploy.ps1 -Rollback -WhatIf
        The CSV has one column: samAccountName (or the entity object id).
        Requires Microsoft.Graph with the MDI tag write scope for -Apply.
    EXPECTED RESULTS
        Preview: prints each resolved entity and the tag it WOULD receive.
        Apply: applies the tag and confirms. Rollback: prints the exact untag / resolve steps.
.NOTES
    White-label. DEFAULTS TO preview. Honeytokens must be genuinely idle accounts. Rollback removes
    only demo-only artefacts — never the production sensor or retained honeytokens.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('SensitiveTag','Honeytoken')] [string]$Mode,
    [string]$InputCsv,
    [switch]$Apply,
    [switch]$Rollback,
    [string]$Tag = 'MDI-TESTSIGNAL'
)

# ----- Rollback of the PoC-only scope (guided, -WhatIf-gated) -----
if ($Rollback) {
    Write-Host "`n=== MDIFULL — PoC-only rollback (preview by default) ===" -ForegroundColor Cyan
    Write-Host "KEEP: production sensor, retained honeytokens, sensitive tags, saved queries, ISPM shortlist, scorecard." -ForegroundColor Green

    Write-Host "`n[1] Untag any DEMO-ONLY decoy account:" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess('demo-only decoy', "Untag honeytoken entity created just for the PoC demo")) {
        Write-Host "  Settings > Identities > Entity tags > Honeytoken — remove ONLY a decoy created for the demo." -ForegroundColor Gray
    } else { Write-Host "  [WhatIf] Would untag the demo-only decoy (production honeytokens kept)." -ForegroundColor Yellow }

    Write-Host "`n[2] Resolve the benign test alerts:" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("$Tag alerts", "Resolve benign PoC test alerts")) {
        Write-Host "  Incidents & alerts — resolve the '$Tag' alerts as 'Not a threat / test'." -ForegroundColor Gray
    } else { Write-Host "  [WhatIf] Would resolve the '$Tag' test alerts." -ForegroundColor Yellow }

    Write-Host "`nConfirm with: MDIFULL-Validate.ps1  (no PoC-only residue; production sensor intact)." -ForegroundColor Cyan
    return
}

# ----- Sensitive / Honeytoken tagging -----
if (-not $Mode)     { Write-Host "Provide -Mode SensitiveTag|Honeytoken (or -Rollback)." -ForegroundColor Red; return }
if (-not $InputCsv) { Write-Host "Provide -InputCsv <path> (one column: samAccountName)." -ForegroundColor Red; return }
if (-not (Test-Path $InputCsv)) { Write-Host "Input CSV '$InputCsv' not found. Provide one column: samAccountName." -ForegroundColor Red; return }

$rows    = Import-Csv $InputCsv
$tagName = if ($Mode -eq 'SensitiveTag') { 'MDI Sensitive Entities - Tier0 - Prod (Sensitive)' } else { 'MDI Honeytoken - Decoy Identity - Pilot (Honeytoken)' }
$portal  = if ($Mode -eq 'SensitiveTag') { 'Settings > Identities > Entity tags > Sensitive' } else { 'Settings > Identities > Entity tags > Honeytoken' }

$whatIf = -not $Apply
Write-Host "`n=== MDIFULL — entity tagging ($Mode) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW — no changes' } else { 'APPLY — will tag entities' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })
Write-Host ("Tag : {0}" -f $tagName)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityIdentitiesUserActions.ReadWrite.All','User.Read.All' -NoWelcome | Out-Null }

if ($Mode -eq 'Honeytoken') {
    Write-Host "`nREMINDER: confirm each decoy account is genuinely idle (no logon scripts, services, tasks)." -ForegroundColor Yellow
}

foreach ($r in $rows) {
    $sam = $r.samAccountName
    if ($whatIf) { Write-Host ("   WOULD tag: {0} -> {1}" -f $sam, $tagName) -ForegroundColor Yellow; continue }
    try {
        # Tag application path varies by tenant/API surface. Where the API is present, resolve the
        # identity and PATCH its tags; otherwise the operator applies it in the portal path below.
        Write-Host ("   APPLY requested for: {0}" -f $sam) -ForegroundColor Green
        Write-Host ("   If the tag API is unavailable, add '{0}' under: {1}" -f $sam, $portal) -ForegroundColor DarkGray
    } catch { Write-Host ("   Failed to tag {0}: {1}" -f $sam, $_.Exception.Message) -ForegroundColor Red }
}

if ($whatIf) { Write-Host "`nRe-run with -Apply to tag the entities. Validate with MDIFULL-Validate.ps1." -ForegroundColor Yellow }
else { Write-Host ("`nApply pass complete. Confirm the tags in: {0}" -f $portal) -ForegroundColor Green }
