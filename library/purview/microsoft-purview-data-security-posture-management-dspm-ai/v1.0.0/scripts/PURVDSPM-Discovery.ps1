<#
.SYNOPSIS
    PURVDSPM-Discovery.ps1 — inventory the controls that feed DSPM posture (read-only).
.DESCRIPTION
    PURPOSE
        Reads the sensitivity labels, label policies, DLP policies and rules, and auto-labeling policies
        that Data Security Posture Management aggregates into posture — your baseline of the levers DSPM
        will recommend extending. With -IncludeSensitiveTypes it also records the sensitive information
        types in scope. Read-only; changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell:
          Connect-IPPSSession
          .\PURVDSPM-Discovery.ps1
          .\PURVDSPM-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        DSPM-Posture-Estate-Discovery.csv listing labels, label policies, DLP policies/rules, and
        auto-labeling policies. With -IncludeSensitiveTypes, Sensitive-Data-Risk-Estate-Assess.csv of
        the sensitive info types. Compare counts against the Purview portal (Testing doc, Test 2).
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    Cmdlets are standard Security & Compliance PowerShell (Get-Label, Get-LabelPolicy,
    Get-DlpCompliancePolicy, Get-DlpComplianceRule, Get-AutoSensitivityLabelPolicy,
    Get-DlpSensitiveInformationType); none are invented.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath = ".\DSPM-Posture-Estate-Discovery.csv",
    [string]$SensitiveOutPath = ".\Sensitive-Data-Risk-Estate-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== PURVDSPM Discovery — controls inventory (read-only) ===" -ForegroundColor Cyan

function Test-IppsConnected {
    try { Get-Label -ErrorAction Stop | Out-Null; return $true }
    catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first." -ForegroundColor Red; return $false }
}
if (-not (Test-IppsConnected)) { return }

$rows = [System.Collections.Generic.List[object]]::new()

# Sensitivity labels
foreach ($l in (Get-Label -ErrorAction SilentlyContinue)) {
    $rows.Add([pscustomobject]@{
        Type = "SensitivityLabel"; Name = $l.DisplayName; Identity = $l.Name
        State = $(if ($l.Disabled) { "Disabled" } else { "Enabled" })
        Detail = ("Priority={0}; Parent={1}" -f $l.Priority, $l.ParentId)
    })
}
# Label policies
foreach ($p in (Get-LabelPolicy -ErrorAction SilentlyContinue)) {
    $rows.Add([pscustomobject]@{
        Type = "LabelPolicy"; Name = $p.Name; Identity = $p.Guid
        State = $p.Mode; Detail = ("Labels={0}" -f ($p.Labels -join ", "))
    })
}
# DLP policies
$dlpPolicies = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
foreach ($d in $dlpPolicies) {
    $rows.Add([pscustomobject]@{
        Type = "DlpPolicy"; Name = $d.Name; Identity = $d.Guid
        State = $d.Mode; Detail = ("Enabled={0}; Workloads={1}" -f $d.Enabled, $d.Workload)
    })
}
# DLP rules (conditions/actions summary)
foreach ($r in (Get-DlpComplianceRule -ErrorAction SilentlyContinue)) {
    $rows.Add([pscustomobject]@{
        Type = "DlpRule"; Name = $r.Name; Identity = $r.Guid
        State = $(if ($r.Disabled) { "Disabled" } else { "Enabled" })
        Detail = ("Policy={0}; BlockAccess={1}" -f $r.Policy, $r.BlockAccess)
    })
}
# Auto-labeling policies (may be unlicensed)
try {
    foreach ($a in (Get-AutoSensitivityLabelPolicy -ErrorAction Stop)) {
        $rows.Add([pscustomobject]@{
            Type = "AutoLabelPolicy"; Name = $a.Name; Identity = $a.Guid
            State = $a.Mode; Detail = ("Label={0}; Workloads={1}" -f $a.ApplySensitivityLabel, ($a.Workload -join ","))
        })
    }
} catch { Write-Host "  Auto-labeling policies not readable (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nControls inventory written to {0}  (DSPM Posture - Estate - Discovery)" -f $OutPath) -ForegroundColor Green
$rows | Group-Object Type | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-18} {1}" -f $_.Name, $_.Count) }

if ($IncludeSensitiveTypes) {
    Write-Host "`n=== Sensitive information types in scope ===" -ForegroundColor Cyan
    try {
        $sit = Get-DlpSensitiveInformationType -ErrorAction Stop |
            Select-Object @{n="Type";e={"SensitiveInfoType"}}, Name, Publisher, Description
        $sit | Export-Csv -Path $SensitiveOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  {0} sensitive info type(s) written to {1}  (Sensitive-Data Risk - Estate - Assess)" -f @($sit).Count, $SensitiveOutPath) -ForegroundColor Green
    } catch { Write-Host "  Could not read sensitive info types: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "`nNext: read DSPM → Overview & Recommendations in the portal, then run PURVDSPM-AIExposure.ps1." -ForegroundColor Cyan
