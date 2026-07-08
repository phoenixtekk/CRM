<#
.SYNOPSIS
    OPSAUTO-Discovery.ps1 — Inventory current Purview policy state to a snapshot (read-only).
.DESCRIPTION
    PURPOSE
        Enumerates the Purview policy objects the framework manages — DLP compliance policies (and their
        MODE), sensitivity labels, label policies, and retention (data lifecycle) policies + rules — with no
        changes, and writes a JSON snapshot (Automation Snapshot - Tenant State - Current) that Validate and
        Report consume. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSAUTO-Discovery.ps1 -OutFile .\snapshot.json
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA sign-in;
        no secrets in code.
    EXPECTED RESULTS
        Console counts per object type and a JSON snapshot at -OutFile. Each DLP policy shows its Mode
        (e.g. Enable vs a test/simulation value — VERIFY the exact values in your tenant). Non-fatal read
        errors per type are reported and skipped.
.NOTES
    Purview category — Automation Framework. Read-only. DLP mode values and cmdlet parameters are evolving/
    licensing-dependent; confirm against your entitlements and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$OutFile = ".\Automation-Snapshot-Tenant-State-Current.json"
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

$snapshot = [ordered]@{
    generatedUtc     = (Get-Date).ToUniversalTime().ToString('o')
    dlpPolicies      = @()
    sensitivityLabels= @()
    labelPolicies    = @()
    retentionPolicies= @()
}

Write-Section "DLP compliance policies"
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $dlp) {
        $snapshot.dlpPolicies += [ordered]@{ name=$p.Name; mode=$p.Mode; enabled=$p.Enabled; workload=$p.Workload; guid="$($p.Guid)" }
    }
    Ok ("DLP policies: {0}" -f @($dlp).Count)
} catch { Warn "Could not read DLP policies: $($_.Exception.Message)" }

Write-Section "Sensitivity labels"
try {
    $labels = Get-Label -ErrorAction Stop
    foreach ($l in $labels) {
        $snapshot.sensitivityLabels += [ordered]@{ name=$l.Name; displayName=$l.DisplayName; guid="$($l.Guid)"; parentId="$($l.ParentId)" }
    }
    Ok ("Sensitivity labels: {0}" -f @($labels).Count)
} catch { Warn "Could not read sensitivity labels: $($_.Exception.Message)" }

Write-Section "Label policies (publish state = enforce)"
try {
    $lp = Get-LabelPolicy -ErrorAction Stop
    foreach ($p in $lp) {
        $snapshot.labelPolicies += [ordered]@{ name=$p.Name; enabled=$p.Enabled; mode=$p.Mode; labels=@($p.Labels) }
    }
    Ok ("Label policies: {0}" -f @($lp).Count)
} catch { Warn "Could not read label policies: $($_.Exception.Message)" }

Write-Section "Retention (data lifecycle) policies"
try {
    $ret = Get-RetentionCompliancePolicy -ErrorAction Stop
    foreach ($p in $ret) {
        $rules = @()
        try { $rules = @(Get-RetentionComplianceRule -Policy $p.Name -ErrorAction Stop | ForEach-Object { $_.Name }) } catch {}
        $snapshot.retentionPolicies += [ordered]@{ name=$p.Name; enabled=$p.Enabled; mode=$p.Mode; workload=$p.Workload; guid="$($p.Guid)"; rules=$rules }
    }
    Ok ("Retention policies: {0}" -f @($ret).Count)
} catch { Warn "Could not read retention policies: $($_.Exception.Message)" }

$snapshot | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutFile -Encoding UTF8
Write-Section "Snapshot written"
Ok "  $OutFile  (feed this to OPSAUTO-Validate.ps1 / OPSAUTO-Report.ps1)"
Warn "  Records-management, insider-risk, and communication-compliance objects are intentionally NOT inventoried here (out of automated scope)."
