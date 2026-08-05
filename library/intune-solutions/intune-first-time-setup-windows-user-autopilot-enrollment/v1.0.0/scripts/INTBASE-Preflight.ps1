<#
.SYNOPSIS
    INTBASE-Preflight.ps1 — verify tenant readiness for first-time Windows Intune enrollment.

.DESCRIPTION
    PURPOSE
        Read-only preflight for the Microsoft Intune First-Time Setup for Windows. Confirms Intune-bearing
        licensing exists, the MDM authority is Intune, Windows automatic-enrollment is scoped, and the
        Intune Provisioning Client service principal owns the Autopilot device group used for
        enrollment-time grouping.

    HOW TO RUN
        Connect-MgGraph -Environment Global -Scopes "Organization.Read.All","DeviceManagementServiceConfig.Read.All","Group.Read.All","Directory.Read.All"
        # Government: Connect-MgGraph -Environment USGov   (or USGovDoD)
        .\INTBASE-Preflight.ps1 -AutopilotGroupName "INTBASE - Autopilot Devices"

    EXPECTED RESULTS
        A PASS/FAIL table and an overall verdict. All PASS = the tenant is ready to enroll first Windows
        devices (user-driven + basic Autopilot). Read-only — makes no changes.

.NOTES
    Intune Solutions — read-only. Requires the Microsoft.Graph PowerShell module.
#>
[CmdletBinding()]
param(
    [string]$AutopilotGroupName = "INTBASE - Autopilot Devices",
    # Intune Provisioning Client (a.k.a. Intune Autopilot ConfidentialClient) — first-party AppId.
    [string]$ProvisioningClientAppId = "f1346770-5b25-470b-88bd-d5744ab7952c"
)

function R($n, $p, $d) { [pscustomobject]@{ Check = $n; Result = $(if ($p) { 'PASS' } else { 'FAIL' }); Detail = $d } }
$res = New-Object System.Collections.Generic.List[object]

if (-not (Get-MgContext)) { Write-Host "Not connected. Run Connect-MgGraph first." -ForegroundColor Red; exit 1 }

# 1. Intune-bearing licensing present in the tenant
try {
    $skus = Get-MgSubscribedSku -All
    $hasIntune = [bool]($skus | Where-Object { $_.ServicePlans.ServicePlanName -match 'INTUNE_A|INTUNE_O365|INTUNE_EDU' })
    $res.Add((R 'Intune-bearing license present' $hasIntune (($skus | Where-Object { $_.ServicePlans.ServicePlanName -match 'INTUNE' } | Select-Object -Expand SkuPartNumber) -join ', ')))
} catch { $res.Add((R 'Intune-bearing license present' $false $_.Exception.Message)) }

# 2. MDM authority / Windows automatic enrollment configured
try {
    $ae = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceEnrollmentConfigurations?`$top=50"
    $winAuto = $ae.value | Where-Object { $_.'@odata.type' -match 'windows' -or $_.deviceEnrollmentConfigurationType -match 'windows' }
    $res.Add((R 'Windows enrollment configuration present' ([bool]$ae.value) ("configs=" + ($ae.value.Count))))
} catch { $res.Add((R 'Windows enrollment configuration present' $false $_.Exception.Message)) }

# 3. Autopilot device group exists and is Assigned (not dynamic)
$grp = $null
try {
    $g = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f ($AutopilotGroupName -replace "'", "''"))
    $grp = $g.value | Select-Object -First 1
    if ($grp) {
        $isAssigned = -not ($grp.membershipRule) -and ($grp.groupTypes -notcontains 'DynamicMembership')
        $res.Add((R "Autopilot group '$AutopilotGroupName' exists (Assigned)" $isAssigned ("id=" + $grp.id + "; dynamic=" + (-not $isAssigned))))
    } else {
        $res.Add((R "Autopilot group '$AutopilotGroupName' exists (Assigned)" $false 'group not found'))
    }
} catch { $res.Add((R "Autopilot group '$AutopilotGroupName' exists (Assigned)" $false $_.Exception.Message)) }

# 4. Intune Provisioning Client owns the Autopilot group (enrollment-time grouping requirement)
if ($grp) {
    try {
        $owners = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/owners" -f $grp.id)
        $ownerAppIds = @($owners.value | ForEach-Object { $_.appId })
        $ownsIt = $ownerAppIds -contains $ProvisioningClientAppId
        $res.Add((R 'Intune Provisioning Client is group Owner' $ownsIt ("ownerAppIds=" + ($ownerAppIds -join ', '))))
    } catch { $res.Add((R 'Intune Provisioning Client is group Owner' $false $_.Exception.Message)) }
} else {
    $res.Add((R 'Intune Provisioning Client is group Owner' $false 'group missing — cannot check'))
}

Write-Host "`n=== INTBASE Preflight (tenant: $((Get-MgContext).TenantId)) ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$overall = if ($res | Where-Object { $_.Result -eq 'FAIL' }) { 'NOT READY' } else { 'READY' }
Write-Host "Overall: $overall" -ForegroundColor $(if ($overall -eq 'READY') { 'Green' } else { 'Yellow' })
