<#
.SYNOPSIS
    AIWLSEC-ContentSafety.ps1 — read-only content-safety / responsible-AI posture review of Azure OpenAI deployments.
.DESCRIPTION
    PURPOSE
        For each Azure OpenAI model deployment in scope, reports whether a content-filter (RAI) policy is
        attached and lists the custom RAI policies defined on the account. It also emits a checklist of the
        higher-order safety controls to VERIFY — prompt shields / jailbreak detection, protected-material
        detection, and groundedness detection — WITHOUT asserting a gap, because several are in preview or
        region-limited. The acceptable-content threshold itself is the customer's trust-and-safety decision;
        this reviews whether controls EXIST, not what they should be set to. Read-only; changes nothing.
    HOW TO RUN
        Connect-AzAccount
        pwsh -File .\AIWLSEC-ContentSafety.ps1 -SubscriptionIds "<sub>" -OutputFolder "<secure path>"
        *Verify the current RAI-policy API surface, property names, and preview status for your region.*
    EXPECTED RESULTS
        A per-deployment table (content filter attached? which policy?) and a "verify availability" checklist
        of preview safety features. CSV in the output folder. Read-only.
.NOTES
    White-label. Read-only. Makes no changes. Preview features are flagged "verify", never asserted as gaps.
#>
[CmdletBinding()]
param(
    [string[]]$SubscriptionIds,
    [Parameter(Mandatory=$true)][string]$OutputFolder
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$rows = New-Object System.Collections.Generic.List[object]
Write-Host "AIWLSEC content-safety / responsible-AI review (read-only)`n" -ForegroundColor Cyan

if (-not $SubscriptionIds) { $SubscriptionIds = (Get-AzSubscription -ErrorAction SilentlyContinue).Id }

foreach ($sid in $SubscriptionIds) {
    try { Set-AzContext -SubscriptionId $sid -ErrorAction Stop | Out-Null } catch { Write-Host "  (skip $sid — Reader missing? R1)" -ForegroundColor Yellow; continue }

    foreach ($a in (Get-AzCognitiveServicesAccount -ErrorAction SilentlyContinue | Where-Object { $_.Kind -in @('OpenAI','AIServices') })) {
        # Custom RAI content-filter policies defined on the account (API surface varies — *verify*)
        $raiPolicies = @()
        try {
            $resp = Invoke-AzRestMethod -Method GET -Path ("$($a.Id)/raiPolicies?api-version=2024-10-01") -ErrorAction SilentlyContinue
            if ($resp -and $resp.Content) { $raiPolicies = (ConvertFrom-Json $resp.Content).value }
        } catch {}
        $policyNames = if ($raiPolicies) { ($raiPolicies.name) -join ',' } else { '(default only — verify)' }

        $deployments = @()
        try { $deployments = Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $a.ResourceGroupName -AccountName $a.AccountName -ErrorAction SilentlyContinue } catch {}
        if (-not $deployments) {
            $rows.Add([pscustomobject]@{ Subscription=$sid; Account=$a.AccountName; Deployment='(none)'; ContentFilter='n/a'; Verdict='no deployments' })
            continue
        }
        foreach ($d in $deployments) {
            $filter = $d.Properties.RaiPolicyName    # *verify property name*
            $verdict = if ($filter) { "PASS: filter '$filter'" } else { 'FINDING: no content-filter policy attached' }
            $rows.Add([pscustomobject]@{ Subscription=$sid; Account=$a.AccountName; Deployment=$d.Name
                ContentFilter=(if($filter){$filter}else{'(none)'}); AccountPolicies=$policyNames; Verdict=$verdict })
        }
    }
}

if ($rows.Count -eq 0) { Write-Host "No Azure OpenAI deployments found in scope (R1)." -ForegroundColor Yellow }
else {
    $rows | Format-Table -AutoSize
    $csv = Join-Path $OutputFolder "AIWLSEC-contentsafety-$stamp.csv"
    $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
    Write-Host "`nSaved: $csv" -ForegroundColor Green
    $findings = @($rows | Where-Object { $_.Verdict -like 'FINDING*' })
    Write-Host "$($findings.Count) deployment(s) with no content filter attached. Feed to AIWLSEC-Report.ps1." -ForegroundColor Yellow
}

# --- Higher-order safety controls to VERIFY (do NOT assert as gaps) ----------
Write-Host "`n--- Verify these higher-order safety controls in Azure AI Foundry / Content Safety (several are PREVIEW) ---" -ForegroundColor Cyan
@(
    'Prompt Shields (jailbreak / indirect prompt-injection detection) — *verify availability in your region*',
    'Protected-material detection (text/code) — *verify availability*',
    'Groundedness detection for RAG responses — *verify availability (preview)*',
    'Asynchronous / streaming content filtering — *verify availability*',
    'A documented responsible-AI review + owner per model in use — governance (customer-owned policy)'
) | ForEach-Object { Write-Host "  [ ] $_" -ForegroundColor Gray }
Write-Host "`nRead-only; nothing was changed. Preview features are flagged to verify — not reported as hard gaps." -ForegroundColor Green
