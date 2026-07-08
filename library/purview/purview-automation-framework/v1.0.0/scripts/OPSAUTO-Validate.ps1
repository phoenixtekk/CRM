<#
.SYNOPSIS
    OPSAUTO-Validate.ps1 — Compare deployed Purview state to the desired-state config; report drift (read-only).
.DESCRIPTION
    PURPOSE
        Reconciles the desired-state config (Automation Config - Purview Ops - Baseline) against what is
        actually deployed and reports DRIFT: MISSING (in config, not in tenant), MODE-MISMATCH (present but
        wrong mode/enable state), and EXTRA (a managed-name object in the tenant not tracked... plus flags
        config-named objects that changed). Produces Automation Validate - Desired State - Drift. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSAUTO-Validate.ps1 -ConfigPath .\baseline.json -Scope Pilot
        Optionally -SnapshotPath .\snapshot.json to validate against a captured snapshot instead of live.
        Requires ExchangeOnlineManagement (Connect-IPPSSession) for live mode. No secrets.
    EXPECTED RESULTS
        A per-policy PASS/DRIFT line and an overall result. Exit-friendly: writes a JSON drift report and
        returns non-zero drift count in $LASTEXITCODE-style summary. VERIFY the expected DLP mode value for
        your tenant (the config's 'expectMode').
.NOTES
    Purview category — Automation Framework. Read-only. DLP mode values evolve/are licensing-dependent;
    confirm expected values against your tenant and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [ValidateSet('Pilot','Full')][string]$Scope = 'Pilot',
    [string]$SnapshotPath,   # optional: validate against a Discovery snapshot instead of connecting live
    [string]$UserPrincipalName,
    [string]$OutFile = ".\Automation-Validate-Desired-State-Drift.json"
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Pass($m){ Write-Host "  [PASS] $m" -ForegroundColor Green }
function Drift($m){ Write-Host "  [DRIFT] $m" -ForegroundColor Yellow }

$cfg = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$targets = @($cfg.policies | Where-Object { $_.scope -eq $Scope -or $Scope -eq 'Full' })

# --- Load current state: from snapshot or live ---
$live = @{ dlp=@{}; label=@{}; labelPolicy=@{}; retention=@{} }
if ($SnapshotPath) {
    $snap = Get-Content -Raw -Path $SnapshotPath | ConvertFrom-Json
    foreach ($d in $snap.dlpPolicies)       { $live.dlp[$d.name]       = $d }
    foreach ($l in $snap.sensitivityLabels) { $live.label[$l.name]     = $l }
    foreach ($p in $snap.labelPolicies)     { $live.labelPolicy[$p.name]= $p }
    foreach ($r in $snap.retentionPolicies) { $live.retention[$r.name] = $r }
    Write-Section "Validating against snapshot: $SnapshotPath"
} else {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { throw "ExchangeOnlineManagement not installed." }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
    Connect-IPPSSession @cp -ErrorAction Stop | Out-Null
    try { Get-DlpCompliancePolicy -ErrorAction Stop | ForEach-Object { $live.dlp[$_.Name] = $_ } } catch {}
    try { Get-Label -ErrorAction Stop | ForEach-Object { $live.label[$_.Name] = $_ } } catch {}
    try { Get-LabelPolicy -ErrorAction Stop | ForEach-Object { $live.labelPolicy[$_.Name] = $_ } } catch {}
    try { Get-RetentionCompliancePolicy -ErrorAction Stop | ForEach-Object { $live.retention[$_.Name] = $_ } } catch {}
    Write-Section "Validating against LIVE tenant"
}

$report = @(); $driftCount = 0

foreach ($p in $targets) {
    $bucket = switch ($p.type) { 'dlp'{'dlp'} 'label'{'label'} 'labelPolicy'{'labelPolicy'} 'retention'{'retention'} default {$null} }
    if (-not $bucket) { continue }
    $found = $live[$bucket][$p.name]
    if (-not $found) {
        Drift "$($p.type) '$($p.name)' MISSING (in config, not deployed)."
        $report += [ordered]@{ type=$p.type; name=$p.name; status='MISSING' }; $driftCount++
        continue
    }
    # mode / enable-state check where the config declares an expectation
    switch ($p.type) {
        'dlp' {
            $expect = if ($p.expectMode) { $p.expectMode } else { $null }
            if ($expect -and "$($found.mode)$($found.Mode)" -notmatch [regex]::Escape($expect)) {
                Drift "dlp '$($p.name)' MODE-MISMATCH (expected '$expect', found '$($found.mode)$($found.Mode)')."
                $report += [ordered]@{ type='dlp'; name=$p.name; status='MODE-MISMATCH'; expected=$expect; actual="$($found.mode)$($found.Mode)" }; $driftCount++
            } else { Pass "dlp '$($p.name)' present$([string]::IsNullOrEmpty($expect) ? '' : " (mode ok)")." }
        }
        'retention' {
            if ($p.PSObject.Properties.Name -contains 'expectEnabled') {
                $act = [bool]($found.enabled -or $found.Enabled)
                if ($act -ne [bool]$p.expectEnabled) {
                    Drift "retention '$($p.name)' ENABLE-MISMATCH (expected Enabled=$($p.expectEnabled), found $act)."
                    $report += [ordered]@{ type='retention'; name=$p.name; status='ENABLE-MISMATCH'; expected=$p.expectEnabled; actual=$act }; $driftCount++
                } else { Pass "retention '$($p.name)' present (Enabled=$act)." }
            } else { Pass "retention '$($p.name)' present." }
        }
        default { Pass "$($p.type) '$($p.name)' present." }
    }
}

# --- EXTRA: config-managed names present in tenant but not in this scope's config are informational ---
$configNames = @($cfg.policies | ForEach-Object { $_.name })
foreach ($bucket in 'dlp','label','labelPolicy','retention') {
    foreach ($name in $live[$bucket].Keys) {
        if ($configNames -notcontains $name -and $name -like 'Automation *') {
            Drift "$bucket '$name' EXTRA (managed-style name in tenant but not in config) — investigate with owner."
            $report += [ordered]@{ type=$bucket; name=$name; status='EXTRA' }; $driftCount++
        }
    }
}

@{ generatedUtc=(Get-Date).ToUniversalTime().ToString('o'); scope=$Scope; driftCount=$driftCount; items=$report } |
    ConvertTo-Json -Depth 6 | Out-File -FilePath $OutFile -Encoding UTF8

Write-Section "Result"
if ($driftCount -eq 0) { Pass "No drift for scope '$Scope'. Desired state matches deployed state." }
else { Drift "$driftCount drift item(s) for scope '$Scope'. See $OutFile. Reconcile via OPSAUTO-Deploy.ps1 or update the config." }
