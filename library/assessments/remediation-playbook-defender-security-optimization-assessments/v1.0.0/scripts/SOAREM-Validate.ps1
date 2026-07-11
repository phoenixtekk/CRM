<#
.SYNOPSIS
    SOAREM-Validate.ps1 — read-only post-change verification that a remediated control is now correct
    on the pilot scope.
.DESCRIPTION
    PURPOSE
        After SOAREM-Remediate.ps1 applies a change to the pilot scope, this script confirms the
        SPECIFIC control the finding was about is now in the expected state (e.g. the OAuth policy
        exists, the workload plan is on, the session policy is present in monitor). READ-ONLY — it
        checks state and reports Pass/Gap; it changes nothing.
    HOW TO RUN
        Connect-MgGraph -Scopes "SecurityEvents.Read.All","Directory.Read.All"   # read-only
        powershell -ExecutionPolicy Bypass -File .\SOAREM-Validate.ps1 `
            -RemediationPlanPath ".\Remediation Plan - Defender SOA - Assess.json" `
            -FindingId "<finding id>" -PilotScope "Pilot Group - Defender SOA" `
            -OutputPath ".\SOAREM-validation.json"
    EXPECTED RESULTS
        A Pass/Gap verdict for the specific remediated control on the pilot scope, with evidence.
.NOTES
    White-label. Read-only. Verification confirms the control is in place; the re-score
    (SOAREM-Rescore.ps1) proves the finding closed. The state checks are provided as guarded stubs to
    be completed for the specific finding; verify current cmdlets.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RemediationPlanPath,
    [Parameter(Mandatory)][string]$FindingId,
    [string]$PilotScope,
    [string]$OutputPath = ".\SOAREM-validation.json"
)

$ErrorActionPreference = 'Stop'
$plan = Get-Content $RemediationPlanPath -Raw | ConvertFrom-Json
$item = $plan.plan | Where-Object { $_.findingId -eq $FindingId } | Select-Object -First 1
if (-not $item) { throw "Finding id '$FindingId' not found in the remediation plan." }

Write-Host "SOAREM-Validate — verifying control for finding $FindingId (read-only)..." -ForegroundColor Cyan

# Per-domain state check. Stubs describe the read to confirm the control on $PilotScope. An operator
# completes the specific read for their finding. Default verdict is 'Gap - unverified' until a real
# check confirms Pass, so the loop never falsely claims closure.
$result = 'Gap'
$evidence = "Unverified — complete the guarded state check for domain '$($item.domain)' on scope '$PilotScope'."
switch ($item.domain) {
    'appGovernanceOAuth'   { $evidence = "STUB: confirm the OAuth-app policy exists (Cloud apps -> App governance). Scope: $PilotScope." }
    'sessionAccessPolicies'{ $evidence = "STUB: confirm the session/access policy exists and is in MONITOR. Scope: $PilotScope." }
    'planCoverage'         { $evidence = "STUB: confirm Get-AzSecurityPricing shows the plan = Standard on the pilot subscription." }
    'agentCoverage'        { $evidence = "STUB: confirm agentless scanning enabled / agent onboarded on $PilotScope." }
    'unifiedRbac'          { $evidence = "STUB: confirm the least-privilege role assignment on $PilotScope and break-glass excluded." }
    'regulatoryCompliance' { $evidence = "STUB: confirm the required standard is mapped in the compliance dashboard." }
    default                { $evidence = "STUB: confirm '$($item.remediation)' is in place on $PilotScope." }
}

$out = [ordered]@{
    solution     = "SOAREM"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    findingId    = $FindingId
    domain       = $item.domain
    control      = $item.control
    pilotScope   = $PilotScope
    result       = $result
    evidence     = $evidence
    note         = "Read-only verification. Default is 'Gap - unverified' until the guarded state check confirms Pass — prevents falsely claiming closure. Re-score with SOAREM-Rescore.ps1 to prove closure."
}
$out | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Verification: {0} — {1}" -f $result, $evidence) -ForegroundColor Yellow
Write-Host "Written: $OutputPath (read-only)." -ForegroundColor Green
