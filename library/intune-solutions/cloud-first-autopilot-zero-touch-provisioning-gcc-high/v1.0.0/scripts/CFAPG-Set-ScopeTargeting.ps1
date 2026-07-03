<#
.SYNOPSIS
    CFAPG-Set-ScopeTargeting.ps1 — safely widen provisioning scope during Expand.
.DESCRIPTION
    PURPOSE
        Connects to Microsoft Graph US Gov and adds members (users or groups) to the
        CFAPG provisioning scope on a GCC High / DoD tenant during the Expand phase — for
        example adding a new business-unit group to CFAPG-Provisioning-Users so more users
        can provision devices. Runs in preview mode by default (-WhatIf) and only changes
        membership when you pass -WhatIf:$false. Placeholders use hyphenated names such as
        your-tenant-id, your-target-group-name, and your-member-object-id.
    HOW TO RUN
        Preview (no change):
          powershell -ExecutionPolicy Bypass -File .\CFAPG-Set-ScopeTargeting.ps1 -AddMemberObjectIds your-member-object-id
        Apply:
          powershell -ExecutionPolicy Bypass -File .\CFAPG-Set-ScopeTargeting.ps1 -AddMemberObjectIds your-member-object-id -WhatIf:$false
        (Graph scopes; -Environment USGov)
        Scopes requested: Group.ReadWrite.All, Directory.Read.All
    EXPECTED RESULTS
        Preview lists the members that would be added and changes nothing. Apply adds them
        and confirms. PASS when the target group contains the intended members afterward.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints
    except the explicit membership add performed only when -WhatIf:$false is passed.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$TenantId,
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',
    # The scope group to widen (default: the provisioning users group).
    [string]$TargetGroupName = 'CFAPG-Provisioning-Users',
    # Object ids of users or groups to add, e.g. your-member-object-id.
    [string[]]$AddMemberObjectIds = @(),
    # Default to preview. Pass -WhatIf:$false to actually apply the change.
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
$baseUri = 'https://graph.microsoft.us/beta'

if (-not $AddMemberObjectIds -or $AddMemberObjectIds.Count -eq 0) {
    Write-Host "No -AddMemberObjectIds supplied. Provide user/group object ids (e.g. your-member-object-id) to add. Nothing to do." -ForegroundColor Yellow
    return
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$connect = @{ Environment = $Environment; Scopes = @('Group.ReadWrite.All','Directory.Read.All') }
if ($TenantId) { $connect['TenantId'] = $TenantId }
Connect-MgGraph @connect | Out-Null
$ctx = Get-MgContext
Write-Host ("Connected. Environment = {0} | Tenant = {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Cyan
if ($ctx.Environment -notmatch 'USGov') { throw "Connected environment is not US Gov. Refusing to run against a non-GCC-High cloud." }

$mode = if ($WhatIf) { 'PREVIEW (-WhatIf)' } else { 'APPLY' }
Write-Host ("Mode: {0}" -f $mode) -ForegroundColor Yellow

# Resolve target group
$esc = [uri]::EscapeDataString($TargetGroupName)
$grp = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups?`$filter=displayName eq '$esc'&`$select=id,displayName,membershipRule").value | Select-Object -First 1
if (-not $grp) { throw "Target group '$TargetGroupName' not found (03-implementation Step 1)." }
if ($grp.membershipRule) { throw "Target group '$TargetGroupName' is DYNAMIC; membership is rule-driven and cannot be edited directly. Adjust the rule in the portal instead." }

# Existing members for idempotency
$existing = @()
$uri = "$baseUri/groups/$($grp.id)/members?`$select=id"
do { $p = Invoke-MgGraphRequest -Method GET -Uri $uri; $existing += $p.value.id; $uri = $p.'@odata.nextLink' } while ($uri)

foreach ($id in $AddMemberObjectIds) {
    if ($existing -contains $id) {
        Write-Host ("  [SKIP] {0} already a member of {1}" -f $id, $grp.displayName) -ForegroundColor DarkGray
        continue
    }
    $action = "Add member '$id' to group '$($grp.displayName)'"
    if ($WhatIf) {
        Write-Host ("  [PREVIEW] Would: {0}" -f $action) -ForegroundColor Magenta
        continue
    }
    if ($PSCmdlet.ShouldProcess($grp.displayName, $action)) {
        $body = @{ '@odata.id' = "https://graph.microsoft.us/v1.0/directoryObjects/$id" }
        Invoke-MgGraphRequest -Method POST -Uri "$baseUri/groups/$($grp.id)/members/`$ref" -Body ($body | ConvertTo-Json)
        Write-Host ("  [APPLIED] {0}" -f $action) -ForegroundColor Green
    }
}

if ($WhatIf) {
    Write-Host "`nPreview only — nothing changed. Re-run with -WhatIf:`$false to apply." -ForegroundColor Magenta
} else {
    Write-Host "`nScope updated. Validate the expanded pilot with CFAPG-Validation.ps1 and CFAPG-Report.ps1." -ForegroundColor Cyan
}
