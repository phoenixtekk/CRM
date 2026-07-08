<#
.SYNOPSIS
    CMPPCI-Report.ps1 — produce the PCI Posture – Report: audit state, DLP mode, label, role separation, licensing (read-only).
.DESCRIPTION
    PURPOSE
        Read-only posture report for the PCI-DSS program. Rolls up the live control state for the report:
        unified-audit state + retention (Req 10), the cardholder-data DLP policy and its mode (Req 3),
        the cardholder-data label presence (Req 3), the Compliance Manager role-group membership /
        separation snapshot (Req 7), and the SKUs it can read (licensing). Exports CSV/HTML for the
        assessment package. It reports state; it changes nothing and it does not attest.
    HOW TO RUN
        Connect first: Connect-IPPSSession (and Connect-ExchangeOnline for the audit-config read).
          .\CMPPCI-Report.ps1
          .\CMPPCI-Report.ps1 -CsvPath .\pci-posture.csv -HtmlPath .\pci-posture.html
    EXPECTED RESULTS
        PCI Posture – Report rows: audit ON + retention, DLP present + mode (should read simulation until
        enforcement is gated), label present, role separation snapshot, licensing. The portal Compliance
        Manager export remains the authoritative score source.
.NOTES
    White-label. Read-only. Whether the score/evidence SATISFIES PCI-DSS and how the CDE is scoped are
    QSA/compliance/legal determinations — DEFERRED. Compliance Manager scoring/export are portal
    operations. Feature availability is licensing-/tenant-dependent and evolving. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [string]   $PolicyName = 'DLP-PCI-CardholderData',
    [string]   $LabelName  = 'Label-PCI-CardholderData',
    [string[]] $RoleGroups = @('ComplianceAdministrator','Compliance Manager Administrators','Compliance Manager Assessors','Compliance Manager Contributors','Compliance Manager Readers'),
    [string]   $CsvPath,
    [string]   $HtmlPath
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession | Out-Null }
} catch { Write-Error ("Connect-IPPSSession failed: {0}" -f $_.Exception.Message); return }

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row([string]$Requirement,[string]$Control,[string]$State){ $rows.Add([pscustomobject]@{ Requirement = $Requirement; Control = $Control; State = $State }) }

# --- Req 10: unified audit + retention --------------------------------------------------------------
Write-Section 'Req 10 — unified audit logging + retention'
try {
    if (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue) {
        $ua = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
    } else {
        Connect-ExchangeOnline -ShowBanner:$false | Out-Null
        $ua = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
    }
    Write-Host ("UnifiedAuditLogIngestionEnabled : {0}" -f $ua) -ForegroundColor ($(if($ua){'Green'}else{'Yellow'}))
    Add-Row 'Req 10' 'Unified audit ingestion' ($(if($ua){'ON'}else{'OFF — enable (Step 4)'}))
} catch { Write-Warning $_.Exception.Message; Add-Row 'Req 10' 'Unified audit ingestion' 'UNKNOWN' }
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction SilentlyContinue
    Add-Row 'Req 10' 'Audit retention policy' ($(if($arp){("PRESENT ({0})" -f @($arp).Count)}else{'NONE — add to meet Req 10 retention'}))
} catch {}

# --- Req 3: cardholder-data DLP + label -------------------------------------------------------------
Write-Section 'Req 3 — cardholder-data DLP + label'
try {
    $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($pol) {
        $enforcing = ("$($pol.Mode)" -eq 'Enable')
        Write-Host ("DLP '{0}' Mode : {1}" -f $PolicyName, $pol.Mode) -ForegroundColor ($(if("$($pol.Mode)" -like 'Test*'){'Green'}else{'Yellow'}))
        Add-Row 'Req 3' 'Cardholder DLP policy' ("PRESENT (Mode=$($pol.Mode)$([string]::Empty))" + ($(if($enforcing){' — ENFORCING'}else{' — simulation/pending enforcement'})))
    } else { Add-Row 'Req 3' 'Cardholder DLP policy' "MISSING '$PolicyName' — create in simulation (Step 6)" }
} catch { Write-Warning $_.Exception.Message }
try {
    $lbl = Get-Label -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $LabelName -or $_.Name -eq $LabelName }
    Add-Row 'Req 3' 'Cardholder label' ($(if($lbl){'PUBLISHED'}else{"MISSING '$LabelName' — publish (Step 6)"}))
} catch {}

# --- Req 7: role separation snapshot ----------------------------------------------------------------
Write-Section 'Req 7 — role separation (PCI Roles – Separation Evidence)'
$roleMap = @{}
foreach ($rgName in $RoleGroups) {
    try {
        $rg = Get-RoleGroup -Identity $rgName -ErrorAction SilentlyContinue
        if ($rg) {
            $members = @(Get-RoleGroupMember -Identity $rgName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
            $roleMap[$rgName] = $members
            Write-Host ("{0}: {1} member(s)" -f $rgName, $members.Count)
            Add-Row 'Req 7' "Role: $rgName" ("{0} member(s)" -f $members.Count)
        }
    } catch {}
}
# Flag any admin who is also a contributor (separation-of-duties signal)
$admins = @()
foreach ($k in $roleMap.Keys) { if ($k -match 'Administrator') { $admins += $roleMap[$k] } }
$contrib = @(); foreach ($k in $roleMap.Keys) { if ($k -match 'Contributor') { $contrib += $roleMap[$k] } }
$overlap = @($admins | Where-Object { $contrib -contains $_ } | Select-Object -Unique)
if ($overlap.Count -gt 0) {
    Write-Host ("SEPARATION FLAG: {0} identity(ies) are both administrator and contributor." -f $overlap.Count) -ForegroundColor Yellow
    Add-Row 'Req 7' 'Separation-of-duties flag' ("Overlap: " + ($overlap -join ', '))
} else { Add-Row 'Req 7' 'Separation-of-duties' 'No admin/contributor overlap detected' }

# --- Licensing note ---------------------------------------------------------------------------------
Add-Row 'Licensing' 'PCI-DSS template / advanced controls' 'Verify E5 / E5 Compliance + Audit (Premium) entitlement in the portal'

# --- Emit -------------------------------------------------------------------------------------------
Write-Section 'PCI Posture – Report'
$rows | Format-Table Requirement, Control, State -AutoSize | Out-String | Write-Host
Write-Host 'Authoritative score/evidence: the portal Compliance Manager export. QSA/compliance judge sufficiency and CDE scope — deferred.' -ForegroundColor DarkGray

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("CSV written: {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message) }
}
if ($HtmlPath) {
    try {
        $head = '<style>body{font-family:Segoe UI,Arial,sans-serif}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px 10px;font-size:13px}th{background:#f2f2f2;text-align:left}</style>'
        $pre  = "<h2>PCI Posture &ndash; Report</h2><p>Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Live tenant state. The portal Compliance Manager export is authoritative; CDE scope and attestation are QSA/compliance determinations &mdash; deferred.</p>"
        $rows | ConvertTo-Html -Head $head -PreContent $pre -Property Requirement, Control, State | Out-File -FilePath $HtmlPath -Encoding UTF8
        Write-Host ("HTML written: {0}" -f $HtmlPath) -ForegroundColor Green
    } catch { Write-Warning ("Could not write HTML: {0}" -f $_.Exception.Message) }
}
