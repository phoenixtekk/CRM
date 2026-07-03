<#
.SYNOPSIS
    HIPAACOMPG-Remediation.ps1 — safely repair missing scope-group assignments on the HIPAA/HITRUST objects on a GCC High tenant (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Change script that closes the most common gap discovery finds: the clinical scope group is
        not assigned to the compliance policy or a configuration baseline. It appends the group to
        each named object's assignments. Runs in preview (-WhatIf) by default and only changes
        assignments — it never edits a setting, onboards, or offboards a device. Replace values like
        your-group-name only if you override the defaults. Connects to Microsoft Graph US Gov
        (graph.microsoft.us).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HIPAACOMPG-Remediation.ps1                              # preview (WhatIf)
        powershell -ExecutionPolicy Bypass -File .\HIPAACOMPG-Remediation.ps1 -WhatIf:$false -Confirm:$false  # apply
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.Read.All;
         connects with -Environment USGov)
    EXPECTED RESULTS
        A list of planned assignment changes. In preview nothing is written. When applied, the group
        'HIPAA - Clinical Endpoints' is added to each named object missing it. PASS = the
        planned/applied changes match what HIPAACOMPG-Discovery.ps1 reported missing. A
        Commercial-authority error means the session did not reach the US Gov cloud (aborts to avoid
        changing the wrong tenant) — see 06-troubleshooting.md, section F.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless you explicitly apply changes.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string] $TenantId,
    [string] $GroupName            = 'HIPAA - Clinical Endpoints',
    [string] $CompliancePolicyName = 'HIPAA Compliance - Clinical Endpoints - Policy',
    [string[]] $BaselineNames      = @(
        'Encryption - Clinical Endpoints - Baseline',
        'Lock - Clinical Endpoints - Baseline',
        'Antivirus - Clinical Endpoints - Baseline',
        'Firewall - Clinical Endpoints - Baseline',
        'Patch - Clinical Endpoints - Baseline',
        'Access - Clinical Endpoints - Baseline'
    )
)

$ErrorActionPreference = 'Stop'
$GraphBase = 'https://graph.microsoft.us/beta'
# Default to preview unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $p = @{ Environment = 'USGov'; Scopes = @('DeviceManagementConfiguration.ReadWrite.All','Group.Read.All') }
    if ($TenantId) { $p.TenantId = $TenantId }
    Connect-MgGraph @p | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { throw "Connected to '$($ctx.Environment)', not USGov. Aborting on GCC High to avoid changing the wrong tenant (06-troubleshooting.md, F)." }
    Write-Host ("Connected. Environment: {0} | Tenant: {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Green
}

function Get-GovGroupId {
    param([string] $Name)
    $r = Invoke-MgGraphRequest -Method GET -Uri ("{0}/groups?`$filter=displayName eq '{1}'" -f $GraphBase, $Name) -ErrorAction Stop
    (@($r.value) | Select-Object -First 1).id
}

function Get-Policy {
    param([string] $Kind, [string] $Name)  # Kind = deviceCompliancePolicies | deviceConfigurations
    $r = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/deviceManagement/$Kind" -ErrorAction Stop
    @($r.value) | Where-Object { $_.displayName -eq $Name } | Select-Object -First 1
}

function Add-GroupAssignment {
    param([string] $Kind, [string] $PolicyId, [string] $GroupId, [string] $PolicyName, [string] $GroupName)
    $base = "$GraphBase/deviceManagement/$Kind/$PolicyId"
    $cur  = Invoke-MgGraphRequest -Method GET -Uri "$base/assignments" -ErrorAction Stop
    $existing = @($cur.value)
    if ($existing | Where-Object { $_.target.groupId -eq $GroupId }) {
        Write-Host ("  Already assigned: '{0}' -> '{1}'. No change." -f $PolicyName, $GroupName) -ForegroundColor DarkGray
        return
    }
    $targets = @()
    foreach ($a in $existing) { $targets += @{ target = $a.target } }
    $targets += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId } }
    $body = @{ assignments = $targets } | ConvertTo-Json -Depth 8

    if ($PSCmdlet.ShouldProcess(("{0} '{1}'" -f $Kind, $PolicyName), ("Assign group '{0}'" -f $GroupName))) {
        Invoke-MgGraphRequest -Method POST -Uri "$base/assign" -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
        Write-Host ("  APPLIED: assigned '{0}' -> '{1}'." -f $PolicyName, $GroupName) -ForegroundColor Green
    } else {
        Write-Host ("  WHATIF: would assign '{0}' -> '{1}'." -f $PolicyName, $GroupName) -ForegroundColor Yellow
    }
}

try {
    Connect-UsGovGraph -TenantId $TenantId
    if ($WhatIfPreference) { Write-Host "Running in PREVIEW (-WhatIf). No changes will be written. Re-run with -WhatIf:`$false -Confirm:`$false to apply." -ForegroundColor Cyan }

    $groupId = Get-GovGroupId -Name $GroupName
    if (-not $groupId) { throw "Group '$GroupName' not found. Create it first (02-requirements.md R5 / HIPAACOMPG-Set-ScopeTargeting.ps1)." }

    Write-Host "`nChecking compliance policy assignment..." -ForegroundColor Cyan
    $cp = Get-Policy 'deviceCompliancePolicies' $CompliancePolicyName
    if ($cp) { Add-GroupAssignment 'deviceCompliancePolicies' $cp.id $groupId $CompliancePolicyName $GroupName }
    else { Write-Warning "Compliance policy '$CompliancePolicyName' not found — create it (03-implementation.md Step 3)." }

    Write-Host "`nChecking configuration baseline assignments..." -ForegroundColor Cyan
    foreach ($name in $BaselineNames) {
        $b = Get-Policy 'deviceConfigurations' $name
        if ($b) { Add-GroupAssignment 'deviceConfigurations' $b.id $groupId $name $GroupName }
        else { Write-Warning "  Baseline '$name' not found under deviceConfigurations — create it (03-implementation.md Steps 4-8), or it may be a settings-catalog/Update-ring object managed elsewhere." }
    }

    Write-Host "`nDone. Re-run HIPAACOMPG-Discovery.ps1 / HIPAACOMPG-Validation.ps1 to confirm." -ForegroundColor Green
}
catch {
    Write-Error ("Remediation failed: {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
