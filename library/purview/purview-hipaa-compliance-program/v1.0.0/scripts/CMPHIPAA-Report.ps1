<#
.SYNOPSIS
    CMPHIPAA-Report.ps1 — produce the HIPAA Posture - Report management rollup (read-only).
.DESCRIPTION
    PURPOSE
        Assembles a HIPAA Posture - Report from the local tracking artifacts (HIPAA Action Plan - Pilot,
        HIPAA Evidence - Register, HIPAA Control Map - Safeguards) and the live role-separation snapshot:
        a safeguard-status rollup grouped by HIPAA safeguard family (Administrative / Physical / Technical),
        the evidence/test-status breakdown, the Compliance Manager role separation, and licensing context.
        It is a MANAGEMENT rollup — the authoritative score and export live in the Purview portal's
        Compliance Manager. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPHIPAA-Report.ps1 -ArtifactsDir .\HIPAA-artifacts
        Optionally -OutFile .\HIPAA-Posture-Report.csv to save the rollup. PowerShell 5.1+ / 7+.
        The role-separation section uses ExchangeOnlineManagement (Connect-IPPSSession); use -SkipRoles to
        report from artifacts only. Interactive modern-auth sign-in; no secrets in code.
    EXPECTED RESULTS
        A console rollup: counts of actions by implementation status and by safeguard family, evidence
        auto-vs-manual and test-status counts, and the role-group membership. With -OutFile, the per-action
        rollup is written to CSV. A reminder that the authoritative score is the portal's Compliance Manager
        export.
.NOTES
    Purview category — HIPAA compliance program. Read-only management rollup; not the authoritative score.
    Whether the posture satisfies the HIPAA obligation is a compliance/privacy/legal determination.
#>
[CmdletBinding()]
param(
    [string]$ArtifactsDir = (Join-Path (Get-Location) 'HIPAA-artifacts'),
    [string]$OutFile,
    [switch]$SkipRoles,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Info($m){ Write-Host $m -ForegroundColor Gray }

# Map a safeguard citation to its HIPAA family for the rollup.
function Get-SafeguardFamily([string]$s){
    if ($s -match '164\.308') { return 'Administrative (§164.308)' }
    if ($s -match '164\.310') { return 'Physical (§164.310)' }
    if ($s -match '164\.312') { return 'Technical (§164.312)' }
    if ($s -match '164\.314') { return 'Organizational (§164.314)' }
    if ($s -match '164\.316') { return 'Documentation (§164.316)' }
    if ($s -match '164\.4')   { return 'Breach Notification (§164.400-414)' }
    return 'Other / unmapped'
}

$planPath = Join-Path $ArtifactsDir 'HIPAA Action Plan - Pilot.csv'
$evidPath = Join-Path $ArtifactsDir 'HIPAA Evidence - Register.csv'

if (-not (Test-Path $planPath)) {
    Warn "Action plan not found at $planPath. Run CMPHIPAA-Configuration.ps1 -Commit first."
} else {
    $plan = @(Import-Csv -Path $planPath)
    Write-Section "Safeguard-status rollup ($($plan.Count) actions)"
    Info "By implementation status:"
    $plan | Group-Object ImplementationStatus | Sort-Object Name |
        ForEach-Object { Info ("  {0,-22} {1}" -f $_.Name, $_.Count) }

    Info "`nBy HIPAA safeguard family:"
    $plan | Group-Object { Get-SafeguardFamily $_.Safeguard } | Sort-Object Name |
        ForEach-Object { Info ("  {0,-30} {1}" -f $_.Name, $_.Count) }

    $unassigned = @($plan | Where-Object { [string]::IsNullOrWhiteSpace($_.Owner) })
    if ($unassigned.Count -gt 0) { Warn ("{0} action(s) have NO owner — not audit-defensible." -f $unassigned.Count) }
    else { Ok "Every action has an owner." }

    if ($OutFile) {
        $plan | Select-Object Action, Safeguard,
            @{n='SafeguardFamily';e={Get-SafeguardFamily $_.Safeguard}},
            Owner, TargetDate, ImplementationStatus, TestMode, EvidenceSource |
            Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8
        Ok "Wrote per-action rollup to $OutFile"
    }
}

if (Test-Path $evidPath) {
    $evid = @(Import-Csv -Path $evidPath)
    Write-Section "Evidence register ($($evid.Count) rows)"
    Info "By test mode (auto vs manual):"
    $evid | Group-Object TestMode | Sort-Object Name | ForEach-Object { Info ("  {0,-10} {1}" -f $_.Name, $_.Count) }
    Info "By test status:"
    $evid | Group-Object TestStatus | Sort-Object Name | ForEach-Object { Info ("  {0,-16} {1}" -f $_.Name, $_.Count) }
    $noEvidence = @($evid | Where-Object { [string]::IsNullOrWhiteSpace($_.EvidenceSource) })
    if ($noEvidence.Count -gt 0) { Warn ("{0} row(s) have NO evidence source." -f $noEvidence.Count) }
} else {
    Warn "Evidence register not found at $evidPath."
}

if (-not $SkipRoles) {
    Write-Section "Role separation (live)"
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Warn "ExchangeOnlineManagement not installed — skipping role section (use -SkipRoles to silence)."
    } else {
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        $cp = @{ ShowBanner = $false }
        if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
        try {
            Connect-IPPSSession @cp -ErrorAction Stop | Out-Null
            foreach ($g in @('Compliance Manager Administrators','Compliance Manager Assessors','Compliance Manager Contributors','Compliance Manager Readers')) {
                try {
                    $m = @(Get-RoleGroupMember -Identity $g -ErrorAction Stop | Select-Object -ExpandProperty Name)
                    Info ("  {0}: {1}" -f $g, ($(if ($m){ $m -join ', ' } else { '(empty)' })))
                } catch { Warn ("  {0}: could not read — verify the role-group name in your tenant." -f $g) }
            }
        } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }
    }
}

Write-Section "Note"
Warn "This is a MANAGEMENT rollup. The AUTHORITATIVE HIPAA score and evidence export are in the Purview portal → Compliance Manager. Whether the posture satisfies the HIPAA obligation is a compliance/privacy/legal determination."
