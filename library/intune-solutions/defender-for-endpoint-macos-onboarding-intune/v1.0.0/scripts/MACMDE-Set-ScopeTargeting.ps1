<#
.SYNOPSIS
    MACMDE-Set-ScopeTargeting.ps1 — safely widen the MDE-for-macOS target scope during Expand.
.DESCRIPTION
    PURPOSE
        Connects to Microsoft Graph and adds members (Macs or groups) to an MDE macOS target group
        during the Expand phase — for example adding a business-unit device group to
        'MDE macOS – Production Devices' so more Macs receive the capability profiles, the Defender
        app, and onboarding. Runs in preview mode by default (-WhatIf) and only changes membership
        when you pass -WhatIf:$false. Placeholders use hyphenated names such as your-tenant-id and
        your-member-object-id. Expand the CAPABILITY profiles first, then app, then onboarding.
    HOW TO RUN
        Preview (no change):
          powershell -ExecutionPolicy Bypass -File .\MACMDE-Set-ScopeTargeting.ps1 -AddMemberObjectIds your-member-object-id
        Apply:
          powershell -ExecutionPolicy Bypass -File .\MACMDE-Set-ScopeTargeting.ps1 -AddMemberObjectIds your-member-object-id -WhatIf:$false
        Scopes requested: Group.ReadWrite.All, Directory.Read.All
    EXPECTED RESULTS
        Preview lists the members that would be added and changes nothing. Apply adds them and
        confirms. PASS when the target group contains the intended members afterward.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph except the explicit
    membership add performed only when -WhatIf:$false is passed.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$TenantId,
    # The scope group to widen (default: the production devices group).
    [string]$TargetGroupName = 'MDE macOS – Production Devices',
    # Object ids of Macs (Entra device objects) or groups to add, e.g. your-member-object-id.
    [string[]]$AddMemberObjectIds = @(),
    # Default to preview. Pass -WhatIf:$false to actually apply the change.
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
$baseUri = 'https://graph.microsoft.com/beta'

if (-not $AddMemberObjectIds -or $AddMemberObjectIds.Count -eq 0) {
    Write-Host "No -AddMemberObjectIds supplied. Provide device/group object ids (e.g. your-member-object-id) to add. Nothing to do." -ForegroundColor Yellow
    return
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$connect = @{ Scopes = @('Group.ReadWrite.All','Directory.Read.All') }
if ($TenantId) { $connect['TenantId'] = $TenantId }
Connect-MgGraph @connect | Out-Null
$ctx = Get-MgContext
Write-Host ("Connected. Tenant = {0}" -f $ctx.TenantId) -ForegroundColor Cyan

$mode = if ($WhatIf) { 'PREVIEW (-WhatIf)' } else { 'APPLY' }
Write-Host ("Mode: {0}" -f $mode) -ForegroundColor Yellow

# Resolve target group
$esc = [uri]::EscapeDataString($TargetGroupName)
$grp = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups?`$filter=displayName eq '$esc'&`$select=id,displayName,membershipRule").value | Select-Object -First 1
if (-not $grp) { throw "Target group '$TargetGroupName' not found (03-implementation Step 3)." }
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
        $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" }
        Invoke-MgGraphRequest -Method POST -Uri "$baseUri/groups/$($grp.id)/members/`$ref" -Body ($body | ConvertTo-Json)
        Write-Host ("  [APPLIED] {0}" -f $action) -ForegroundColor Green
    }
}

if ($WhatIf) {
    Write-Host "`nPreview only — nothing changed. Re-run with -WhatIf:`$false to apply." -ForegroundColor Magenta
} else {
    Write-Host "`nScope updated. Ensure the five capability profiles are assigned/applying to this group BEFORE the app and onboarding." -ForegroundColor Cyan
    Write-Host "Validate the expanded set with MACMDE-Report.ps1 and spot-check 'mdatp health' on a sample Mac." -ForegroundColor Cyan
}
