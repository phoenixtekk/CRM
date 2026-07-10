<#
.SYNOPSIS
    FABGOV-TenantSettings-Baseline.ps1 — compare live tenant settings to a desired-state baseline (preview-first).
.DESCRIPTION
    PURPOSE
        Exports the tenant's current admin (tenant) settings and compares them to a desired-state baseline
        JSON that represents 'Tenant Governance Baseline - Fabric/Power BI - v1', producing a human-readable
        drift report (setting, live value, baseline value, scope). By default it is REPORT-ONLY and writes
        nothing back. -Apply is intentionally gated and, even then, only previews unless -Confirm is added.
    HOW TO RUN
        Export a starter baseline from the live tenant:
          .\FABGOV-TenantSettings-Baseline.ps1 -ExportBaseline .\baseline.json
        Compare live settings to a reviewed baseline (report-only):
          .\FABGOV-TenantSettings-Baseline.ps1 -Baseline .\baseline.json
        (Apply is deliberately restricted — see NOTES. Tenant-setting changes should be made in the admin
        portal, piloted on 'Governance Pilot Ring - Fabric - Ring1', and change-approved.)
        Requires MicrosoftPowerBIMgmt and the Fabric/Power BI Administrator role.
    EXPECTED RESULTS
        A drift table of settings that differ from the baseline; an exported baseline file when
        -ExportBaseline is used. No changes to the tenant in report-only mode.
.NOTES
    Data — Fabric/Power BI Governance. Reads GetTenantSettings via the admin API.
    Writing tenant settings via API is limited/preview and high-blast-radius; this script therefore
    treats the admin PORTAL (piloted + change-approved) as the source of change and stays report-first.
    *Verify current admin-API tenant-settings write support in your tenant before enabling any apply.*
    White-label. No tenant values hard-coded.
#>
[CmdletBinding()]
param(
    [string]$Baseline,
    [string]$ExportBaseline,
    [switch]$Apply,          # gate 1: opt-in to the (preview-only) apply path
    [switch]$Confirm         # gate 2: without this, -Apply still only previews
)

if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop
try { Connect-PowerBIServiceAccount -ErrorAction Stop | Out-Null }
catch { Write-Host "Sign-in failed: $($_.Exception.Message)" -ForegroundColor Red; return }

# GetTenantSettings (admin) — read the live settings
try {
    $live = (Invoke-PowerBIRestMethod -Url "admin/tenantsettings" -Method Get | ConvertFrom-Json).tenantSettings
} catch {
    Write-Host "Could not read tenant settings: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Confirm the admin role and that admin/tenantsettings is available in your tenant." -ForegroundColor Yellow
    Disconnect-PowerBIServiceAccount | Out-Null; return
}
Write-Host ("Live tenant settings read: {0}" -f $live.Count) -ForegroundColor Green

# Export a starter baseline (a snapshot to review and trim to the settings you govern)
if ($ExportBaseline) {
    $live | Select-Object settingName, title, enabled, canSpecifySecurityGroups,
        @{n='enabledSecurityGroups';e={ ($_.enabledSecurityGroups | ForEach-Object { $_.name }) -join ';' }} |
        Sort-Object settingName | ConvertTo-Json -Depth 5 | Out-File $ExportBaseline -Encoding utf8
    Write-Host "Baseline snapshot written to $ExportBaseline. Review and keep only the settings you govern." -ForegroundColor Cyan
    Disconnect-PowerBIServiceAccount | Out-Null; return
}

if (-not $Baseline) {
    Write-Host "Provide -Baseline <file.json> to compare, or -ExportBaseline <file.json> to snapshot." -ForegroundColor Yellow
    Disconnect-PowerBIServiceAccount | Out-Null; return
}
if (-not (Test-Path $Baseline)) { Write-Host "Baseline file not found: $Baseline" -ForegroundColor Red; Disconnect-PowerBIServiceAccount | Out-Null; return }

$desired = Get-Content $Baseline -Raw | ConvertFrom-Json
$drift = @()
foreach ($d in $desired) {
    $l = $live | Where-Object { $_.settingName -eq $d.settingName }
    if (-not $l) { $drift += [pscustomobject]@{ Setting=$d.settingName; Live='(not present)'; Baseline="enabled=$($d.enabled)"; Scope='n/a' }; continue }
    $liveGroups = ($l.enabledSecurityGroups | ForEach-Object { $_.name }) -join ';'
    if ($l.enabled -ne $d.enabled -or $liveGroups -ne $d.enabledSecurityGroups) {
        $drift += [pscustomobject]@{
            Setting  = $d.settingName
            Live     = "enabled=$($l.enabled); groups=[$liveGroups]"
            Baseline = "enabled=$($d.enabled); groups=[$($d.enabledSecurityGroups)]"
            Scope    = if ($l.canSpecifySecurityGroups) { 'group-scopable' } else { 'org-wide only' }
        }
    }
}

Write-Host "`n=== Drift vs 'Tenant Governance Baseline - Fabric/Power BI - v1' ===" -ForegroundColor Cyan
if ($drift) { $drift | Format-Table -AutoSize } else { Write-Host "No drift — live tenant settings match the baseline." -ForegroundColor Green }

if ($Apply) {
    Write-Host "`n-Apply requested. This path is preview-only and does not write tenant settings." -ForegroundColor Yellow
    Write-Host "Tenant-setting changes must be made in the admin portal, piloted on the ring, and change-approved." -ForegroundColor Yellow
    if ($Confirm) { Write-Host "(-Confirm noted, but write-back is intentionally not implemented — see NOTES.)" -ForegroundColor Yellow }
    Write-Host "Would reconcile the $($drift.Count) drifted setting(s) above." -ForegroundColor Gray
}

Disconnect-PowerBIServiceAccount | Out-Null
