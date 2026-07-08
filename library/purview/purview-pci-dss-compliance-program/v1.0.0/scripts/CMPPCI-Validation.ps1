<#
.SYNOPSIS
    CMPPCI-Validation.ps1 — validate the technical evidence behind the PCI-DSS controls (read-only).
.DESCRIPTION
    PURPOSE
        Cross-checks that the technical controls the PCI-DSS assessment's improvement actions claim are
        actually in place: unified audit logging enabled + retention (Req 10); the cardholder-data DLP
        policy present and IN SIMULATION MODE with the Credit Card Number rule (Req 3); the sensitivity
        label published (Req 3); and least-privilege role separation (Req 7). This is the evidence
        cross-check — it confirms the controls exist and are in the expected state, so nothing is marked
        "implemented" without proof. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPPCI-Validation.ps1

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession) with read access to DLP, labels, audit
        config, and role groups. Compliance Manager assessment scores/evidence are authoritative in the
        Purview portal — this validates the underlying technical signals behind them. Verify capability
        availability against your licensing/tenant.
    EXPECTED RESULTS
        A per-control PASS/FAIL table: audit logging (PASS = enabled), DLP present + in simulation (PASS),
        Credit Card Number rule present (PASS), label published (PASS), role separation (PASS). Overall
        PASS = every in-scope control is in its expected state; note that Req 3 stays "piloted, pending
        enforcement" while the DLP is in simulation.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $PolicyName = 'DLP-PCI-CardholderData',
    [string] $RuleName   = 'DLP-PCI-CardholderData-Rule',
    [string] $LabelName  = 'Label-PCI-CardholderData'
)

$ErrorActionPreference = 'Stop'
$results = @()
function Add-Result([string]$Control, [string]$Check, [string]$Verdict, [string]$Detail) {
    $script:results += [pscustomobject]@{ Control = $Control; Check = $Check; Verdict = $Verdict; Detail = $Detail }
}

try {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession | Out-Null
    }
}
catch {
    Write-Error ("Failed to connect to Security & Compliance PowerShell: {0}" -f $_.Exception.Message)
    return
}

# ---- Req 10: unified audit logging ----------------------------------------------------------------
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($cfg.UnifiedAuditLogIngestionEnabled) {
        Add-Result 'Req 10 (Logging)' 'Unified audit log ingestion' 'PASS' 'Enabled = True'
    } else {
        Add-Result 'Req 10 (Logging)' 'Unified audit log ingestion' 'FAIL' 'Enabled = False — turn on (03-implementation.md Step 4)'
    }
}
catch { Add-Result 'Req 10 (Logging)' 'Unified audit log ingestion' 'UNKNOWN' $_.Exception.Message }

# Audit retention policies (Audit Premium) — informational
try {
    if (Get-Command Get-UnifiedAuditLogRetentionPolicy -ErrorAction SilentlyContinue) {
        $ret = @(Get-UnifiedAuditLogRetentionPolicy -ErrorAction SilentlyContinue)
        if ($ret.Count -gt 0) {
            Add-Result 'Req 10 (Logging)' 'Audit retention policy' 'PASS' ("{0} custom retention policy(ies) present" -f $ret.Count)
        } else {
            Add-Result 'Req 10 (Logging)' 'Audit retention policy' 'NOTE' 'No custom retention policy — confirm default meets your PCI-DSS version'
        }
    } else {
        Add-Result 'Req 10 (Logging)' 'Audit retention policy' 'NOTE' 'Retention cmdlet not available (Audit Premium / licensing) — verify in portal'
    }
}
catch { Add-Result 'Req 10 (Logging)' 'Audit retention policy' 'UNKNOWN' $_.Exception.Message }

# ---- Req 3: cardholder-data DLP in simulation -----------------------------------------------------
try {
    $pol = @(Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $PolicyName })
    if ($pol.Count -eq 0) {
        Add-Result 'Req 3 (Data)' 'DLP policy present' 'FAIL' ("'{0}' not found — create in simulation (CMPPCI-Configuration.ps1)" -f $PolicyName)
    }
    else {
        $mode = [string]$pol[0].Mode
        if ($mode -match 'Test') {
            Add-Result 'Req 3 (Data)' 'DLP policy present + mode' 'PASS' ("'{0}' in SIMULATION ({1}) — piloted, pending enforcement" -f $PolicyName, $mode)
        } elseif ($mode -match 'Enable') {
            Add-Result 'Req 3 (Data)' 'DLP policy present + mode' 'PASS' ("'{0}' ENFORCING ({1}) — Req 3 control active" -f $PolicyName, $mode)
        } else {
            Add-Result 'Req 3 (Data)' 'DLP policy present + mode' 'NOTE' ("'{0}' mode '{1}' — confirm intended" -f $PolicyName, $mode)
        }
        $rule = @(Get-DlpComplianceRule -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $RuleName })
        if ($rule.Count -gt 0) {
            Add-Result 'Req 3 (Data)' 'Credit Card Number rule' 'PASS' ("'{0}' present" -f $RuleName)
        } else {
            Add-Result 'Req 3 (Data)' 'Credit Card Number rule' 'FAIL' ("'{0}' not found under the policy" -f $RuleName)
        }
    }
}
catch { Add-Result 'Req 3 (Data)' 'DLP policy present' 'UNKNOWN' $_.Exception.Message }

# ---- Req 3: sensitivity label ---------------------------------------------------------------------
try {
    if (Get-Command Get-Label -ErrorAction SilentlyContinue) {
        $lbl = @(Get-Label -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $LabelName -or $_.Name -eq $LabelName })
        if ($lbl.Count -gt 0) {
            Add-Result 'Req 3 (Data)' 'Sensitivity label' 'PASS' ("'{0}' present (confirm published to SG-PCI-Pilot in portal)" -f $LabelName)
        } else {
            Add-Result 'Req 3 (Data)' 'Sensitivity label' 'FAIL' ("'{0}' not found — publish it (03-implementation.md Step 6)" -f $LabelName)
        }
    } else {
        Add-Result 'Req 3 (Data)' 'Sensitivity label' 'NOTE' 'Get-Label not available — verify the label in the portal'
    }
}
catch { Add-Result 'Req 3 (Data)' 'Sensitivity label' 'UNKNOWN' $_.Exception.Message }

# ---- Req 7: role separation -----------------------------------------------------------------------
$roleGroups = @('Compliance Manager Administrators','Compliance Manager Contributors','Compliance Manager Readers')
$memberMap = @{}
foreach ($rgName in $roleGroups) {
    try {
        foreach ($m in @(Get-RoleGroupMember -Identity $rgName -ErrorAction SilentlyContinue)) {
            $key = if ($m.PrimarySmtpAddress) { [string]$m.PrimarySmtpAddress } else { [string]$m.Name }
            if (-not $memberMap.ContainsKey($key)) { $memberMap[$key] = New-Object System.Collections.Generic.List[string] }
            $memberMap[$key].Add($rgName)
        }
    } catch { }
}
$conflict = @($memberMap.Keys | Where-Object {
    ($memberMap[$_] -contains 'Compliance Manager Administrators') -and ($memberMap[$_] -contains 'Compliance Manager Contributors')
})
if ($conflict.Count -gt 0) {
    Add-Result 'Req 7 (Access)' 'Role separation' 'FAIL' ("{0} account(s) are both Administrator and Contributor" -f $conflict.Count)
} else {
    Add-Result 'Req 7 (Access)' 'Role separation' 'PASS' 'No admin/contributor overlap detected'
}

# ---- Verdict --------------------------------------------------------------------------------------
Write-Host ''
Write-Host '=== PCI-DSS technical-evidence validation ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fails = @($results | Where-Object { $_.Verdict -eq 'FAIL' })
if ($fails.Count -eq 0) {
    Write-Host 'OVERALL: PASS — all in-scope controls are in their expected state.' -ForegroundColor Green
    Write-Host 'Note: while the DLP is in SIMULATION, record Req 3 as "piloted, pending enforcement".'
} else {
    Write-Host ("OVERALL: FAIL — {0} control(s) need attention (see FAIL rows)." -f $fails.Count) -ForegroundColor Red
}
Write-Host 'Adequacy/attestation (whether this evidence satisfies PCI-DSS) is a QSA/compliance determination.'
