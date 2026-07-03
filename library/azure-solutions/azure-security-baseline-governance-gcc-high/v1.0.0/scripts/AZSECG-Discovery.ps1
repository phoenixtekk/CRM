<#
.SYNOPSIS
    AZSECG-Discovery.ps1 — Read-only inventory of governance baseline state on an Azure Government (GCC High) subscription.
.DESCRIPTION
    PURPOSE
        Captures the current governance posture on an Azure Government tenant: management-group
        hierarchy, standing role assignments, policy assignments, Microsoft Defender for Cloud plan
        status, and Secure Score. This is the pre-change baseline and rollback reference. It writes
        nothing and changes nothing. Provide your subscription id as 'your-subscription-id'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AZSECG-Discovery.ps1 -SubscriptionId your-subscription-id

        Required modules: Az.Accounts, Az.Resources, Az.Security.
        Connects to Azure US Gov endpoints with Connect-AzAccount -Environment AzureUSGovernment.
        The script fails fast if the current context is not AzureUSGovernment.
    EXPECTED RESULTS
        A console summary (and optional JSON via -OutputPath) of MGs, roles, policy, Defender plans,
        and Secure Score. PASS = discovery completes and lists your Gov subscription with no blocking
        prerequisite gaps. FAIL = prerequisite gaps reported; fix before configuring.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Connect-USGov {
    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx -or $ctx.Environment.Name -ne 'AzureUSGovernment') {
        Write-Host 'Connecting to Azure Government (AzureUSGovernment)...' -ForegroundColor Cyan
        Connect-AzAccount -Environment AzureUSGovernment | Out-Null
        $ctx = Get-AzContext
    }
    if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
        throw "Wrong cloud: context is '$($ctx.Environment.Name)'. This solution requires AzureUSGovernment. Run Connect-AzAccount -Environment AzureUSGovernment."
    }
    Write-Host "Cloud OK: $($ctx.Environment.Name)  ARM=$($ctx.Environment.ResourceManagerUrl)" -ForegroundColor Green
}

Connect-USGov
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

$report = [ordered]@{
    generatedAt      = (Get-Date).ToString('o')
    environment      = (Get-AzContext).Environment.Name
    resourceManager  = (Get-AzContext).Environment.ResourceManagerUrl
    subscriptionId   = $SubscriptionId
}

Write-Host "`n=== Management groups ===" -ForegroundColor Yellow
try {
    $mgs = Get-AzManagementGroup -ErrorAction Stop
    $report.managementGroups = @($mgs | Select-Object Name, DisplayName)
    $mgs | Select-Object Name, DisplayName | Format-Table -AutoSize
} catch {
    Write-Warning "Could not enumerate management groups: $($_.Exception.Message)"
    $report.managementGroups = @()
}

Write-Host "`n=== Role assignments (subscription scope) ===" -ForegroundColor Yellow
$roles = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId"
$report.roleAssignments = @($roles | Select-Object DisplayName, RoleDefinitionName, Scope)
$roles | Select-Object DisplayName, RoleDefinitionName, Scope | Format-Table -AutoSize
$broad = $roles | Where-Object { $_.RoleDefinitionName -in @('Owner','Contributor') -and $_.Scope -eq "/subscriptions/$SubscriptionId" }
$report.broadStandingGrants = @($broad | Select-Object DisplayName, RoleDefinitionName)
if ($broad) { Write-Host ("NOTE: {0} broad standing Owner/Contributor grant(s) at subscription scope — candidates for least-privilege reduction." -f $broad.Count) -ForegroundColor Magenta }

Write-Host "`n=== Policy assignments ===" -ForegroundColor Yellow
$pols = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId"
$report.policyAssignments = @($pols | Select-Object -ExpandProperty Name)
$pols | Select-Object Name | Format-Table -AutoSize

Write-Host "`n=== Microsoft Defender for Cloud plans ===" -ForegroundColor Yellow
try {
    $pricings = Get-AzSecurityPricing -ErrorAction Stop
    $report.defenderPlans = @($pricings | Select-Object Name, PricingTier)
    $pricings | Select-Object Name, PricingTier | Format-Table -AutoSize
    $govUnavailable = @('AppServices','CosmosDbs')
    $flagged = $pricings | Where-Object { $_.Name -in $govUnavailable -and $_.PricingTier -eq 'Standard' }
    if ($flagged) { Write-Host "WARNING: A Defender plan not available in Azure Government appears enabled — verify: $($flagged.Name -join ', ')" -ForegroundColor Red }
} catch {
    Write-Warning "Could not read Defender pricing (ensure Security Admin + Microsoft.Security provider registered): $($_.Exception.Message)"
    $report.defenderPlans = @()
}

Write-Host "`n=== Secure Score ===" -ForegroundColor Yellow
try {
    $score = Get-AzSecuritySecureScore -ErrorAction Stop
    $report.secureScore = @($score | Select-Object DisplayName, @{n='Percentage';e={[math]::Round($_.Percentage*100,1)}})
    $score | Select-Object DisplayName, @{n='Percentage';e={[math]::Round($_.Percentage*100,1)}} | Format-Table -AutoSize
} catch {
    Write-Warning "Secure Score not available yet: $($_.Exception.Message)"
    $report.secureScore = @()
}

if ($OutputPath) {
    $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "`nBaseline written to $OutputPath" -ForegroundColor Green
}

Write-Host "`nDiscovery complete. This is your pre-change baseline (rollback reference)." -ForegroundColor Green
