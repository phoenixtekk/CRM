<#
.SYNOPSIS
    INDGOV-Report.ps1 — read-only Government control evidence report: control -> Purview object -> configuration -> proof, plus a DLP simulation-match summary. Makes no changes.
.DESCRIPTION
    PURPOSE
        Produces the ongoing evidence artifact for the government (CJIS/CMMC/ITAR) program — the binder you
        show an auditor/assessor: which Purview object implements each control (CJI/CUI/ITAR labels, services
        DLP, endpoint DLP, records retention, audit-evidence retention), its current configuration, and a
        proof reference, cross-referenced to 'Control Map – Gov – Purview'. It also summarizes DLP alerts/
        matches (Microsoft Graph security alerts) by workload/severity/status so the SIMULATION pilot's
        matches — what WOULD have been blocked — are evidenced. Read-only.
    HOW TO RUN
        # Control inventory (S&C PowerShell — pass your cloud endpoint in GCC High/DoD):
        .\INDGOV-Report.ps1 -ConnectionUri https://ps.compliance.protection.office365.us/powershell-liveid/ -CsvPath .\Gov-Controls-Binder.csv
        # DLP simulation-match summary (Graph, read-only) — connect first:
        Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -Environment USGov   # verify environment for your cloud
        .\INDGOV-Report.ps1 -DlpMatches -DaysBack 30 -CsvPath .\Gov-DLP-Evidence.csv
        PowerShell 5.1+/7+; ExchangeOnlineManagement for the control inventory, Microsoft.Graph for the DLP
        matches. No secrets in code. DLP alert surfacing can lag events by minutes.
    EXPECTED RESULTS
        A control -> object -> configuration -> proof table ('Evidence – Gov Controls – Binder') and, with
        -DlpMatches, a summary of DLP alerts by service/severity/status. Zero DLP matches during an active
        simulation may mean detection is under-matching (see the Testing guide) — not that no controlled data
        moved. With -CsvPath, the evidence CSV(s) are written.
.NOTES
    Purview category — Government industry bundle (CJIS/CMMC/ITAR). Read-only evidence. DLP matches can
    contain CJI/CUI/ITAR — restrict who runs/reads this to the least-privilege reviewer, separate from the
    configuring admin. Verify licensing/tenant/cloud; Graph security-alert availability depends on your plan
    and cloud. No certification/authorization is implied.
#>
[CmdletBinding()]
param(
    [string]$ConnectionUri,             # sovereign-cloud S&C endpoint — VERIFY for your cloud
    [switch]$DlpMatches,                # include the DLP simulation-match summary (requires Connect-MgGraph)
    [int]$DaysBack = 30,
    [string]$CsvPath,
    [string]$DlpTitleFilter = 'DLP'     # keep alerts whose category/title indicate Data Loss Prevention
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# ---------- Part 1: control -> object -> configuration -> proof inventory ----------
Write-Section "Evidence – Gov Controls – Binder (control inventory)"
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed — skipping control inventory. Install-Module ExchangeOnlineManagement -Scope CurrentUser"
} else {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $connectParams = @{}
    if ($ConnectionUri) { $connectParams['ConnectionUri'] = $ConnectionUri; Warn "Using sovereign-cloud S&C endpoint: $ConnectionUri (verify for your cloud)." }
    try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message) — pass the correct -ConnectionUri for GCC High/DoD." }

    $rows = @()
    function Add-Row($control,$name,$config,$proof){ $script:rows += [pscustomobject]@{ Control=$control; PurviewObject=$name; Configuration=$config; Proof=$proof } }

    # Labels
    try {
        $labels = Get-Label -ErrorAction Stop
        foreach ($n in @('Protect – Gov CJI – Restricted','Protect – Gov CUI – Controlled','Protect – Gov ITAR – Controlled')) {
            $l = $labels | Where-Object { $_.DisplayName -eq $n }
            if ($l) { $enc = if ("$($l.EncryptionEnabled)" -eq 'True' -or "$($l.ContentType)" -match 'Encrypt') { 'encrypts' } else { 'NO ENCRYPTION (verify)' }; Add-Row 'Sensitivity label' $n "protection=$enc" 'Get-Label' }
            else { Add-Row 'Sensitivity label' $n 'NOT FOUND' 'Get-Label' }
        }
    } catch { Warn "Get-Label failed: $($_.Exception.Message)" }

    # DLP (services + endpoint)
    try {
        $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
        foreach ($n in @('DLP – Gov Controlled Data – Simulate','DLP – Gov Endpoint Egress – Simulate')) {
            $p = $dlp | Where-Object { $_.Name -eq $n }
            if ($p) { Add-Row 'DLP policy' $n "mode=$($p.Mode)" 'Get-DlpCompliancePolicy' } else { Add-Row 'DLP policy' $n 'NOT FOUND' 'Get-DlpCompliancePolicy' }
        }
    } catch { Warn "Get-DlpCompliancePolicy failed: $($_.Exception.Message)" }

    # Retention
    try {
        $r = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq 'Retention – Gov Records – Publish' }
        if ($r) { Add-Row 'Records retention' 'Retention – Gov Records – Publish' "enabled=$($r.Enabled)" 'Get-RetentionCompliancePolicy' } else { Add-Row 'Records retention' 'Retention – Gov Records – Publish' 'NOT FOUND' 'Get-RetentionCompliancePolicy' }
    } catch { Warn "Get-RetentionCompliancePolicy failed: $($_.Exception.Message)" }

    # Audit
    try {
        $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq 'Audit Retention – Gov Evidence – LongTerm' }
        if ($arp) { Add-Row 'Audit evidence retention' 'Audit Retention – Gov Evidence – LongTerm' "duration=$($arp.RetentionDuration); priority=$($arp.Priority)" 'Get-UnifiedAuditLogRetentionPolicy' } else { Add-Row 'Audit evidence retention' 'Audit Retention – Gov Evidence – LongTerm' 'NOT FOUND' 'Get-UnifiedAuditLogRetentionPolicy' }
    } catch { Warn "Get-UnifiedAuditLogRetentionPolicy failed: $($_.Exception.Message)" }

    if ($rows.Count) {
        $rows | Format-Table -AutoSize | Out-String | Write-Host
        if ($CsvPath) {
            $binderPath = if ($DlpMatches) { [System.IO.Path]::ChangeExtension($CsvPath, $null).TrimEnd('.') + '-controls.csv' } else { $CsvPath }
            $rows | Export-Csv -Path $binderPath -NoTypeInformation
            Write-Host ("Control-inventory evidence written to {0}." -f $binderPath) -ForegroundColor Green
        }
        Warn "Cross-reference each row to 'Control Map – Gov – Purview'. A 'NOT FOUND' row is a control gap. Configuration adequacy (classification/retention/ITAR access) is compliance/security/legal's determination."
    }
}

# ---------- Part 2: DLP simulation-match summary (Graph, optional) ----------
if ($DlpMatches) {
    Write-Section "DLP simulation-match summary (Microsoft Graph security alerts)"
    if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
        Warn "Microsoft Graph SDK not available. Install Microsoft.Graph and run Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -Environment <your cloud>."
    } else {
        try { $ctx = Get-MgContext } catch { $ctx = $null }
        if (-not $ctx) { Warn "Not connected to Graph. Run: Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -Environment <your cloud>." }
        else {
            $since = (Get-Date).ToUniversalTime().AddDays(-1 * [math]::Abs($DaysBack)).ToString('yyyy-MM-ddTHH:mm:ssZ')
            Write-Host ("DLP matches since {0}" -f $since) -ForegroundColor Cyan
            $alerts = @()
            try {
                $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=createdDateTime ge $since"
                do {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                    if ($resp.value) { $alerts += $resp.value }
                    $uri = $resp.'@odata.nextLink'
                } while ($uri)
            } catch { Warn "Could not read security alerts (scope/licensing/cloud?): $($_.Exception.Message)" }

            $dlpAlerts = @($alerts | Where-Object { ("$($_.category) $($_.title) $($_.detectionSource) $($_.serviceSource)") -match $DlpTitleFilter })
            Write-Host ("Total alerts in window: {0}  |  DLP-related: {1}" -f @($alerts).Count, $dlpAlerts.Count) -ForegroundColor Green
            if ($dlpAlerts.Count -eq 0) {
                Warn "No DLP alerts in the window. During an active SIMULATION this can indicate under-matching detection (see Testing Gate 5/6) — not necessarily that no controlled data moved."
            } else {
                $mrows = foreach ($a in $dlpAlerts) { [pscustomobject]@{ Created=$a.createdDateTime; Service=$a.serviceSource; Severity=$a.severity; Status=$a.status; Title=$a.title; AlertId=$a.id } }
                Write-Host "`n-- By service --" -ForegroundColor Cyan
                $mrows | Group-Object Service | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize
                Write-Host "-- By severity --" -ForegroundColor Cyan
                $mrows | Group-Object Severity | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize
                Write-Host "-- By status --" -ForegroundColor Cyan
                $mrows | Group-Object Status | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize
                if ($CsvPath) {
                    $dlpPath = [System.IO.Path]::ChangeExtension($CsvPath, $null).TrimEnd('.') + '-dlp.csv'
                    $mrows | Sort-Object Created -Descending | Export-Csv -Path $dlpPath -NoTypeInformation
                    Write-Host ("DLP simulation-match evidence written to {0}." -f $dlpPath) -ForegroundColor Green
                }
                Warn "DLP matches can contain CJI/CUI/ITAR — restrict access to this output to the least-privilege reviewer."
            }
        }
    }
}

Write-Host "`nDone. This is read-only evidence. Regenerate on a cadence; determinations remain compliance/security/records/legal's." -ForegroundColor White
