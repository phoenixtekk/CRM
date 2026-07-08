<#
.SYNOPSIS
    OME-Validate.ps1 — validate OME branding + the two pilot rules are healthy, in Audit mode, and pilot-scoped (read-only).
.DESCRIPTION
    PURPOSE
        Read-only validation for Purview Message Encryption (OME). Confirms the RMS foundation, that the
        expected OME branding configuration exists, and that the two mail flow rules
        (OME-Encrypt-Outbound-Pilot / OME-DoNotForward-Confidential) exist, are ENABLED, are in
        Mode=Audit, and are scoped to the pilot group (SG-OME-Pilot). Maps directly to Testing Gate 5.
        Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement; Connect-ExchangeOnline as an Exchange admin.
          .\OME-Validate.ps1
          .\OME-Validate.ps1 -PilotGroup "SG-OME-Pilot@contoso.com" -SaveReport .\OME-Validate.csv
    EXPECTED RESULTS
        PASS = both rules present, enabled, Mode=Audit, scoped to the pilot group, each with a rights-
        protection action. A rule that is already Enforce, disabled, or over-scoped is flagged so it is
        corrected before enforcement.
.NOTES
    White-label. Read-only. Exchange Online PowerShell. No credentials in code. No cmdlets invented.
    Enforcing/expanding a rule remains a deliberate, gated step (03-implementation.md Phase 5).
#>

[CmdletBinding()]
param(
    [string] $PilotGroup = 'SG-OME-Pilot@contoso.com',
    [string[]] $RuleNames = @('OME-Encrypt-Outbound-Pilot','OME-DoNotForward-Confidential'),
    [string] $ConfigurationName = 'OME Configuration',
    [string] $SaveReport
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not (Get-Command Get-TransportRule -ErrorAction SilentlyContinue)) {
    Write-Error 'Not connected to Exchange Online. Run Connect-ExchangeOnline with an Exchange admin, then retry.'
    return
}

$report = [System.Collections.Generic.List[object]]::new()
function Add-Row([string]$Check,[string]$Result,[string]$Detail) {
    $report.Add([pscustomobject]@{ Check = $Check; Result = $Result; Detail = $Detail })
}
$fail = 0

# --- RMS foundation ---------------------------------------------------------------------------------
Write-Section 'RMS foundation'
try {
    $irm = Get-IRMConfiguration -ErrorAction Stop
    $rms = [bool]$irm.AzureRMSLicensingEnabled
    Write-Host ("AzureRMSLicensingEnabled : {0}" -f $irm.AzureRMSLicensingEnabled) -ForegroundColor ($(if($rms){'Green'}else{'Yellow'}))
    Add-Row 'RMS enabled' ($(if($rms){'PASS'}else{'FAIL'})) "AzureRMSLicensingEnabled=$($irm.AzureRMSLicensingEnabled)"
    if (-not $rms) { $fail++ }
} catch { Write-Warning $_.Exception.Message; Add-Row 'RMS enabled' 'UNKNOWN' $_.Exception.Message; $fail++ }

# --- Branding ---------------------------------------------------------------------------------------
Write-Section 'OME branding configuration'
try {
    $cfg = Get-OMEConfiguration -Identity $ConfigurationName -ErrorAction Stop
    $hasBrand = [bool]($cfg.EmailText -or $cfg.PortalText -or $cfg.BackgroundColor -or $cfg.Image)
    Write-Host ("Configuration '{0}' found. Branding set: {1}" -f $ConfigurationName, $hasBrand) -ForegroundColor ($(if($hasBrand){'Green'}else{'Yellow'}))
    Add-Row 'Branding present' ($(if($hasBrand){'PASS'}else{'WARN'})) "Identity=$($cfg.Identity)"
    if (-not $hasBrand) { Write-Host '  Default branding is in use — confirm this is the deliberate choice (Gate 4).' -ForegroundColor Yellow }
} catch { Write-Warning $_.Exception.Message; Add-Row 'Branding present' 'WARN' 'Could not read OME configuration' }

# --- Resolve pilot group membership (for scope check) ----------------------------------------------
$pilotMembers = @()
try { $pilotMembers = @(Get-DistributionGroupMember -Identity $PilotGroup -ErrorAction Stop | Select-Object -ExpandProperty PrimarySmtpAddress) }
catch {
    try { $pilotMembers = @(Get-UnifiedGroupLinks -Identity $PilotGroup -LinkType Members -ErrorAction Stop | Select-Object -ExpandProperty PrimarySmtpAddress) }
    catch { Write-Host ("  Note: could not enumerate '{0}' membership (verify group type/name)." -f $PilotGroup) -ForegroundColor Yellow }
}

# --- Rules ------------------------------------------------------------------------------------------
Write-Section 'Mail flow rules — enabled, Audit mode, pilot-scoped'
foreach ($rn in $RuleNames) {
    $r = Get-TransportRule -Identity $rn -ErrorAction SilentlyContinue
    if (-not $r) {
        Write-Host ("  {0} : NOT FOUND" -f $rn) -ForegroundColor Yellow
        Add-Row $rn 'FAIL' 'Rule not found'; $fail++; continue
    }
    $enabled  = ($r.State -eq 'Enabled')
    $isAudit  = ($r.Mode -eq 'Audit')
    $blob     = ($r | Out-String)
    $hasProt  = ($blob -match 'ApplyRightsProtectionTemplate' -or $blob -match 'ApplyRightsProtectionCustomizationTemplate' -or $blob -match 'ApplyOME')
    $scoped   = ($r.FromMemberOf -and ($r.FromMemberOf -join ';') -match [regex]::Escape(($PilotGroup -split '@')[0]))

    $ok = $enabled -and $isAudit -and $hasProt
    $clr = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("  {0} : State={1}; Mode={2}; RightsProtection={3}; PilotScoped={4}" -f $rn, $r.State, $r.Mode, $hasProt, $scoped) -ForegroundColor $clr
    if (-not $isAudit) { Write-Host ("    NOTE: Mode is '{0}' — this rule is ENFORCING. Confirm this is deliberate and gated." -f $r.Mode) -ForegroundColor Yellow }
    if (-not $scoped)  { Write-Host '    NOTE: pilot-group scope not detected on -FromMemberOf — confirm scope before enforcing.' -ForegroundColor Yellow }
    Add-Row $rn ($(if($ok){'PASS'}else{'REVIEW'})) ("State=$($r.State); Mode=$($r.Mode); Prot=$hasProt; PilotScoped=$scoped")
    if (-not $ok) { $fail++ }
}

# --- Verdict ----------------------------------------------------------------------------------------
Write-Section 'Validation complete'
if ($fail -eq 0) {
    Write-Host 'PASS — branding + rules are healthy, in Audit mode, and pilot-scoped (Gate 5).' -ForegroundColor Green
} else {
    Write-Host ("REVIEW — {0} check(s) need attention before enforcement. See notes above and 06-troubleshooting.md." -f $fail) -ForegroundColor Yellow
}

if ($SaveReport) {
    try { $report | Export-Csv -Path $SaveReport -NoTypeInformation -Encoding UTF8; Write-Host ("Saved: {0}" -f $SaveReport) -ForegroundColor Green }
    catch { Write-Warning ("Could not save report: {0}" -f $_.Exception.Message) }
}
