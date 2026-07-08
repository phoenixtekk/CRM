<#
.SYNOPSIS
    DLPCLOUD-FilePolicy.ps1 — cloud-app DLP policy config helper (validates + emits the spec; -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Prepares a Defender for Cloud Apps FILE or SESSION policy safely. It (1) validates that the
        sensitive-information-type and/or sensitivity label the policy will match on actually exist in the
        tenant (Security & Compliance PowerShell), and (2) emits the exact, ready-to-enter policy
        specification (filters + governance/session action) to configure in Cloud apps -> Policies. MDCA
        file/session policies are not created by a supported PowerShell cmdlet, so this helper does not
        write policy by default: with -WhatIf it validates and prints the spec only. If an MDCA REST API
        token is supplied (env var), -WhatIf can also list existing policies read-only. It NEVER emits an
        enforcing spec by default — the initial spec is alert-only (file) / Monitor-only (session).
    HOW TO RUN
        # Validate + print a file-policy spec (alert-only) for the Credit Card SIT + Confidential label:
        powershell -File .\DLPCLOUD-FilePolicy.ps1 -PolicyName 'MDCA - SaaS Files PII - File Policy' `
            -PolicyType File -App 'Box' -Sit 'Credit Card Number' -Label 'Confidential' -WhatIf
        # Session-policy spec (Monitor only) controlling download:
        powershell -File .\DLPCLOUD-FilePolicy.ps1 -PolicyName 'MDCA - Download Protect PII - Session Policy' `
            -PolicyType Session -App 'Box' -Sit 'Credit Card Number' -WhatIf
        Requires Security & Compliance PowerShell (Connect-IPPSSession) for SIT/label validation.
    EXPECTED RESULTS
        -WhatIf: prints VALID/MISSING for each referenced SIT/label and the full policy spec to enter in
        the portal (test-mode action). PASS signal: all referenced detectors report VALID and the emitted
        action is non-enforcing (alert-only / Monitor only). -Commit is reserved and refuses to emit an
        enforcing action.
.NOTES
    Purview — Cloud-App DLP. Validation is read-only; no supported write cmdlet exists for MDCA policies, so this helper emits a spec (never enforcing by default). No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [ValidateSet('File','Session','Access')][string]$PolicyType = 'File',
    [string]$App = 'Box',
    [string[]]$Sit = @('Credit Card Number'),
    [string]$Label,
    [int]$MinCount = 10,
    [ValidateSet('Low','Medium','High')][string]$Confidence = 'High',
    # Non-enforcing test-mode actions only unless the operator deliberately overrides in the portal.
    [ValidateSet('AlertOnly','MonitorOnly')][string]$Action = $(if ($PolicyType -eq 'File') { 'AlertOnly' } else { 'MonitorOnly' }),
    [string]$UserPrincipalName,
    # Your MDCA/Defender portal URL — only used to list existing policies read-only if MDCA_API_TOKEN is set.
    [string]$McasUrl,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host ("=== MDCA {0} policy spec: '{1}' ===" -f $PolicyType, $PolicyName) -ForegroundColor Cyan

# --- Validate the referenced detectors exist (read-only) ---
$allValid = $true
$allSits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
foreach ($s in $Sit) {
    $exists = [bool]($allSits | Where-Object { $_.Name -eq $s })
    if ($exists) { Write-Host ("  SIT   VALID  : {0}" -f $s) -ForegroundColor Green }
    else { Write-Host ("  SIT   MISSING: {0} (create it in Purview first)" -f $s) -ForegroundColor Yellow; $allValid = $false }
}
if ($Label) {
    $labels = Get-Label -ErrorAction SilentlyContinue
    $lblExists = [bool]($labels | Where-Object { $_.DisplayName -eq $Label -or $_.Name -eq $Label })
    if ($lblExists) { Write-Host ("  LABEL VALID  : {0}" -f $Label) -ForegroundColor Green }
    else { Write-Host ("  LABEL MISSING: {0} (create/publish it in Purview first)" -f $Label) -ForegroundColor Yellow; $allValid = $false }
}

$confMap = @{ Low = 65; Medium = 75; High = 85 }
$minConfidence = $confMap[$Confidence]

# --- Emit the policy spec to enter in the portal ---
Write-Host '--- Policy specification (enter in Defender portal -> Cloud apps -> Policies) ---' -ForegroundColor Cyan
Write-Host ("  Type            : {0} policy" -f $PolicyType)
Write-Host ("  Name            : {0}" -f $PolicyName)
Write-Host ("  App filter      : {0}" -f $App)
Write-Host ("  Content match   : SIT(s) [{0}] minCount={1} minConfidence={2}{3}" -f ($Sit -join '; '), $MinCount, $minConfidence, $(if ($Label) { " ; sensitivity label = '$Label'" } else { '' }))
switch ($PolicyType) {
    'File'    { Write-Host ("  Extra filters   : sharing level = external/public (recommended first)")
                Write-Host ("  Governance      : {0} => Create alert + Notify owner (NO remove-sharing/label/quarantine/trash yet)" -f $Action) }
    'Session' { Write-Host ("  Session control : Control file download (with inspection)")
                Write-Host ("  Action          : {0} (NO block/protect yet)" -f $Action)
                Write-Host ("  Requires        : CA App Control routing for '{0}' (Entra CA policy, report-only) — Req 2.4" -f $App) }
    'Access'  { Write-Host ("  Access filter   : device tag = unmanaged/non-compliant")
                Write-Host ("  Action          : {0} (NO block yet)" -f $Action)
                Write-Host ("  Requires        : CA App Control routing for '{0}' — Req 2.4" -f $App) }
}

# --- MDCA REST read-only listing (optional) ---
$token = $env:MDCA_API_TOKEN
if ($token -and $McasUrl) {
    $headers = @{ Authorization = "Token $token" }
    try {
        $pol = Invoke-RestMethod -Method Get -Uri ("{0}/api/v1/policies/" -f $McasUrl.TrimEnd('/')) -Headers $headers -ErrorAction Stop
        Write-Host ("Existing MDCA policies in tenant: {0}" -f (@($pol.data).Count)) -ForegroundColor Green
    } catch {
        Write-Host ("MDCA REST policy list skipped/failed: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
    }
}

# --- Safety gate ---
if ($Commit) {
    Write-Host 'SAFETY: MDCA file/session/access policies have no supported creation cmdlet; this helper only emits the spec.' -ForegroundColor Yellow
    Write-Host 'Create the policy in the Defender portal using the spec above, keeping the action NON-ENFORCING (alert-only / Monitor only) first.' -ForegroundColor Yellow
} else {
    if ($allValid) { Write-Host 'PASS: all referenced detectors exist. Enter the spec above (test mode), then measure with DLPCLOUD-Report.ps1.' -ForegroundColor Green }
    else { Write-Host 'FIX: create the MISSING SIT/label in Purview before configuring this policy.' -ForegroundColor Yellow }
}
