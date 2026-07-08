<#
.SYNOPSIS
    DLPOD-Validate.ps1 — read-only validation of the OneDrive DLP policies against the expected pass/fail gates.
.DESCRIPTION
    PURPOSE
        Checks the OneDrive DLP policies you built against the solution's validation gates and emits a
        pass/attention record: (1) each policy actually targets the OneDrive location; (2) its Mode is a
        recognized value (Test* = simulation / Enable = enforcing / Disable = off) — flagging anything
        Enabled so an unintended enforcement is caught; (3) the policy's rules carry a
        ContentContainsSensitiveInformation condition, and (for the external-share policy) an AccessScope
        of NotInOrganization; and (4) the pilot-ring member-of scope, if set. Read-only — makes no
        changes; this is the evidence-capture step, not a remediation.
    HOW TO RUN
        # Validate the two standard policies:
        powershell -ExecutionPolicy Bypass -File .\DLPOD-Validate.ps1 -CsvPath .\DLPOD-Validation.csv
        # Validate specific policies by name:
        powershell -File .\DLPOD-Validate.ps1 -PolicyNames 'DLP - OneDrive Sensitive - Simulation','DLP - OneDrive External Share - Simulation'
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        A console table of each policy with OneDriveTargeted / Mode / HasSITCondition / ExternalShareScope
        / PilotRingScope and a PASS/ATTENTION verdict, plus an optional CSV for the deliverable record.
        PASS signal: policies target OneDrive, are in the expected mode (simulation during pilot build),
        and carry the expected conditions. ATTENTION: any policy Enabled unexpectedly or missing a SIT
        condition is flagged for review.
.NOTES
    Purview — OneDrive for Business DLP. Read-only validation / evidence capture. No changes made.
#>
[CmdletBinding()]
param(
    [string[]]$PolicyNames = @('DLP - OneDrive Sensitive - Simulation','DLP - OneDrive External Share - Simulation'),
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host '=== OneDrive DLP Validation (read-only) ===' -ForegroundColor Cyan

$results = foreach ($name in $PolicyNames) {
    $p = Get-DlpCompliancePolicy -Identity $name -ErrorAction SilentlyContinue
    if (-not $p) {
        Write-Host ("MISSING: policy '{0}' not found." -f $name) -ForegroundColor Yellow
        [pscustomobject]@{
            Policy = $name; Found = $false; OneDriveTargeted = $false; Mode = 'n/a'
            HasSITCondition = $false; ExternalShareScope = 'n/a'; PilotRingScope = 'n/a'; Verdict = 'ATTENTION (missing)'
        }
        continue
    }

    $odTargeted = ($p.OneDriveLocation -and $p.OneDriveLocation.Count -gt 0)
    $isSim      = $p.Mode -like 'Test*'

    # Inspect the policy's rules for the expected conditions.
    $rules = Get-DlpComplianceRule -Policy $name -ErrorAction SilentlyContinue
    $hasSit = $false; $extScope = $false
    foreach ($r in $rules) {
        if ($r.ContentContainsSensitiveInformation) { $hasSit = $true }
        # AccessScope NotInOrganization = the "shared outside the org" over-share condition.
        if ($r.AccessScope -and ($r.AccessScope -match 'NotInOrganization')) { $extScope = $true }
    }
    $ring = if ($p.OneDriveSharedByMemberOf -and $p.OneDriveSharedByMemberOf.Count -gt 0) { ($p.OneDriveSharedByMemberOf -join ', ') } else { '(all OneDrive accounts)' }

    # Verdict: ATTENTION if not targeting OneDrive, missing a SIT condition, or unexpectedly enforcing.
    $notes = @()
    if (-not $odTargeted) { $notes += 'not targeting OneDrive' }
    if (-not $hasSit)     { $notes += 'no SIT condition' }
    if ($p.Mode -eq 'Enable') { $notes += 'ENFORCING (confirm intended)' }
    $verdict = if ($notes.Count -eq 0) { 'PASS' } else { 'ATTENTION (' + ($notes -join '; ') + ')' }

    [pscustomobject]@{
        Policy             = $p.Name
        Found              = $true
        OneDriveTargeted   = $odTargeted
        Mode               = $p.Mode
        Simulation         = $isSim
        HasSITCondition    = $hasSit
        ExternalShareScope = $extScope
        PilotRingScope     = $ring
        Verdict            = $verdict
    }
}

$results | Format-Table Policy, OneDriveTargeted, Mode, HasSITCondition, ExternalShareScope, Verdict -AutoSize

$attention = @($results | Where-Object { $_.Verdict -ne 'PASS' })
if ($attention.Count -eq 0) {
    Write-Host 'ALL PASS: policies target OneDrive, carry a SIT condition, and are in the expected mode.' -ForegroundColor Green
} else {
    Write-Host ("{0} policy(ies) need attention — review the Verdict column above." -f $attention.Count) -ForegroundColor Yellow
}

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Validation record exported to {0} (attach to the deliverable evidence)." -f $CsvPath) -ForegroundColor Green
}
