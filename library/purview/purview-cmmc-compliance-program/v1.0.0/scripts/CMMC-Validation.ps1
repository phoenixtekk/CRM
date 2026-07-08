<#
.SYNOPSIS
    CMMC-Validation.ps1 — read-only check of the technical signals behind automatable NIST 800-171 actions.
.DESCRIPTION
    PURPOSE
        Confirms whether the underlying Microsoft 365 technical controls that Compliance Manager can
        AUTOMATICALLY TEST for the CMMC (NIST SP 800-171) assessment are actually present, so you can
        tell which improvement actions can auto-pass and which still need MANUAL evidence. It maps each
        checked signal to a NIST 800-171 family: unified audit logging (AU), Conditional Access / MFA
        (AC, IA), DLP + sensitivity-label + retention policies (MP, SC, media/records). It does NOT
        score CMMC and does NOT replace the portal or the C3PAO determination.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMMC-Validation.ps1
        Sign in as a Compliance Administrator / Global Reader when prompted (S&C PowerShell + Graph).
        For GCC High pass -ExoConnectionUri / -GraphEnvironment as in CMMC-Discovery.ps1.
    EXPECTED RESULTS
        A family-by-family PASS/GAP table of the technical signals. "SIGNALS PRESENT" when the core
        automatable controls are found; any GAP is a candidate for manual evidence or a POA&M item.
        Read-only — makes no changes. Exit 0 if no gaps in the core signals, 1 otherwise.
.NOTES
    White-label — Purview Solutions. Read-only.
    Uses Get-AdminAuditLogConfig / Get-DlpCompliancePolicy / Get-Label / Get-RetentionCompliancePolicy
    (S&C PowerShell) and Get-MgIdentityConditionalAccessPolicy (Graph). Signal presence is NOT a CMMC
    pass — evidence adequacy is a compliance/C3PAO determination. Verify per your tenant/cloud.
#>
[CmdletBinding()] param(
    [string]$ExoConnectionUri,
    [string]$GraphEnvironment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if ($ExoConnectionUri) { Connect-IPPSSession -ConnectionUri $ExoConnectionUri -ShowBanner:$false }
else                   { Connect-IPPSSession -ShowBanner:$false }

Write-Host "`n=== Purview CMMC — technical-signal validation (NIST 800-171) ===" -ForegroundColor Cyan
$results = New-Object System.Collections.Generic.List[object]
function Add-Result([string]$Family,[string]$Signal,[bool]$Ok,[string]$Detail) {
    $results.Add([pscustomobject]@{ Family=$Family; Signal=$Signal; State=($(if($Ok){'PASS'}else{'GAP'})); Detail=$Detail })
}

# AU — unified audit logging
try {
    $audit = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = [bool]$audit.UnifiedAuditLogIngestionEnabled
    Add-Result 'AU (Audit & Accountability)' 'Unified audit logging enabled' $on ($(if($on){'On'}else{'Off — enable auditing'}))
} catch { Add-Result 'AU (Audit & Accountability)' 'Unified audit logging enabled' $false ("read failed: {0}" -f $_.Exception.Message) }

# MP/SC — DLP policies present
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    Add-Result 'SC/MP (Protection of CUI)' 'DLP policy present' ($dlp.Count -ge 1) ("{0} DLP policy(ies)" -f $dlp.Count)
} catch { Add-Result 'SC/MP (Protection of CUI)' 'DLP policy present' $false ("read failed: {0}" -f $_.Exception.Message) }

# SC/MP — sensitivity labels present (CUI marking/protection)
try {
    $labels = @(Get-Label -ErrorAction Stop)
    Add-Result 'SC/MP (CUI marking & protection)' 'Sensitivity label present' ($labels.Count -ge 1) ("{0} label(s)" -f $labels.Count)
} catch { Add-Result 'SC/MP (CUI marking & protection)' 'Sensitivity label present' $false ("read failed: {0}" -f $_.Exception.Message) }

# MP/AU — retention policy present (records/media)
try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    Add-Result 'MP (Media / records retention)' 'Retention policy present' ($ret.Count -ge 1) ("{0} retention policy(ies)" -f $ret.Count)
} catch { Add-Result 'MP (Media / records retention)' 'Retention policy present' $false ("read failed: {0}" -f $_.Exception.Message) }

# AC/IA — Conditional Access / MFA (via Graph)
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction Stop
    Connect-MgGraph -Scopes 'Policy.Read.All' -Environment $GraphEnvironment -NoWelcome
    $ca = @(Get-MgIdentityConditionalAccessPolicy -ErrorAction Stop)
    $enabled = @($ca | Where-Object { $_.State -eq 'enabled' })
    $mfa = @($ca | Where-Object { $_.State -eq 'enabled' -and ($_.GrantControls.BuiltInControls -contains 'mfa') })
    Add-Result 'AC/IA (Access control & auth)' 'Conditional Access policy enabled' ($enabled.Count -ge 1) ("{0} enabled CA policy(ies)" -f $enabled.Count)
    Add-Result 'IA (Identification & Auth)'   'MFA enforced by a CA policy'        ($mfa.Count -ge 1)     ("{0} CA policy(ies) requiring MFA" -f $mfa.Count)
    Disconnect-MgGraph | Out-Null
} catch {
    Add-Result 'AC/IA (Access control & auth)' 'Conditional Access / MFA' $false ("Graph read unavailable: {0}" -f $_.Exception.Message)
}

Write-Host ""
$results | Format-Table Family, Signal, State, Detail -AutoSize
$gaps = @($results | Where-Object { $_.State -eq 'GAP' })
if ($gaps.Count -eq 0) {
    Write-Host "`nResult: SIGNALS PRESENT — the core automatable NIST 800-171 controls are configured." -ForegroundColor Green
    Write-Host "Note: signal presence is not a CMMC pass; evidence adequacy is a compliance/C3PAO determination." -ForegroundColor Cyan
} else {
    Write-Host ("`nResult: {0} GAP(s) — supply MANUAL evidence or add to the POA&M; pilot any technical remediation in simulation/test." -f $gaps.Count) -ForegroundColor Yellow
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
if ($gaps.Count -eq 0) { exit 0 } else { exit 1 }
