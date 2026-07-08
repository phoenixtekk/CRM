<#
.SYNOPSIS
    CMPPCI-Discovery.ps1 — assess PCI-DSS program readiness, ROLE SEPARATION, audit logging, and cardholder-data controls (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell (and optionally Microsoft Graph) and inventories the
        readiness for a Microsoft Purview PCI-DSS compliance program: the Compliance role groups and their
        membership (flagging CONFLICTING role combinations = the PCI-DSS Req 7 separation check), whether
        unified audit logging is enabled (Req 10), whether the built-in "Credit Card Number" sensitive
        information type is present (Req 3), and any existing Credit Card Number DLP policy / label and its
        mode. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPPCI-Discovery.ps1
        # Optionally include a Graph licensing check:
        powershell -ExecutionPolicy Bypass -File .\CMPPCI-Discovery.ps1 -CheckLicensing

        Prereqs: ExchangeOnlineManagement module (Connect-IPPSSession) and an MFA-capable admin with at
        least read access to role groups, DLP, and audit config; for -CheckLicensing, Microsoft.Graph with
        Organization.Read.All. The PCI-DSS assessment template, evidence, and labels are managed in the
        Purview portal (purview.microsoft.com); some objects have no PowerShell read surface — where that
        is the case this script says so. Verify capability availability against your licensing/tenant
        (E5 / E5 Compliance / Compliance Manager Premium Assessment Add-On).
    EXPECTED RESULTS
        A readiness summary: role-group membership with a SEPARATION verdict (PASS = no conflicting
        combination), audit-logging state (PASS = enabled), Credit Card Number SIT presence (PASS = found),
        and the existing cardholder-data DLP policy/label with its mode. PASS overall = separation clean,
        audit logging on, and the Credit Card Number SIT available.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Microsoft Graph. No credentials in code.
#>

[CmdletBinding()]
param(
    [switch] $CheckLicensing
)

$ErrorActionPreference = 'Stop'

function Write-Section([string] $Title) {
    Write-Host ''
    Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan
}

# Compliance / Compliance Manager role groups. Separation intent (PCI-DSS Req 7): Administrators
# configure; Assessors/Contributors update actions/evidence; Readers/QSA are read-only.
$roleGroups = @(
    'Compliance Manager Administrators',
    'Compliance Manager Assessors',
    'Compliance Manager Contributors',
    'Compliance Manager Readers',
    'Compliance Administrator',
    'Compliance Data Administrator'
)

# Combinations that violate duty separation if held by the same account.
$conflictPairs = @(
    @('Compliance Manager Administrators','Compliance Manager Contributors'),
    @('Compliance Manager Administrators','Compliance Manager Assessors'),
    @('Compliance Manager Readers','Compliance Manager Administrators'),
    @('Compliance Manager Readers','Compliance Manager Contributors')
)

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    Write-Host 'Install ExchangeOnlineManagement and sign in with an MFA-capable admin, then retry.'
    return
}

# ---- Role groups + separation (Req 7) -------------------------------------------------------------
Write-Section 'Compliance role groups and membership (PCI-DSS Req 7)'
$memberMap = @{}
$groupRows = @()
foreach ($rgName in $roleGroups) {
    try {
        $null = Get-RoleGroup -Identity $rgName -ErrorAction Stop
        $members = @(Get-RoleGroupMember -Identity $rgName -ErrorAction SilentlyContinue)
        $groupRows += [pscustomobject]@{ RoleGroup = $rgName; Members = $members.Count }
        foreach ($m in $members) {
            $key = if ($m.PrimarySmtpAddress) { [string]$m.PrimarySmtpAddress } else { [string]$m.Name }
            if (-not $memberMap.ContainsKey($key)) { $memberMap[$key] = New-Object System.Collections.Generic.List[string] }
            $memberMap[$key].Add($rgName)
        }
    }
    catch {
        $groupRows += [pscustomobject]@{ RoleGroup = $rgName; Members = 'not found / no access' }
    }
}
$groupRows | Format-Table -AutoSize

Write-Section 'ROLE-SEPARATION check (PCI-DSS Req 7)'
$violations = @()
foreach ($acct in $memberMap.Keys) {
    $held = $memberMap[$acct]
    foreach ($pair in $conflictPairs) {
        if (($held -contains $pair[0]) -and ($held -contains $pair[1])) {
            $violations += [pscustomobject]@{ Account = $acct; Conflict = ('{0} + {1}' -f $pair[0], $pair[1]) }
        }
    }
}
if ($violations.Count -gt 0) {
    Write-Host 'SEPARATION: FAIL — accounts hold conflicting Compliance roles:' -ForegroundColor Red
    $violations | Format-Table -AutoSize
    Write-Host 'Remediate in Purview -> Settings -> Roles & scopes so each person holds one function.'
} else {
    Write-Host 'SEPARATION: PASS — no account holds a conflicting role combination.' -ForegroundColor Green
}

# ---- Unified audit logging (Req 10) ---------------------------------------------------------------
Write-Section 'Unified audit logging (PCI-DSS Req 10)'
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($cfg.UnifiedAuditLogIngestionEnabled) {
        Write-Host 'AUDIT LOGGING: PASS — UnifiedAuditLogIngestionEnabled = True.' -ForegroundColor Green
    } else {
        Write-Host 'AUDIT LOGGING: FAIL — unified audit logging is OFF. Enable it (03-implementation.md Step 4).' -ForegroundColor Red
    }
}
catch {
    Write-Warning ("Could not read audit config: {0}" -f $_.Exception.Message)
    Write-Host 'Confirm in Purview -> Audit, or via Get-AdminAuditLogConfig with sufficient rights.'
}

# ---- Credit Card Number SIT (Req 3) ---------------------------------------------------------------
Write-Section 'Cardholder-data sensitive information type (PCI-DSS Req 3)'
try {
    $sit = Get-DlpSensitiveInformationType -ErrorAction Stop | Where-Object { $_.Name -eq 'Credit Card Number' }
    if ($sit) {
        Write-Host 'SIT: PASS — the built-in "Credit Card Number" sensitive information type is available.' -ForegroundColor Green
    } else {
        Write-Host 'SIT: NOTE — "Credit Card Number" not returned by name; check the exact SIT name in your tenant.' -ForegroundColor Yellow
    }
}
catch {
    Write-Warning ("Could not enumerate sensitive information types: {0}" -f $_.Exception.Message)
}

# ---- Existing cardholder-data DLP policy / mode ---------------------------------------------------
Write-Section 'Existing cardholder-data DLP policy (where readable)'
try {
    $pol = @(Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq 'DLP-PCI-CardholderData' })
    if ($pol.Count -gt 0) {
        $pol | Select-Object Name, Mode, Enabled | Format-Table -AutoSize
        if ($pol[0].Mode -match 'Test') {
            Write-Host 'DLP present and in SIMULATION/TEST mode — as expected before enforcement.' -ForegroundColor Green
        } else {
            Write-Host ("DLP present in mode '{0}'. Confirm this is intended (enforce only after validation)." -f $pol[0].Mode) -ForegroundColor Yellow
        }
    } else {
        Write-Host 'No DLP-PCI-CardholderData policy yet — create it in SIMULATION with CMPPCI-Configuration.ps1 (03-implementation.md Step 6).' -ForegroundColor Yellow
    }
}
catch {
    Write-Warning ("Could not read DLP policies: {0}" -f $_.Exception.Message)
}

# ---- Optional licensing check via Graph -----------------------------------------------------------
if ($CheckLicensing) {
    Write-Section 'Licensing (Microsoft Graph)'
    try {
        if (-not (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue)) {
            Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome | Out-Null
        }
        Get-MgSubscribedSku -ErrorAction Stop |
            Select-Object SkuPartNumber, @{n='Consumed';e={$_.ConsumedUnits}} |
            Sort-Object SkuPartNumber | Format-Table -AutoSize
        Write-Host 'Confirm E5 / E5 Compliance / Compliance Manager Premium Assessment Add-On entitlement — the PCI-DSS template is premium.' -ForegroundColor Yellow
    }
    catch {
        Write-Warning ("Graph licensing read failed: {0}" -f $_.Exception.Message)
        Write-Host 'Install Microsoft.Graph and consent to Organization.Read.All, or check the M365 admin center.'
    }
}

Write-Section 'Discovery complete'
Write-Host 'Read-only assessment finished. Expected object names:'
Write-Host '  Assessment  : PCI Assessment - Baseline - Pilot'
Write-Host '  DLP policy  : DLP-PCI-CardholderData (rule DLP-PCI-CardholderData-Rule, Credit Card Number SIT)'
Write-Host '  Label       : Label-PCI-CardholderData'
Write-Host '  Pilot scope : SG-PCI-Pilot'
if ($violations.Count -gt 0) { Write-Host 'ACTION REQUIRED: fix role-separation violations above before proceeding.' -ForegroundColor Red }
Write-Host 'Note: PCI-DSS version/SAQ applicability and CDE scoping are QSA/compliance determinations, not outputs of this script.'
