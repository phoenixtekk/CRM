<#
.SYNOPSIS
    PURVIEWG-Validation.ps1 — validate that the designed Purview objects exist and are scoped (read-only, GCC High).
.DESCRIPTION
    PURPOSE
        Checks a GCC High tenant for the specific, named Purview objects this solution creates and
        reports PASS or FAIL for each: the pilot group, the four sensitivity labels, the label
        policy, the auto-labeling policy, the DLP policy, and the retention labels/policies. It does
        not change anything. Use it as the pilot validation gate before expanding scope. Replace the
        default names only if you named your objects differently.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Validation.ps1

        Required Graph scopes (delegated): InformationProtectionPolicy.Read, Policy.Read.All,
        Directory.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). Objects that
        Graph cannot read (DLP/retention) are validated against a Security & Compliance PowerShell
        session if one is present; otherwise the script marks them MANUAL and tells you where to look.
        For DoD change USGov to USGovDoD.
    EXPECTED RESULTS
        A checklist with PASS/FAIL/MANUAL per object and a final summary count. PASS overall = every
        required object is present and correctly named. FAIL = one or more objects are missing or
        misnamed; the report names them so you can remediate.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph (US Gov endpoints for GCC High).
#>

[CmdletBinding()]
param(
    [string]   $PilotGroupName   = 'SG-Purview-Pilot',
    [string[]] $LabelNames       = @('Public','General','Confidential','Confidential \ CUI'),
    [string]   $LabelPolicyName  = 'LP-Purview-Pilot',
    [string]   $AutoLabelName    = 'AL-CUI-ServiceSide',
    [string]   $DlpPolicyName    = 'DLP-CUI-Baseline',
    [string]   $RetentionLabel   = 'Ret-CUI-7yr',
    [string[]] $RetentionPolicies= @('RP-CUI-7yr-Auto','RP-Baseline-Retain'),
    [ValidateSet('USGov','USGovDoD')]
    [string]   $GraphEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string] $Item, [string] $Status, [string] $Detail = '') {
    $results.Add([pscustomobject]@{ Item = $Item; Status = $Status; Detail = $Detail })
}

try {
    $scopes = @('InformationProtectionPolicy.Read','Policy.Read.All','Directory.Read.All')
    Connect-MgGraph -Environment $GraphEnvironment -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -notin @('USGov','USGovDoD')) {
        Add-Result 'Cloud environment' 'FAIL' ("Environment is {0}, expected USGov (GCC High)." -f $ctx.Environment)
    } else {
        Add-Result 'Cloud environment' 'PASS' ("Environment {0}." -f $ctx.Environment)
    }
}
catch {
    Write-Error ("Graph connect (US Gov) failed: {0}" -f $_.Exception.Message)
    return
}

# Pilot group
try {
    $grp = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ConsistencyLevel eventual -CountVariable c -All
    if ($grp) { Add-Result "Pilot group '$PilotGroupName'" 'PASS' ("Id {0}" -f $grp[0].Id) }
    else      { Add-Result "Pilot group '$PilotGroupName'" 'FAIL' 'Not found in entra.microsoft.us.' }
}
catch { Add-Result "Pilot group '$PilotGroupName'" 'FAIL' $_.Exception.Message }

# Sensitivity labels
try {
    $labels = Get-MgInformationProtectionPolicyLabel -All
    $have   = @($labels | Select-Object -ExpandProperty Name)
    foreach ($n in $LabelNames) {
        if ($have -contains $n) { Add-Result "Label '$n'" 'PASS' }
        else                    { Add-Result "Label '$n'" 'FAIL' 'Label not found via Graph.' }
    }
}
catch {
    foreach ($n in $LabelNames) { Add-Result "Label '$n'" 'MANUAL' 'Graph label read failed; verify in compliance.microsoft.us.' }
}

# DLP / auto-label / retention — Security & Compliance PowerShell if available, else MANUAL
$sccCmds = Get-Command -Name Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
if ($sccCmds) {
    try {
        $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object Name -eq $DlpPolicyName
        if ($dlp) { Add-Result "DLP policy '$DlpPolicyName'" 'PASS' ("Mode {0}" -f $dlp.Mode) }
        else      { Add-Result "DLP policy '$DlpPolicyName'" 'FAIL' 'Not found.' }
    } catch { Add-Result "DLP policy '$DlpPolicyName'" 'MANUAL' $_.Exception.Message }

    try {
        $al = Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Where-Object Name -eq $AutoLabelName
        if ($al) { Add-Result "Auto-label policy '$AutoLabelName'" 'PASS' ("Mode {0}" -f $al.Mode) }
        else     { Add-Result "Auto-label policy '$AutoLabelName'" 'FAIL' 'Not found.' }
    } catch { Add-Result "Auto-label policy '$AutoLabelName'" 'MANUAL' $_.Exception.Message }

    try {
        $tag = Get-ComplianceTag -ErrorAction Stop | Where-Object Name -eq $RetentionLabel
        if ($tag) { Add-Result "Retention label '$RetentionLabel'" 'PASS' }
        else      { Add-Result "Retention label '$RetentionLabel'" 'FAIL' 'Not found.' }
    } catch { Add-Result "Retention label '$RetentionLabel'" 'MANUAL' $_.Exception.Message }

    try {
        $rps = Get-RetentionCompliancePolicy -ErrorAction Stop
        foreach ($p in $RetentionPolicies) {
            if ($rps | Where-Object Name -eq $p) { Add-Result "Retention policy '$p'" 'PASS' }
            else                                 { Add-Result "Retention policy '$p'" 'FAIL' 'Not found.' }
        }
    } catch { foreach ($p in $RetentionPolicies) { Add-Result "Retention policy '$p'" 'MANUAL' $_.Exception.Message } }
}
else {
    Add-Result "DLP policy '$DlpPolicyName'" 'MANUAL' 'Connect Security & Compliance PowerShell (GCC High URI) to validate.'
    Add-Result "Auto-label policy '$AutoLabelName'" 'MANUAL' 'Connect Security & Compliance PowerShell (GCC High URI) to validate.'
    Add-Result "Retention label '$RetentionLabel'" 'MANUAL' 'Connect Security & Compliance PowerShell (GCC High URI) to validate.'
    foreach ($p in $RetentionPolicies) { Add-Result "Retention policy '$p'" 'MANUAL' 'Connect Security & Compliance PowerShell (GCC High URI) to validate.' }
    Write-Host ''
    Write-Host 'To validate DLP/retention, first run:' -ForegroundColor Yellow
    Write-Host '  Connect-IPPSSession -ConnectionUri https://ps.compliance.protection.office365.us/powershell-liveid/ -ExchangeEnvironmentName O365USGovGCCHigh'
}

Write-Host ''
$results | Format-Table -AutoSize
$fail = ($results | Where-Object Status -eq 'FAIL').Count
$manual = ($results | Where-Object Status -eq 'MANUAL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host ("VALIDATION PASS — 0 FAIL, {0} MANUAL to confirm." -f $manual) -ForegroundColor Green }
else             { Write-Host ("VALIDATION FAIL — {0} object(s) missing/misnamed, {1} MANUAL." -f $fail, $manual) -ForegroundColor Red }
