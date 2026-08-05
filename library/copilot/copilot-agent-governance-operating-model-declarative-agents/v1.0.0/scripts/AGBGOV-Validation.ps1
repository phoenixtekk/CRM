<#
.SYNOPSIS
    AGBGOV-Validation.ps1 — Test whether agents pass the governance gates. READ-ONLY.

.DESCRIPTION
    Purpose:
        Validates each business-process agent against the governance gates defined in the operating
        model, and reports PASS/FAIL per gate. It answers "does the governance actually hold?" for a
        given set of agents. It changes nothing.

        Gates evaluated per agent:
          G1  Owner present            - Agent Owner is named.
          G2  Sponsor present          - Business Sponsor is named.
          G3  Approval recorded        - an ARB Decision Reference (AGBARB-YYYY-...) exists for any
                                         agent in 'Approved - business use'.
          G4  Data review for sensitive- agents at Confidential/Restricted have a Data & Security
                                         Reviewer named.
          G5  Sharing justified        - agents shared 'Anyone in org' are Approved and reviewed.
          G6  Naming convention        - name matches 'AGBGOV - <Function> - <Purpose> - <Audience>'.
          G7  Review not overdue       - Next Review Date is in the future (if present).

    How to run:
        # Export the "AGBGOV - Agent Register" SharePoint list to CSV, or use an Agent Registry
        # export, then:
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Validation.ps1 -RegisterCsv .\AGBGOV-Register-Export.csv -CsvPath .\Validation.csv

        # -FailOnGate makes the script exit 1 if any agent fails a gate (useful in a pipeline).

    Expected results:
        A per-agent, per-gate PASS/FAIL CSV at -CsvPath, plus a console summary of failing gates.
        Exit code 0 (all pass) or 1 (failures) when -FailOnGate is set.

.NOTES
    Copilot category - governance - READ-ONLY. No tenant connection required; operates on the CSV.
    Column names are matched defensively so either the register export or the Agent Registry export
    can be used. Verify current agent admin capabilities against Microsoft documentation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RegisterCsv,

    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [switch]$FailOnGate
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $RegisterCsv)) { throw "Register CSV not found: $RegisterCsv" }

$rows = Import-Csv -Path $RegisterCsv
$namePattern = '^AGBGOV\s+–\s+.+\s+–\s+.+\s+–\s+.+$'   # en dash separated, four segments

function Val($row, [string[]]$names) {
    foreach ($n in $names) {
        if ($row.PSObject.Properties[$n]) { return "$($row.$n)".Trim() }
    }
    return ''
}

$results = foreach ($r in $rows) {
    $name        = Val $r @('Agent Name','AgentName','Name','DisplayName')
    $owner       = Val $r @('Agent Owner','AgentOwner','Owner')
    $sponsor     = Val $r @('Business Sponsor','BusinessSponsor','Sponsor')
    $reviewer    = Val $r @('Data & Security Reviewer','DataSecurityReviewer','Reviewer')
    $classif     = Val $r @('Data Classification','DataClassification','Classification')
    $sharing     = Val $r @('Sharing Scope','SharingScope','AvailableTo','Availability')
    $lifecycle   = Val $r @('Lifecycle State','LifecycleState','Status')
    $arbRef      = Val $r @('ARB Decision Reference','ARBDecisionReference','DecisionReference')
    $nextReview  = Val $r @('Next Review Date','NextReviewDate')

    $isApproved  = $lifecycle -match 'business use'
    $isSensitive = $classif -match 'Confidential|Restricted'
    $isOrgWide   = $sharing -match 'Anyone in org|all'

    $g1 = [bool]$owner
    $g2 = [bool]$sponsor
    $g3 = (-not $isApproved) -or ($arbRef -match '^AGBARB-')
    $g4 = (-not $isSensitive) -or [bool]$reviewer
    $g5 = (-not $isOrgWide) -or ($isApproved -and [bool]$reviewer)
    $g6 = $name -match $namePattern
    $g7 = $true
    if ($nextReview) {
        $dt = $null
        if ([datetime]::TryParse($nextReview, [ref]$dt)) { $g7 = ($dt -ge (Get-Date)) }
    }

    [pscustomobject]@{
        AgentName            = $name
        G1_OwnerPresent      = if ($g1) {'PASS'} else {'FAIL'}
        G2_SponsorPresent    = if ($g2) {'PASS'} else {'FAIL'}
        G3_ApprovalRecorded  = if ($g3) {'PASS'} else {'FAIL'}
        G4_DataReview        = if ($g4) {'PASS'} else {'FAIL'}
        G5_SharingJustified  = if ($g5) {'PASS'} else {'FAIL'}
        G6_NamingConvention  = if ($g6) {'PASS'} else {'FAIL'}
        G7_ReviewNotOverdue  = if ($g7) {'PASS'} else {'FAIL'}
        OverallResult        = if ($g1 -and $g2 -and $g3 -and $g4 -and $g5 -and $g6 -and $g7) {'PASS'} else {'FAIL'}
    }
}

$results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "Validation written to: $CsvPath" -ForegroundColor Green

$fail = @($results | Where-Object OverallResult -eq 'FAIL')
Write-Host "`n===== AGBGOV validation summary =====" -ForegroundColor Cyan
Write-Host ("Agents evaluated..... {0}" -f @($results).Count)
Write-Host ("Agents passing....... {0}" -f (@($results).Count - $fail.Count))
Write-Host ("Agents failing....... {0}" -f $fail.Count)
foreach ($gate in 'G1_OwnerPresent','G2_SponsorPresent','G3_ApprovalRecorded','G4_DataReview','G5_SharingJustified','G6_NamingConvention','G7_ReviewNotOverdue') {
    $c = @($results | Where-Object { $_.$gate -eq 'FAIL' }).Count
    if ($c -gt 0) { Write-Host ("  {0} failing: {1}" -f $gate, $c) -ForegroundColor Yellow }
}
Write-Host "====================================`n"

if ($FailOnGate -and $fail.Count -gt 0) { exit 1 }
exit 0
