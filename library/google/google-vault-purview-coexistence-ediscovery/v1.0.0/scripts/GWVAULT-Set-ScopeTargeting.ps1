<#
.SYNOPSIS
    GWVAULT-Set-ScopeTargeting.ps1 — create the coexistence pilot custodian scope + matter (idempotent, default -WhatIf).
.DESCRIPTION
    PURPOSE
        Sets up the objects used to scope the controlled coexistence rollout so Vault and Purview holds
        can be targeted at the SAME pilot custodians under the SAME matter name:
            - a Google Workspace group for the pilot custodians:  Coexistence - Pilot Custodians - Pilot
            - a Google Vault matter (matched to the Purview case name):  Litigation - <Scope> - Hold
        Existing objects (matched by group email / matter name) are reused, not duplicated. Members are
        NOT added — add representative pilot custodians by hand. Create the MATCHING Purview eDiscovery
        case with the identical name in the Purview portal (holds do not sync).
    HOW TO RUN
        Report only (default):  powershell -ExecutionPolicy Bypass -File .\GWVAULT-Set-ScopeTargeting.ps1 -GroupEmail coexistence-pilot@your-domain -MatterName "Litigation - Acme v. Example - Hold"
        Apply:                  ... -GroupEmail coexistence-pilot@your-domain -MatterName "Litigation - Acme v. Example - Hold" -Apply
        Requires a Google super-admin OAuth access token in GOOGLE_OAUTH_TOKEN with scopes
        admin.directory.group (create/read groups) and ediscovery (create/read Vault matters).
    EXPECTED RESULTS
        The pilot scope group and the Vault matter exist (created if missing, reused if present), with
        their identifiers printed for use in Vault hold targeting — and a reminder to create the matched
        Purview case with the identical name.
.NOTES
    White-label — the repeatable way. Safe by default (-WhatIf); pass -Apply to create. Display names use
    ASCII hyphens; keep the matter name VERBATIM as the Purview case name so the parallel holds are
    unmistakably the same matter. This is the technical mapping, not legal advice.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)][string]$GroupEmail,
    [Parameter(Mandatory=$true)][string]$MatterName,
    [switch]$Apply
)

if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token with the admin.directory.group and ediscovery scopes." -ForegroundColor Red
    return
}
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$groupDisplay = 'Coexistence - Pilot Custodians - Pilot'

Write-Host "`n=== Coexistence pilot scope group + Vault matter ===" -ForegroundColor Cyan

# --- Pilot custodian group (reuse if present) ---
Write-Host "`n[1] Pilot custodian group" -ForegroundColor Cyan
$existingGrp = $null
try {
    $existingGrp = Invoke-RestMethod -Method GET -Headers $headers -ErrorAction Stop `
        -Uri ("https://admin.googleapis.com/admin/directory/v1/groups/{0}" -f [uri]::EscapeDataString($GroupEmail))
} catch { $existingGrp = $null }

if ($existingGrp -and $existingGrp.email) {
    Write-Host ("  EXISTS: {0}  ({1}, id {2})" -f $groupDisplay, $existingGrp.email, $existingGrp.id) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($groupDisplay, "Create Google Workspace group ($GroupEmail)")) {
        $gbody = @{ email = $GroupEmail; name = $groupDisplay; description = "Pilot custodian scope for Vault<->Purview coexistence holds ($groupDisplay)." } | ConvertTo-Json
        try {
            $created = Invoke-RestMethod -Method POST -Headers $headers -Body $gbody -ErrorAction Stop `
                -Uri "https://admin.googleapis.com/admin/directory/v1/groups"
            Write-Host ("  CREATED: {0}  ({1}, id {2})" -f $groupDisplay, $created.email, $created.id) -ForegroundColor Green
        } catch { Write-Host ("  Failed to create group {0}: {1}" -f $GroupEmail, $_.Exception.Message) -ForegroundColor Red }
    } else {
        Write-Host ("  WHATIF: would create group {0} ({1})" -f $groupDisplay, $GroupEmail) -ForegroundColor Yellow
    }
}

# --- Vault matter (reuse if a matching open matter exists) ---
Write-Host "`n[2] Vault matter (matched to the Purview case name)" -ForegroundColor Cyan
$existingMatter = $null
try {
    $ms = Invoke-RestMethod -Method GET -Headers $headers -ErrorAction Stop `
        -Uri "https://vault.googleapis.com/v1/matters?view=BASIC&pageSize=100&state=OPEN"
    if ($ms -and $ms.matters) { $existingMatter = $ms.matters | Where-Object { $_.name -eq $MatterName } | Select-Object -First 1 }
} catch { $existingMatter = $null }

if ($existingMatter) {
    Write-Host ("  EXISTS: matter '{0}'  (id {1})" -f $existingMatter.name, $existingMatter.matterId) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($MatterName, "Create Google Vault matter")) {
        $mbody = @{ name = $MatterName; description = "Coexistence matter; mirror as the identically named Purview eDiscovery case." } | ConvertTo-Json
        try {
            $cm = Invoke-RestMethod -Method POST -Headers $headers -Body $mbody -ErrorAction Stop `
                -Uri "https://vault.googleapis.com/v1/matters"
            Write-Host ("  CREATED: matter '{0}'  (id {1})" -f $cm.name, $cm.matterId) -ForegroundColor Green
        } catch { Write-Host ("  Failed to create matter '{0}': {1}" -f $MatterName, $_.Exception.Message) -ForegroundColor Red }
    } else {
        Write-Host ("  WHATIF: would create Vault matter '{0}'" -f $MatterName) -ForegroundColor Yellow
    }
}

Write-Host "`nNext: add representative pilot custodians to the group, place the Vault hold in the matter" -ForegroundColor Yellow
Write-Host "(Implementation Step 4), and create the MATCHING Purview case with the identical name '$MatterName'" -ForegroundColor Yellow
Write-Host "then its parallel eDiscovery hold (Implementation Step 5; verify in your tenant)." -ForegroundColor Yellow
