<#
.SYNOPSIS
    CPLTREADY-Validate.ps1 — pre-enablement validation of Copilot readiness for the cohort/wave.
.DESCRIPTION
    PURPOSE
        Confirms the gate conditions before enabling Copilot for a group: the cohort and licensing
        groups exist, members are Copilot-licensed with a usage location, a sensitivity-label baseline
        is published, and (informational) reminds you that oversharing must be cleared. Read-only.
    HOW TO RUN
        Connect-MgGraph -Scopes "Group.Read.All","User.Read.All","Directory.Read.All","InformationProtectionPolicy.Read"
        powershell -ExecutionPolicy Bypass -File .\CPLTREADY-Validate.ps1 -CohortGroupId <id> -LicenseGroupId <id>
        Requires module: Microsoft.Graph.
    EXPECTED RESULTS
        PASS/FAIL per check: groups present, all members licensed, usage location set, labels published.
        A final gate line. Note: verify Copilot SKU and base-plan prerequisite in your tenant.
.NOTES
    Copilot. White-label. Read-only. Licensing/preview facts: verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$CohortGroupId,
    [Parameter(Mandatory)] [string]$LicenseGroupId,
    [string]$CopilotSkuPartNumber = 'Microsoft_365_Copilot'
)

Write-Host "=== CPLTREADY Validate — pre-enablement gate ===" -ForegroundColor Cyan
if (-not (Get-MgContext)) { Write-Host "Run Connect-MgGraph first (see header)." -ForegroundColor Yellow; return }
$results = @{}

# Copilot SKU id
$copilot = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -eq $CopilotSkuPartNumber -or $_.SkuPartNumber -match 'Copilot' }
$copilotSkuIds = @($copilot.SkuId)
$results['Copilot SKU present'] = [bool]$copilot

# Groups exist
foreach ($pair in @(@{n='Cohort group';id=$CohortGroupId}, @{n='License group';id=$LicenseGroupId})) {
    $g = Get-MgGroup -GroupId $pair.id -ErrorAction SilentlyContinue
    $results[$pair.n + ' exists'] = [bool]$g
}

# Members licensed + usage location
$members = Get-MgGroupMember -GroupId $CohortGroupId -All -ErrorAction SilentlyContinue
$total = ($members|Measure-Object).Count; $lic = 0; $noLoc = 0
foreach ($m in $members) {
    $u = Get-MgUser -UserId $m.Id -Property "userPrincipalName,assignedLicenses,usageLocation" -ErrorAction SilentlyContinue
    if (-not $u) { continue }
    if (@($u.AssignedLicenses.SkuId | Where-Object { $copilotSkuIds -contains $_ }).Count -gt 0) { $lic++ }
    if (-not $u.UsageLocation) { $noLoc++ }
}
$results['All cohort members Copilot-licensed'] = ($total -gt 0 -and $lic -eq $total)
$results['All cohort members have usage location'] = ($noLoc -eq 0)

# Sensitivity labels published
try {
    $labels = Get-MgInformationProtectionPolicyLabel -All -ErrorAction Stop
    $results['Sensitivity-label baseline published'] = (($labels|Measure-Object).Count -gt 0)
} catch { $results['Sensitivity-label baseline published'] = $false }

Write-Host ""
$allPass = $true
foreach ($k in $results.Keys | Sort-Object) {
    $ok = $results[$k]
    if (-not $ok) { $allPass = $false }
    Write-Host ("  [{0}] {1}" -f ($(if($ok){'PASS'}else{'FAIL'}), $k)) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
}
Write-Host ("  (Manual) Oversharing remediated for scope : run CPLTREADY-OversharingScan.ps1 and confirm cleared" ) -ForegroundColor Gray

Write-Host ("`nGate: {0}" -f ($(if($allPass){'READY to enable (confirm oversharing cleared)'}else{'NOT READY — resolve FAIL items above'}))) -ForegroundColor ($(if($allPass){'Green'}else{'Yellow'}))
Write-Host ("Cohort licensing: {0}/{1} members Copilot-licensed; {2} missing usage location." -f $lic, $total, $noLoc)
