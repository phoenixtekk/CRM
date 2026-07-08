<#
.SYNOPSIS
    OPSCOE-ScopeCheck.ps1 — confirm sign-in, compliance licensing, and which Purview capabilities are in the CoE's remit (read-only).
.DESCRIPTION
    PURPOSE
        Read-only pre-flight for a Microsoft Purview Center of Excellence. Confirms your Security &
        Compliance PowerShell (and optional Graph) sign-in, reports which compliance SKUs are present,
        and lists which governed capabilities (sensitivity/retention labels, DLP, auto-labeling,
        communication compliance, audit) are visible versus unlicensed or portal-only — so the CoE's
        remit is bounded by what the tenant can actually run. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+, with the ExchangeOnlineManagement (Security & Compliance PowerShell) and,
        optionally, Microsoft.Graph modules:
          Connect-IPPSSession
          Connect-ExchangeOnline        # optional, enables audit-config visibility
          .\OPSCOE-ScopeCheck.ps1
        To also read licensing/directory via Graph, pass -UseGraph (Connect-MgGraph is invoked read-only).
    EXPECTED RESULTS
        A readiness summary: sign-in OK, compliance SKUs present, and per-capability visibility
        (in-remit / unlicensed / portal-only). Written to .\OPSCOE-ScopeCheck-Scope-Assess.csv.
        Resolves Requirements 2.1-2.4. Any FAIL must be resolved before governing that capability.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials are stored or requested in code.
    Availability caveat: Purview capabilities are licensing-/tenant-dependent and the portal evolves;
    insider risk (and parts of communication compliance) are primarily portal-managed with limited
    PowerShell — this script reports what it can see and flags the rest for attestation. Cmdlets are
    standard Security & Compliance PowerShell / Exchange Online / Graph; none are invented.
#>
[CmdletBinding()]
param(
    [switch]$UseGraph,
    [string]$OutPath = ".\OPSCOE-ScopeCheck-Scope-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== OPSCOE Scope Check — Purview CoE readiness (read-only) ===" -ForegroundColor Cyan

$findings = [System.Collections.Generic.List[object]]::new()
function Add-Finding($check, $status, $detail) {
    $findings.Add([pscustomobject]@{ Check = $check; Status = $status; Detail = $detail })
    $color = switch ($status) { "OK" { "Green" } "WARN" { "Yellow" } "INFO" { "Gray" } default { "Red" } }
    Write-Host ("  [{0,-4}] {1} — {2}" -f $status, $check, $detail) -ForegroundColor $color
}

# 1. Security & Compliance PowerShell session
try {
    $labels = Get-Label -ErrorAction Stop
    Add-Finding "S&C PowerShell session" "OK" ("Connected; {0} sensitivity label(s) visible" -f @($labels).Count)
} catch {
    Add-Finding "S&C PowerShell session" "FAIL" "Not connected. Run Connect-IPPSSession first (Req 2.3 / GR 3)."
    $labels = @()
}

# 2. Governed capability visibility — labels / label policies
try {
    $lp = Get-LabelPolicy -ErrorAction Stop
    Add-Finding "Sensitivity labels + policies" "OK" ("{0} label(s), {1} label policy(ies) — in remit" -f @($labels).Count, @($lp).Count)
} catch { Add-Finding "Sensitivity labels + policies" "WARN" "Could not read label policies: $($_.Exception.Message)" }

# 3. DLP
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    Add-Finding "DLP policies" "OK" ("{0} DLP policy(ies) — in remit" -f @($dlp).Count)
} catch { Add-Finding "DLP policies" "WARN" "Could not read DLP policies (role/licensing?): $($_.Exception.Message)" }

# 4. Retention / records
try {
    $ret = Get-RetentionCompliancePolicy -ErrorAction Stop
    Add-Finding "Retention policies/labels" "OK" ("{0} retention policy(ies) — in remit" -f @($ret).Count)
} catch { Add-Finding "Retention policies/labels" "WARN" "Could not read retention policies: $($_.Exception.Message)" }

# 5. Auto-labeling (licensing-dependent)
try {
    $auto = Get-AutoSensitivityLabelPolicy -ErrorAction Stop
    Add-Finding "Auto-labeling" "OK" ("{0} auto-labeling policy(ies) — in remit (E5/E5 Compliance)" -f @($auto).Count)
} catch { Add-Finding "Auto-labeling" "WARN" "Not readable — may be unlicensed (E5 required): $($_.Exception.Message)" }

# 6. Communication compliance (portal-managed; cmdlet may be absent)
$scv2 = Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue
if ($scv2) {
    try {
        $cc = Get-SupervisoryReviewPolicyV2 -ErrorAction Stop
        Add-Finding "Communication compliance" "OK" ("{0} policy(ies) readable — in remit; case actions deferred to HR/legal" -f @($cc).Count)
    } catch { Add-Finding "Communication compliance" "WARN" "Cmdlet present but read failed (role?): $($_.Exception.Message)" }
} else {
    Add-Finding "Communication compliance" "INFO" "No PowerShell surface in this session — govern by attestation (portal-managed)."
}

# 7. Insider risk — portal-managed, limited/evolving PowerShell -> attestation
Add-Finding "Insider risk" "INFO" "Primarily portal-managed (limited/evolving PowerShell) — govern by attestation with a named owner."

# 8. Unified auditing (evidence backbone)
try {
    $cfgCmd = Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue
    if ($cfgCmd) {
        $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
        $on = $cfg.UnifiedAuditLogIngestionEnabled
        Add-Finding "Unified auditing" ($(if ($on) { "OK" } else { "WARN" })) ("UnifiedAuditLogIngestionEnabled = {0} — evidence backbone for the CoE" -f $on)
    } else {
        Add-Finding "Unified auditing" "INFO" "Get-AdminAuditLogConfig not in session — Connect-ExchangeOnline to check, or confirm in Purview -> Audit."
    }
} catch { Add-Finding "Unified auditing" "WARN" "Could not read audit config: $($_.Exception.Message)" }

# 9. Role-group readability (board membership will be managed here)
try {
    $rg = Get-RoleGroup -ErrorAction Stop
    Add-Finding "Role groups" "OK" ("{0} role group(s) readable — board membership manageable here (Req 2.5)" -f @($rg).Count)
} catch { Add-Finding "Role groups" "WARN" "Could not read role groups (need Connect-ExchangeOnline/Compliance Admin): $($_.Exception.Message)" }

# 10. Optional Graph — licensing SKUs
if ($UseGraph) {
    try {
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Scopes "Organization.Read.All","Directory.Read.All","User.Read.All","RoleManagement.Read.Directory" -NoWelcome -ErrorAction Stop
        }
        $ctx = Get-MgContext
        Add-Finding "Graph session" "OK" ("Connected as {0}" -f $ctx.Account)
        try {
            $skus = Get-MgSubscribedSku -ErrorAction Stop
            $names = ($skus | Select-Object -ExpandProperty SkuPartNumber) -join ", "
            $hasE5 = @($skus | Where-Object { $_.SkuPartNumber -match "E5|INFORMATION_PROTECTION_COMPLIANCE|Compliance" }).Count -gt 0
            Add-Finding "Compliance licensing (Graph)" ($(if ($hasE5) { "OK" } else { "INFO" })) ("SKUs: {0}" -f $names)
        } catch { Add-Finding "Compliance licensing (Graph)" "WARN" "Could not read subscribedSkus: $($_.Exception.Message)" }
    } catch { Add-Finding "Graph session" "WARN" "Graph connect failed: $($_.Exception.Message)" }
}

$findings | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nReadiness written to {0}  (Purview CoE Scope - Assess)" -f $OutPath) -ForegroundColor Green
Write-Host "Next: run OPSCOE-Discovery.ps1 to inventory the governed estate." -ForegroundColor Cyan
if ($findings | Where-Object Status -eq "FAIL") { Write-Host "`nOne or more FAIL checks — resolve before governing that capability." -ForegroundColor Red }
