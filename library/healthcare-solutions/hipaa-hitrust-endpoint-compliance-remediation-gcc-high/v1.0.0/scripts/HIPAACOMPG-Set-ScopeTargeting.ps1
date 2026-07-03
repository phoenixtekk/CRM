<#
.SYNOPSIS
    HIPAACOMPG-Set-ScopeTargeting.ps1 — ensure the clinical scope group exists and apply an Intune scope tag to the HIPAA/HITRUST objects on a GCC High tenant (WhatIf by default).
.DESCRIPTION
    PURPOSE
        Change script that (1) ensures the security group 'HIPAA - Clinical Endpoints' exists on
        your GCC High tenant, creating it if missing, and (2) applies an Intune RBAC scope tag to the
        named compliance policy and configuration baselines so regional or mission admins see only
        their own devices and policies. Runs in preview (-WhatIf) by default; only creates the group
        and sets scope tags — it never changes device state or policy settings. Replace values like
        your-scope-tag-name only if you set -ScopeTagName. Connects to Microsoft Graph US Gov
        (graph.microsoft.us).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HIPAACOMPG-Set-ScopeTargeting.ps1                                    # preview: ensure group only
        powershell -ExecutionPolicy Bypass -File .\HIPAACOMPG-Set-ScopeTargeting.ps1 -ScopeTagName "HIPAA-Region-East" -WhatIf:$false -Confirm:$false   # apply
        (Graph scopes: Group.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All,
         DeviceManagementRBAC.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        The group is confirmed/created and, if -ScopeTagName is given, its id is added to each named
        policy's roleScopeTagIds. In preview nothing is written. PASS = the group exists and each
        policy lists the scope tag after applying. A Commercial-authority error means the session did
        not reach the US Gov cloud (aborts) — see 06-troubleshooting.md, section F.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless you explicitly apply changes.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]   $TenantId,
    [string]   $GroupName            = 'HIPAA - Clinical Endpoints',
    [string]   $MembershipRule       = '(device.deviceOSType -eq "Windows") and (device.deviceCategory -eq "Clinical")',
    [string]   $ScopeTagName,
    [string[]] $CompliancePolicyNames = @('HIPAA Compliance - Clinical Endpoints - Policy'),
    [string[]] $BaselineNames         = @(
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
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $p = @{ Environment = 'USGov'; Scopes = @(
        'Group.ReadWrite.All',
        'DeviceManagementConfiguration.ReadWrite.All',
        'DeviceManagementRBAC.Read.All'
    ) }
    if ($TenantId) { $p.TenantId = $TenantId }
    Connect-MgGraph @p | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { throw "Connected to '$($ctx.Environment)', not USGov. Aborting on GCC High to avoid changing the wrong tenant (06-troubleshooting.md, F)." }
    Write-Host ("Connected. Environment: {0} | Tenant: {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Green
}

function Get-GovGroup {
    param([string] $Name)
    $r = Invoke-MgGraphRequest -Method GET -Uri ("{0}/groups?`$filter=displayName eq '{1}'" -f $GraphBase, $Name) -ErrorAction Stop
    @($r.value) | Select-Object -First 1
}

function Ensure-Group {
    param([string] $Name, [string] $Rule)
    $g = Get-GovGroup -Name $Name
    if ($g) { Write-Host ("  Group '{0}' already exists (id {1})." -f $Name, $g.id) -ForegroundColor DarkGray; return $g.id }

    $mailNick = ($Name -replace '[^A-Za-z0-9]', '')
    $body = @{
        displayName                   = $Name
        description                   = 'Clinical Windows endpoints in scope for HIPAA/HITRUST endpoint enforcement (GCC High).'
        securityEnabled               = $true
        mailEnabled                   = $false
        mailNickname                  = $mailNick
        groupTypes                    = @('DynamicMembership')
        membershipRule                = $Rule
        membershipRuleProcessingState = 'On'
    } | ConvertTo-Json -Depth 6

    if ($PSCmdlet.ShouldProcess(("group '{0}'" -f $Name), 'Create dynamic security group')) {
        $new = Invoke-MgGraphRequest -Method POST -Uri "$GraphBase/groups" -Body $body -ContentType 'application/json' -ErrorAction Stop
        Write-Host ("  APPLIED: created group '{0}' (id {1})." -f $Name, $new.id) -ForegroundColor Green
        return $new.id
    } else {
        Write-Host ("  WHATIF: would create dynamic security group '{0}' with rule: {1}" -f $Name, $Rule) -ForegroundColor Yellow
        return $null
    }
}

function Get-ScopeTagId {
    param([string] $Name)
    $r = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/deviceManagement/roleScopeTags" -ErrorAction Stop
    (@($r.value) | Where-Object { $_.displayName -eq $Name } | Select-Object -First 1).id
}

function Set-PolicyScopeTag {
    param([string] $Kind, [string] $Name, [string] $ScopeTagId, [string] $ScopeTagName)
    $list   = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/deviceManagement/$Kind" -ErrorAction Stop
    $policy = @($list.value) | Where-Object { $_.displayName -eq $Name } | Select-Object -First 1
    if (-not $policy) { Write-Warning "  Policy '$Name' not found under $Kind — skipping (create it per 03-implementation.md)."; return }

    $current = @(); if ($policy.roleScopeTagIds) { $current = @($policy.roleScopeTagIds) }
    if ($current -contains $ScopeTagId) {
        Write-Host ("  Already scoped: '{0}' has tag '{1}'. No change." -f $Name, $ScopeTagName) -ForegroundColor DarkGray
        return
    }
    $new  = @($current + $ScopeTagId | Select-Object -Unique)
    $body = @{ roleScopeTagIds = $new } | ConvertTo-Json

    if ($PSCmdlet.ShouldProcess(("{0} '{1}'" -f $Kind, $Name), ("Add scope tag '{0}'" -f $ScopeTagName))) {
        Invoke-MgGraphRequest -Method PATCH -Uri "$GraphBase/deviceManagement/$Kind/$($policy.id)" -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
        Write-Host ("  APPLIED: '{0}' now scoped with '{1}'." -f $Name, $ScopeTagName) -ForegroundColor Green
    } else {
        Write-Host ("  WHATIF: would add scope tag '{0}' to '{1}'." -f $ScopeTagName, $Name) -ForegroundColor Yellow
    }
}

try {
    Connect-UsGovGraph -TenantId $TenantId
    if ($WhatIfPreference) { Write-Host "Running in PREVIEW (-WhatIf). No changes will be written. Re-run with -WhatIf:`$false -Confirm:`$false to apply." -ForegroundColor Cyan }

    Write-Host "`nEnsuring clinical scope group..." -ForegroundColor Cyan
    Ensure-Group -Name $GroupName -Rule $MembershipRule | Out-Null

    if ($ScopeTagName) {
        $tagId = Get-ScopeTagId -Name $ScopeTagName
        if (-not $tagId) { throw "Scope tag '$ScopeTagName' not found. Create it in intune.microsoft.us -> Tenant administration -> Roles -> Scope (Tags)." }
        Write-Host ("`nResolved scope tag '{0}' -> id {1}" -f $ScopeTagName, $tagId) -ForegroundColor Cyan

        Write-Host "`nApplying scope tag to compliance policies..." -ForegroundColor Cyan
        foreach ($n in $CompliancePolicyNames) { Set-PolicyScopeTag 'deviceCompliancePolicies' $n $tagId $ScopeTagName }

        Write-Host "`nApplying scope tag to configuration baselines..." -ForegroundColor Cyan
        foreach ($n in $BaselineNames) { Set-PolicyScopeTag 'deviceConfigurations' $n $tagId $ScopeTagName }
    } else {
        Write-Host "`nNo -ScopeTagName supplied; ensured the scope group only. Pass -ScopeTagName to also tag the named policies." -ForegroundColor DarkGray
    }

    Write-Host "`nDone." -ForegroundColor Green
}
catch {
    Write-Error ("Scope targeting failed: {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
