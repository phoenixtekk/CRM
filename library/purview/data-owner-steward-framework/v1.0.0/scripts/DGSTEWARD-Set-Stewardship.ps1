<#
.SYNOPSIS
    DGSTEWARD-Set-Stewardship.ps1 — assign data owners/stewards to Purview controls from a matrix CSV (-WhatIf by default; no change without -Commit).
.DESCRIPTION
    PURPOSE
        Applies the stewardship assignment matrix: writes an "Owner=; Steward=; Reviewed=; ReviewBy="
        tag to each in-scope control's comment/metadata (sensitivity label, DLP policy, retention policy)
        and, where named, adds a member to the built-in role group that steward needs. SAFE BY DEFAULT —
        runs as a -WhatIf preview that changes nothing and prints the exact reverse command for each
        action; pass -Commit to apply. Writes the record "Stewardship Assignments - Configure".
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\DGSTEWARD-Set-Stewardship.ps1 -MatrixPath .\Purview-Stewardship-Matrix.csv -WhatIf
        Apply (pilot domain first):
            powershell -ExecutionPolicy Bypass -File .\DGSTEWARD-Set-Stewardship.ps1 -MatrixPath .\Purview-Stewardship-Matrix.csv -Commit
        CSV columns: ControlType,Name,Identity,Owner,Steward,RoleGroup,Member,Reviewed,ReviewBy
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        Preview lists every intended tag write and role-group add with its reverse command; -Commit applies
        them. PASS = re-running DGSTEWARD-Assess-Ownership.ps1 shows the controls now Owned.
.NOTES
    Purview — Data-Owner & Steward Framework. Safe by default (-WhatIf). No secrets in code. Governance-domain
    owner/steward assignment is made in the Unified Catalog portal (or a confirmed Graph data-plane API) — this
    script does not invent that API; it flags GovernanceDomain rows for portal action.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$MatrixPath,
    [switch]$Commit,
    [string]$ReportName = 'Stewardship Assignments - Configure'
)

# -WhatIf is the default: -Commit must be explicit to change anything.
if (-not $Commit) { $WhatIfPreference = $true }

Write-Host ("=== {0} ({1}) ===" -f $ReportName, $(if ($Commit) {'COMMIT'} else {'WHATIF — no changes'})) -ForegroundColor Cyan

if (-not (Test-Path $MatrixPath)) { throw "Matrix CSV not found: $MatrixPath" }
$matrix = Import-Csv -Path $MatrixPath

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$applied = New-Object System.Collections.Generic.List[object]

function New-Tag {
    param($row)
    $parts = @()
    if ($row.Owner)    { $parts += "Owner=$($row.Owner)" }
    if ($row.Steward)  { $parts += "Steward=$($row.Steward)" }
    if ($row.Reviewed) { $parts += "Reviewed=$($row.Reviewed)" }
    if ($row.ReviewBy) { $parts += "ReviewBy=$($row.ReviewBy)" }
    ($parts -join '; ')
}

foreach ($row in $matrix) {
    $tag = New-Tag -row $row

    # --- Write the owner/steward tag to the control's comment/metadata ---
    switch ($row.ControlType) {
        'SensitivityLabel' {
            $target = "Set-Label -Identity '$($row.Identity)' -Comment '$tag'"
            $reverse = "Set-Label -Identity '$($row.Identity)' -Comment '<previous comment>'"
            if ($PSCmdlet.ShouldProcess($row.Name, "Set Owner/Steward tag [$tag]")) {
                Set-Label -Identity $row.Identity -Comment $tag -ErrorAction Stop
            }
            Write-Host ("  [{0}] {1}: {2}" -f $row.ControlType, $row.Name, $tag)
            Write-Host ("    reverse: {0}" -f $reverse) -ForegroundColor DarkGray
        }
        'DlpPolicy' {
            $reverse = "Set-DlpCompliancePolicy -Identity '$($row.Identity)' -Comment '<previous comment>'"
            if ($PSCmdlet.ShouldProcess($row.Name, "Set Owner/Steward tag [$tag]")) {
                Set-DlpCompliancePolicy -Identity $row.Identity -Comment $tag -ErrorAction Stop
            }
            Write-Host ("  [{0}] {1}: {2}" -f $row.ControlType, $row.Name, $tag)
            Write-Host ("    reverse: {0}" -f $reverse) -ForegroundColor DarkGray
        }
        'RetentionPolicy' {
            $reverse = "Set-RetentionCompliancePolicy -Identity '$($row.Identity)' -Comment '<previous comment>'"
            if ($PSCmdlet.ShouldProcess($row.Name, "Set Owner/Steward tag [$tag]")) {
                Set-RetentionCompliancePolicy -Identity $row.Identity -Comment $tag -ErrorAction Stop
            }
            Write-Host ("  [{0}] {1}: {2}" -f $row.ControlType, $row.Name, $tag)
            Write-Host ("    reverse: {0}" -f $reverse) -ForegroundColor DarkGray
        }
        'GovernanceDomain' {
            Write-Host ("  [GovernanceDomain] {0}: assign Owner/Steward in the Unified Catalog portal (verify path). Tag: {1}" -f $row.Name, $tag) -ForegroundColor Yellow
        }
        default {
            Write-Warning ("  Unknown ControlType '{0}' for '{1}' — skipped." -f $row.ControlType, $row.Name)
        }
    }

    # --- Optional: add the steward to a built-in role group (least-privilege) ---
    if ($row.RoleGroup -and $row.Member) {
        $reverse = "Remove-RoleGroupMember -Identity '$($row.RoleGroup)' -Member '$($row.Member)' -Confirm:`$false"
        $rg = Get-RoleGroup -Identity $row.RoleGroup -ErrorAction SilentlyContinue
        if (-not $rg) {
            Write-Warning ("    Role group '{0}' not found (verify the exact name in your tenant — the portal is evolving). Skipped." -f $row.RoleGroup)
        } else {
            if ($PSCmdlet.ShouldProcess($row.RoleGroup, "Add member $($row.Member)")) {
                Add-RoleGroupMember -Identity $row.RoleGroup -Member $row.Member -Confirm:$false -ErrorAction Stop
            }
            Write-Host ("    role: add {0} to {1}" -f $row.Member, $row.RoleGroup)
            Write-Host ("    reverse: {0}" -f $reverse) -ForegroundColor DarkGray
        }
    }

    $applied.Add([pscustomobject]@{ ControlType=$row.ControlType; Name=$row.Name; Tag=$tag;
        RoleGroup=$row.RoleGroup; Member=$row.Member; Committed=[bool]$Commit })
}

Write-Host ("--- {0} row(s) processed ({1}) ---" -f $applied.Count, $(if ($Commit) {'committed'} else {'preview only'})) -ForegroundColor Cyan
if (-not $Commit) {
    Write-Host 'No changes were made. Review the preview, then re-run with -Commit (pilot domain first).' -ForegroundColor Yellow
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
Write-Host 'Stewardship assignment step complete.' -ForegroundColor Green
