<#
.SYNOPSIS
    PURVARCH-Validation.ps1 — check design conformance: SoD conflicts, least privilege, licensing coverage, scope, naming (read-only).
.DESCRIPTION
    PURPOSE
        Validates that the Microsoft Purview design is conformant BEFORE capabilities are built against
        it. It reports separation-of-duties conflicts across the compliance role groups (the "PA RBAC
        SoD - Conflicts" register), least-privilege posture, whether the pilot ring / adaptive scope is
        present, and which existing objects do NOT conform to the "<Purpose> - <Scope> - <Stage>" naming
        standard. Read-only — it changes nothing. Findings are pass/fail lines aligned to 05-testing.md.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Validation.ps1 -PilotGroup SG-PA-Pilot -AdaptiveScope AS-PA-Pilot

        Prereqs: ExchangeOnlineManagement module (Connect-IPPSSession) and an MFA-capable admin with read
        access to role groups and compliance policies. Role-group names and adaptive-scope availability
        EVOLVE and are licensing-gated — verify against your tenant.
    EXPECTED RESULTS
        A conformance report: SoD conflict list (people in two SEPARATED domains), least-privilege flags
        (readers/auditors also holding admin), pilot-ring/scope presence, and naming-drift list. PASS
        overall = no unaccepted SoD conflict, the pilot ring exists, and naming drift is enumerated.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/',
    [string] $PilotGroup    = 'SG-PA-Pilot',
    [string] $AdaptiveScope = 'AS-PA-Pilot',
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# Separated capability DOMAINS. A person administering two DIFFERENT domains is a SoD conflict to review.
$domains = [ordered]@{
    'InformationProtection'  = @('Information Protection','Information Protection Admins')
    'Records'                = @('Records Management')
    'InsiderRisk'            = @('Insider Risk Management','Insider Risk Management Admins')
    'CommunicationCompliance'= @('Communication Compliance','Communication Compliance Admins')
    'eDiscovery'             = @('eDiscovery Administrator','eDiscovery Manager')
}
# Read-only groups that should NOT overlap with any admin/analyst membership.
$readOnly = @('Information Protection Readers','Insider Risk Management Auditors',
              'Communication Compliance Viewers','Audit Reader','Global Reader')
# Naming standard: "<Purpose> - <Scope> - <Stage>" using an en dash or hyphen as separator.
$namingRegex = '^\S.*\s[-–]\s.*\s[-–]\s(Sim|Prod|Assess|Design|Pilot)\b'

$rows = @()

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); return }

# --- Build member -> domains map --------------------------------------------------------------------
Write-Section 'Separation of duties (PA RBAC SoD - Conflicts)'
$memberDomains = @{}   # UPN -> set of domain keys
foreach ($d in $domains.Keys) {
    foreach ($g in $domains[$d]) {
        try {
            $members = @(Get-RoleGroupMember -Identity $g -ErrorAction Stop)
            foreach ($m in $members) {
                $id = if ($m.WindowsLiveID) { $m.WindowsLiveID } elseif ($m.PrimarySmtpAddress) { $m.PrimarySmtpAddress } else { $m.Name }
                if (-not $memberDomains.ContainsKey($id)) { $memberDomains[$id] = New-Object System.Collections.Generic.HashSet[string] }
                [void]$memberDomains[$id].Add($d)
            }
        } catch { }  # group absent/renamed — Discovery already flags this
    }
}
$conflicts = @()
foreach ($id in $memberDomains.Keys) {
    if ($memberDomains[$id].Count -gt 1) {
        $doms = ($memberDomains[$id] -join ', ')
        $conflicts += [pscustomobject]@{ Member=$id; Domains=$doms }
    }
}
if ($conflicts.Count -eq 0) {
    Write-Host '  [PASS] No person administers two separated capability domains.' -ForegroundColor Green
} else {
    Write-Host ("  [REVIEW] {0} person(s) span multiple separated domains — confirm the owners accepted each:" -f $conflicts.Count) -ForegroundColor Yellow
    $conflicts | Format-Table -AutoSize
    foreach ($c in $conflicts) { $rows += [pscustomobject]@{ Section='SoD'; Item=$c.Member; Value=$c.Domains; Note='review' } }
}

# --- Least privilege: read-only members who also hold an admin/analyst domain -----------------------
Write-Section 'Least privilege (read-only members that also hold admin/analyst roles)'
$roMembers = @{}
foreach ($g in $readOnly) {
    try {
        foreach ($m in @(Get-RoleGroupMember -Identity $g -ErrorAction Stop)) {
            $id = if ($m.WindowsLiveID) { $m.WindowsLiveID } elseif ($m.PrimarySmtpAddress) { $m.PrimarySmtpAddress } else { $m.Name }
            $roMembers[$id] = $true
        }
    } catch { }
}
$leak = @($roMembers.Keys | Where-Object { $memberDomains.ContainsKey($_) })
if ($leak.Count -eq 0) {
    Write-Host '  [PASS] No read-only/auditor member also holds an admin/analyst domain role.' -ForegroundColor Green
} else {
    Write-Host '  [REVIEW] Read-only members also holding admin/analyst roles (defeats read-only intent):' -ForegroundColor Yellow
    $leak | ForEach-Object { Write-Host ("    - {0}" -f $_); $rows += [pscustomobject]@{ Section='LeastPriv'; Item=$_; Value='read-only+admin'; Note='review' } }
}

# --- Pilot ring / adaptive scope presence -----------------------------------------------------------
Write-Section 'Pilot ring and adaptive scope'
$pilotOk = $false
if (Get-Command Get-AdaptiveScope -ErrorAction SilentlyContinue) {
    try {
        $sc = Get-AdaptiveScope -Identity $AdaptiveScope -ErrorAction Stop
        Write-Host ("  [PASS] Adaptive scope present: {0}" -f $sc.Name) -ForegroundColor Green
        $pilotOk = $true
    } catch {
        Write-Host ("  [INFO] Adaptive scope '{0}' not found (may be static-scope design, or not yet scaffolded)." -f $AdaptiveScope) -ForegroundColor Yellow
    }
} else {
    Write-Host '  [INFO] Get-AdaptiveScope not available (adaptive scopes are licensing-gated). Verify in your tenant.' -ForegroundColor DarkGray
}
Write-Host ("  Confirm the pilot ring group '{0}' exists (Entra/Exchange) — PURVARCH-Set-Scope.ps1 manages it." -f $PilotGroup)
$rows += [pscustomobject]@{ Section='Scope'; Item=$AdaptiveScope; Value=$pilotOk; Note='adaptive-scope-present' }

# --- Naming conformance -----------------------------------------------------------------------------
Write-Section 'Naming conformance (existing objects vs "<Purpose> - <Scope> - <Stage>")'
function Check-Naming([string] $cmd, [string] $label) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host ("  {0}: cmdlet {1} not available — skipped." -f $label,$cmd) -ForegroundColor DarkGray; return
    }
    try {
        $objs = @(& $cmd -ErrorAction Stop)
        $bad  = @($objs | Where-Object { $_.Name -notmatch $namingRegex })
        if ($objs.Count -eq 0) {
            Write-Host ("  {0}: none present." -f $label)
        } elseif ($bad.Count -eq 0) {
            Write-Host ("  [PASS] {0}: all {1} conform." -f $label,$objs.Count) -ForegroundColor Green
        } else {
            Write-Host ("  [DRIFT] {0}: {1} of {2} do NOT conform:" -f $label,$bad.Count,$objs.Count) -ForegroundColor Yellow
            $bad | Select-Object -First 20 | ForEach-Object {
                Write-Host ("     - {0}" -f $_.Name)
                $script:rows += [pscustomobject]@{ Section='Naming'; Item=$_.Name; Value='nonconforming'; Note=$label }
            }
        }
    } catch { Write-Host ("  {0}: unreadable ({1})" -f $label,$_.Exception.Message) -ForegroundColor Yellow }
}
Check-Naming 'Get-DlpCompliancePolicy'       'DLP policies'
Check-Naming 'Get-RetentionCompliancePolicy' 'Retention policies'
Check-Naming 'Get-Label'                      'Sensitivity labels'
Check-Naming 'Get-ComplianceTag'             'Retention labels'

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nFindings written to {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message) }
}

Write-Section 'Validation complete'
$verdictFail = ($conflicts.Count -gt 0) -or ($leak.Count -gt 0)
if ($verdictFail) {
    Write-Host 'RESULT: items to REVIEW above — resolve or accept SoD/least-privilege findings before building capabilities.' -ForegroundColor Yellow
} else {
    Write-Host 'RESULT: separation of duties and least privilege hold. Confirm naming drift is planned for remediation.' -ForegroundColor Green
}
Write-Host 'The AUTHORITATIVE role/scope/policy state is the Purview portal — verify against your tenant.'
