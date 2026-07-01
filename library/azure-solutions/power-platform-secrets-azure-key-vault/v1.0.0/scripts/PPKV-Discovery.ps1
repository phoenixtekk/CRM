<#
.SYNOPSIS
    PPKV-Discovery.ps1 — inventory Key Vaults, secrets, and RBAC assignments, and scan exported
    Power Platform definitions for hardcoded-secret patterns.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Standardize Power Platform Secrets in Azure Key Vault" solution.
        Lists Key Vaults in the subscription (or one named vault), their permission model, their
        secrets (metadata only), and the RBAC role assignments on each vault. If -ExportPath is
        supplied, performs a best-effort scan of exported flow / app / custom-connector JSON files
        for patterns that look like hardcoded secrets. Makes no changes and prints NO secret values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PPKV-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\PPKV-Discovery.ps1 -VaultName 'pp-secrets-prod-kv'
        powershell -ExecutionPolicy Bypass -File .\PPKV-Discovery.ps1 -ExportPath 'C:\exports\pilot'
        Requires the Az PowerShell modules (Az.Accounts, Az.KeyVault, Az.Resources). Run
        Connect-AzAccount first, or the script will prompt.
    EXPECTED RESULTS
        A per-vault snapshot: permission model, secret names with enabled/expiry metadata, and RBAC
        role assignments. If -ExportPath is used, a list of files + line hints where a hardcoded
        secret pattern was detected (for manual review) — a single readiness picture before you
        vault and remediate.
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
    Operates on metadata/identifiers only — never reads or prints secret values. The export scan is
    heuristic (best-effort) and flags candidates for human review; it is not a guarantee.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$VaultName,
    [string]$ExportPath
)

foreach ($m in 'Az.Accounts','Az.KeyVault','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Install-Module Az -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.KeyVault -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

Write-Host "`n=== Power Platform secrets — Key Vault discovery ===" -ForegroundColor Cyan

# --- Vaults ---
$vaults = if ($VaultName) { Get-AzKeyVault -VaultName $VaultName } else { Get-AzKeyVault }
if (-not $vaults) { Write-Host "  No Key Vaults found in scope." -ForegroundColor Yellow }

foreach ($v in $vaults) {
    $full = Get-AzKeyVault -VaultName $v.VaultName
    $model = if ($full.EnableRbacAuthorization) { 'Azure RBAC' } else { 'Access policy (legacy)' }
    Write-Host ("`n-- Vault: {0} --" -f $full.VaultName) -ForegroundColor Cyan
    Write-Host ("   Permission model : {0}" -f $model) -ForegroundColor ($(if ($full.EnableRbacAuthorization) { 'Green' } else { 'Yellow' }))
    Write-Host ("   Resource group   : {0}" -f $full.ResourceGroupName)

    # Secrets — metadata only (names, enabled, expiry). Never retrieves values.
    Write-Host "   Secrets:" -ForegroundColor Cyan
    try {
        $secrets = Get-AzKeyVaultSecret -VaultName $full.VaultName   # metadata list; no values
        if ($secrets) {
            foreach ($s in $secrets) {
                $exp = if ($s.Expires) { $s.Expires.ToString('yyyy-MM-dd') } else { '(none)' }
                Write-Host ("     {0,-32} enabled:{1}  expires:{2}" -f $s.Name, $s.Enabled, $exp)
            }
        } else { Write-Host "     (none)" }
    } catch { Write-Host ("     Could not list secrets: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    # RBAC assignments scoped to the vault
    Write-Host "   RBAC role assignments:" -ForegroundColor Cyan
    try {
        $ra = Get-AzRoleAssignment -Scope $full.ResourceId
        if ($ra) {
            foreach ($r in $ra) {
                Write-Host ("     {0,-30} {1}  ({2})" -f $r.RoleDefinitionName, $r.DisplayName, $r.ObjectType)
            }
        } else { Write-Host "     (none)" }
    } catch { Write-Host ("     Could not read role assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

# --- Optional: scan exported Power Platform definitions for hardcoded-secret patterns ---
if ($ExportPath) {
    Write-Host "`n-- Hardcoded-secret scan of exports: $ExportPath --" -ForegroundColor Cyan
    if (-not (Test-Path $ExportPath)) {
        Write-Host "   Path not found." -ForegroundColor Yellow
    } else {
        # Heuristic patterns. Best-effort — flags candidates for human review, prints only the match location.
        $patterns = @(
            @{ Name = 'Connection string'; Regex = '(?i)(Password|Pwd|AccountKey|SharedAccessKey)\s*=\s*[^;"''\s]{6,}' },
            @{ Name = 'Bearer/JWT token';  Regex = 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' },
            @{ Name = 'Client secret-ish'; Regex = '(?i)"?(client_secret|clientSecret|apiKey|api_key|secret|password)"?\s*[:=]\s*"[^"]{8,}"' },
            @{ Name = 'AKV data-plane URL (review)'; Regex = 'https://[a-z0-9-]+\.vault\.azure\.net/secrets/[^"''\s]+' }
        )
        $files = Get-ChildItem -Path $ExportPath -Recurse -Include *.json,*.msapp,*.zip -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Extension -eq '.json' }   # scan JSON definitions; archives should be expanded first
        if (-not $files) { Write-Host "   No .json definition files found (expand .zip/.msapp exports first)." -ForegroundColor Yellow }
        $hits = 0
        foreach ($f in $files) {
            $ln = 0
            foreach ($line in (Get-Content -Path $f.FullName -ErrorAction SilentlyContinue)) {
                $ln++
                foreach ($p in $patterns) {
                    if ($line -match $p.Regex) {
                        $hits++
                        # Print location + which pattern only — NOT the matched value.
                        Write-Host ("   [{0}] {1}:{2}" -f $p.Name, $f.FullName, $ln) -ForegroundColor Red
                    }
                }
            }
        }
        if ($hits -eq 0) { Write-Host "   No hardcoded-secret patterns detected (best-effort)." -ForegroundColor Green }
        else { Write-Host ("   {0} candidate(s) flagged — review each manually." -f $hits) -ForegroundColor Yellow }
    }
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
