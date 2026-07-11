<#
.SYNOPSIS
    MDEONB-PromoteASR.ps1 — promote ASR rules from audit to block for the pilot ring.
    SAFE PREVIEW by default (-WhatIf); the block policy is changed only when confirmed with -Apply.
.DESCRIPTION
    PURPOSE
        Change helper for the "Onboarding Accelerator — Microsoft Defender for Endpoint" solution.
        Takes the audited ASR configuration ('MDE ASR Rules - Pilot Ring - Audit') and switches the
        named rules to Block on the pilot ring ('MDE ASR Rules - Pilot Ring - Block'). This is the
        only script that can change configuration, and it defaults to a safe preview so you can see
        exactly which rules WOULD move to block before anything enforces.
    HOW TO RUN
        # Preview (default — shows what WOULD change, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\MDEONB-PromoteASR.ps1 -PolicyId <block-policy-id>
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\MDEONB-PromoteASR.ps1 -PolicyId <block-policy-id> -Apply
        Requires Microsoft.Graph with DeviceManagementConfiguration.ReadWrite.All.
        Only run AFTER reviewing MDEONB-Report.ps1 -Section ASR and adding needed exclusions.
    EXPECTED RESULTS
        Preview: lists the ASR rules that WOULD move audit -> block on the pilot ring.
        Apply: sets those rules to block. Validate with MDEONB-Validate.ps1 -Check ASR and watch for
        false positives before promoting to production rings.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. NEVER promote to block without an audit review first.
    Pilot ring only — expand ring-by-ring after each validates clean.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PolicyId,
    [string[]]$Rules = @('BlockCredentialStealingFromLsass','BlockOfficeChildProcess','BlockOfficeCommsChildProcess','BlockExecutableContentFromEmailAndWebmail'),
    [switch]$Apply
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' -NoWelcome | Out-Null }

$whatIf = -not $Apply
Write-Host "`n=== MDEONB promote ASR audit -> block (pilot ring) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will set rules to BLOCK' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })
Write-Host "Rules to promote:" -ForegroundColor Cyan
$Rules | ForEach-Object { Write-Host ("   {0} -> Block" -f $_) }

Write-Host "`nPRE-FLIGHT: confirm you reviewed audit events (MDEONB-Report.ps1 -Section ASR) and added exclusions." -ForegroundColor Yellow

if ($whatIf) {
    Write-Host "`nWOULD set the above rules to Block on policy '$PolicyId' (pilot ring only)." -ForegroundColor Yellow
    Write-Host "Re-run with -Apply to enforce. Then validate with MDEONB-Validate.ps1 -Check ASR." -ForegroundColor Yellow
    return
}

# Apply: patch the ASR configuration policy so each named rule is set to Block (value 1).
# ASR settings live under the endpoint-security ASR policy; adjust the setting identifiers to match
# your policy's schema. The block value for an ASR rule setting is 'block' / 1.
$settings = foreach ($r in $Rules) { @{ ruleId = $r; state = 'block' } }
$body = @{ asrRules = $settings } | ConvertTo-Json -Depth 6
try {
    Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/{0}" -f $PolicyId) -Body $body -ContentType 'application/json' | Out-Null
    Write-Host "`nAPPLIED — requested rules set to Block on the pilot ring. Watch for false positives; validate with MDEONB-Validate.ps1 -Check ASR." -ForegroundColor Green
} catch {
    Write-Host ("Apply failed via API ({0})." -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "If the policy schema differs, set the rules to Block in Intune: Endpoint security > Attack surface reduction > 'MDE ASR Rules - Pilot Ring - Block'." -ForegroundColor DarkGray
}
