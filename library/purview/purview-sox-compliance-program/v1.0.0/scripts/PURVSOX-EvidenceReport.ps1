<#
.SYNOPSIS
    PURVSOX-EvidenceReport.ps1 — produce the SOX control-to-evidence scorecard and run the three evidence runbooks (read-only).
.DESCRIPTION
    PURPOSE
        Read-only. Two outputs: (1) SOX Program - Purview Controls - Report — a control-to-evidence
        scorecard reading live state (audit on, label published, DLP present + mode, retention scoped,
        audit-retention present); (2) the auditor evidence runbooks over a bounded window via
        Search-UnifiedAuditLog — Financial Data Access (FileAccessed/FileDownloaded), Control Change
        Management (Set-DlpCompliancePolicy/New-Label/role adds), and Access Provisioning (group/role
        adds, sharing). It reads and summarizes only — it never changes a control and never rules on
        SOX adequacy.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVSOX-EvidenceReport.ps1 -Days 7 -OutputFolder .\PURVSOX-out
        .\PURVSOX-EvidenceReport.ps1 -Days 30 -FinanceSites "https://contoso.sharepoint.com/sites/FinancePilot" -OutputFolder .\PURVSOX-out
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). Interactive
        modern-auth / MFA admin; no secrets in code.
    EXPECTED RESULTS
        A printed scorecard (one row per control with PRESENT/GAP), and one CSV per runbook of the benign/
        test activity in the window. PASS = every control PRESENT and each runbook returns interpretable
        rows for the pilot scope. Audit is not retroactive — only activity after logging was enabled appears.
.NOTES
    Purview category — SOX Compliance Program. Read-only. Control-design adequacy, operating-effectiveness,
    materiality, and retention-schedule sufficiency are management/internal-audit/records/legal
    determinations — DEFERRED. Feature availability is licensing-/tenant-dependent. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [ValidateRange(1,90)][int]$Days = 7,
    [string[]]$FinanceSites,                          # optional SharePoint site URL filter for access/provisioning
    [string]$LabelName          = 'Financial – SOX Reporting – Confidential',
    [string]$DlpName            = 'DLP – SOX Financial Data – Simulation',
    [string]$RetentionName      = 'Retention – SOX Financial Records – Governed',
    [string]$AuditRetentionName = 'Audit Retention – Financial Data Access – SOX',
    [string]$OutputFolder = '.\PURVSOX-out'
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

$start = (Get-Date).AddDays(-$Days); $end = Get-Date

# --- Control-to-evidence scorecard (live state) -----------------------------------------------------
Write-Section 'SOX Program - Purview Controls - Report (scorecard)'
$score = [System.Collections.Generic.List[object]]::new()
function Add-Score([string]$Control,[string]$Objective,[string]$State){ $score.Add([pscustomobject]@{ Control = $Control; ITGC_Objective = $Objective; State = $State }) }

$auditOn = $false
try { Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null; $auditOn = [bool](Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled }
catch { Warn "Exchange Online read failed: $($_.Exception.Message)" }
Add-Score 'Unified audit' 'IT operations / evidence foundation' ($(if($auditOn){'PRESENT (ON)'}else{'GAP (OFF — enable, Step 3)'}))

$ippsOk = $false
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; $ippsOk = $true } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }
if ($ippsOk) {
    try { $lbl = Get-Label -Identity $LabelName -ErrorAction SilentlyContinue; Add-Score 'Financial label' 'Access to programs & data / classification' ($(if($lbl){'PRESENT'}else{'GAP (create/publish, Step 4)'})) } catch {}
    try {
        $dlp = Get-DlpCompliancePolicy -Identity $DlpName -ErrorAction SilentlyContinue
        Add-Score 'Financial DLP' 'Access to programs & data / exposure' ($(if($dlp){("PRESENT (Mode=$($dlp.Mode))")}else{'GAP (create in simulation, Step 5)'}))
    } catch {}
    try { $rp = Get-RetentionCompliancePolicy -Identity $RetentionName -ErrorAction SilentlyContinue; Add-Score 'Records retention' 'Records retention' ($(if($rp){('PRESENT (Enabled=' + $rp.Enabled + ')')}else{'GAP (create scoped, Step 6)'})) } catch {}
    try { $arp = Get-UnifiedAuditLogRetentionPolicy -Identity $AuditRetentionName -ErrorAction SilentlyContinue; Add-Score 'Audit retention' 'Change management / access trail' ($(if($arp){("PRESENT (dur=$($arp.RetentionDuration))")}else{'GAP (create, Step 7)'})) } catch {}
}
$score | Format-Table Control, ITGC_Objective, State -AutoSize | Out-String | Write-Host
$score | Export-Csv (Join-Path $OutputFolder 'SOX Program - Purview Controls - Report.csv') -NoTypeInformation -Encoding UTF8

# --- Evidence runbooks (audit-log searches) ---------------------------------------------------------
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    Warn 'Search-UnifiedAuditLog unavailable (connect Exchange Online). Skipping runbooks.'
} else {
    function Invoke-Runbook([string]$Name,[string[]]$Operations,[string]$File,[string]$Answers){
        Write-Section ("Runbook: {0}" -f $Name)
        Write-Host ("  Answers: {0}" -f $Answers) -ForegroundColor DarkGray
        try {
            $ev = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations $Operations -ResultSize 5000 -ErrorAction Stop)
            if ($FinanceSites -and $Name -ne 'Control Change Management') {
                $ev = $ev | Where-Object { $blob = $_.AuditData; $FinanceSites | Where-Object { $blob -match [regex]::Escape($_) } }
            }
            Write-Host ("  Events in window ({0} days): {1}" -f $Days, @($ev).Count) -ForegroundColor Green
            $rows = $ev | ForEach-Object {
                [pscustomobject]@{ CreationDate = $_.CreationDate; Operation = $_.Operations; User = $_.UserIds; RecordType = $_.RecordType }
            }
            $rows | Group-Object Operation | Sort-Object Count -Descending | Select-Object @{n='Operation';e={$_.Name}}, Count | Format-Table -AutoSize | Out-String | Write-Host
            $rows | Export-Csv (Join-Path $OutputFolder $File) -NoTypeInformation -Encoding UTF8
        } catch { Warn ("  Runbook query failed: {0}" -f $_.Exception.Message) }
    }

    Invoke-Runbook 'Financial Data Access' @('FileAccessed','FileDownloaded','FileSyncDownloadedFull') `
        'Evidence - Financial Data Access.csv' 'Who accessed/downloaded labeled financial content? (correlate with the label)'

    Invoke-Runbook 'Control Change Management' @('New-DlpCompliancePolicy','Set-DlpCompliancePolicy','New-Label','Set-Label','New-RetentionCompliancePolicy','Set-RetentionCompliancePolicy','Add member to role.') `
        'Evidence - Control Change Management.csv' 'Who changed a DLP/label/retention/role configuration? (change-management ITGC)'

    Invoke-Runbook 'Access Provisioning' @('Add member to group.','Add member to role.','SharingInvitationCreated','AnonymousLinkCreated') `
        'Evidence - Access Provisioning.csv' 'Who was granted access to financial data? (segregation of duties / provisioning)'
}

Write-Section 'Evidence report complete'
$gaps = @($score | Where-Object { $_.State -like 'GAP*' }).Count
if ($gaps -eq 0) { Ok 'All controls PRESENT. Walk each runbook CSV with your reviewer.' }
else { Warn ("$gaps control gap(s) — address per the Implementation guide before expanding.") }
Write-Host 'Reminder: audit is not retroactive; only activity after logging was enabled appears. SOX adequacy is management/internal-audit/records/legal — deferred.' -ForegroundColor DarkGray
