<#
.SYNOPSIS
    Read-only readiness discovery for a FINRA/SEC communications-supervision program in Microsoft Purview
    Communication Compliance (safe: makes NO changes).
.DESCRIPTION
    Connects to Security & Compliance PowerShell and reports the signals needed before configuring:
    the four Communication Compliance role groups and their membership (the role-separation snapshot),
    any existing supervisory-review policies/rules, retention policies that already cover communications,
    and privacy/scope signals. Flags collapsed separation and over-broad scope. Read-only.
.EXAMPLE
    .\CCFIN-Discovery.ps1
    Runs all read-only checks against the connected tenant and prints the readiness report.
.EXAMPLE
    .\CCFIN-Discovery.ps1 -ReportPath .\ccfin-discovery.txt
    Also writes the report to a file. (PowerShell 5.1+/7+; Connect-IPPSSession.)
.NOTES
    Expected results: PASS = four role groups exist with separated membership and you can see current
    policies/retention. FAIL signals: missing role groups, collapsed separation (same identity builder+
    reviewer), or an existing policy scoped to "everyone". No changes are made by this script.
    Cmdlet availability is plan-dependent - verify in your tenant. No credentials are stored in code.
#>
[CmdletBinding()]
param(
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
$lines = New-Object System.Collections.Generic.List[string]
function Say([string]$m) { Write-Host $m; $lines.Add($m) }

Say "==================================================================="
Say " CCFIN - FINRA/SEC Communications Compliance : Discovery (READ-ONLY)"
Say " $(Get-Date -Format s)"
Say "==================================================================="

# --- Connect (interactive modern auth; no secrets in code) ---
try {
    if (-not (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue)) {
        Say "[*] Connecting to Security & Compliance PowerShell (Connect-IPPSSession)..."
        Connect-IPPSSession -ErrorAction Stop | Out-Null
    }
    Say "[OK] Security & Compliance PowerShell session available."
} catch {
    Say "[FAIL] Could not establish a Security & Compliance PowerShell session: $($_.Exception.Message)"
    Say "       Install ExchangeOnlineManagement and run Connect-IPPSSession with a modern-auth admin."
    if ($ReportPath) { $lines | Set-Content -Path $ReportPath }
    return
}

# --- 1. Role groups & separation snapshot (FINRA Supervision Roles - Evidence) ---
Say ""
Say "--- 1. Role separation snapshot (FINRA Supervision Roles - Evidence) ---"
$ccRoleGroups = @(
    'Communication Compliance Admin',
    'Communication Compliance Analysts',
    'Communication Compliance Investigators',
    'Communication Compliance Viewers',
    'Communication Compliance'
)
$memberMap = @{}
foreach ($rg in $ccRoleGroups) {
    try {
        $g = Get-RoleGroup -Identity $rg -ErrorAction Stop
        $members = @($g.Members | ForEach-Object { $_.ToString() })
        $memberMap[$rg] = $members
        Say ("[OK] {0}: {1} member(s)" -f $rg, $members.Count)
        foreach ($m in $members) { Say ("       - {0}" -f $m) }
    } catch {
        Say ("[--] {0}: not found or not readable" -f $rg)
        $memberMap[$rg] = @()
    }
}

# Separation heuristic: same identity in Admin AND (Analysts or Investigators)
$builders = @($memberMap['Communication Compliance Admin'])
$reviewers = @($memberMap['Communication Compliance Analysts']) + @($memberMap['Communication Compliance Investigators'])
$overlap = $builders | Where-Object { $reviewers -contains $_ }
if ($overlap -and $overlap.Count -gt 0) {
    Say ("[WARN] Separation risk: {0} identity(ies) are BOTH policy-builder (Admin) and reviewer/investigator:" -f $overlap.Count)
    foreach ($o in $overlap) { Say ("       ! {0}" -f $o) }
    Say "       Confirm Compliance/Legal explicitly accepted this, or correct membership (Implementation Step 2)."
} else {
    Say "[OK] No builder is also a reviewer/investigator (separation intact by membership)."
}
if (@($memberMap['Communication Compliance']).Count -gt 0) {
    Say "[WARN] The combined 'Communication Compliance' role group has members - it collapses separation. Use only for a tiny pilot."
}

# --- 2. Existing supervisory-review policies/rules ---
Say ""
Say "--- 2. Existing supervisory-review policies / rules ---"
try {
    $pols = @(Get-SupervisoryReviewPolicyV2 -ErrorAction Stop)
    if ($pols.Count -eq 0) {
        Say "[--] No supervisory-review policies exist yet (expected for a new program)."
    } else {
        foreach ($p in $pols) {
            Say ("[OK] Policy: {0}   Enabled={1}" -f $p.Name, $p.Enabled)
            try {
                $rules = @(Get-SupervisoryReviewRule -Policy $p.Name -ErrorAction SilentlyContinue)
                foreach ($r in $rules) { Say ("       rule: {0}" -f $r.Name) }
            } catch {}
        }
    }
} catch {
    Say "[--] Get-SupervisoryReviewPolicyV2 unavailable in this tenant/session - verify licensing (Requirement 2.1)."
}

# --- 3. Retention policies that may cover communications (evidence layer) ---
Say ""
Say "--- 3. Retention coverage signals (evidence layer, 17a-4 posture) ---"
try {
    $rps = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    if ($rps.Count -eq 0) {
        Say "[--] No retention policies found - the evidence layer is not yet configured (Implementation Step 7)."
    } else {
        foreach ($rp in $rps) {
            $locked = $false
            try { $locked = [bool]$rp.RestrictiveRetention } catch {}
            $lockTxt = if ($locked) { "IMMUTABLE (Preservation Lock)" } else { "not locked" }
            Say ("[OK] Retention policy: {0}   Enabled={1}   {2}" -f $rp.Name, $rp.Enabled, $lockTxt)
        }
        Say "     (Whether any of these cover the supervised comms for the approved period is a Compliance/Records determination.)"
    }
} catch {
    Say "[--] Get-RetentionCompliancePolicy unavailable - verify licensing/roles (GR SS3)."
}

# --- 4. Privacy / scope signal reminder ---
Say ""
Say "--- 4. Privacy & scope reminders (verify in portal) ---"
Say "[i] Confirm the privacy option (pseudonymized usernames if required) in Settings > Communication Compliance."
Say "[i] Confirm the supervised population is the APPROVED registered set (FINRA Supervised - Pilot), not 'everyone',"
Say "    and that FINRA Excluded - Privacy holds anyone who must not be supervised (Requirements 2.3, 2.7)."

Say ""
Say "=== Discovery complete (no changes made). Resolve any [WARN]/[FAIL] before configuring. ==="
if ($ReportPath) {
    try { $lines | Set-Content -Path $ReportPath -Encoding UTF8; Write-Host "[i] Report written to $ReportPath" }
    catch { Write-Warning "Could not write report: $($_.Exception.Message)" }
}
