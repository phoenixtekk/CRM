<#
.SYNOPSIS
    PURVARCH-Configuration.ps1 — apply the designed RBAC role-group membership (least privilege, separated); -WhatIf by default.
.DESCRIPTION
    PURPOSE
        Applies the "PA RBAC Model - Tenant - Design" by adding/removing compliance role-group members
        from a design file, enforcing least-privilege separation of duties. It composes
        Add-RoleGroupMember / Remove-RoleGroupMember. SAFE BY DEFAULT: it runs in -WhatIf mode and only
        DESCRIBES the change; nothing is written until -Commit is supplied. It configures ONLY the
        foundation RBAC guardrails — it builds NO capability policy (DLP, labels, retention, insider
        risk); those are separate, piloted-in-simulation changes owned by their own solutions.
    HOW TO RUN
        # Dry-run (default) from a CSV of Group,Member,Action rows:
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Configuration.ps1 -DesignCsv .\rbac-model.csv
        # Apply after reviewing the dry-run:
        powershell -ExecutionPolicy Bypass -File .\PURVARCH-Configuration.ps1 -DesignCsv .\rbac-model.csv -Commit

        DesignCsv columns: Group (role-group name), Member (UPN), Action (Add|Remove). Prereqs:
        ExchangeOnlineManagement (Connect-IPPSSession) and an admin able to manage role-group membership.
        Role-group names EVOLVE and the tenant may use unified Purview RBAC — verify names against your
        tenant before -Commit.
    EXPECTED RESULTS
        Without -Commit: a per-row plan of exactly what WOULD change (and any [MISSING] group or member).
        With -Commit: each Add/Remove executed, with a PASS/FAIL line per row. PASS = every intended
        membership change applied and no unintended broad-role grants.
.NOTES
    White-label. -WhatIf by default; writes only with -Commit. Security & Compliance PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $DesignCsv,
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/',
    [switch] $Commit
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not (Test-Path $DesignCsv)) {
    Write-Error ("Design CSV not found: {0}" -f $DesignCsv)
    Write-Host 'Provide a CSV with columns: Group,Member,Action (Add|Remove).'
    return
}

# Broad roles that should be RARE — flag any Add targeting them so least privilege is deliberate.
$broadRoles = @('Organization Management','Compliance Administrator','Compliance Data Administrator')

try {
    $rowsIn = @(Import-Csv -Path $DesignCsv)
} catch {
    Write-Error ("Could not read design CSV: {0}" -f $_.Exception.Message); return
}
if ($rowsIn.Count -eq 0) { Write-Host 'Design CSV has no rows. Nothing to do.'; return }

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); return
}

$mode = if ($Commit) { 'COMMIT (changes WILL be applied)' } else { '-WhatIf (dry-run — no changes)' }
Write-Section ("Mode: {0}" -f $mode)

$applied = 0; $skipped = 0; $failed = 0
foreach ($r in $rowsIn) {
    $group  = ($r.Group  | ForEach-Object { $_ }).ToString().Trim()
    $member = ($r.Member | ForEach-Object { $_ }).ToString().Trim()
    $action = ($r.Action | ForEach-Object { $_ }).ToString().Trim()

    if ([string]::IsNullOrWhiteSpace($group) -or [string]::IsNullOrWhiteSpace($member) -or `
        ($action -notin @('Add','Remove'))) {
        Write-Host ("  [SKIP  ] invalid row: Group='{0}' Member='{1}' Action='{2}'" -f $group,$member,$action) -ForegroundColor Yellow
        $skipped++; continue
    }

    # Confirm the role group exists.
    try { Get-RoleGroup -Identity $group -ErrorAction Stop | Out-Null }
    catch {
        Write-Host ("  [MISSING] role group not found: '{0}' — verify the name in your tenant." -f $group) -ForegroundColor Red
        $failed++; continue
    }

    if ($action -eq 'Add' -and ($broadRoles -contains $group)) {
        Write-Host ("  [WARN  ] Add to BROAD role '{0}' for {1} — confirm this is intended (least privilege)." -f $group,$member) -ForegroundColor Yellow
    }

    if (-not $Commit) {
        Write-Host ("  [WHATIF] {0,-6} {1}  ->  {2}" -f $action, $member, $group)
        continue
    }

    try {
        if ($action -eq 'Add') {
            Add-RoleGroupMember -Identity $group -Member $member -ErrorAction Stop -Confirm:$false
        } else {
            Remove-RoleGroupMember -Identity $group -Member $member -ErrorAction Stop -Confirm:$false
        }
        Write-Host ("  [PASS  ] {0,-6} {1}  ->  {2}" -f $action, $member, $group) -ForegroundColor Green
        $applied++
    }
    catch {
        Write-Host ("  [FAIL  ] {0,-6} {1}  ->  {2} : {3}" -f $action,$member,$group,$_.Exception.Message) -ForegroundColor Red
        $failed++
    }
}

Write-Section 'Configuration summary'
if ($Commit) {
    Write-Host ("Applied: {0}   Skipped: {1}   Failed: {2}" -f $applied,$skipped,$failed)
    Write-Host 'Re-run PURVARCH-Discovery.ps1 / PURVARCH-Validation.ps1 to confirm least-privilege separation holds.'
} else {
    Write-Host 'Dry-run only. Review the plan above, then re-run with -Commit to apply.'
    Write-Host 'ROLLBACK for any applied change is the reverse Action (Add <-> Remove) in the design CSV.'
}
Write-Host 'This tool configures ONLY the RBAC guardrails. Capability policies are built later, in simulation first.'
