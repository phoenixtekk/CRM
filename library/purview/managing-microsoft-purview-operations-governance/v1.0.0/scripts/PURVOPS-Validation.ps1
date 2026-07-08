<#
.SYNOPSIS
    PURVOPS-Validation.ps1 — read-only Purview role & access review: enumerate compliance role groups + members and diff against an approved baseline. Makes no changes.
.DESCRIPTION
    PURPOSE
        Drives the quarterly access review. Enumerates Purview/compliance role groups and their members and
        either saves the current membership as the approved baseline (-SaveApprovedList) or compares live
        membership to an approved CSV (-ApprovedListCsv), flagging unapproved ADDITIONS, missing (removed)
        members, and accounts holding MULTIPLE sensitive role groups (for justification). Read-only.
    HOW TO RUN
        Connect-IPPSSession                                  # modern-auth admin sign-in (no secrets in code)
        .\PURVOPS-Validation.ps1 -SaveApprovedList -ApprovedListCsv .\Approved-Roles.csv
        .\PURVOPS-Validation.ps1 -ApprovedListCsv .\Approved-Roles.csv
        PowerShell 5.1+/7+; requires Security & Compliance PowerShell (Get-RoleGroup / Get-RoleGroupMember).
    EXPECTED RESULTS
        A membership table by role group, and (with an approved CSV) an Additions/Removals diff plus a
        multi-role privileged-account list. Zero unexplained additions + all privileged accounts attested = pass.
.NOTES
    Purview — Operations & Governance. Read-only. This reports membership for attestation; the ACCOUNTABLE
    OWNER attests and any removal is done under change control. Preserve administrator/investigator role
    separation for insider-risk / communication-compliance. Verify role-group availability for your tenant.
#>
[CmdletBinding()]
param(
    [string]$ApprovedListCsv = '.\Approved-Roles.csv',
    [switch]$SaveApprovedList,
    # Role groups treated as "sensitive" for the multi-role privilege flag (adjust to your governance).
    [string[]]$SensitiveRoleGroups = @(
        'ComplianceAdministrator','Compliance Administrator','Compliance Data Administrator',
        'Insider Risk Management','InsiderRiskManagement','eDiscovery Manager','eDiscovery Administrator',
        'Information Protection','Information Protection Admins','Records Management','Audit Manager'
    )
)

if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) {
    Write-Error "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first."
    return
}

Write-Host "=== Access Review - Purview Roles - Quarterly ===" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]
$groups = Get-RoleGroup -ErrorAction SilentlyContinue
foreach ($g in $groups) {
    try {
        $members = Get-RoleGroupMember -Identity $g.Name -ErrorAction Stop
    } catch { $members = @() }
    foreach ($m in $members) {
        $rows.Add([pscustomobject]@{
            RoleGroup = $g.Name
            Member    = if ($m.PrimarySmtpAddress) { [string]$m.PrimarySmtpAddress } else { [string]$m.Name }
            Display   = [string]$m.DisplayName
        })
    }
    if (-not $members -or $members.Count -eq 0) {
        $rows.Add([pscustomobject]@{ RoleGroup=$g.Name; Member='(none)'; Display='' })
    }
}

$rows | Sort-Object RoleGroup, Member | Format-Table -AutoSize
Write-Host ("Role groups: {0}  |  membership rows: {1}" -f $groups.Count, @($rows | Where-Object {$_.Member -ne '(none)'}).Count) -ForegroundColor Green

# --- Multi-role (privileged) accounts across sensitive groups ---
$sensitiveRows = $rows | Where-Object { $_.Member -ne '(none)' -and ($SensitiveRoleGroups -contains $_.RoleGroup) }
$multi = $sensitiveRows | Group-Object Member | Where-Object { $_.Count -gt 1 }
if ($multi) {
    Write-Host "`n--- Accounts in MULTIPLE sensitive role groups (require justification) ---" -ForegroundColor Yellow
    foreach ($mg in $multi) {
        Write-Host ("  {0} -> {1}" -f $mg.Name, (($mg.Group.RoleGroup) -join ', ')) -ForegroundColor Yellow
    }
}

# --- Save approved baseline ---
if ($SaveApprovedList) {
    $rows | Where-Object { $_.Member -ne '(none)' } | Select-Object RoleGroup, Member |
        Export-Csv -Path $ApprovedListCsv -NoTypeInformation
    Write-Host ("`nApproved membership baseline saved to {0}. Re-save only AFTER attestation." -f $ApprovedListCsv) -ForegroundColor Green
    return
}

# --- Diff live vs approved ---
if (Test-Path $ApprovedListCsv) {
    $approved = Import-Csv $ApprovedListCsv
    $keyOf = { param($r) "{0}|{1}" -f $r.RoleGroup, $r.Member }
    $appSet = @{}; foreach ($a in $approved) { $appSet[(& $keyOf $a)] = $true }
    $liveSet = @{}; foreach ($l in ($rows | Where-Object {$_.Member -ne '(none)'})) { $liveSet[(& $keyOf $l)] = $l }

    $additions = @(); $removals = @()
    foreach ($k in $liveSet.Keys) { if (-not $appSet.ContainsKey($k)) { $additions += $liveSet[$k] } }
    foreach ($k in $appSet.Keys)  { if (-not $liveSet.ContainsKey($k)) { $removals  += $k } }

    Write-Host "`n=== Diff vs approved baseline ===" -ForegroundColor Yellow
    if ($additions.Count -eq 0 -and $removals.Count -eq 0) {
        Write-Host "No membership drift. Live matches approved. (PASS)" -ForegroundColor Green
    } else {
        if ($additions.Count) {
            Write-Host "Unapproved ADDITIONS (investigate/attest or remove under change control):" -ForegroundColor Red
            $additions | Sort-Object RoleGroup, Member | Format-Table RoleGroup, Member -AutoSize
        }
        if ($removals.Count) {
            Write-Host "Members in approved list but NOT live (expected if removed under change control):" -ForegroundColor Cyan
            $removals | Sort-Object | ForEach-Object { Write-Host ("  {0}" -f $_) }
        }
    }
} else {
    Write-Warning "No approved list at $ApprovedListCsv. Run with -SaveApprovedList (after the owner confirms membership is correct) to establish the baseline."
}
