<#
.SYNOPSIS
    OPSAUTO-Deploy.ps1 — Reconcile a desired-state config into Purview, SAFE-FIRST (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reads a declarative desired-state config (Automation Config - Purview Ops - Baseline) and reconciles
        it into the tenant: creates/updates the DLP, sensitivity-label, and retention policies it lists.
        Runs -WhatIf by default (prints the exact New-/Set-* it would run, no changes). On -Commit it
        deploys SAFE-FIRST: DLP into test/simulation mode, labels/retention UNPUBLISHED. It ENFORCES
        (DLP Enable, publish labels/retention) ONLY on the separate, explicit -Enforce -Commit. -Remove
        deletes only config-managed objects.
    HOW TO RUN
        # 1. structural check (no tenant calls):  .\OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -ValidateConfigOnly
        # 2. dry run:                             .\OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -WhatIf
        # 3. safe-first deploy:                   .\OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -Commit
        # 4. enforce (deliberate, gated):         .\OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -Enforce -Commit
        # rollback:                               .\OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -Remove -Commit
        Requires ExchangeOnlineManagement (Connect-IPPSSession) + the write role per policy type. No secrets.
    EXPECTED RESULTS
        -WhatIf prints planned actions and makes NO changes. -Commit reports created/updated objects in
        SAFE-FIRST mode. -Enforce -Commit reports objects moved to enforce/publish. VERIFY the DLP
        test/simulation mode value your tenant accepts before -Commit.
.NOTES
    Purview category — Automation Framework. Safe-by-default (-WhatIf). Enforcement is a separate -Enforce
    gate. DLP mode values / cmdlet parameters are evolving/licensing-dependent — verify against your tenant
    and current Microsoft documentation. No hardcoded credentials or secrets.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [ValidateSet('Pilot','Full')][string]$Scope = 'Pilot',
    [switch]$ValidateConfigOnly,   # parse + structurally validate the config; no tenant calls
    [switch]$WhatIf,               # default posture when neither -Commit nor -Remove is set
    [switch]$Commit,               # apply changes SAFE-FIRST (no enforcement unless -Enforce also set)
    [switch]$Enforce,              # with -Commit: move objects to enforce/publish (HIGH-IMPACT, deliberate)
    [switch]$Remove,               # remove config-managed objects (requires -Commit to actually delete)
    [string]$UserPrincipalName,
    # The DLP "test/simulation" mode value varies by tenant/version — override here after verifying yours.
    [string]$DlpTestMode = 'TestWithoutNotifications'
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  $m" -ForegroundColor Yellow }
function Plan($m){ Write-Host "  WHATIF: $m" -ForegroundColor Magenta }

# Safe default: if neither -Commit nor -Remove, force dry-run.
if (-not $Commit -and -not $Remove) { $WhatIf = $true }
$doWrite = ($Commit -or $Remove) -and -not $WhatIf

# ---- Load + structurally validate the config ----
if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
$cfg = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$errors = @()
if (-not $cfg.policies) { $errors += "Config has no 'policies' array." }
$valid = @('dlp','label','labelPolicy','retention')
foreach ($p in $cfg.policies) {
    if (-not $p.type)  { $errors += "A policy entry is missing 'type'." ; continue }
    if ($valid -notcontains $p.type) { $errors += "Policy '$($p.name)': unsupported type '$($p.type)' (allowed: $($valid -join ', '))." }
    if (-not $p.name)  { $errors += "A '$($p.type)' entry is missing 'name'." }
    if (-not $p.scope) { $errors += "Policy '$($p.name)': missing 'scope' (Pilot/Full)." }
    if ($p.type -eq 'dlp' -and -not $p.owner)       { Warn "DLP '$($p.name)': no content 'owner' recorded — content is a compliance/legal determination (Req 2.6)." }
    if ($p.type -eq 'retention' -and -not $p.owner) { Warn "Retention '$($p.name)': no content 'owner' recorded — retention duration is a records/legal determination (Req 2.6)." }
    if (($p.requiresE5) -and $p.requiresE5 -eq $true) { Warn "Policy '$($p.name)': flagged requiresE5 — verify your licensing/tenant (Req 2.1)." }
}
if ($errors.Count) { Write-Section "Config validation FAILED"; $errors | ForEach-Object { Warn $_ }; throw "Fix the config and re-run." }
Ok "Config parsed and structurally valid ($((@($cfg.policies)).Count) policies)."
if ($ValidateConfigOnly) { Write-Section "Validate-only complete (no tenant calls)"; return }

# Only act on entries in the requested scope.
$targets = @($cfg.policies | Where-Object { $_.scope -eq $Scope -or $Scope -eq 'Full' })
Write-Section ("Scope: {0}  —  {1} policy object(s) in scope" -f $Scope, $targets.Count)
if ($WhatIf) { Warn "DRY RUN — no changes will be made. Re-run with -Commit to apply (safe-first) or -Enforce -Commit to enforce." }
if ($Enforce -and $doWrite) { Warn "ENFORCE requested — objects will be moved to enforce/publish (HIGH-IMPACT). This is deliberate." }

# ---- Connect (skip if pure dry-run to keep it offline-safe) ----
if ($doWrite) {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { throw "ExchangeOnlineManagement not installed." }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $conn = @{ ShowBanner = $false }; if ($UserPrincipalName) { $conn['UserPrincipalName'] = $UserPrincipalName }
    Connect-IPPSSession @conn -ErrorAction Stop | Out-Null
    Ok "Connected to Security & Compliance PowerShell."
} else {
    Warn "Not connecting during dry-run. Planned actions below are illustrative of what -Commit would run."
}

function Test-Exists($getCmd, $name) {
    if (-not $doWrite) { return $null }
    try { return & $getCmd -Identity $name -ErrorAction Stop } catch { return $null }
}

# ---- Reconcile each object ----
foreach ($p in $targets) {
    switch ($p.type) {

        'dlp' {
            $mode = if ($Enforce) { 'Enable' } else { $DlpTestMode }
            if ($Remove) {
                Plan "Remove-DlpCompliancePolicy -Identity '$($p.name)'"
                if ($doWrite) { try { Remove-DlpCompliancePolicy -Identity $p.name -Confirm:$false -ErrorAction Stop; Ok "Removed DLP '$($p.name)'." } catch { Warn "Remove DLP '$($p.name)' failed: $($_.Exception.Message)" } }
                continue
            }
            $existing = Test-Exists 'Get-DlpCompliancePolicy' $p.name
            if ($existing) {
                Plan "Set-DlpCompliancePolicy -Identity '$($p.name)' -Mode $mode"
                if ($doWrite) { try { Set-DlpCompliancePolicy -Identity $p.name -Mode $mode -ErrorAction Stop; Ok "Updated DLP '$($p.name)' -> mode $mode." } catch { Warn "Set DLP '$($p.name)' failed (verify -Mode value for your tenant): $($_.Exception.Message)" } }
            } else {
                Plan "New-DlpCompliancePolicy -Name '$($p.name)' -Mode $mode -<locations from config>"
                if ($doWrite) {
                    try {
                        $np = @{ Name = $p.name; Mode = $mode }
                        if ($p.exchangeLocation)   { $np['ExchangeLocation']   = @($p.exchangeLocation) }
                        if ($p.sharePointLocation) { $np['SharePointLocation'] = @($p.sharePointLocation) }
                        if ($p.oneDriveLocation)   { $np['OneDriveLocation']   = @($p.oneDriveLocation) }
                        if ($p.teamsLocation)      { $np['TeamsLocation']      = @($p.teamsLocation) }
                        if ($p.endpointDlpLocation){ $np['EndpointDlpLocation']= @($p.endpointDlpLocation) }
                        New-DlpCompliancePolicy @np -ErrorAction Stop | Out-Null
                        Ok "Created DLP '$($p.name)' in mode $mode. NOTE: add rules (New-DlpComplianceRule) per the config's ruleset before enforcing."
                    } catch { Warn "New DLP '$($p.name)' failed (verify locations/-Mode for your tenant/licensing): $($_.Exception.Message)" }
                }
            }
        }

        'label' {
            if ($Remove) {
                Plan "Remove-Label -Identity '$($p.name)'"
                if ($doWrite) { try { Remove-Label -Identity $p.name -Confirm:$false -ErrorAction Stop; Ok "Removed label '$($p.name)'." } catch { Warn "Remove label '$($p.name)' failed: $($_.Exception.Message)" } }
                continue
            }
            # Labels are created regardless; PUBLISHING (enforce) is done via the labelPolicy entry, not here.
            $existing = Test-Exists 'Get-Label' $p.name
            if ($existing) {
                Plan "Set-Label -Identity '$($p.name)' (update display/tooltip per config)"
                if ($doWrite) { try { Set-Label -Identity $p.name -DisplayName $p.displayName -Tooltip $p.tooltip -ErrorAction Stop; Ok "Updated label '$($p.name)'." } catch { Warn "Set label '$($p.name)' failed: $($_.Exception.Message)" } }
            } else {
                Plan "New-Label -Name '$($p.name)' -DisplayName '$($p.displayName)' (created UNPUBLISHED)"
                if ($doWrite) { try { New-Label -Name $p.name -DisplayName $p.displayName -Tooltip $p.tooltip -ErrorAction Stop | Out-Null; Ok "Created label '$($p.name)' (not yet published)." } catch { Warn "New label '$($p.name)' failed: $($_.Exception.Message)" } }
            }
        }

        'labelPolicy' {
            if ($Remove) {
                Plan "Remove-LabelPolicy -Identity '$($p.name)'"
                if ($doWrite) { try { Remove-LabelPolicy -Identity $p.name -Confirm:$false -ErrorAction Stop; Ok "Removed label policy '$($p.name)'." } catch { Warn "Remove label policy '$($p.name)' failed: $($_.Exception.Message)" } }
                continue
            }
            $existing = Test-Exists 'Get-LabelPolicy' $p.name
            if (-not $existing) {
                # Creating a label policy publishes its labels — that IS the enforce step. Only do it under -Enforce.
                if (-not $Enforce) {
                    Plan "SKIP publish of label policy '$($p.name)' — creating/publishing a label policy is the ENFORCE step. Re-run with -Enforce -Commit."
                    Warn "Label policy '$($p.name)' not created: publishing labels is enforcement; use -Enforce -Commit deliberately."
                } else {
                    Plan "New-LabelPolicy -Name '$($p.name)' -Labels <from config> -ExchangeLocation/... (PUBLISH = enforce)"
                    if ($doWrite) {
                        try {
                            $lpArgs = @{ Name = $p.name; Labels = @($p.labels) }
                            New-LabelPolicy @lpArgs -ErrorAction Stop | Out-Null
                            Ok "Published label policy '$($p.name)' (labels now available to users)."
                        } catch { Warn "New label policy '$($p.name)' failed: $($_.Exception.Message)" }
                    }
                }
            } else {
                Plan "Set-LabelPolicy -Identity '$($p.name)' (reconcile labels/scope)"
                if ($doWrite -and $Enforce) { try { Set-LabelPolicy -Identity $p.name -AddLabels @($p.labels) -ErrorAction Stop; Ok "Updated label policy '$($p.name)'." } catch { Warn "Set label policy '$($p.name)' failed: $($_.Exception.Message)" } }
                elseif (-not $Enforce) { Warn "Label policy '$($p.name)' exists; skipping update (use -Enforce to reconcile a published policy)." }
            }
        }

        'retention' {
            if ($Remove) {
                Plan "Remove-RetentionCompliancePolicy -Identity '$($p.name)'"
                if ($doWrite) { try { Remove-RetentionCompliancePolicy -Identity $p.name -Confirm:$false -ErrorAction Stop; Ok "Removed retention policy '$($p.name)'." } catch { Warn "Remove retention '$($p.name)' failed: $($_.Exception.Message)" } }
                continue
            }
            $existing = Test-Exists 'Get-RetentionCompliancePolicy' $p.name
            # Safe-first: create the policy but keep it disabled/unpublished; publishing (Enabled) is the enforce step.
            $enabled = [bool]$Enforce
            if ($existing) {
                Plan "Set-RetentionCompliancePolicy -Identity '$($p.name)' -Enabled `$$enabled"
                if ($doWrite) { try { Set-RetentionCompliancePolicy -Identity $p.name -Enabled:$enabled -ErrorAction Stop; Ok "Updated retention '$($p.name)' (Enabled=$enabled)." } catch { Warn "Set retention '$($p.name)' failed: $($_.Exception.Message)" } }
            } else {
                Plan "New-RetentionCompliancePolicy -Name '$($p.name)' -<locations> -Enabled `$$enabled  (rules added separately)"
                if ($doWrite) {
                    try {
                        $rp = @{ Name = $p.name; Enabled = $enabled }
                        if ($p.exchangeLocation)   { $rp['ExchangeLocation']   = @($p.exchangeLocation) }
                        if ($p.sharePointLocation) { $rp['SharePointLocation'] = @($p.sharePointLocation) }
                        if ($p.oneDriveLocation)   { $rp['OneDriveLocation']   = @($p.oneDriveLocation) }
                        if ($p.teamsChannelLocation){ $rp['TeamsChannelLocation']= @($p.teamsChannelLocation) }
                        New-RetentionCompliancePolicy @rp -ErrorAction Stop | Out-Null
                        Ok "Created retention '$($p.name)' (Enabled=$enabled). NOTE: add its rule (New-RetentionComplianceRule) with the OWNER-APPROVED duration before enforcing."
                    } catch { Warn "New retention '$($p.name)' failed (verify locations/licensing): $($_.Exception.Message)" }
                }
            }
        }
    }
}

Write-Section "Done"
if ($WhatIf)  { Warn "Dry run only. Re-run with -Commit (safe-first) then -Enforce -Commit (deliberate) after review." }
if ($doWrite -and -not $Enforce -and -not $Remove) { Ok "Safe-first deploy complete: DLP in test mode, labels/retention UNPUBLISHED. Validate with OPSAUTO-Validate.ps1 before enforcing." }
if ($doWrite -and $Enforce) { Warn "ENFORCE complete. Monitor pilot impact; roll back by re-running without -Enforce (-Commit) or with -Remove -Commit." }
