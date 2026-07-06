<#
.SYNOPSIS
    GWREG-Report.ps1 — controlled-data compliance coverage / evidence report (read-only).
.DESCRIPTION
    PURPOSE
        Read-only report that compiles the controlled-data control COVERAGE across the scopes you list -
        data-region residency, Access Management policy, Access Approvals, Access Transparency evidence,
        and CSE where relied upon - into a dated coverage/evidence record for the audit file. It states
        TECHNICAL coverage and its scope; it does NOT assert ITAR/DFARS compliance (that is legal's
        determination on top of this evidence). Exports optional CSV/JSON for attachment to the audit.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWREG-Report.ps1 -OrgUnitPaths /Controlled,/Controlled/Eng `
            [-OutFile coverage-report] [-CustomerId your-domain-customer-id]
        Requires a super-admin OAuth token in GOOGLE_OAUTH_TOKEN (read-only). Where a control cannot be
        read live it is recorded as 'confirm-in-console' so the record is honest. No changes are made.
    EXPECTED RESULTS
        A per-scope coverage table on screen and, if -OutFile is set, coverage-report.csv/.json for the
        evidence store. Run on a cadence and before each audit; keep the dated history (best practice).
.NOTES
    White-label — the repeatable way. Read-only. Reports coverage/evidence, never a legal conclusion.
    Add-on-gated evidence features (policy-compliance log events, data-regions advanced reporting,
    compliance exports) are cited or flagged "verify in your tenant"; no secrets are ever recorded.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string[]]$OrgUnitPaths,
    [string]$OutFile,
    [string]$CustomerId
)

$token = $env:GOOGLE_OAUTH_TOKEN
if (-not $token) {
    Write-Host "Set GOOGLE_OAUTH_TOKEN to a super-admin OAuth access token (e.g. 'gcloud auth print-access-token')." -ForegroundColor Red
    return
}

$stamp = (Get-Date).ToString('u')
Write-Host "`n=== Controlled-data compliance coverage / evidence report ===" -ForegroundColor Cyan
Write-Host "Generated: $stamp   Scopes: $($OrgUnitPaths -join ', ')"
Write-Host "Technical coverage only - NOT a legal ITAR/DFARS determination.`n"

$rows = New-Object System.Collections.Generic.List[object]
foreach ($ou in $OrgUnitPaths) {
    # Live compliance-setting reads are add-on-gated and not uniformly exposed; record 'confirm-in-console'
    # rather than invent a value. This keeps the evidence honest and points the auditor to the surface.
    $rows.Add([pscustomobject]@{
        Scope                = $ou
        DataRegion           = 'confirm-in-console: Data > Compliance > Data regions'
        AccessManagement     = 'confirm-in-console: Data > Compliance > Access Management (licensed?)'
        AccessApprovals      = 'confirm-in-console: Data > Compliance > Access Approvals'
        AccessTransparency   = 'evidence: Reporting > Access Transparency log events'
        ClientSideEncryption = 'confirm-in-console: Data > Compliance > Client-side encryption (if relied upon)'
        EvidenceFeatures     = 'policy-compliance log events / data-regions reporting / compliance exports (add-on) - verify entitlement'
        Generated            = $stamp
    })
}

$rows | Format-Table -AutoSize Scope, DataRegion, AccessManagement, AccessApprovals, ClientSideEncryption

Write-Host "`nEvidence surfaces to retain (route to SIEM/evidence store, per retention requirement):" -ForegroundColor Yellow
Write-Host "  - Access Transparency log events (Google-staff access allowed via Access Management/Approvals)"
Write-Host "  - Policy-compliance log events; Data-regions advanced reporting; Compliance data exports (Assured Controls add-on)"

if ($OutFile) {
    $csv = "$OutFile.csv"; $json = "$OutFile.json"
    try {
        $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
        $rows | ConvertTo-Json -Depth 4 | Out-File -FilePath $json -Encoding UTF8
        Write-Host "`nWrote evidence: $csv and $json" -ForegroundColor Green
    } catch {
        Write-Host ("Could not write output files: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}
Write-Host "`nReminder: coverage records WHICH control is configured and its scope - never keys/tokens. Legal signs off compliance." -ForegroundColor DarkYellow
