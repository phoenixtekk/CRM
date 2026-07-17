<#
.SYNOPSIS
    MBXRBAC-Set-AccessPolicy.ps1 — the ONLY state-changer: create/verify the Application Access Policy
    (or the Graph RBAC assignment) that scopes an app to a mail-enabled security group / resource
    scope. DEFAULTS TO -WhatIf (preview only) — it changes nothing unless you pass -Apply.
.DESCRIPTION
    PURPOSE
        The single configuring script for the "Scoping Application-Permission Mailbox Access" solution.
        For the Application Access Policy model it ensures the mail-enabled security group exists,
        contains the allowed mailbox(es), and that an Application Access Policy binds the app to it.
        For the Graph RBAC-for-Exchange model it previews the scope + scoped role assignment. BY
        DEFAULT it runs in -WhatIf mode and only PRINTS what it would do; pass -Apply to execute.
    HOW TO RUN
        # Preview (default — makes NO changes):
        powershell -ExecutionPolicy Bypass -File .\MBXRBAC-Set-AccessPolicy.ps1 `
          -AppId "11111111-1111-1111-1111-111111111111" `
          -ScopeGroup "App Mailbox Scope – Reporting – Prod" `
          -GroupSmtp "app-mailbox-scope-reporting@contoso.com" `
          -AllowedMailbox "reports@contoso.com"
        # Execute for real (only when the preview is correct AND change control is approved):
        ... -Apply
        Requires ExchangeOnlineManagement. Run Connect-ExchangeOnline first, or the script prompts.
    REQUIRED SCOPES / ROLES
        Exchange Online: a role that can run New-DistributionGroup, Add-DistributionGroupMember, and
        New-ApplicationAccessPolicy (and, for the RBAC model, New-ManagementScope /
        New-ManagementRoleAssignment) — commonly Global Administrator or an Exchange role carrying
        Role Management / Organization Configuration rights. VERIFY the exact minimum role and all
        cmdlet names/parameters against current Microsoft documentation.
    EXPECTED RESULTS
        In -WhatIf (default): a printed plan of every object that WOULD be created, no changes made.
        With -Apply: the mail-enabled security group and Application Access Policy exist and scope the
        app; the script then reminds you to allow propagation and run MBXRBAC-Validate.ps1 +
        MBXRBAC-Test-Boundary.ps1.
.NOTES
    Azure Solutions — STATE-CHANGER, defaults to -WhatIf. White-label sample values use contoso.com.
    Every cmdlet/parameter/role/model name below: VERIFY against current Microsoft documentation —
    exact syntax and which model is current/recommended are version- and cloud-dependent.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$AppId,
    [string]$ScopeGroup     = "App Mailbox Scope – Reporting – Prod",
    [string]$GroupSmtp      = "app-mailbox-scope-reporting@contoso.com",
    [string[]]$AllowedMailbox = @("reports@contoso.com"),
    [string]$PolicyDescription = "App Mailbox Scope – Reporting – Prod – Policy",
    [ValidateSet('RestrictAccess','DenyAccess')] [string]$AccessRight = 'RestrictAccess',
    [switch]$Apply   # default OFF => -WhatIf preview only
)

$WhatIf = -not $Apply
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
try { Get-ConnectionInformation -ErrorAction Stop | Out-Null } catch { try { Connect-ExchangeOnline -ShowBanner:$false | Out-Null } catch { Write-Host "Connect-ExchangeOnline failed: $($_.Exception.Message)" -ForegroundColor Red; exit 2 } }

$mode = if ($WhatIf) { 'WHATIF (preview only — no changes)' } else { 'APPLY (executing changes)' }
Write-Host "`n=== Set Application Access Policy — mode: $mode ===" -ForegroundColor Cyan
Write-Host "   App: $AppId   Group: '$ScopeGroup' ($GroupSmtp)   AccessRight: $AccessRight" -ForegroundColor Gray
Write-Host "   Allowed mailbox(es): $($AllowedMailbox -join ', ')" -ForegroundColor Gray
if ($WhatIf) { Write-Host "   (pass -Apply to execute; VERIFY every cmdlet against current Microsoft docs first)" -ForegroundColor Yellow }

# 1) Mail-enabled security group.
$grp = $null
try { $grp = Get-DistributionGroup -Identity $ScopeGroup -ErrorAction Stop } catch {}
if ($grp) {
    Write-Host "   [exists] mail-enabled security group '$ScopeGroup'" -ForegroundColor Green
} else {
    if ($WhatIf) { Write-Host "   [would create] New-DistributionGroup -Name '$ScopeGroup' -Type Security -PrimarySmtpAddress '$GroupSmtp'" -ForegroundColor Yellow }
    else {
        try { New-DistributionGroup -Name $ScopeGroup -Type Security -PrimarySmtpAddress $GroupSmtp -ErrorAction Stop | Out-Null; Write-Host "   [created] group '$ScopeGroup'" -ForegroundColor Green }
        catch { Write-Host "   [ERROR] creating group: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
    }
}

# 2) Membership (only the allowed mailboxes).
foreach ($mbx in $AllowedMailbox) {
    if ($WhatIf) { Write-Host "   [would add] Add-DistributionGroupMember -Identity '$ScopeGroup' -Member '$mbx'" -ForegroundColor Yellow }
    else {
        try { Add-DistributionGroupMember -Identity $ScopeGroup -Member $mbx -ErrorAction Stop; Write-Host "   [added] '$mbx' to '$ScopeGroup'" -ForegroundColor Green }
        catch { Write-Host "   [skip] '$mbx' ($($_.Exception.Message))" -ForegroundColor DarkYellow }
    }
}

# 3) Application Access Policy binding the app to the group. VERIFY cmdlet/params with Microsoft.
if ($WhatIf) {
    Write-Host "   [would create] New-ApplicationAccessPolicy -AppId '$AppId' -PolicyScopeGroupId '$GroupSmtp' -AccessRight $AccessRight -Description '$PolicyDescription'" -ForegroundColor Yellow
} else {
    try {
        New-ApplicationAccessPolicy -AppId $AppId -PolicyScopeGroupId $GroupSmtp -AccessRight $AccessRight -Description $PolicyDescription -ErrorAction Stop | Out-Null
        Write-Host "   [created] Application Access Policy '$PolicyDescription'" -ForegroundColor Green
    } catch { Write-Host "   [ERROR] creating access policy: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
}

Write-Host "`n--- Graph RBAC-for-Exchange model (alternative — preview only) ---" -ForegroundColor Cyan
Write-Host "   If you use the resource-scoped RBAC model instead, the equivalent objects are:" -ForegroundColor Gray
Write-Host "     New-ManagementScope -Name 'App Mailbox Scope – Reporting – RBAC Scope' -RecipientRestrictionFilter \"MemberOfGroup -eq '<DN of $ScopeGroup>'\"" -ForegroundColor DarkGray
Write-Host "     New-ManagementRoleAssignment -Name 'App Mailbox Scope – Reporting – RBAC Assignment' -App '$AppId' -Role '<Application Mail.Read>' -CustomResourceScope 'App Mailbox Scope – Reporting – RBAC Scope'" -ForegroundColor DarkGray
Write-Host "   VERIFY these cmdlets, role names, scope-object types, and which model is current against current Microsoft documentation before running them." -ForegroundColor Yellow

Write-Host ""
if ($WhatIf) { Write-Host "Preview complete. No changes made. Re-run with -Apply to execute." -ForegroundColor Green }
else { Write-Host "Apply complete. Allow propagation (verify current window with Microsoft), then run MBXRBAC-Validate.ps1 and MBXRBAC-Test-Boundary.ps1." -ForegroundColor Green }
