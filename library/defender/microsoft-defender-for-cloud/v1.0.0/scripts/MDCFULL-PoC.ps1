<#
.SYNOPSIS
    MDCFULL-PoC.ps1 — guided, BENIGN, reversible Defender for Cloud proof-of-concept helper. Signal is
    benign only; the teardown DISABLES the paid plan to STOP billing. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Runs the Phase D proof-of-concept for the "Microsoft Defender for Cloud" (complete) solution on a
        single pilot subscription, via one -Action switch:
          -Action Assess     : read-only readiness preview (roles, pilot subscription, plan state, candidates).
          -Action TestSignal : generate BENIGN test signal — (1) guides creation of Defender for Cloud's
                               built-in SAMPLE security alerts; (2) with -DeployTestResource deploys a
                               benign, DELIBERATELY-MISCONFIGURED test storage account (public blob access,
                               NO real data) tagged MDC-PoC-TESTSIGNAL so CSPM raises a recommendation;
                               (3) prints the EICAR test-file steps for a benign Defender-for-Servers alert.
                               NO real attack, real malware, or real data exposure is ever performed.
          -Action Scorecard  : maps observations (recommendation/Secure Score/alert/compliance) to your
                               criteria.json and writes 'MDC PoC Scorecard - Pilot Sub - Validate.json'.
          -Action Teardown   : deletes the benign test resource(s), sets the chosen Defender plan back to
                               Free to STOP BILLING, and reminds you to dismiss sample alerts. -WhatIf-gated.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-PoC.ps1 -Action Assess
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-PoC.ps1 -Action TestSignal -ResourceGroup "MDC PoC - Pilot RG - Pilot" -DeployTestResource
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-PoC.ps1 -Action Scorecard -CriteriaPath .\criteria.json
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-PoC.ps1 -Action Teardown -WhatIf
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-PoC.ps1 -Action Teardown -SubscriptionId <guid> -WorkloadPlan StorageAccounts
        Requires Az.Accounts (+ Az.Storage/Az.Security/Az.Resources per action). Contributor/Security Admin
        on the PILOT subscription for TestSignal/Teardown; Security Reader for Assess/Scorecard.
    EXPECTED RESULTS
        Assess previews readiness; TestSignal populates benign signal; Scorecard writes the decision
        artifact; Teardown deletes the test resource and sets the plan to Free (billing stopped).
.NOTES
    White-label. BENIGN signal only (sample alerts + benign misconfig test resource + EICAR) — never real
    attacks. Disabling the plan at teardown is what STOPS the Defender-for-Cloud billing. Verify current
    pricing before enabling. Whether the PoC "passed" is the customer's security/compliance decision.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Assess','TestSignal','Scorecard','Teardown')]
    [string]$Action,
    [string]$SubscriptionId,
    [string]$ResourceGroup = 'MDC PoC - Pilot RG - Pilot',
    [string]$Location = 'eastus',
    [switch]$DeployTestResource,
    [ValidateSet('VirtualMachines','StorageAccounts','SqlServers','Containers','KeyVaults','AppServices')]
    [string]$WorkloadPlan = 'StorageAccounts',
    [string]$Tag = 'MDC-PoC-TESTSIGNAL',
    [string]$CriteriaPath = '.\criteria.json',
    [string]$OutFile = 'MDC PoC Scorecard - Pilot Sub - Validate.json',
    [switch]$DeleteResourceGroup
)

Import-Module Az.Accounts -ErrorAction SilentlyContinue
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$rgName = ($ResourceGroup -replace '[^A-Za-z0-9-]','-')

switch ($Action) {

    'Assess' {
        Import-Module Az.Security -ErrorAction SilentlyContinue
        Write-Host "`n=== MDCFULL PoC — Assess (read-only preview) ===" -ForegroundColor Cyan
        $ctx = Get-AzContext
        Write-Host ("Account: {0}" -f $ctx.Account.Id)
        Write-Host ("Subscription: {0}" -f $ctx.Subscription.Id)
        try {
            $pricings = Get-AzSecurityPricing -ErrorAction Stop
            $on = @($pricings | Where-Object { $_.PricingTier -eq 'Standard' } | ForEach-Object { $_.Name })
            Write-Host ("Plans currently On (paid): {0}" -f $(if ($on) { $on -join ', ' } else { '(none — CSPM only)' })) -ForegroundColor $(if ($on) { 'Green' } else { 'Yellow' })
        } catch { Write-Host ("Could not read pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        Write-Host "Confirm the cost owner accepts the short Defender-plan billing window before enabling." -ForegroundColor Yellow
        Write-Host "Enable one workload plan with: MDCFULL-Deploy.ps1 -SubscriptionId <id> -Plans $WorkloadPlan -Apply" -ForegroundColor Cyan
    }

    'TestSignal' {
        Write-Host "`n=== MDCFULL PoC — benign test signal ($Tag) ===" -ForegroundColor Cyan
        Write-Host "SAFE ONLY: sample alerts + a benign misconfigured test resource (no real data) + EICAR. No real attacks." -ForegroundColor Yellow

        Write-Host "`n[1] Create built-in SAMPLE security alerts:" -ForegroundColor Cyan
        Write-Host "  portal.azure.com -> Microsoft Defender for Cloud -> Security alerts -> Sample alerts ->" -ForegroundColor Gray
        Write-Host "  select the PILOT subscription and the enabled plan(s) -> Create sample alerts. (Microsoft-provided, benign.)" -ForegroundColor Green

        Write-Host "`n[2] Deploy the benign misconfigured test resource (CSPM recommendation):" -ForegroundColor Cyan
        if ($DeployTestResource) {
            foreach ($m in 'Az.Accounts','Az.Storage') { if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber } }
            Import-Module Az.Storage -ErrorAction Stop
            $saName = ('mdcpoc' + -join ((48..57)+(97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_}))
            if ($PSCmdlet.ShouldProcess("$saName in $rgName", "Deploy benign misconfigured test storage account (public access)")) {
                try {
                    if (-not (Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue)) { New-AzResourceGroup -Name $rgName -Location $Location | Out-Null }
                    New-AzStorageAccount -ResourceGroupName $rgName -Name $saName -Location $Location -SkuName Standard_LRS -Kind StorageV2 -AllowBlobPublicAccess $true -Tag @{ purpose = $Tag } -ErrorAction Stop | Out-Null
                    Write-Host "  Deployed benign test storage '$saName' (public blob access ON) so CSPM raises a recommendation." -ForegroundColor Green
                    Write-Host "  It holds NO real data and is deleted at teardown." -ForegroundColor Gray
                } catch { Write-Host ("  Deploy failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
            } else {
                Write-Host "  [WhatIf] Would deploy a benign misconfigured test storage account in '$rgName'." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Pass -DeployTestResource to deploy the benign misconfigured storage account, or create one in the portal." -ForegroundColor Gray
        }

        Write-Host "`n[3] (Optional) Trigger a benign workload alert on a pilot VM (Defender for Servers):" -ForegroundColor Cyan
        Write-Host "  On a pilot VM covered by Defender for Servers, write the EICAR anti-malware TEST file (benign, not malware):" -ForegroundColor Gray
        Write-Host "    `$e='X5O!P%@AP[4\PZX54(P^)7CC)7}`$'+'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!`$H+H*'; Set-Content C:\Temp\eicar-poc.com `$e -Encoding ascii -NoNewline" -ForegroundColor Gray
        Write-Host "  This raises a benign Defender-for-Servers alert. Delete the file afterwards." -ForegroundColor Green
        Write-Host ("`nSignal generated at: {0}  (record this for scorecard latency). Next: MDCFULL-Validate.ps1 -PoC" -f (Get-Date).ToString('u')) -ForegroundColor Cyan
    }

    'Scorecard' {
        Import-Module Az.Security -ErrorAction SilentlyContinue
        Write-Host "`n=== MDCFULL PoC — scorecard ===" -ForegroundColor Cyan
        $criteria = $null
        if (Test-Path $CriteriaPath) { try { $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json } catch {} }
        # Observe (read-only)
        $obs = [ordered]@{}
        try { $obs.SecureScorePresent = ($null -ne (Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1)) } catch { $obs.SecureScorePresent = $false }
        try { $obs.AlertFired = ((Get-AzSecurityAlert -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) } catch { $obs.AlertFired = $false }
        try { $obs.RecommendationRaised = ((Get-AzSecurityAssessment -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) } catch { $obs.RecommendationRaised = $false }
        $obs.RegulatoryComplianceVisible = $null  # confirm in portal (Regulatory compliance blade)

        $card = [ordered]@{ Timestamp = (Get-Date).ToString('s'); Subscription = (Get-AzContext).Subscription.Id; Observations = $obs; Criteria = $criteria; Verdict = 'Owner decision' }
        foreach ($k in $obs.Keys) { Write-Host ("   {0,-30} {1}" -f $k, $obs[$k]) -ForegroundColor $(if ($obs[$k] -eq $true) { 'Green' } elseif ($null -eq $obs[$k]) { 'DarkGray' } else { 'Yellow' }) }
        Write-Host "   RegulatoryComplianceVisible: confirm in portal -> Regulatory compliance (pilot subscription)." -ForegroundColor DarkGray
        $card | ConvertTo-Json -Depth 8 | Set-Content -Path $OutFile -Encoding UTF8
        Write-Host ("`nScorecard written: {0}. Whether the PoC 'passed' is the customer's security/compliance decision." -f $OutFile) -ForegroundColor Green
    }

    'Teardown' {
        foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') { if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber } }
        Import-Module Az.Security -ErrorAction Stop; Import-Module Az.Resources -ErrorAction Stop
        Write-Host "`n=== MDCFULL PoC — teardown (preview by default; stops billing) ===" -ForegroundColor Cyan

        Write-Host "`n[1] Delete benign test resource(s) tagged '$Tag':" -ForegroundColor Cyan
        try {
            $res = Get-AzResource -TagName purpose -TagValue $Tag -ErrorAction SilentlyContinue
            if ($res) {
                foreach ($r in $res) {
                    if ($PSCmdlet.ShouldProcess($r.Name, "Delete test resource")) {
                        Remove-AzResource -ResourceId $r.ResourceId -Force -ErrorAction SilentlyContinue | Out-Null
                        Write-Host "  Deleted: $($r.Name)" -ForegroundColor Green
                    } else { Write-Host "  [WhatIf] Would delete: $($r.Name)" -ForegroundColor Yellow }
                }
            } else { Write-Host "  No resources tagged '$Tag' found." -ForegroundColor Gray }
        } catch { Write-Host ("  Could not enumerate tagged resources: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

        if ($DeleteResourceGroup) {
            if ($PSCmdlet.ShouldProcess($rgName, "Delete pilot resource group")) {
                Remove-AzResourceGroup -Name $rgName -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  Deleted resource group '$rgName'." -ForegroundColor Green
            } else { Write-Host "  [WhatIf] Would delete resource group '$rgName'." -ForegroundColor Yellow }
        }

        Write-Host "`n[2] Disable Defender for $WorkloadPlan (set to Free) to STOP billing:" -ForegroundColor Cyan
        if ($PSCmdlet.ShouldProcess("$WorkloadPlan", "Set Defender plan to Free (stop billing)")) {
            try {
                Set-AzSecurityPricing -Name $WorkloadPlan -PricingTier 'Free' -ErrorAction Stop
                Write-Host "  Defender for $WorkloadPlan set to Free — billing stopped." -ForegroundColor Green
            } catch { Write-Host ("  Could not disable plan: {0}. Disable it in the portal (Environment settings -> Defender plans)." -f $_.Exception.Message) -ForegroundColor Yellow }
        } else {
            Write-Host "  [WhatIf] Would set Defender for $WorkloadPlan to Free (stop billing)." -ForegroundColor Yellow
        }

        Write-Host "`n[3] Dismiss the benign sample alerts:" -ForegroundColor Cyan
        Write-Host "  portal.azure.com -> Microsoft Defender for Cloud -> Security alerts -> dismiss the '$Tag' / sample alerts." -ForegroundColor Gray
        Write-Host "`nConfirm with: MDCFULL-Validate.ps1 -PoC  (plan should be Free; test resource gone)." -ForegroundColor Cyan
    }
}
