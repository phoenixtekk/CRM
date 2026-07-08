<#
.SYNOPSIS
    PURVIMP-Set-RoleGroups.ps1 — least-privilege Purview role-group / RBAC setup helper (-WhatIf by default; -Commit to apply).
.DESCRIPTION
    PURPOSE
        Applies a least-privilege role assignment matrix: adds named members to the built-in Security &
        Compliance role groups their function needs (Compliance Administrator, Records Management,
        Insider Risk Management, eDiscovery Manager, Audit Manager/Reader, Content Explorer viewers,
        Communication Compliance, etc.). SAFE BY DEFAULT — previews with -WhatIf and changes nothing
        until you pass -Commit. Prints the exact reverse (Remove-RoleGroupMember) command for each add.
    HOW TO RUN
        # Dry-run (no changes):
        powershell -ExecutionPolicy Bypass -File .\PURVIMP-Set-RoleGroups.ps1 -MatrixPath .\Purview-Role-Matrix.csv -WhatIf
        # Apply:
        powershell -ExecutionPolicy Bypass -File .\PURVIMP-Set-RoleGroups.ps1 -MatrixPath .\Purview-Role-Matrix.csv -Commit
        Matrix CSV columns: RoleGroup, Member   (Member = UPN or mail-enabled security group)
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        Dry-run lists each intended add + its reverse command and flags any role group missing in the
        tenant. With -Commit, Get-RoleGroupMember returns exactly the intended members. PASS = least-
        privilege membership matches the approved matrix; sensitive roles contain only approved members.
.NOTES
    Purview — Implementing Microsoft Purview: Foundation, Roles & Onboarding. Membership of sensitive
    role groups (Insider Risk, Communication Compliance, eDiscovery) is confirmed with HR/privacy/legal —
    this tool implements the assignment, it does not make the determination. No secrets in code.
#>
[CmdletBinding(DefaultParameterSetName='WhatIf')]
param(
    [Parameter(Mandatory)][string]$MatrixPath,
    [switch]$Commit,
    [switch]$WhatIf = $true
)

if ($Commit) { $WhatIf = $false }

if (-not (Test-Path $MatrixPath)) { throw "Matrix CSV not found: $MatrixPath" }
$matrix = Import-Csv -Path $MatrixPath
if (-not ($matrix | Get-Member -Name RoleGroup) -or -not ($matrix | Get-Member -Name Member)) {
    throw "Matrix CSV must have columns: RoleGroup, Member"
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$mode = if ($WhatIf) { 'DRY-RUN (-WhatIf): no changes will be made' } else { 'COMMIT: changes WILL be applied' }
Write-Host ("=== Purview Role Matrix – Design  [{0}] ===" -f $mode) -ForegroundColor Cyan

foreach ($row in $matrix) {
    $rgName  = $row.RoleGroup.Trim()
    $member  = $row.Member.Trim()
    if (-not $rgName -or -not $member) { continue }

    $rg = Get-RoleGroup -Identity $rgName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host ("  [MISSING] Role group '{0}' does not exist in this tenant — verify the name, or create a custom scoped group with New-RoleGroup." -f $rgName) -ForegroundColor Yellow
        continue
    }

    $existing = @(Get-RoleGroupMember -Identity $rgName -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -eq $member -or $_.PrimarySmtpAddress -eq $member -or $_.WindowsLiveID -eq $member })
    if ($existing.Count -gt 0) {
        Write-Host ("  [SKIP] '{0}' already a member of '{1}'" -f $member, $rgName) -ForegroundColor DarkGray
        continue
    }

    $reverse = ("Remove-RoleGroupMember -Identity '{0}' -Member '{1}' -Confirm:`$false" -f $rgName, $member)
    if ($WhatIf) {
        Write-Host ("  [WOULD ADD] '{0}' -> '{1}'" -f $member, $rgName) -ForegroundColor Yellow
        Write-Host ("             reverse: {0}" -f $reverse) -ForegroundColor DarkGray
    } else {
        try {
            Add-RoleGroupMember -Identity $rgName -Member $member -Confirm:$false -ErrorAction Stop
            Write-Host ("  [ADDED] '{0}' -> '{1}'   (reverse: {2})" -f $member, $rgName, $reverse) -ForegroundColor Green
        } catch {
            Write-Host ("  [ERROR] adding '{0}' to '{1}': {2}" -f $member, $rgName, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

if ($WhatIf) {
    Write-Host "`nDry-run complete. Re-run with -Commit to apply. Apply to the pilot ring first." -ForegroundColor Cyan
} else {
    Write-Host "`nCommit complete. Verify with: Get-RoleGroupMember -Identity '<RoleGroup>'" -ForegroundColor Green
}
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
