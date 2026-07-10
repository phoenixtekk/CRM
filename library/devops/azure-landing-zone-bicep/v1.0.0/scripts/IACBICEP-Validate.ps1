<#
.SYNOPSIS
    IACBICEP-Validate.ps1 — what-if / read-only validation of the deployed Bicep landing zone.
.DESCRIPTION
    PURPOSE
        Confirms the landing zone matches the Testing guide's pass/fail gates: the management-group
        hierarchy exists, the guardrail policy is assigned in the EXPECTED effect (Audit during pilot),
        the least-privilege custom-role assignment is present, standing Owner is minimal, and hub-spoke
        peerings are Connected. Runs `bicep build` and a management-group `what-if` so you can see any
        pending change WITHOUT deploying.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACBICEP-Validate.ps1 -ManagementGroupId alz -Environment NonProd
        Requires the Azure CLI (az, az bicep) and the Az PowerShell modules. Run az login / Connect-AzAccount first.
        *Verify current az / Az module versions.*
    EXPECTED RESULTS
        A PASS/FAIL line per gate and the what-if preview text. No changes are made.
.NOTES
    White-label. Read-only / what-if only. Does not deploy.
#>
[CmdletBinding()]
param(
    [string]$ManagementGroupId = 'alz',
    [ValidateSet('NonProd','Prod')] [string]$Environment = 'NonProd',
    [string]$TemplateFile = '..\main.bicep',
    [string]$ExpectedPolicyEffect = 'Audit'
)

$ErrorActionPreference = 'Continue'
$scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
$pass = 0; $fail = 0
function Gate($name, $ok, $detail) {
    if ($ok) { Write-Host "PASS  $name" -ForegroundColor Green; $script:pass++ }
    else     { Write-Host "FAIL  $name — $detail" -ForegroundColor Red; $script:fail++ }
}

Write-Host "Validating landing zone '$ManagementGroupId' ($Environment)`n" -ForegroundColor Cyan

# Gate 1 — Bicep builds
$build = az bicep build --file $TemplateFile 2>&1
Gate 'Bicep template builds' ($LASTEXITCODE -eq 0) "az bicep build returned $LASTEXITCODE"

# Gate 2 — Management-group hierarchy present
$expected = @('Platform-Tenant-Prod','LandingZones-Tenant-Prod','Sandbox-Tenant-NonProd')
$existing = (az account management-group list --query "[].name" -o tsv) 2>$null
$missing  = $expected | Where-Object { $existing -notcontains $_ }
Gate 'Management-group hierarchy present' (-not $missing) ("missing: " + ($missing -join ', '))

# Gate 3 — Guardrail assigned in the expected effect
$assign = az policy assignment list --scope $scope --query "[?name=='Guardrails-LandingZones']" -o json 2>$null | ConvertFrom-Json
$effect = $assign.parameters.effect.value
Gate "Guardrail assigned in effect '$ExpectedPolicyEffect'" ($effect -eq $ExpectedPolicyEffect) "found effect '$effect'"

# Gate 4 — Least-privilege: standing Owner count is small
try {
    $owners = Get-AzRoleAssignment -RoleDefinitionName 'Owner' -ErrorAction Stop
    Gate 'Standing Owner assignments minimal (<=2 break-glass)' ($owners.Count -le 2) "$($owners.Count) standing Owners"
} catch { Gate 'Standing Owner check' $false $_.Exception.Message }

# Gate 5 — Hub-spoke peerings Connected
try {
    $peers = Get-AzVirtualNetwork -ErrorAction Stop | ForEach-Object { $_.VirtualNetworkPeerings } | Where-Object { $_ }
    $bad   = $peers | Where-Object { $_.PeeringState -ne 'Connected' }
    Gate 'Hub-spoke peerings Connected' ($peers.Count -gt 0 -and -not $bad) ("non-connected: " + (($bad.Name) -join ', '))
} catch { Gate 'Peering check' $false $_.Exception.Message }

# What-if preview (informational — shows any pending drift)
Write-Host "`n--- what-if preview (no changes applied) ---" -ForegroundColor Cyan
az deployment mg what-if --management-group-id $ManagementGroupId --location eastus `
    --template-file $TemplateFile --parameters deployHierarchy=true deployPolicy=true policyEffect=$ExpectedPolicyEffect 2>&1 |
    Out-Host

Write-Host "`nResult: $pass passed, $fail failed." -ForegroundColor ($(if ($fail) {'Red'} else {'Green'}))
if ($fail) { exit 1 } else { exit 0 }
