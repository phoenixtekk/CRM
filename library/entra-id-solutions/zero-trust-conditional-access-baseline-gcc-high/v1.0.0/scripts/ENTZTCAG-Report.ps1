<#
.SYNOPSIS
    ENTZTCAG-Report.ps1 — report-only impact analysis from sign-in logs before you enforce.
.DESCRIPTION
    PURPOSE
        Read-only analysis of what the report-only baseline WOULD have done. For recent sign-ins it
        reads the applied Conditional Access policy results (including report-only results) and
        summarizes, per policy: how many sign-ins it would have granted, would have required a control
        for (MFA/compliant device/etc.), or would have blocked. This is the evidence you review before
        moving a policy from report-only to enforce.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTZTCAG-Report.ps1
        Optional: -LookbackDays 7  -PolicyNameLike 'CA00'  -CsvPath .\ca-impact.csv
        Consents to AuditLog.Read.All, Policy.Read.All, Directory.Read.All (read-only). No changes.
    EXPECTED RESULTS
        Per-policy counts of would-grant / would-require / would-block from report-only results, so you
        can confirm impact is as intended (and break-glass/service accounts are not caught). Nothing is
        modified.
.NOTES
    White-label — Entra ID Solutions. Government (GCC High) edition: connects to the US Gov cloud via Connect-MgGraph -Environment USGov (DoD/IL5: USGovDoD, Graph host dod-graph.microsoft.us). Some CA capabilities (P2/Identity Protection risk conditions, auth strengths, device controls) may lag or differ in GCC High/DoD — verify against current Microsoft Government documentation. Read-only.
#>
[CmdletBinding()]
param(
    [int]$LookbackDays = 7,
    [string]$PolicyNameLike = 'CA0',
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'AuditLog.Read.All','Policy.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== CA Report-Only Impact — last $LookbackDays days — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$since = (Get-Date).AddDays(-$LookbackDays).ToString('yyyy-MM-ddT00:00:00Z')
$filter = "createdDateTime ge $since"
$uri = "/v1.0/auditLogs/signIns?`$filter=$([uri]::EscapeDataString($filter))&`$top=500"

$agg = @{}   # policyName -> @{ report=@{grant;require;block}; enforced=@{...} }
$pageCount = 0
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($s in $resp.value) {
        # report-only policy results
        foreach ($grp in @('appliedConditionalAccessPolicies')) {
            foreach ($pol in @($s.$grp)) {
                if ($pol.displayName -notlike "*$PolicyNameLike*") { continue }
                $name = $pol.displayName
                if (-not $agg.ContainsKey($name)) { $agg[$name] = @{ notApplied=0; success=0; failure=0; reportGrant=0; reportRequire=0; reportBlock=0 } }
                switch ($pol.result) {
                    'success'                 { $agg[$name].success++ }
                    'failure'                 { $agg[$name].failure++ }
                    'notApplied'              { $agg[$name].notApplied++ }
                    'reportOnlySuccess'       { $agg[$name].reportGrant++ }
                    'reportOnlyFailure'       { $agg[$name].reportBlock++ }
                    'reportOnlyInterrupted'   { $agg[$name].reportRequire++ }
                    default                   { }
                }
            }
        }
    }
    $uri = $resp.'@odata.nextLink'
    $pageCount++
} while ($uri -and $pageCount -lt 10)

Write-Host "`n-- Per-policy impact --" -ForegroundColor Cyan
$rows = @()
foreach ($name in ($agg.Keys | Sort-Object)) {
    $a = $agg[$name]
    Write-Host ("  • {0}" -f $name) -ForegroundColor White
    Write-Host ("      report-only: would-grant={0}  would-require(interrupt)={1}  would-block={2}" -f $a.reportGrant, $a.reportRequire, $a.reportBlock)
    Write-Host ("      enforced   : success={0}  failure={1}  notApplied={2}" -f $a.success, $a.failure, $a.notApplied)
    if ($a.reportBlock -gt 0) { Write-Host ("      REVIEW: {0} sign-ins would have been BLOCKED — confirm none are legitimate before enforcing." -f $a.reportBlock) -ForegroundColor Yellow }
    $rows += [pscustomobject]@{ Policy=$name; WouldGrant=$a.reportGrant; WouldRequire=$a.reportRequire; WouldBlock=$a.reportBlock; Success=$a.success; Failure=$a.failure }
}
if (-not $agg.Count) { Write-Host "  no matching policy results in the window (widen -LookbackDays or check -PolicyNameLike)." -ForegroundColor DarkGray }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`nExported to $CsvPath" -ForegroundColor Green }
Write-Host "`nEnforce a policy only when its would-block set contains no legitimate users." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
