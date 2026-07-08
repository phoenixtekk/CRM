<#
.SYNOPSIS
    PURVIRM-Discovery.ps1 — assess Insider Risk Management readiness, ROLE SEPARATION, and privacy posture (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Exchange Online / Security & Compliance PowerShell and inventories the Insider Risk
        Management (IRM) role groups and their membership, then flags any account that holds a
        CONFLICTING COMBINATION of roles (e.g. Admins + Investigators) — the core privacy/separation
        check. It also reports IRM policy presence where the tenant exposes it, and prompts you to
        confirm the anonymization (privacy) setting in the portal (that setting is portal-managed).
        Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVIRM-Discovery.ps1

        Prereqs: ExchangeOnlineManagement module (Connect-IPPSSession / Connect-ExchangeOnline) and an
        MFA-capable admin with at least read access to role groups. IRM policy authoring and the
        anonymization/privacy setting live in the Microsoft Purview portal (purview.microsoft.com ->
        Insider Risk Management -> Settings). Some IRM objects have no PowerShell read surface — where
        that is the case this script says so and points you to the portal. Verify capability
        availability against your licensing/tenant (E5 / E5 Compliance / IRM add-on).
    EXPECTED RESULTS
        A table of the IRM role groups with member counts, a SEPARATION verdict (PASS = no account in a
        conflicting combination; FAIL = at least one account holds conflicting roles), and pointers to
        confirm anonymization in the portal. PASS overall = role separation clean and the assessment
        completes without error.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'

function Write-Section([string] $Title) {
    Write-Host ''
    Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan
}

# The IRM role groups (Microsoft Purview). Separation intent: Admins configure; Analysts/Investigators
# review; Auditors watch the reviewers. The combined 'Insider Risk Management' group defeats separation.
$irmRoleGroups = @(
    'Insider Risk Management Admins',
    'Insider Risk Management Analysts',
    'Insider Risk Management Investigators',
    'Insider Risk Management Auditors',
    'Insider Risk Management'
)

# Combinations that violate duty separation if held by the same account.
$conflictPairs = @(
    @('Insider Risk Management Admins','Insider Risk Management Investigators'),
    @('Insider Risk Management Admins','Insider Risk Management Analysts'),
    @('Insider Risk Management Auditors','Insider Risk Management Investigators'),
    @('Insider Risk Management Auditors','Insider Risk Management Admins'),
    @('Insider Risk Management Auditors','Insider Risk Management Analysts')
)

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    Write-Host 'Install ExchangeOnlineManagement and sign in with an MFA-capable admin, then retry.'
    return
}

Write-Section 'Insider Risk Management role groups and membership'
$memberMap = @{}   # account UPN -> list of IRM role groups held
$groupRows = @()
foreach ($rgName in $irmRoleGroups) {
    try {
        $rg = Get-RoleGroup -Identity $rgName -ErrorAction Stop
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

# Flag the combined 'everything' group being assigned to operators.
if ($memberMap.Keys | Where-Object { $memberMap[$_] -contains 'Insider Risk Management' }) {
    Write-Warning "The combined 'Insider Risk Management' role group has members. Avoid assigning it to production operators; use the granular Admins/Analysts/Investigators/Auditors groups so duties stay separated."
}

Write-Section 'ROLE-SEPARATION check (privacy control)'
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
    Write-Host 'SEPARATION: FAIL — accounts hold conflicting IRM roles:' -ForegroundColor Red
    $violations | Format-Table -AutoSize
    Write-Host 'Remediate in Purview -> Settings -> Roles & scopes so each person holds ONE function.'
} else {
    Write-Host 'SEPARATION: PASS — no account holds a conflicting IRM role combination.' -ForegroundColor Green
}

Write-Section 'IRM policies (where readable)'
if (Get-Command Get-InsiderRiskPolicy -ErrorAction SilentlyContinue) {
    try {
        $pol = Get-InsiderRiskPolicy -ErrorAction Stop
        if ($pol) { $pol | Select-Object Name, Enabled, Guid | Format-Table -AutoSize }
        else      { Write-Host 'No IRM policies returned. Build them in the portal (see 03-implementation.md).' }
    }
    catch {
        Write-Warning ("Could not read IRM policies via cmdlet: {0}" -f $_.Exception.Message)
        Write-Host 'Review policies in purview.microsoft.com -> Insider Risk Management -> Policies.'
    }
} else {
    Write-Host 'Get-InsiderRiskPolicy is not available in this session/tenant (IRM authoring is'
    Write-Host 'primarily portal-based). Review policies in purview.microsoft.com -> Insider Risk'
    Write-Host 'Management -> Policies. Verify capability availability against your licensing/tenant.'
}

Write-Section 'Privacy / anonymization posture (confirm in portal)'
Write-Host 'The IRM privacy setting is managed in the portal, not via this script. Confirm:'
Write-Host '  purview.microsoft.com -> Insider Risk Management -> Settings -> Privacy'
Write-Host '  -> "Show anonymized versions of usernames" should be SELECTED (ON).'
Write-Host 'Keep anonymization ON unless privacy/legal have agreed an exception IN WRITING.'

Write-Section 'Discovery complete'
Write-Host 'Read-only assessment finished. Expected object names:'
Write-Host '  Scope group: SG-IRM-Pilot'
Write-Host '  Policies: IRM-DepartingUser-DataTheft; IRM-DataLeaks-General; IRM-SecurityPolicyViolations'
if ($violations.Count -gt 0) { Write-Host 'ACTION REQUIRED: fix role-separation violations above before proceeding.' -ForegroundColor Red }
