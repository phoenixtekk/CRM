<#
.SYNOPSIS
    OPSCOE-Validate.ps1 - evaluate the governance register against the CoE standards; PASS/FAIL/WARN per artifact (read-only).
.DESCRIPTION
    PURPOSE
        The machine-checkable governance gate for a Purview Center of Excellence. Reads the standards config
        (naming pattern + review cadence) and the governance register (from OPSCOE-Discovery.ps1) and checks,
        per artifact: (1) NAMING conformance to <Purpose> - <Capability> - <State>; (2) an OWNER and a REVIEW
        date exist (register column or stamped Comment); (3) no HIGH-IMPACT policy is ENFORCED without recorded
        simulation/test evidence; (4) SEPARATION OF DUTIES - no board member sits in a conflicting
        investigative role; and (5) the register RECONCILES to the live tenant (no orphaned/unregistered
        artifacts). Read-only. Produces "Purview CoE Lifecycle - Review" with a per-artifact PASS/FAIL/WARN.
    HOW TO RUN
        Connect-IPPSSession    # (+ Connect-ExchangeOnline for role-group membership reconciliation)
        .\OPSCOE-Validate.ps1 -StandardsConfig .\coe-standards.json -Register .\Purview-CoE-Register-Governed.csv -OutPath .\Purview-CoE-Lifecycle-Review.csv
        Optional: -BoardMatrixCsv .\coe-board-matrix.csv to run the separation-of-duties check;
        -SkipLiveReconcile to validate the register alone without connecting.
        coe-standards.json: { "namePattern": "...", "reviewCadenceDays": 90, "investigativeRoles": [ ... ] }
    EXPECTED RESULTS
        A per-artifact PASS/FAIL/WARN table written to -OutPath, plus a summary. PASS overall = every gate
        PASS (WARN allowed only with a recorded, board-accepted exception). Any FAIL is remediated via intake
        before the estate is declared governed.
.NOTES
    White-label Microsoft Purview tooling. Read-only - evaluates only. No credentials in code. Portal-only
    capabilities (insider risk) are governed by attestation rows, not invented cmdlets. Verify in your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$StandardsConfig,
    [Parameter(Mandatory)][string]$Register,
    [string]$OutPath = ".\Purview-CoE-Lifecycle-Review.csv",
    [string]$BoardMatrixCsv,
    [switch]$SkipLiveReconcile
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

if (-not (Test-Path $StandardsConfig)) { Write-Host "[FAIL] standards config not found: $StandardsConfig" -ForegroundColor Red; return }
if (-not (Test-Path $Register))        { Write-Host "[FAIL] register not found: $Register" -ForegroundColor Red; return }

$std = Get-Content -Raw -Path $StandardsConfig | ConvertFrom-Json
$namePattern = if ($std.namePattern) { $std.namePattern } else { '^.+\s[--]\s.+\s[--]\s.+$' }
$cadenceDays = if ($std.reviewCadenceDays) { [int]$std.reviewCadenceDays } else { 90 }
$investigative = if ($std.investigativeRoles) { @($std.investigativeRoles) } else {
    @('Insider Risk Management','Communication Compliance','eDiscovery Manager','eDiscovery Administrator')
}

$reg = @(Import-Csv -Path $Register)
$results = New-Object System.Collections.Generic.List[object]
function Add-Result($type,$name,$check,$status,$detail){
    $results.Add([pscustomobject]@{ Type=$type; Name=$name; Check=$check; Status=$status; Detail=$detail })
}

Write-Section 'Per-artifact gates'
foreach ($a in $reg) {
    $portalOnly = ("$($a.State)" -match 'Portal')
    # 1. Naming conformance (portal-only/attestation rows are exempt)
    if ($portalOnly) { Add-Result $a.Type $a.Name 'Naming' 'WARN' 'Portal-only/attestation - naming standard N/A' }
    elseif ("$($a.Name)" -match $namePattern) { Add-Result $a.Type $a.Name 'Naming' 'PASS' '' }
    else { Add-Result $a.Type $a.Name 'Naming' 'FAIL' 'Does not match <Purpose> - <Capability> - <State> - route through intake' }

    # 2. Owner + review date present and current
    if ([string]::IsNullOrWhiteSpace($a.Owner)) { Add-Result $a.Type $a.Name 'Owner' 'FAIL' 'No owner in register/Comment' }
    else { Add-Result $a.Type $a.Name 'Owner' 'PASS' "Owner=$($a.Owner)" }

    $review = $null
    if (-not [string]::IsNullOrWhiteSpace($a.Review)) { [datetime]::TryParse($a.Review, [ref]$review) | Out-Null }
    if (-not $review) { Add-Result $a.Type $a.Name 'ReviewDate' 'FAIL' 'No/invalid review date' }
    elseif ($review -lt (Get-Date).AddDays(-$cadenceDays)) { Add-Result $a.Type $a.Name 'ReviewDate' 'WARN' "Review overdue (> $cadenceDays days): $($a.Review)" }
    else { Add-Result $a.Type $a.Name 'ReviewDate' 'PASS' "Review=$($a.Review)" }

    # 3. Enforced-without-evidence. State like 'Enable'/'Enabled' on a high-impact type is a FAIL unless
    #    the register records simulation evidence (Detail contains 'SimEvidence' or 'Evidence=').
    $highImpact = @('DlpPolicy','AutoLabelPolicy','RetentionPolicy') -contains "$($a.Type)"
    $enforced   = ("$($a.State)" -match '^(?i)enable') -and ("$($a.State)" -notmatch '(?i)test|sim')
    $hasEvidence= ("$($a.Detail)" -match '(?i)SimEvidence|Evidence=')
    if ($highImpact -and $enforced -and -not $hasEvidence) {
        Add-Result $a.Type $a.Name 'EnforceEvidence' 'FAIL' 'Enforced with no recorded simulation/test evidence'
    } elseif ($highImpact -and $enforced) {
        Add-Result $a.Type $a.Name 'EnforceEvidence' 'PASS' 'Enforced with recorded simulation evidence'
    }
}

# 4. Separation of duties across the board matrix
if ($BoardMatrixCsv -and (Test-Path $BoardMatrixCsv)) {
    Write-Section 'Separation-of-duties (board matrix)'
    $matrix = @(Import-Csv -Path $BoardMatrixCsv)
    $byMember = $matrix | Group-Object Member
    foreach ($g in $byMember) {
        $roles = @($g.Group | ForEach-Object { "$($_.RoleGroup)".Trim() })
        $inv = @($roles | Where-Object { $investigative -contains $_ })
        if ($inv.Count -ge 2) {
            Add-Result 'RoleGroup' $g.Name 'SoD' 'FAIL' ("Holds multiple investigative roles: {0}" -f ($inv -join ', '))
        } elseif ($inv.Count -eq 1 -and $roles.Count -gt 1) {
            Add-Result 'RoleGroup' $g.Name 'SoD' 'WARN' ("Investigative role '{0}' plus other roles - confirm charter separation" -f $inv[0])
        } else {
            Add-Result 'RoleGroup' $g.Name 'SoD' 'PASS' 'No investigative-role conflict'
        }
    }
}

# 5. Register reconciles to the live tenant (orphaned = in tenant, not in register)
if (-not $SkipLiveReconcile) {
    Write-Section 'Register reconciliation vs live tenant'
    try {
        if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ErrorAction Stop | Out-Null }
        $regNames = @($reg | ForEach-Object { "$($_.Name)" })
        $liveNames = New-Object System.Collections.Generic.List[string]
        try { Get-Label -ErrorAction Stop                     | ForEach-Object { $liveNames.Add($_.DisplayName) } } catch {}
        try { Get-DlpCompliancePolicy -ErrorAction Stop       | ForEach-Object { $liveNames.Add($_.Name) } } catch {}
        try { Get-RetentionCompliancePolicy -ErrorAction Stop | ForEach-Object { $liveNames.Add($_.Name) } } catch {}
        try { Get-AutoSensitivityLabelPolicy -ErrorAction Stop| ForEach-Object { $liveNames.Add($_.Name) } } catch {}
        $orphans = @($liveNames | Where-Object { $regNames -notcontains $_ } | Select-Object -Unique)
        if ($orphans.Count -gt 0) {
            foreach ($o in $orphans) { Add-Result 'Unregistered' $o 'Reconcile' 'FAIL' 'Live artifact not in the register - route through intake' }
        } else { Add-Result 'Register' '(all)' 'Reconcile' 'PASS' 'No orphaned/unregistered live artifacts' }
    } catch { Add-Result 'Register' '(all)' 'Reconcile' 'WARN' "Live reconcile skipped: $($_.Exception.Message)" }
}

$results | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8

Write-Section 'Result - Purview CoE Lifecycle - Review'
$results | Format-Table -AutoSize | Out-String | Write-Host
$fail = @($results | Where-Object Status -eq 'FAIL').Count
$warn = @($results | Where-Object Status -eq 'WARN').Count
Write-Host ("PASS/FAIL/WARN written to {0}" -f $OutPath) -ForegroundColor Green
if ($fail -gt 0) { Write-Host ("$fail FAIL - remediate via intake before declaring the estate governed.") -ForegroundColor Red }
elseif ($warn -gt 0) { Write-Host ("0 FAIL, $warn WARN - WARN allowed only with a recorded board-accepted exception.") -ForegroundColor Yellow }
else { Write-Host 'All gates PASS.' -ForegroundColor Green }
Write-Host 'Next: OPSCOE-Register.ps1 to produce the governance scorecard.'
