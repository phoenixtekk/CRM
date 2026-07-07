<#
.SYNOPSIS
    ETDG-Get-DiagnosticReport.ps1 — map an observed Enrollment-Time Grouping error/state to its likely root cause, and flag the Azure Activity Log red herring (read-only).
.DESCRIPTION
    Takes the error string or symptom you observed (e.g. the "not an owner" Save failure, the
    "Updating device group for Apple enrollment policy" hang, or an Azure AuthorizationFailed
    entry) and returns the likely root cause plus the next action, per the solution's decision
    tree. Optionally pulls live group state (if -GroupName is supplied) to corroborate. Explicitly
    identifies the Azure Monitor AuthorizationFailed / microsoft.insights errors as an UNRELATED
    red herring. Read-only.
.EXAMPLE
    .\ETDG-Get-DiagnosticReport.ps1 -Symptom NotAnOwner -GroupName "Autopilot - Devices - Pilot"
    .\ETDG-Get-DiagnosticReport.ps1 -Symptom AzureAuthorizationFailed
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph — only needed with -GroupName)
.NOTES
    Expected results: a printed diagnosis (cause + action). Pass = you leave with a single concrete
    next step. White-label. Read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('NotAnOwner', 'CouldNotFindGroup', 'AppleUpdatingHang', 'AzureAuthorizationFailed', 'SavedButNoMembership', 'Unknown')]
    [string]$Symptom,
    [string]$GroupName,
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'
)

$ErrorActionPreference = 'Stop'

# --- Static decision-tree knowledge (keyed to exact symptoms) ---
$diagnoses = @{
    'NotAnOwner' = @{
        Match  = '"Unable to save device group ... the Intune Provisioning Client application is not an owner."'
        Cause  = 'The Intune Provisioning Client SP is NOT an owner of the group, OR the ownership has not propagated yet (5-10 min).'
        Action = 'Add the SP as owner by AppId (ETDG-Set-ProvisioningClientOwner.ps1), wait 5-10 minutes, confirm on the Owners blade, then retry Save.'
    }
    'CouldNotFindGroup' = @{
        Match  = '"...we could not find the security group you selected..."'
        Cause  = 'The group was deleted/renamed after selection, is off-spec (wrong type), OR is outside the admin''s custom Intune RBAC scope groups.'
        Action = 'Confirm the group still exists and is Security/Assigned/cloud-only; if custom RBAC is used, add the group to the admin''s scope groups (ETDG-Test-EnrollmentGroupPrereqs.ps1).'
    }
    'AppleUpdatingHang' = @{
        Match  = 'Notification "Updating device group for Apple enrollment policy" hangs or fails.'
        Cause  = 'Same backend as Windows: usually the owner is missing/not propagated, or the group is off-spec (Dynamic/synced/role-assignable). Apple is sparsely documented but uses the same mechanism.'
        Action = 'Run ETDG-Assess-GroupReadiness.ps1 on the Apple group; fix any FAIL (owner first), wait for propagation, re-save the ADE profile.'
    }
    'AzureAuthorizationFailed' = @{
        Match  = 'Azure Activity Log: AuthorizationFailed on microsoft.insights/eventtypes/values/read across subscriptions.'
        Cause  = 'RED HERRING — this is an Azure Monitor Reader-access error surfaced by the portal background, UNRELATED to Enrollment-Time Grouping.'
        Action = 'IGNORE for this problem. Do not chase subscription RBAC. Diagnose the actual enrollment-grouping Save error instead.'
    }
    'SavedButNoMembership' = @{
        Match  = 'Policy saved successfully, but enrolled devices never join the group.'
        Cause  = 'Owner may have been removed after Save, the policy the device enrolled through lacks the Device Group setting, or the group was later changed off-spec.'
        Action = 'Re-run ETDG-Assess-GroupReadiness.ps1 (confirm R7 still PASS); confirm the enrollment policy/profile still has the correct Device Group set; re-enroll a test device.'
    }
    'Unknown' = @{
        Match  = 'Owner IS present and correct, spec passes, yet Save still fails.'
        Cause  = 'Likely a tenant/service-side backend issue.'
        Action = 'Inspect the actual failing request via Microsoft Graph / browser dev tools (F12 > Network) to capture the real backend error, then open a Microsoft support case with that payload.'
    }
}

$d = $diagnoses[$Symptom]
Write-Host "`n=== ETDG diagnostic report ===" -ForegroundColor Cyan
Write-Host ("Symptom  : {0}" -f $Symptom)
Write-Host ("Matches  : {0}" -f $d.Match)
Write-Host ("Cause    : {0}" -f $d.Cause) -ForegroundColor $(if ($Symptom -eq 'AzureAuthorizationFailed') { 'Yellow' } else { 'White' })
Write-Host ("Action   : {0}" -f $d.Action) -ForegroundColor Green

if ($Symptom -eq 'AzureAuthorizationFailed') {
    Write-Host "`n(Reminder) The Azure Monitor AuthorizationFailed noise never blocks Enrollment-Time Grouping. It is safe to ignore here." -ForegroundColor Yellow
}

# --- Optional live corroboration ---
if ($GroupName -and $Symptom -in @('NotAnOwner', 'CouldNotFindGroup', 'AppleUpdatingHang', 'SavedButNoMembership')) {
    Write-Host "`n--- Live group state (corroboration) ---" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host "Microsoft.Graph SDK not installed — skipping live check." -ForegroundColor Yellow
        return
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes @('Group.Read.All') | Out-Null }

    $escaped = $GroupName -replace "'", "''"
    $grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $escaped)).value
    if (-not $grp) { Write-Host "Group '$GroupName' not found (matches 'could not find the security group')." -ForegroundColor Red; return }
    $g = $grp[0]
    $owners = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$($g.id)/owners").value
    $ownerOk = [bool]($owners | Where-Object { $_.appId -eq $ProvisioningClientAppId })
    Write-Host ("  Assigned membership : {0}" -f $(if ([string]::IsNullOrEmpty($g.membershipRule)) { 'PASS' } else { 'FAIL (Dynamic)' }))
    Write-Host ("  Cloud-only          : {0}" -f $(if (-not $g.onPremisesSyncEnabled) { 'PASS' } else { 'FAIL (synced)' }))
    Write-Host ("  Role-assignable     : {0}" -f $(if (-not $g.isAssignableToRole) { 'PASS (not role-assignable)' } else { 'FAIL (role-assignable)' }))
    Write-Host ("  Provisioning owner  : {0}" -f $(if ($ownerOk) { 'PASS' } else { 'FAIL — add SP as owner' })) -ForegroundColor $(if ($ownerOk) { 'Green' } else { 'Red' })
}
