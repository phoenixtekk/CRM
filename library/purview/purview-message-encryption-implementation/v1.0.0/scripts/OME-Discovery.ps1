<#
.SYNOPSIS
    OME-Discovery.ps1 — assess Purview Message Encryption (OME) readiness: RMS/IRM, templates, branding, and rules (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Exchange Online PowerShell to assess readiness for Purview Message Encryption (OME).
        It reports the IRM/Azure RMS configuration (AzureRMSLicensingEnabled), the available RMS
        protection templates (Encrypt / Do Not Forward), existing OME branding configurations
        (default + any custom), and any mail flow (transport) rules that apply or remove OME — with a
        Basic-vs-Advanced licensing hint. Read-only: it changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with the ExchangeOnlineManagement module.
        Connect-ExchangeOnline (MFA-capable Exchange admin), then:
          .\OME-Discovery.ps1
          .\OME-Discovery.ps1 -SaveReport .\OME-Discovery.csv
        Some settings (Azure RMS activation, branding preview) are portal-managed; where a value has no
        read surface this script says so. Verify capability/licensing against your tenant (Basic OME via
        AIP/Azure RMS; Advanced Message Encryption for custom branding / revocation / expiration).
    EXPECTED RESULTS
        A readiness summary: RMS enablement (True/False), the RMS templates found, OME configurations,
        OME-related transport rules with their Mode/State, and a verdict. PASS overall = RMS is enabled
        and the two protection templates are present.
.NOTES
    White-label. Read-only. Exchange Online PowerShell. No credentials in code. No cmdlets invented.
#>

[CmdletBinding()]
param(
    [string] $SaveReport
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Text fragments that indicate a transport rule applies/removes OME. Parameter names evolve; scan
# readable rule text rather than assume a single property.
$omeRuleHints = @('ApplyRightsProtectionTemplate', 'ApplyRightsProtectionCustomizationTemplate',
                  'ApplyOME', 'RemoveOME', 'Encrypt', 'Do Not Forward', 'rights protection')

try {
    Write-Section 'Connecting to Exchange Online PowerShell'
    if (-not (Get-Command Get-IRMConfiguration -ErrorAction SilentlyContinue)) {
        Connect-ExchangeOnline -ShowBanner:$false | Out-Null
    }
}
catch { }

if (-not (Get-Command Get-IRMConfiguration -ErrorAction SilentlyContinue)) {
    Write-Error 'Not connected to Exchange Online. Run Connect-ExchangeOnline with an MFA-capable Exchange admin, then retry.'
    return
}
Write-Host 'Connected.' -ForegroundColor Green

$report = [System.Collections.Generic.List[object]]::new()
function Add-Row([string]$Area,[string]$Item,[string]$Value) {
    $report.Add([pscustomobject]@{ Area = $Area; Item = $Item; Value = $Value })
}

# --- IRM / Azure RMS foundation ---------------------------------------------------------------------
Write-Section 'IRM / Azure RMS foundation (OME depends on this)'
$rmsEnabled = $false
try {
    $irm = Get-IRMConfiguration -ErrorAction Stop
    $rmsEnabled = [bool]$irm.AzureRMSLicensingEnabled
    Write-Host ("AzureRMSLicensingEnabled : {0}" -f $irm.AzureRMSLicensingEnabled) -ForegroundColor ($(if($rmsEnabled){'Green'}else{'Yellow'}))
    Write-Host ("InternalLicensingEnabled : {0}" -f $irm.InternalLicensingEnabled)
    Write-Host ("ClientAccessServerEnabled: {0}" -f $irm.ClientAccessServerEnabled)
    Add-Row 'RMS' 'AzureRMSLicensingEnabled' "$($irm.AzureRMSLicensingEnabled)"
}
catch {
    Write-Warning ("Could not read IRM configuration: {0}" -f $_.Exception.Message)
}
if (-not $rmsEnabled) {
    Write-Host 'Azure RMS is not enabled for Exchange Online. Enable it before configuring OME:' -ForegroundColor Yellow
    Write-Host '  Set-IRMConfiguration -AzureRMSLicensingEnabled $true   (then Test-IRMConfiguration)'
}

# --- RMS templates ----------------------------------------------------------------------------------
Write-Section 'RMS protection templates (Encrypt / Do Not Forward)'
try {
    $tmpl = @(Get-RMSTemplate -ErrorAction Stop)
    if ($tmpl.Count -eq 0) {
        Write-Host 'No RMS templates returned. Confirm RMS is active, then allow propagation.' -ForegroundColor Yellow
    } else {
        $tmpl | Select-Object Name, Type, Description | Format-Table -AutoSize
    }
    foreach ($t in $tmpl) { Add-Row 'Templates' $t.Name "$($t.Type)" }
    $haveEncrypt = [bool]($tmpl | Where-Object { $_.Name -match 'Encrypt' })
    $haveDnf     = [bool]($tmpl | Where-Object { $_.Name -match 'Do Not Forward' })
    Write-Host ("Encrypt template present       : {0}" -f $haveEncrypt) -ForegroundColor ($(if($haveEncrypt){'Green'}else{'Yellow'}))
    Write-Host ("Do Not Forward template present: {0}" -f $haveDnf)     -ForegroundColor ($(if($haveDnf){'Green'}else{'Yellow'}))
}
catch {
    Write-Warning ("Could not enumerate RMS templates: {0}" -f $_.Exception.Message)
    $haveEncrypt = $false; $haveDnf = $false
}

# --- OME branding configurations --------------------------------------------------------------------
Write-Section 'OME branding configurations (default + custom)'
try {
    $omeCfg = @(Get-OMEConfiguration -ErrorAction Stop)
    if ($omeCfg.Count -eq 0) {
        Write-Host 'No OME configuration returned (unexpected — a default usually exists). Verify in portal.' -ForegroundColor Yellow
    } else {
        $omeCfg | Select-Object Identity, BackgroundColor, EmailText | Format-Table -AutoSize
        Write-Host ("OME configurations found: {0} (more than 1 implies custom templates = Advanced Message Encryption)." -f $omeCfg.Count)
    }
    foreach ($c in $omeCfg) { Add-Row 'Branding' 'OMEConfiguration' "$($c.Identity)" }
}
catch {
    Write-Warning ("Could not read OME configuration(s): {0}" -f $_.Exception.Message)
    Write-Host 'Confirm branding in the Exchange/Purview portal; Set-OMEConfiguration manages the default.'
}

# --- OME-related transport rules --------------------------------------------------------------------
Write-Section 'Mail flow (transport) rules that apply/remove OME'
try {
    $rules = @(Get-TransportRule -ErrorAction Stop)
    $omeRules = @()
    foreach ($r in $rules) {
        $blob = ($r | Out-String)
        if ($omeRuleHints | Where-Object { $blob -match [regex]::Escape($_) }) {
            $omeRules += [pscustomobject]@{ Name = $r.Name; State = $r.State; Mode = $r.Mode }
        }
    }
    if ($omeRules.Count -gt 0) {
        Write-Host 'Transport rules referencing OME / rights protection:' -ForegroundColor Green
        $omeRules | Format-Table -AutoSize
        foreach ($r in $omeRules) { Add-Row 'Rules' $r.Name ("State=$($r.State); Mode=$($r.Mode)") }
    } else {
        Write-Host 'No OME transport rules found yet. Expected (built in Audit mode first):'
        Write-Host '  OME-Encrypt-Outbound-Pilot (Encrypt) / OME-DoNotForward-Confidential (Do Not Forward).'
    }
}
catch {
    Write-Warning ("Could not enumerate transport rules: {0}" -f $_.Exception.Message)
}

# --- Verdict ----------------------------------------------------------------------------------------
Write-Section 'Discovery complete'
if ($rmsEnabled -and $haveEncrypt -and $haveDnf) {
    Write-Host 'READINESS: RMS is enabled and both protection templates are present — OME can be configured.' -ForegroundColor Green
} else {
    Write-Host 'READINESS: enable Azure RMS and/or confirm the Encrypt + Do Not Forward templates before' -ForegroundColor Yellow
    Write-Host '           configuring branding and rules. See 02-requirements.md R1/R2.'
}
Write-Host 'Licensing: Basic OME (Encrypt / Do Not Forward / default branding) via AIP/Azure RMS;'
Write-Host 'Advanced Message Encryption (custom branding, revocation, expiration) needs E5 / E5 Compliance.'
Write-Host 'Expected object names: SG-OME-Pilot; OME-Encrypt-Outbound-Pilot; OME-DoNotForward-Confidential; OME-Branding-Corp.'

if ($SaveReport) {
    try { $report | Export-Csv -Path $SaveReport -NoTypeInformation -Encoding UTF8; Write-Host ("Saved: {0}" -f $SaveReport) -ForegroundColor Green }
    catch { Write-Warning ("Could not save report: {0}" -f $_.Exception.Message) }
}
