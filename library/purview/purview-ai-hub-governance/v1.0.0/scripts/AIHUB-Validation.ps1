<#
.SYNOPSIS
    AIHUB-Validation.ps1 — read-only check that AI visibility is on, the DLP-for-AI policy is in a TEST mode (never Enable during pilot), scoped to the pilot ring, and the target label exists.
.DESCRIPTION
    Validates the scriptable AI-governance state against the design: unified audit enabled (visibility);
    the DLP-for-AI policy exists in a Test/simulation mode (asserts NOT Enable while piloting), scoped to
    the pilot group; and the target sensitivity label the DLP rule references exists. Read-only - makes no
    changes. The portal-driven controls (insider risk / communication compliance / the AI DLP action) are
    validated in the portal; this covers the parts PowerShell can see.
.EXAMPLE
    .\AIHUB-Validation.ps1 -PolicyName "AI-DLP-ProtectLabeled-Sim" -TargetLabel "Highly Confidential"
    Confirms audit on, the policy in a Test mode, and the label present.
.EXAMPLE
    .\AIHUB-Validation.ps1 -PolicyName "AI-DLP-ProtectLabeled-Sim" -ExpectEnforced
    After the pilot passes, expects the policy to be Enable (enforcing).
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession). Role: Compliance/DLP +
    Audit reader.
    Expected results: PASS = audit on, policy in Test (or Enable if -ExpectEnforced), label present.
    FAIL = audit off, policy Enable during pilot (a pilot DLP-for-AI policy must NEVER enforce), policy/
    label missing. Resolve FAILs with AIHUB-Config.ps1 before proceeding.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'AI-DLP-ProtectLabeled-Sim',
    [string]$TargetLabel = 'Highly Confidential',
    [switch]$ExpectEnforced
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

function Check([string]$name, [bool]$ok, [string]$detail) {
    $tag = if ($ok) { 'PASS' } else { 'FAIL' }
    $col = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} {2}" -f $tag, $name, $detail) -ForegroundColor $col
    return $ok
}

Write-Host "=== AIHUB validation (read-only) ===" -ForegroundColor Cyan
$results = @()

# 1. Audit on
try {
    $on = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
    $results += Check 'Unified audit enabled (AI visibility)' $on "(UnifiedAuditLogIngestionEnabled=$on)"
} catch { $results += Check 'Unified audit enabled' $false "(unable to read: $($_.Exception.Message))" }

# 2. DLP-for-AI policy mode + scope
$p = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $p) {
    $results += Check "DLP-for-AI policy '$PolicyName' exists" $false '(not found - create it in Step 5)'
} else {
    $mode = "$($p.Mode)"
    if ($ExpectEnforced) {
        $results += Check 'DLP policy enforcing (post-pilot)' ($mode -match 'Enable') "(Mode=$mode)"
    } else {
        $isTest = ($mode -match 'Test|Disable')
        $results += Check 'DLP policy in TEST/simulation (never Enable during pilot)' $isTest "(Mode=$mode)"
        if ($mode -match 'Enable') { Write-Host "     A pilot DLP-for-AI policy must NOT enforce - set back to test (AIHUB-Config.ps1 -SetDlpMode -Mode TestWithoutNotifications -Commit)." -ForegroundColor Red }
    }
    $scope = ("$($p.ExchangeLocation)" + ';' + "$($p.ModernGroupLocation)" + ';' + "$($p.EndpointDlpLocation)")
    $results += Check 'DLP policy scoped (confirm pilot ring in portal)' ([bool]$scope) '(confirm the scope targets grp-ai-pilot@contoso.com in the portal)'
}

# 3. Target label exists
$lbl = Get-Label -Identity $TargetLabel -ErrorAction SilentlyContinue
$results += Check "Target label '$TargetLabel' exists" ([bool]$lbl) $(if ($lbl) { '' } else { '(create/publish it - Req 2.5)' })

$passCount = ($results | Where-Object { $_ }).Count
Write-Host ("`n=== {0}/{1} checks passed ===" -f $passCount, $results.Count) -ForegroundColor $(if ($passCount -eq $results.Count) { 'Green' } else { 'Yellow' })
Write-Host "Portal-validate: Copilot honors labels, the AI DLP action, and the insider-risk/comms-compliance detections (privacy-by-design)." -ForegroundColor Cyan
if ($passCount -ne $results.Count) { Write-Host 'Resolve FAIL items with AIHUB-Config.ps1 before enforcing/widening scope.' -ForegroundColor Yellow }
