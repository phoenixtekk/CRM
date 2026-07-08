<#
.SYNOPSIS
    PURVIEW-Discovery.ps1 — read-only cross-domain evidence inventory for the Purview maturity assessment.
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell (and, where used, Microsoft Graph) and collects
        the current Microsoft Purview configuration across the ten maturity domains D1-D10 as scoring
        evidence: Information Protection, DLP, Data Lifecycle & Records, Insider Risk, Communication
        Compliance, Audit, eDiscovery, DSPM, Data Governance, and Compliance Manager. Read-only — it
        changes nothing. Where a capability is plan-gated or a signal is uncertain it is flagged
        "verify your licensing/tenant" rather than asserted.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-Discovery.ps1 -JsonPath .\purview-evidence.json
        Sign in as Global Reader / Compliance Administrator (+ per-solution reader roles) when prompted.
    EXPECTED RESULTS
        A per-domain evidence summary (a signal, or an explicit "unreadable / unlicensed / verify your
        licensing-tenant" note) for each of D1-D10, optionally written to JSON for PURVIEW-MaturityScore.ps1.
.NOTES
    White-label — Purview Solutions. READ-ONLY.
    Uses Get-Label / Get-LabelPolicy / Get-AutoSensitivityLabelPolicy / Get-DlpCompliancePolicy /
    Get-ComplianceTag / Get-RetentionCompliancePolicy / Get-ComplianceCase / Get-AdminAuditLogConfig.
    D4/D5/D8/D9/D10 presence signals are collected read-only; case content is never read (HR/legal-sensitive).
#>
[CmdletBinding()]
param(
    [string]$JsonPath
)

function Try-Get {
    param([string]$Domain, [scriptblock]$Probe)
    try {
        $result = & $Probe
        return [pscustomobject]@{ Domain = $Domain; Readable = $true; Signal = $result; Note = $null }
    } catch {
        return [pscustomobject]@{ Domain = $Domain; Readable = $false; Signal = $null;
            Note = "unreadable / unlicensed — verify your licensing/tenant" }
    }
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== Microsoft Purview — maturity assessment evidence discovery (read-only) ===" -ForegroundColor Cyan

$evidence = [ordered]@{}

# D1 Information Protection
$evidence['D1'] = Try-Get 'D1 Information Protection' {
    $labels = @(Get-Label -ErrorAction Stop)
    $pols   = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
    $auto   = @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)
    "labels=$($labels.Count); labelPolicies=$($pols.Count); autoLabelPolicies=$($auto.Count)"
}
# D2 Data Loss Prevention
$evidence['D2'] = Try-Get 'D2 Data Loss Prevention' {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    $enforce = @($dlp | Where-Object { $_.Mode -match 'Enable' })
    "dlpPolicies=$($dlp.Count); enforcing=$($enforce.Count); testOrAudit=$($dlp.Count - $enforce.Count)"
}
# D3 Data Lifecycle & Records
$evidence['D3'] = Try-Get 'D3 Data Lifecycle & Records' {
    $tags = @(Get-ComplianceTag -ErrorAction Stop)
    $rpol = @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)
    $records = @($tags | Where-Object { $_.IsRecordLabel -eq $true })
    "retentionLabels=$($tags.Count); recordLabels=$($records.Count); retentionPolicies=$($rpol.Count)"
}
# D4 Insider Risk (presence only — HR/legal-sensitive; no case content)
$evidence['D4'] = Try-Get 'D4 Insider Risk Management' {
    $c = @(Get-InsiderRiskPolicy -ErrorAction Stop)
    "insiderRiskPolicies=$($c.Count) (presence only — HR/legal-gated)"
}
# D5 Communication Compliance (presence only — HR/legal-sensitive; no case content)
$evidence['D5'] = Try-Get 'D5 Communication Compliance' {
    $s = @(Get-SupervisoryReviewPolicyV2 -ErrorAction Stop)
    "commCompliancePolicies=$($s.Count) (presence only — HR/legal-gated)"
}
# D6 Audit
$evidence['D6'] = Try-Get 'D6 Audit' {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    "unifiedAuditLogIngestionEnabled=$($cfg.UnifiedAuditLogIngestionEnabled) (Audit Premium = verify your licensing/tenant)"
}
# D7 eDiscovery
$evidence['D7'] = Try-Get 'D7 eDiscovery' {
    $cases = @(Get-ComplianceCase -ErrorAction Stop)
    "eDiscoveryCases=$($cases.Count) (Standard vs Premium = verify your licensing/tenant)"
}
# D8 DSPM (presence signal — preview features vary; flag)
$evidence['D8'] = [pscustomobject]@{ Domain = 'D8 Data Security Posture (DSPM)'; Readable = $true;
    Signal = "DSPM / DSPM for AI is portal-surfaced and partly preview — verify your licensing/tenant in the Purview portal (DSPM)"; Note = 'manual portal check' }
# D9 Data Governance (Unified Catalog / Data Map — Graph/portal)
$evidence['D9'] = [pscustomobject]@{ Domain = 'D9 Data Governance'; Readable = $true;
    Signal = "Unified Catalog / Data Map registration is portal/Graph-surfaced — verify your licensing/tenant in the Purview portal (Data Map)"; Note = 'manual portal check' }
# D10 Compliance Manager
$evidence['D10'] = [pscustomobject]@{ Domain = 'D10 Compliance Manager'; Readable = $true;
    Signal = "Compliance Manager score/assessments are portal-surfaced — verify in the Purview portal (Compliance Manager)"; Note = 'manual portal check' }

foreach ($k in $evidence.Keys) {
    $e = $evidence[$k]
    if ($e.Readable) {
        Write-Host ("`n[{0}] {1}" -f $k, $e.Domain) -ForegroundColor Cyan
        Write-Host ("    {0}" -f $e.Signal)
        if ($e.Note) { Write-Host ("    note: {0}" -f $e.Note) -ForegroundColor DarkGray }
    } else {
        Write-Host ("`n[{0}] {1}" -f $k, $e.Domain) -ForegroundColor Yellow
        Write-Host ("    {0}" -f $e.Note) -ForegroundColor Yellow
    }
}

if ($JsonPath) {
    $out = $evidence.GetEnumerator() | ForEach-Object { $_.Value | Add-Member -NotePropertyName Key -NotePropertyValue $_.Key -PassThru }
    $out | ConvertTo-Json -Depth 5 | Set-Content -Path $JsonPath -Encoding UTF8
    Write-Host "`nEvidence written to $JsonPath (feed PURVIEW-MaturityScore.ps1)." -ForegroundColor Green
}

Write-Host "`nDiscovery complete. Next: PURVIEW-MaturityScore.ps1 to score the rubric." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
