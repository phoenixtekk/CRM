<#
.SYNOPSIS
    CMMC-Report.ps1 — read-only CMMC posture report (CMMC Score Posture - Report).
.DESCRIPTION
    PURPOSE
        Produces the 'CMMC Score Posture - Report': the Compliance Manager role-separation snapshot,
        a coverage summary of the technical signals behind automatable NIST 800-171 actions grouped by
        family, and the licensing entitlement — the internal readiness picture you review before the
        C3PAO assessment. It explicitly notes that the AUTHORITATIVE score/export live in the Purview
        Compliance Manager portal, and that the SPRS score and certification are separate determinations.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMMC-Report.ps1 -CsvPath C:\Temp\cmmc-posture.csv
        Sign in as a Compliance Administrator / Global Reader when prompted. For GCC High pass
        -ExoConnectionUri / -GraphEnvironment as in CMMC-Discovery.ps1.
    EXPECTED RESULTS
        A role-separation table, a family-by-family technical-signal coverage table, and a licensing
        line, optionally exported to CSV. Read-only — makes no changes.
.NOTES
    White-label — Purview Solutions. Read-only.
    Reuses read-only calls (Get-RoleGroupMember, Get-AdminAuditLogConfig, Get-DlpCompliancePolicy,
    Get-Label, Get-RetentionCompliancePolicy, Get-MgSubscribedSku). Not the authoritative score —
    the portal Compliance Manager export is; SPRS/certification are compliance/C3PAO determinations.
#>
[CmdletBinding()] param(
    [string]$CsvPath,
    [string]$ExoConnectionUri,
    [string]$GraphEnvironment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if ($ExoConnectionUri) { Connect-IPPSSession -ConnectionUri $ExoConnectionUri -ShowBanner:$false }
else                   { Connect-IPPSSession -ShowBanner:$false }

Write-Host "`n=== CMMC Score Posture - Report ===" -ForegroundColor Cyan
Write-Host ("Generated: {0}" -f (Get-Date)) -ForegroundColor Gray

# --- Role separation ---
Write-Host "`n--- Role separation (Compliance Manager) ---" -ForegroundColor Cyan
$cmGroups = 'Compliance Manager Administrators','Compliance Manager Assessors','Compliance Manager Contributors','Compliance Manager Readers'
foreach ($g in $cmGroups) {
    try { $m = @(Get-RoleGroupMember -Identity $g -ErrorAction Stop | Select-Object -ExpandProperty Name); Write-Host ("  {0}: {1}" -f $g, ($(if($m){$m -join ', '}else{'(none)'}))) }
    catch { Write-Host ("  {0}: not found (verify the exact name in your tenant)" -f $g) -ForegroundColor Yellow }
}

# --- Technical-signal coverage by NIST 800-171 family ---
Write-Host "`n--- Technical-signal coverage (automatable NIST 800-171 actions) ---" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]
function Add-Row([string]$Family,[string]$Signal,[bool]$Ok,[string]$Detail){ $rows.Add([pscustomobject]@{ Family=$Family; Signal=$Signal; State=($(if($Ok){'PASS'}else{'GAP'})); Detail=$Detail }) }

try { $on=[bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled; Add-Row 'AU' 'Unified audit logging' $on ($(if($on){'On'}else{'Off'})) } catch { Add-Row 'AU' 'Unified audit logging' $false 'read failed' }
try { $d=@(Get-DlpCompliancePolicy -ErrorAction Stop); Add-Row 'SC/MP' 'DLP policy present' ($d.Count -ge 1) ("{0} policy(ies)" -f $d.Count) } catch { Add-Row 'SC/MP' 'DLP policy present' $false 'read failed' }
try { $l=@(Get-Label -ErrorAction Stop); Add-Row 'SC/MP' 'Sensitivity label present' ($l.Count -ge 1) ("{0} label(s)" -f $l.Count) } catch { Add-Row 'SC/MP' 'Sensitivity label present' $false 'read failed' }
try { $r=@(Get-RetentionCompliancePolicy -ErrorAction Stop); Add-Row 'MP' 'Retention policy present' ($r.Count -ge 1) ("{0} policy(ies)" -f $r.Count) } catch { Add-Row 'MP' 'Retention policy present' $false 'read failed' }

$rows | Format-Table Family, Signal, State, Detail -AutoSize
$passCount = @($rows | Where-Object { $_.State -eq 'PASS' }).Count
Write-Host ("  Signals present: {0}/{1}" -f $passCount, $rows.Count) -ForegroundColor Cyan

# --- Licensing entitlement ---
Write-Host "`n--- Licensing (premium CMMC/NIST template entitlement) ---" -ForegroundColor Cyan
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.DirectoryManagement)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    Connect-MgGraph -Scopes 'Organization.Read.All' -Environment $GraphEnvironment -NoWelcome
    $skus = Get-MgSubscribedSku -ErrorAction Stop
    $e5 = @($skus | Where-Object { $_.SkuPartNumber -match 'E5|COMPLIANCE|INFORMATION_PROTECTION' })
    Write-Host ("  E5/Compliance-related SKUs seen: {0} — CONFIRM the CMMC/NIST premium template is available to create in the portal." -f $e5.Count) -ForegroundColor ($(if($e5){'Cyan'}else{'Yellow'}))
    Disconnect-MgGraph | Out-Null
} catch { Write-Host ("  Licensing read unavailable: {0} — verify entitlement manually (Requirement 2.1)." -f $_.Exception.Message) -ForegroundColor Yellow }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("`nSaved technical-signal coverage to {0}" -f $CsvPath) -ForegroundColor Green }

Write-Host "`nNOTE: the AUTHORITATIVE CMMC score and export live in the Purview Compliance Manager portal." -ForegroundColor Yellow
Write-Host "      The NIST 800-171 DoD Assessment Methodology / SPRS score and CMMC certification are" -ForegroundColor Yellow
Write-Host "      compliance/security/legal/C3PAO determinations — not produced by this report." -ForegroundColor Yellow
Write-Host "`nReport complete." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
