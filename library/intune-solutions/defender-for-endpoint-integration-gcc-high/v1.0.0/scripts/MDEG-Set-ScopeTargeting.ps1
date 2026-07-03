<#
.SYNOPSIS
    MDEG-Set-ScopeTargeting.ps1 — apply RBAC scope tags to MDE policies on a GCC High tenant (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Change script that applies an Intune scope tag to the MDE onboarding and risk-based
        compliance policies so regional or mission admins see only their own devices and
        policies. Runs in preview (-WhatIf) by default; only sets scope tags, never touches
        device state. Replace values like your-scope-tag-name only if you override the default.
        Connects to US Government Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEG-Set-ScopeTargeting.ps1 -ScopeTagName "MDE-Region-East"        # preview
        powershell -ExecutionPolicy Bypass -File .\MDEG-Set-ScopeTargeting.ps1 -ScopeTagName "MDE-Region-East" -WhatIf:$false -Confirm:$false   # apply
        (Graph scopes: DeviceManagementConfiguration.ReadWrite.All,
         DeviceManagementRBAC.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        The named scope tag is resolved and its id is added to each target policy's roleScopeTagIds.
        In preview nothing is written. PASS = each policy lists the scope tag after applying.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless you explicitly apply changes.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]   $TenantId,
    [Parameter(Mandatory = $true)]
    [string]   $ScopeTagName,
    [string[]] $EdrPolicyNames        = @('MDE - EDR Onboarding - Pilot'),
    [string[]] $CompliancePolicyNames = @('CP-Windows-MDE-Risk')
)

$ErrorActionPreference = 'Stop'
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $p = @{ Environment = 'USGov'; Scopes = @('DeviceManagementConfiguration.ReadWrite.All','DeviceManagementRBAC.Read.All') }
    if ($TenantId) { $p.TenantId = $TenantId }
    Connect-MgGraph @p | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { throw "Connected to '$($ctx.Environment)', not USGov. Aborting on GCC High to avoid changing the wrong tenant." }
}

function Get-ScopeTagId {
    param([string] $Name)
    $r = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.us/beta/deviceManagement/roleScopeTags" -ErrorAction Stop
    (@($r.value) | Where-Object { $_.displayName -eq $Name } | Select-Object -First 1).id
}

function Set-PolicyScopeTag {
    param([string] $Kind, [string] $Name, [string] $ScopeTagId, [string] $ScopeTagName)
    $list = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.us/beta/deviceManagement/$Kind" -ErrorAction Stop
    $policy = @($list.value) | Where-Object { $_.displayName -eq $Name } | Select-Object -First 1
    if (-not $policy) { Write-Warning "  Policy '$Name' not found under $Kind — skipping."; return }

    $current = @()
    if ($policy.roleScopeTagIds) { $current = @($policy.roleScopeTagIds) }
    if ($current -contains $ScopeTagId) {
        Write-Host ("  Already scoped: '{0}' has tag '{1}'. No change." -f $Name, $ScopeTagName) -ForegroundColor DarkGray
        return
    }
    $new = @($current + $ScopeTagId | Select-Object -Unique)
    $body = @{ roleScopeTagIds = $new } | ConvertTo-Json

    if ($PSCmdlet.ShouldProcess(("{0} '{1}'" -f $Kind, $Name), ("Add scope tag '{0}'" -f $ScopeTagName))) {
        Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.us/beta/deviceManagement/$Kind/$($policy.id)" -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
        Write-Host ("  APPLIED: '{0}' now scoped with '{1}'." -f $Name, $ScopeTagName) -ForegroundColor Green
    } else {
        Write-Host ("  WHATIF: would add scope tag '{0}' to '{1}'." -f $ScopeTagName, $Name) -ForegroundColor Yellow
    }
}

try {
    Connect-UsGovGraph -TenantId $TenantId
    if ($WhatIfPreference) { Write-Host "Running in PREVIEW (-WhatIf). No changes will be written. Re-run with -WhatIf:`$false -Confirm:`$false to apply." -ForegroundColor Cyan }

    $tagId = Get-ScopeTagId -Name $ScopeTagName
    if (-not $tagId) { throw "Scope tag '$ScopeTagName' not found. Create it in intune.microsoft.us -> Tenant administration -> Roles -> Scope (Tags)." }
    Write-Host ("Resolved scope tag '{0}' -> id {1}" -f $ScopeTagName, $tagId) -ForegroundColor Cyan

    Write-Host "`nApplying to EDR onboarding policies..." -ForegroundColor Cyan
    foreach ($n in $EdrPolicyNames) { Set-PolicyScopeTag 'deviceConfigurations' $n $tagId $ScopeTagName }

    Write-Host "`nApplying to risk-based compliance policies..." -ForegroundColor Cyan
    foreach ($n in $CompliancePolicyNames) { Set-PolicyScopeTag 'deviceCompliancePolicies' $n $tagId $ScopeTagName }

    Write-Host "`nDone." -ForegroundColor Green
}
catch {
    Write-Error ("Scope targeting failed: {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
