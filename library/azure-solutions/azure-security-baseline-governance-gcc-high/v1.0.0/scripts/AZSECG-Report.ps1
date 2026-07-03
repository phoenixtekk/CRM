<#
.SYNOPSIS
    AZSECG-Report.ps1 — Read-only HTML evidence report for the governance baseline on Azure Government (GCC High).
.DESCRIPTION
    PURPOSE
        Produces a dated HTML report summarizing the governance baseline on an Azure Government
        subscription: cloud/endpoint confirmation, management groups, policy assignments and
        compliance, Microsoft Defender for Cloud plans, and Secure Score. For audit evidence
        (FedRAMP High). Read-only. Provide 'your-subscription-id' and an output path.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AZSECG-Report.ps1 -SubscriptionId your-subscription-id -OutputPath .\AZSECG-report.html

        Required modules: Az.Accounts, Az.Resources, Az.Security, Az.PolicyInsights.
        Connects with Connect-AzAccount -Environment AzureUSGovernment (fails fast if not US Gov).
    EXPECTED RESULTS
        An HTML file at -OutputPath. PASS = report generates and shows the baseline objects and
        current compliance/Secure Score. Keep each dated report as audit evidence on Gov storage.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

# Connect / guard
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne 'AzureUSGovernment') {
    Connect-AzAccount -Environment AzureUSGovernment | Out-Null
    $ctx = Get-AzContext
}
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    throw "Wrong cloud: '$($ctx.Environment.Name)'. Run Connect-AzAccount -Environment AzureUSGovernment."
}
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

function HtmlEncode([string]$s){ if($null -eq $s){return ''}; return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;') }
function Rows($items,$cols){
    if(-not $items){ return "<tr><td colspan='$($cols.Count)'><em>none</em></td></tr>" }
    ($items | ForEach-Object {
        $r = $_
        '<tr>' + (($cols | ForEach-Object { "<td>$(HtmlEncode ([string]$r.$_))</td>" }) -join '') + '</tr>'
    }) -join "`n"
}

# Gather (read-only)
$mgs      = try { Get-AzManagementGroup | Select-Object Name, DisplayName } catch { @() }
$pols     = try { Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" | Select-Object Name } catch { @() }
$pricings = try { Get-AzSecurityPricing | Select-Object Name, PricingTier } catch { @() }
$score    = try { Get-AzSecuritySecureScore | Select-Object DisplayName, @{n='Percent';e={[math]::Round($_.Percentage*100,1)}} } catch { @() }
$compliance = try { Get-AzPolicyStateSummary -SubscriptionId $SubscriptionId | Select-Object -ExpandProperty Results } catch { $null }

$compText = if ($compliance) { "$($compliance.NonCompliantResources) non-compliant / $($compliance.NonCompliantPolicies) policies" } else { 'n/a (Az.PolicyInsights not available or no data)' }
$now = (Get-Date).ToString('u')

$html = @"
<!doctype html><html><head><meta charset='utf-8'><title>AZSECG Governance Report — Azure Government</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:2rem;color:#1b1b1b}
h1{color:#0b3d2e}h2{color:#13512e;border-bottom:2px solid #cfe8dc;padding-bottom:.25rem;margin-top:1.6rem}
table{border-collapse:collapse;width:100%;margin:.5rem 0}th,td{border:1px solid #cfe0d8;padding:.4rem .6rem;text-align:left;font-size:.92rem}
th{background:#eaf4ef}.meta{background:#f4faf7;border:1px solid #cfe8dc;padding:.75rem 1rem;border-radius:6px}
code{background:#f0f4f2;padding:.1rem .3rem;border-radius:3px}.flag{color:#8a1c1c;font-weight:600}
</style></head><body>
<h1>Azure Security Baseline &amp; Governance — Report</h1>
<div class='meta'>
<strong>Cloud:</strong> $(HtmlEncode $ctx.Environment.Name) &nbsp;|&nbsp;
<strong>ARM:</strong> <code>$(HtmlEncode $ctx.Environment.ResourceManagerUrl)</code><br>
<strong>Subscription:</strong> $(HtmlEncode $SubscriptionId)<br>
<strong>Generated:</strong> $now<br>
<span class='flag'>Evidence must be stored on Azure Government storage (blob.core.usgovcloudapi.net), not a Commercial account.</span>
</div>

<h2>Management groups</h2>
<table><tr><th>Name</th><th>Display Name</th></tr>
$(Rows $mgs @('Name','DisplayName'))
</table>

<h2>Policy assignments (subscription scope)</h2>
<table><tr><th>Assignment</th></tr>
$(Rows $pols @('Name'))
</table>
<p><strong>Compliance summary:</strong> $(HtmlEncode $compText)</p>

<h2>Microsoft Defender for Cloud plans</h2>
<p>Only Gov-available plans should be <code>Standard</code> (Servers, Storage, Key Vault, Resource Manager, Containers, DNS, SQL, OSS DBs). App Service / Cosmos DB / Foundry-AI are Not Available in Azure Government.</p>
<table><tr><th>Plan</th><th>Pricing Tier</th></tr>
$(Rows $pricings @('Name','PricingTier'))
</table>

<h2>Secure Score</h2>
<table><tr><th>Score</th><th>Percent</th></tr>
$(Rows $score @('DisplayName','Percent'))
</table>

<p style='margin-top:2rem;font-size:.85rem;color:#555'>Generated by AZSECG-Report.ps1 — read-only against Azure Government US Gov endpoints.</p>
</body></html>
"@

$html | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Report written to $OutputPath" -ForegroundColor Green
