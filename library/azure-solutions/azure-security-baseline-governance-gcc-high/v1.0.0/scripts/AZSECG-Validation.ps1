<#
.SYNOPSIS
    AZSECG-Validation.ps1 — Read-only pass/fail check of the governance baseline on Azure Government (GCC High).
.DESCRIPTION
    PURPOSE
        Runs the AZSECG test matrix against a deployed baseline on an Azure Government subscription:
        correct cloud, management-group hierarchy, least-privilege custom role, policy initiative
        assignment, Gov-region Allowed Locations, Gov-available Defender plans only, and Secure Score
        presence. Read-only — it verifies, it does not change anything. Use 'your-subscription-id'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AZSECG-Validation.ps1 -SubscriptionId your-subscription-id

        Required modules: Az.Accounts, Az.Resources, Az.Security.
        Connects with Connect-AzAccount -Environment AzureUSGovernment (fails fast if not US Gov).
    EXPECTED RESULTS
        A PASS/FAIL line per test and an overall result. PASS = every applicable test passes.
        FAIL = at least one test fails; the line states what to fix. Exit code 0 = all pass, 1 = any fail.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [string]$CustomRoleName    = 'Governance Operator – Landing Zones – Pilot',
    [string]$InitiativeName    = 'Security Baseline Initiative – Governance Root – Pilot',
    [string[]]$MgNames         = @('Governance Root MG','Platform MG','Landing Zones MG'),
    [string[]]$AllowedGovRegions = @('usgovvirginia','usgovtexas','usgovarizona','usdodeast','usdodcentral')
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Result([string]$id,[string]$name,[bool]$pass,[string]$detail){
    $results.Add([pscustomobject]@{ Id=$id; Test=$name; Result= if($pass){'PASS'}else{'FAIL'}; Detail=$detail })
}

# Connect / guard
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne 'AzureUSGovernment') {
    Connect-AzAccount -Environment AzureUSGovernment | Out-Null
    $ctx = Get-AzContext
}
Add-Result 'T1' 'Context is AzureUSGovernment' ($ctx.Environment.Name -eq 'AzureUSGovernment') "Environment=$($ctx.Environment.Name); ARM=$($ctx.Environment.ResourceManagerUrl)"
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    $results | Format-Table -AutoSize
    throw 'Aborting: not connected to Azure Government. Run Connect-AzAccount -Environment AzureUSGovernment.'
}
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

# T2 management groups
try {
    $mgs = (Get-AzManagementGroup).DisplayName
    $missing = $MgNames | Where-Object { $_ -notin $mgs }
    Add-Result 'T2' 'Management-group hierarchy exists' (-not $missing) ("Missing: {0}" -f ($(if($missing){$missing -join ', '}else{'none'})))
} catch { Add-Result 'T2' 'Management-group hierarchy exists' $false $_.Exception.Message }

# T3 custom role
try {
    $role = Get-AzRoleDefinition -Name $CustomRoleName -ErrorAction SilentlyContinue
    $hasDangerous = $false
    if ($role) {
        $actions = @($role.Actions)
        $hasDangerous = ($actions -contains '*') -or ($role.Actions | Where-Object { $_ -like '*roleAssignments/write' })
    }
    Add-Result 'T3' 'Least-privilege custom role present & scoped' ([bool]$role -and -not $hasDangerous) ("Found={0}; overbroad={1}" -f [bool]$role, $hasDangerous)
} catch { Add-Result 'T3' 'Least-privilege custom role present & scoped' $false $_.Exception.Message }

# T4 initiative assignment
try {
    $assign = Get-AzPolicyAssignment | Where-Object { $_.Name -eq $InitiativeName -or $_.Properties.DisplayName -eq $InitiativeName }
    Add-Result 'T4' 'Security-baseline initiative assigned' ([bool]$assign) ("Found={0}" -f [bool]$assign)
} catch { Add-Result 'T4' 'Security-baseline initiative assigned' $false $_.Exception.Message }

# T5 Allowed Locations = Gov regions only
try {
    $badRegion = $false; $detail = 'no allowedLocations parameter found'
    foreach ($a in (Get-AzPolicyAssignment)) {
        $params = $a.Properties.Parameters
        if ($params -and $params.PSObject.Properties.Name -contains 'listOfAllowedLocations') {
            $vals = @($params.listOfAllowedLocations.value)
            $detail = "allowedLocations = $($vals -join ', ')"
            $nonGov = $vals | Where-Object { $_ -and ($_ -notin $AllowedGovRegions) }
            if ($nonGov) { $badRegion = $true; $detail += " | NON-GOV: $($nonGov -join ', ')" }
        }
    }
    Add-Result 'T5' 'Allowed Locations are Gov regions only' (-not $badRegion) $detail
} catch { Add-Result 'T5' 'Allowed Locations are Gov regions only' $false $_.Exception.Message }

# T6 Defender plans = Gov-available only
try {
    $pricings = Get-AzSecurityPricing
    $govUnavailable = @('AppServices','CosmosDbs')   # not available in Azure Government
    $badPlans = $pricings | Where-Object { $_.Name -in $govUnavailable -and $_.PricingTier -eq 'Standard' }
    Add-Result 'T6' 'Only Gov-available Defender plans enabled' (-not $badPlans) ("Standard plans: {0}" -f (($pricings | Where-Object PricingTier -eq 'Standard').Name -join ', '))
} catch { Add-Result 'T6' 'Only Gov-available Defender plans enabled' $false $_.Exception.Message }

# T8 Secure Score present
try {
    $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue
    Add-Result 'T8' 'Secure Score tracked' ([bool]$score) ("Scores found: {0}" -f (@($score).Count))
} catch { Add-Result 'T8' 'Secure Score tracked' $false $_.Exception.Message }

# Output
Write-Host "`n=== AZSECG Validation (Azure Government) ===" -ForegroundColor Cyan
$results | Format-Table Id, Result, Test, Detail -AutoSize
$failed = @($results | Where-Object Result -eq 'FAIL')
if ($failed.Count -eq 0) {
    Write-Host "OVERALL: PASS — baseline validated on this Gov subscription." -ForegroundColor Green
    exit 0
} else {
    Write-Host ("OVERALL: FAIL — {0} test(s) failed. See Detail above." -f $failed.Count) -ForegroundColor Red
    exit 1
}
