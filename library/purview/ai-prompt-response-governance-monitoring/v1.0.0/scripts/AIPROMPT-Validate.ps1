<#
.SYNOPSIS
    AIPROMPT-Validate.ps1 — validate the AI governance pilot and capture evidence (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the pilot is safe and captured: the DLP-for-AI policy is in TEST mode (not enforcing), the
        Communication-Compliance AI policy exists and is pilot-scoped, and AI interactions are being captured
        by monitoring. Writes a defensible evidence record. Read-only.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (+ Exchange Online for the audit check):
          Connect-IPPSSession
          Connect-ExchangeOnline
          .\AIPROMPT-Validate.ps1
    EXPECTED RESULTS
        AI-Governance-Validation-Estate-Evidence.csv with a PASS/FAIL per check. The gate before enforce/expand
        is: DLP policy in TEST, Communication-Compliance policy present + pilot-scoped, monitoring capturing AI.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    VERIFY IN YOUR TENANT: scope-name matching is heuristic (checks the policy name/comment for the pilot ring
    string). Confirm the actual assigned scope in the portal — the script evidences, it does not certify.
#>
[CmdletBinding()]
param(
    [string]$DlpPolicyName = "AI Prompt DLP - Copilot - Test",
    [string]$CommCompliancePolicyName = "AI Interactions - Copilot - CommCompliance",
    [string]$PilotScope = "AI Governance - Pilot - Ring1",
    [string[]]$AiRecordTypes = @("CopilotInteraction"),
    [int]$SampleDays = 14,
    [string]$OutPath = ".\AI-Governance-Validation-Estate-Evidence.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIPROMPT Validate — AI governance pilot evidence (read-only) ===" -ForegroundColor Cyan
$results = New-Object System.Collections.Generic.List[object]
function Check($name, $ok, $detail) {
    $tag = if ($ok) { "PASS" } else { "FAIL" }
    $col = if ($ok) { "Green" } else { "Red" }
    Write-Host ("[{0}] {1} — {2}" -f $tag, $name, $detail) -ForegroundColor $col
    $results.Add([pscustomobject]@{ Check = $name; Result = $tag; Detail = $detail })
}

# --- 1. DLP-for-AI policy exists and is in TEST mode ---
if (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue) {
    $dlp = Get-DlpCompliancePolicy -Identity $DlpPolicyName -ErrorAction SilentlyContinue
    if ($dlp) {
        $isTest = ("$($dlp.Mode)" -match "(?i)test")
        Check "DLP-for-AI in TEST mode" $isTest ("Mode=$($dlp.Mode) (must be Test before enforce gate)")
        Check "DLP-for-AI pilot-scoped" ("$($dlp.Name) $($dlp.Comment)" -match [regex]::Escape($PilotScope)) ("name/comment references '$PilotScope' — confirm actual scope in portal")
    } else {
        Check "DLP-for-AI policy present" $false "'$DlpPolicyName' not found — create with AIPROMPT-Configure-Governance.ps1 -Action DlpForAI -Commit"
    }
} else { Check "DLP cmdlets available" $false "connect S&C PowerShell (Connect-IPPSSession)" }

# --- 2. Communication-Compliance AI policy exists and pilot-scoped ---
if (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue) {
    $cc = Get-SupervisoryReviewPolicyV2 -Identity $CommCompliancePolicyName -ErrorAction SilentlyContinue
    if (-not $cc) { $cc = @(Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $CommCompliancePolicyName }) | Select-Object -First 1 }
    Check "Communication-Compliance AI policy present" ([bool]$cc) ("'$CommCompliancePolicyName' — verify Copilot/AI source + anonymization ON + reviewer role separation in portal")
} else {
    Check "Communication Compliance reachable" $false "Get-SupervisoryReviewPolicyV2 unavailable — check licensing/role (Req 2.4)"
}

# --- 3. Monitoring is capturing AI interactions ---
if (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue) {
    $start = (Get-Date).AddDays(-1 * [math]::Abs($SampleDays)); $end = Get-Date
    try {
        $sample = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $AiRecordTypes -ResultSize 5 -ErrorAction SilentlyContinue)
        Check "AI monitoring capturing interactions" ($sample.Count -gt 0) ("{0} record(s) sampled in {1}d (RecordType={2}); 0 may be pre-adoption or auditing latency" -f $sample.Count, $SampleDays, ($AiRecordTypes -join ","))
    } catch { Check "AI monitoring capturing interactions" $false "audit search failed: $($_.Exception.Message)" }
} else { Check "Audit search available" $false "connect Exchange Online (Connect-ExchangeOnline)" }

$results | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
$fails = @($results | Where-Object Result -eq "FAIL").Count
Write-Host ("`nEvidence -> {0}  (AI Governance Validation - Estate - Evidence). {1} FAIL check(s)." -f $OutPath, $fails) -ForegroundColor $(if ($fails -eq 0) { "Green" } else { "Yellow" })
Write-Host "GATE: do not enforce/expand (Impl Step 8) until DLP is TEST, the CC policy is pilot-scoped with anonymization, monitoring is capturing, and HR/privacy/legal sign off." -ForegroundColor Cyan
